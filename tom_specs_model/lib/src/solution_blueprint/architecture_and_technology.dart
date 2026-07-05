/// Section 8: Technical Framework Concept. Seeds → ATS.
///
/// Technical framework requirements and constraints.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// 8. Technical Framework Concept. Seeds → ATS.
@Comment('Seeds → ATS')
@MapsTo(D06ArchitectureTechnologySpecification)
@ContentHelp('''
Describe the complete technical foundation for building and operating
the target system. This section seeds the Architecture & Technology
Specification (ATS) document where all technical decisions will be
expanded into detailed implementation specifications.

**Purpose**: Establish technical constraints, architectural decisions,
and infrastructure requirements that guide all development work.

**Structure Overview**:
- **Basic Technical Requirements**: Platform, architecture style, patterns
- **Software Design**: Layering, development environment, reusable components
- **Standard Software**: Compatibility, standards compliance
- **Hardware**: Server, client, network infrastructure
- **Operations**: Backup, deployment, monitoring, maintenance
- **Communication**: Protocols, external connectivity
- **System Operation**: Administration, health checks, capacity
- **Security**: IT security standards, privacy, auditing

**Integration Points**: All subsections feed into the ATS document.
Decisions must align with business requirements from the target-process
sections and the system overview. Security requirements coordinate with
the security and access model.
''')
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
    'ISO/IEC 25010 — product quality (maintainability/portability)',
  ],
  'Captures the technical framework: platform, language, architecture style and design patterns that found and constrain the target system.',
)
@SectionId('TECH')
class TechnicalFrameworkConcept {
  @ContentHelp('''
Provide an executive summary of the technical framework approach.

**Include**:
- Key architectural decisions and rationale
- Critical technology choices and constraints
- Major technical risks and mitigation strategies
- Technology evaluation criteria used
- Timeline for technical decisions and reviews

**Best Practices**:
- Reference industry standards (ISO 42010, TOGAF, IEEE 1471)
- Document trade-offs explicitly (e.g., time-to-market vs. scalability)
- Include technology radar assessment (Adopt, Trial, Assess, Hold)
- Cross-reference with business drivers from project overview
- Plan for technology obsolescence and migration paths
''')
  @SerializationOrder(0)
  String? content;

  /// 8.1. Basic Technical Requirements.
  @SerializationOrder(1)
  BasicTechnicalRequirements basicRequirements = BasicTechnicalRequirements();

  /// 8.2. Software Design Requirements.
  @SerializationOrder(2)
  SoftwareDesignRequirements softwareDesign = SoftwareDesignRequirements();

  /// 8.3. Standard Application Software Requirements.
  @SerializationOrder(3)
  StandardSoftwareRequirements standardSoftware = StandardSoftwareRequirements();

  /// 8.4. Hardware Concept Requirements.
  @SerializationOrder(4)
  HardwareRequirements hardware = HardwareRequirements();

  /// 8.5. Operations Requirements.
  @SerializationOrder(5)
  OperationsRequirements operations = OperationsRequirements();

  /// 8.6. Communication Requirements.
  @SerializationOrder(6)
  CommunicationRequirements communication = CommunicationRequirements();

  /// 8.7. System Operation and Monitoring.
  @SerializationOrder(7)
  SystemOperationAndMonitoring systemOperation = SystemOperationAndMonitoring();

  /// 8.8. Security Requirements.
  @SerializationOrder(8)
  TechnicalSecurityRequirements security = TechnicalSecurityRequirements();

  /// 8.9. System Architecture..
  @SerializationOrder(9)
  SystemArchitectureSpec systemArchitecture = SystemArchitectureSpec();
}

/// 8.1. Basic Technical Requirements.
@DetailedIn(D06ArchitectureTechnologySpecification)
@SecondLevelSectionId(D06ArchitectureTechnologySpecification, 'ATS-BAS')
@ContentHelp('''
Define the foundational technical requirements that govern all system
development. These decisions have far-reaching implications and should
be made early with careful stakeholder alignment.

**Subsections**:
- **Platform and Language**: Runtime environments, programming languages,
  frameworks, build toolchain, deployment targets
- **Architecture Style**: Monolith, microservices, serverless, or hybrid;
  component organization; communication patterns; scalability approach
- **Design Patterns and Standards**: Required patterns, coding standards,
  industry compliance (ISO, OWASP, IEEE), quality metrics

**Decision Criteria**:
- Business requirements alignment (performance, availability, cost)
- Team capabilities and hiring market
- Ecosystem maturity and vendor support
- Long-term maintainability and evolution
- Regulatory and compliance requirements

**Reference Frameworks**: TOGAF, C4 Model, ISO/IEC 25010 (quality model),
OWASP guidelines, IEEE 1471 architectural description.
''')
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
  ],
  'Defines the foundational technical requirements — platform and language, architecture style, and design patterns and standards — that govern all development.',
)
@SectionId('BTREQ')
class BasicTechnicalRequirements {
  @ContentHelp('''
Provide an overview of basic technical requirements and key decisions.

**Include**:
- Summary of platform and language choices
- Architecture style justification
- Key design patterns and standards adopted
- Major technical constraints and their origins
- Dependencies between technical choices

**Best Practices**:
- Use Architecture Decision Records (ADRs) for major decisions
- Document rejected alternatives and reasons
- Identify reversible vs. irreversible decisions
- Plan technical debt management strategy
- Establish technology evaluation criteria
''')
  @SerializationOrder(0)
  String? content;

  /// 8.1.1. Platform and Language.
  @SerializationOrder(1)
  PlatformAndLanguage platformAndLanguage = PlatformAndLanguage();

  /// 8.1.2. Architecture Style.
  @SerializationOrder(2)
  ArchitectureStyle architectureStyle = ArchitectureStyle();

  /// 8.1.3. Design Patterns and Standards.
  @SerializationOrder(3)
  DesignPatternsAndStandards designPatternsAndStandards =
      DesignPatternsAndStandards();
}

// =============================================================================
// 8.1.1. Platform and Language
// =============================================================================

/// 8.1.1. Platform and Language.
///
/// Required platforms (operating system, runtime), programming languages,
/// and framework choices with minimum versions and justification.
@ContentHelp('''
Specify all platform targets, programming languages, frameworks, build
tools, and deployment configurations. These choices define the technical
foundation and constrain future development options.

**Coverage Areas**:
- **Target Platforms**: OS (Linux, Windows, macOS), runtimes (Node.js,
  JVM, .NET), containers (Docker, Kubernetes), cloud platforms (AWS,
  Azure, GCP), mobile (iOS, Android), embedded systems
- **Programming Languages**: Primary and secondary languages, version
  requirements, SDK specifications, type safety requirements
- **Frameworks**: UI frameworks (Flutter, React, Angular), backend
  frameworks (Spring, Django, Express), testing frameworks, ORM/database
- **Build Toolchain**: Build systems, code generators, bundlers, package
  managers, CI/CD integration, artifact repositories
- **Deployment Targets**: Production environments, staging, development,
  edge deployment, app stores, container registries

**Decision Factors**:
- Performance requirements and benchmarks
- Team expertise and learning curve
- Ecosystem maturity and community support
- License compatibility (MIT, Apache, GPL implications)
- Long-term support and vendor viability
- Cross-platform requirements and code sharing
''')
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'Semantic Versioning (SemVer) — version numbering',
    'ISO/IEC 25010 — portability/compatibility',
  ],
  'Specifies the platform targets, programming languages, frameworks, build toolchain and deployment configurations that form the technical foundation.',
)
@SectionId('PLLNG')
class PlatformAndLanguage {
  @ContentHelp('''
Provide a strategic overview of platform and technology selections.

**Include**:
- Executive summary of technology stack
- Primary vs. secondary platform priorities
- Polyglot strategy rationale (if using multiple languages)
- Platform-specific considerations and trade-offs
- Technology adoption timeline and migration paths

**Best Practices**:
- Document minimum viable versions with EOL dates
- Specify LTS (Long-Term Support) requirements
- Plan for breaking changes in major version upgrades
- Consider developer experience and productivity
- Evaluate total cost of ownership (licensing, training, tooling)
''')
  @SerializationOrder(0)
  String? content;

  /// General platform and technology overview.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Target platforms (operating systems, runtimes, containers).
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'ISO/IEC 25010 — portability/compatibility',
    ],
    'The target platforms — operating systems, runtimes and containers — the system will run on.',
  )
  @SectionId('TGPLT-TARG-LST')
  @SectionIdPattern('TGPLT-TARG-xxx')
  @ContentHelp('Add one entry per target platform.')
  @SerializationOrder(2)
  List<TargetPlatformEntry> targetPlatforms = [];

  /// Programming language requirements.
  @StandardReferences(
    [
      'language standard (ISO/ECMA/PEP) — programming language specification',
      'Semantic Versioning (SemVer) — version numbering',
    ],
    'The programming languages, with version and SDK requirements, used to build the system.',
  )
  @SectionId('PLGEN-PROG-LST')
  @SectionIdPattern('PLGEN-PROG-xxx')
  @ContentHelp('Add one entry per programming language.')
  @SerializationOrder(3)
  List<ProgrammingLanguageEntry> programmingLanguages = [];

  /// Framework and library requirements.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'Semantic Versioning (SemVer) — version numbering',
    ],
    'The frameworks and libraries, with versions and license constraints, the system depends on.',
  )
  @SectionId('FWREN-FRAM-LST')
  @SectionIdPattern('FWREN-FRAM-xxx')
  @ContentHelp('Add one entry per framework or library.')
  @SerializationOrder(4)
  List<FrameworkRequirementEntry> frameworks = [];

  /// Build toolchain requirements.
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'The build tools and toolchain — build systems, compilers, bundlers and package managers — used to produce artifacts.',
  )
  @SectionId('BTCEN-BUIL-LST')
  @SectionIdPattern('BTCEN-BUIL-xxx')
  @ContentHelp('Add one entry per build tool.')
  @SerializationOrder(5)
  List<BuildToolchainEntry> buildToolchain = [];

  /// Deployment target specifications.
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'The deployment targets — production, staging and distribution environments — the system is released to.',
  )
  @SectionId('DETAEN-DEPL-LST')
  @SectionIdPattern('DETAEN-DEPL-xxx')
  @ContentHelp('Add one entry per deployment target.')
  @SerializationOrder(6)
  List<DeploymentTargetEntry> deploymentTargets = [];

  /// Dependency management requirements.
  @SerializationOrder(7)
  DependencyManagement dependencyManagement = DependencyManagement();

  /// Runtime environment constraints.
  @SerializationOrder(8)
  RuntimeEnvironment runtimeEnvironment = RuntimeEnvironment();
}

/// Target platform entry (operating system, runtime, container).
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — portability/compatibility',
  ],
  'A single target platform — operating system, runtime or container — with its version, architecture, requirements and lifecycle.',
)
@SectionId('TGPLT')
class TargetPlatformEntry {
  @Form([
    Field('platformName', String, 'Platform Name',
        required: true,
        hint: 'E.g., Linux, Windows Server, macOS, iOS, Android'),
    Field('platformCategory', String, 'Category',
        hint:
            'Operating System, Runtime Environment, Container Platform, Cloud Platform'),
    Field(
        'platformType', String, 'Type', hint: 'Server, Desktop, Mobile, IoT'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Version requirements.
  @SerializationOrder(1)
  TargetPlatformEntryVersion version = TargetPlatformEntryVersion();

  /// Architecture details.
  @SerializationOrder(2)
  TargetPlatformEntryArchitecture architecture =
    TargetPlatformEntryArchitecture();

  /// Requirements and constraints.
  @SerializationOrder(3)
  TargetPlatformEntryRequirements requirements =
    TargetPlatformEntryRequirements();

  /// Lifecycle and compliance.
  @SerializationOrder(4)
  TargetPlatformEntryLifecycle lifecycle = TargetPlatformEntryLifecycle();
}

/// Version requirements.
@StandardReferences(
  ['Semantic Versioning (SemVer) — version numbering'],
  'The minimum, recommended and maximum supported versions of a target platform.',
)
@SectionId('TPEVR')
class TargetPlatformEntryVersion {
  @Form([
  Field('minimumVersion', String, 'Minimum Version',
    required: true, hint: 'Earliest supported version'),
  Field('recommendedVersion', String, 'Recommended Version',
    hint: 'Preferred target version'),
  Field('maximumVersion', String, 'Maximum Version',
    hint: 'Latest tested/supported version'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Architecture details.
@StandardReferences(
  ['ISO/IEC 25010 — portability/compatibility'],
  'The processor architectures and bitness a target platform supports.',
)
@SectionId('TPEAR')
class TargetPlatformEntryArchitecture {
  @Form([
  Field('supportedArchitectures', String, 'Supported Architectures',
    hint: 'E.g., x86_64, ARM64, WASM'),
  Field('bitness', String, 'Bitness', hint: '32-bit, 64-bit, Both'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Requirements and constraints.
@StandardReferences(
  ['ISO/IEC 25010 — portability/compatibility'],
  'The minimum memory, storage and OS features a target platform must provide.',
)
@SectionId('TPERQ')
class TargetPlatformEntryRequirements {
  @Form([
  Field('minimumMemory', String, 'Minimum Memory',
    hint: 'Minimum RAM requirement'),
  Field('minimumStorage', String, 'Minimum Storage',
    hint: 'Minimum disk space'),
  Field('requiredFeatures', String, 'Required Features',
    hint: 'Specific OS features or capabilities needed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Lifecycle and compliance.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The justification, support scope, end-of-life date and certification requirements for a target platform.',
)
@SectionId('TPELC')
class TargetPlatformEntryLifecycle {
  @Form([
  Field('justification', String, 'Justification',
    hint: 'Reason for selecting this platform'),
  Field('supportScope', String, 'Support Scope',
    hint: 'Primary, Secondary, Limited'),
  Field('endOfLifeDate', String, 'End of Life Date',
    hint: 'Platform EOL date for planning'),
  Field('certificationRequirements', String, 'Certification Requirements',
    hint: 'Required platform certifications'),
  Field('notes', String, 'Notes',
    hint: 'Additional platform-specific notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Programming language requirement entry.
@StandardReferences(
  [
    'language standard (ISO/ECMA/PEP) — programming language specification',
    'Semantic Versioning (SemVer) — version numbering',
  ],
  'A single programming language with its variant, version, SDK, usage context, quality settings and justification.',
)
@SectionId('PLGEN')
class ProgrammingLanguageEntry {
  @Form([
    Field('languageName', String, 'Language Name',
        required: true, hint: 'E.g., Dart, TypeScript, Python, Rust'),
    Field('languageVariant', String, 'Variant',
        hint: 'E.g., Sound null safety, Strict mode'),
    Field('minimumVersion', String, 'Minimum Version',
        required: true, hint: 'Earliest supported language version'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Version requirements.
  @SerializationOrder(1)
  ProgrammingLanguageEntryVersion version = ProgrammingLanguageEntryVersion();

  /// SDK configuration.
  @SerializationOrder(2)
  ProgrammingLanguageEntrySdk sdk = ProgrammingLanguageEntrySdk();

  /// Usage context.
  @SerializationOrder(3)
  ProgrammingLanguageEntryUsage usage = ProgrammingLanguageEntryUsage();

  /// Quality settings.
  @SerializationOrder(4)
  ProgrammingLanguageEntryQuality quality = ProgrammingLanguageEntryQuality();

  /// Justification and notes.
  @SerializationOrder(5)
  ProgrammingLanguageEntryJustification justification =
      ProgrammingLanguageEntryJustification();
}

/// Version requirements for programming language.
@StandardReferences(
  ['Semantic Versioning (SemVer) — version numbering'],
  'The recommended and maximum supported versions of a programming language.',
)
@SectionId('PLGVR')
class ProgrammingLanguageEntryVersion {
  @Form([
    Field('recommendedVersion', String, 'Recommended Version',
        hint: 'Preferred target version'),
    Field('maximumVersion', String, 'Maximum Version',
        hint: 'Latest tested/supported version'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// SDK configuration for programming language.
@StandardReferences(
  [
    'Semantic Versioning (SemVer) — version numbering',
    'language standard (ISO/ECMA/PEP) — programming language specification',
  ],
  'The SDK name and minimum/recommended versions for a programming language.',
)
@SectionId('PLGSK')
class ProgrammingLanguageEntrySdk {
  @Form([
    Field('sdkName', String, 'SDK Name', hint: 'E.g., Dart SDK, Node.js'),
    Field('sdkMinVersion', String, 'SDK Min Version',
        hint: 'Minimum SDK version'),
    Field('sdkRecommendedVersion', String, 'SDK Recommended Version',
        hint: 'Recommended SDK version'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Usage context for programming language.
@StandardReferences(
  [
    'language standard (ISO/ECMA/PEP) — programming language specification',
    'Domain-Driven Design — layered/hexagonal architecture',
  ],
  'Where and how a programming language is used — context, share of the codebase, primary status and required language features.',
)
@SectionId('PLGUS')
class ProgrammingLanguageEntryUsage {
  @Form([
    Field('usageContext', String, 'Usage Context',
        hint: 'Backend, Frontend, Full-stack, Scripting, Build tools, Testing'),
    Field('codebasePercentage', String, 'Codebase %',
        hint: 'Approximate percentage of codebase'),
    Field('isPrimaryLanguage', bool, 'Primary Language',
        hint: 'Is this the main implementation language?'),
    Field('requiredFeatures', String, 'Required Language Features',
        hint: 'Specific language features needed'),
    Field('enabledLanguageOptions', String, 'Enabled Options',
        hint: 'Compiler/interpreter options to enable'),
    Field('disabledLanguageOptions', String, 'Disabled Options',
        hint: 'Compiler/interpreter options to disable'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Quality settings for programming language.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality (maintainability/portability)',
    'language standard (ISO/ECMA/PEP) — programming language specification',
  ],
  'The linting, static analysis and code-style standards enforced for a programming language.',
)
@SectionId('PLGQU')
class ProgrammingLanguageEntryQuality {
  @Form([
    Field('lintingRules', String, 'Linting Rules',
        hint: 'Required linting configuration'),
    Field('staticAnalysis', String, 'Static Analysis',
        hint: 'Static analysis requirements'),
    Field('codeStyle', String, 'Code Style',
        hint: 'Code style/formatting standard'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Justification and notes for programming language.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
  ],
  'The rationale for choosing a programming language, the alternatives considered and its migration path.',
)
@SectionId('PLGJT')
class ProgrammingLanguageEntryJustification {
  @Form([
    Field('justification', String, 'Justification',
        required: true, hint: 'Reason for selecting this language'),
    Field('alternativesConsidered', String, 'Alternatives Considered',
        hint: 'Other languages evaluated'),
    Field('migrationPath', String, 'Migration Path',
        hint: 'Upgrade/migration strategy'),
    Field('notes', String, 'Notes', hint: 'Additional language notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Framework or library requirement entry.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'Semantic Versioning (SemVer) — version numbering',
  ],
  'A single framework or library with its identity, version, scope, compatibility, support status and justification.',
)
@SectionId('FRREEN')
class FrameworkRequirementEntry {
  @Form([
    Field('frameworkName', String, 'Framework/Library Name',
        required: true, hint: 'E.g., Flutter, Angular, Django, Spring Boot'),
    Field('frameworkCategory', String, 'Category',
        hint: 'UI Framework, Backend Framework, Testing, State Management'),
    Field('purpose', String, 'Purpose',
        required: true, hint: 'What problem this framework solves'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Identity details.
  @SerializationOrder(1)
  FrameworkIdentity identity = FrameworkIdentity();

  /// Version requirements.
  @SerializationOrder(2)
  FrameworkVersion version = FrameworkVersion();

  /// Scope and plugins.
  @SerializationOrder(3)
  FrameworkScope scope = FrameworkScope();

  /// Compatibility.
  @SerializationOrder(4)
  FrameworkCompatibility compatibility = FrameworkCompatibility();

  /// Support status.
  @SerializationOrder(5)
  FrameworkSupport support = FrameworkSupport();

  /// Justification.
  @SerializationOrder(6)
  FrameworkJustification justification = FrameworkJustification();
}

/// Identity details.
@StandardReferences(
  ['ISO/IEC/IEEE 42010 — architecture description'],
  'The publisher and license identity of a framework or library.',
)
@SectionId('FWRID')
class FrameworkIdentity {
  @Form([
    Field('publisher', String, 'Publisher', hint: 'Framework publisher/owner'),
    Field('license', String, 'License', hint: 'License type (MIT, Apache, etc.)'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Version requirements.
@StandardReferences(
  ['Semantic Versioning (SemVer) — version numbering'],
  'The minimum, recommended and maximum versions and version constraint for a framework.',
)
@SectionId('FWRVR')
class FrameworkVersion {
  @Form([
    Field('minimumVersion', String, 'Minimum Version',
        required: true, hint: 'Earliest supported version'),
    Field('recommendedVersion', String, 'Recommended Version',
        hint: 'Preferred target version'),
    Field('maximumVersion', String, 'Maximum Version',
        hint: 'Latest tested/supported version'),
    Field('versionConstraint', String, 'Version Constraint',
        hint: 'E.g., ^3.0.0, >=2.0.0 <4.0.0'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scope and plugins.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'Domain-Driven Design — layered/hexagonal architecture',
  ],
  'The usage scope, integration points and required/optional plugins of a framework in the architecture.',
)
@SectionId('FWRSC')
class FrameworkScope {
  @Form([
    Field('usageScope', String, 'Usage Scope',
        hint: 'Core, Feature-specific, Development-only, Testing-only'),
    Field('integrationPoints', String, 'Integration Points',
        hint: 'Where this framework integrates in the architecture'),
    Field('requiredPlugins', String, 'Required Plugins/Extensions',
        hint: 'Mandatory plugins or extensions'),
    Field('optionalPlugins', String, 'Optional Plugins/Extensions',
        hint: 'Recommended optional plugins'),
    Field('excludedFeatures', String, 'Excluded Features',
        hint: 'Framework features that should not be used'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compatibility.
@StandardReferences(
  ['ISO/IEC 25010 — portability/compatibility'],
  'The compatibility, conflicts and deprecation warnings of a framework relative to others.',
)
@SectionId('FWRCP')
class FrameworkCompatibility {
  @Form([
    Field('compatibleWith', String, 'Compatible With',
        hint: 'Other frameworks/versions this is compatible with'),
    Field('conflictsWith', String, 'Conflicts With',
        hint: 'Known conflicts with other frameworks'),
    Field('deprecationWarnings', String, 'Deprecation Warnings',
        hint: 'Known deprecations to address'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Support status.
@StandardReferences(
  ['ISO/IEC 12207 — software lifecycle processes'],
  'The support status, community size and documentation quality of a framework.',
)
@SectionId('FWRSP')
class FrameworkSupport {
  @Form([
    Field('supportStatus', String, 'Support Status',
        hint: 'Active, Maintenance, Deprecated'),
    Field('communitySize', String, 'Community Size',
        hint: 'Small, Medium, Large'),
    Field('documentationQuality', String, 'Documentation Quality',
        hint: 'Excellent, Good, Fair, Poor'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Justification.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
  ],
  'The rationale for selecting a framework, the alternatives considered and its risk assessment.',
)
@SectionId('FWRJT')
class FrameworkJustification {
  @Form([
    Field('justification', String, 'Justification',
        required: true, hint: 'Reason for selecting this framework'),
    Field('alternativesConsidered', String, 'Alternatives Considered',
        hint: 'Other frameworks evaluated'),
    Field('riskAssessment', String, 'Risk Assessment',
        hint: 'Vendor lock-in, maintenance, complexity risks'),
    Field('notes', String, 'Notes', hint: 'Additional framework notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Build toolchain requirement entry.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'A single build-toolchain tool with its versions, configuration, build profiles, integrations, outputs and operations.',
)
@SectionId('BTCEN')
class BuildToolchainEntry {
  @Form([
    Field('toolName', String, 'Tool Name',
        required: true, hint: 'E.g., Gradle, CMake, Webpack, Dart build_runner'),
    Field('toolCategory', String, 'Category',
        hint:
            'Build System, Compiler, Bundler, Code Generator, Task Runner, Package Manager'),
    Field('platform', String, 'Platform',
        hint: 'Which platform(s) this tool is used for'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Version requirements.
  @SerializationOrder(1)
  BuildToolchainEntryVersions versions = BuildToolchainEntryVersions();

  /// Configuration and plugins.
  @SerializationOrder(2)
  BuildToolchainEntryConfiguration configuration =
      BuildToolchainEntryConfiguration();

  /// Build profile settings.
  @SerializationOrder(3)
  BuildToolchainEntryProfiles profiles = BuildToolchainEntryProfiles();

  /// Integration touchpoints.
  @SerializationOrder(4)
  BuildToolchainEntryIntegration integration =
      BuildToolchainEntryIntegration();

  /// Output artifact settings.
  @SerializationOrder(5)
  BuildToolchainEntryOutputs outputs = BuildToolchainEntryOutputs();

  /// Performance and rationale.
  @SerializationOrder(6)
  BuildToolchainEntryOperations operations = BuildToolchainEntryOperations();
}

/// Version requirements.
@StandardReferences(
  ['Semantic Versioning (SemVer) — version numbering'],
  'The minimum and recommended versions of a build-toolchain tool.',
)
@SectionId('BTCVR')
class BuildToolchainEntryVersions {
  @Form([
    Field('minimumVersion', String, 'Minimum Version',
        required: true, hint: 'Earliest supported version'),
    Field('recommendedVersion', String, 'Recommended Version',
        hint: 'Preferred target version'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Configuration and plugins.
@StandardReferences(
  ['Twelve-Factor App — cloud-native methodology'],
  'The configuration file and required/optional plugins for a build-toolchain tool.',
)
@SectionId('BTCCF')
class BuildToolchainEntryConfiguration {
  @Form([
    Field('configurationFile', String, 'Configuration File',
        hint: 'Primary configuration file name'),
    Field('requiredPlugins', String, 'Required Plugins',
        hint: 'Mandatory build plugins'),
    Field('optionalPlugins', String, 'Optional Plugins',
        hint: 'Recommended optional plugins'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Build profile settings.
@StandardReferences(
  ['Twelve-Factor App — cloud-native methodology'],
  'The build profiles (debug, release, production) and default profile for a build-toolchain tool.',
)
@SectionId('BTEP')
class BuildToolchainEntryProfiles {
  @Form([
    Field('buildProfiles', String, 'Build Profiles',
        hint: 'E.g., Debug, Release, Profile, Production'),
    Field('defaultProfile', String, 'Default Profile',
        hint: 'Default build profile'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Integration touchpoints.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'The CI/CD and IDE integration points of a build-toolchain tool.',
)
@SectionId('BTEI')
class BuildToolchainEntryIntegration {
  @Form([
    Field('cicdIntegration', String, 'CI/CD Integration',
        hint: 'Integration with CI/CD pipelines'),
    Field('ideIntegration', String, 'IDE Integration',
        hint: 'Integration with development IDEs'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Output artifact settings.
@StandardReferences(
  ['ISO/IEC 12207 — software lifecycle processes'],
  'The output artifacts produced by a build-toolchain tool and where they are stored.',
)
@SectionId('BTEO')
class BuildToolchainEntryOutputs {
  @Form([
    Field('outputArtifacts', String, 'Output Artifacts',
        hint: 'Types of artifacts produced'),
    Field('outputLocations', String, 'Output Locations',
        hint: 'Where build artifacts are stored'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Performance and rationale.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality (maintainability/portability)',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'The caching strategy, parallelization and rationale governing a build-toolchain tool.',
)
@SectionId('BUTOENOP')
class BuildToolchainEntryOperations {
  @Form([
    Field('cachingStrategy', String, 'Caching Strategy',
        hint: 'Build caching approach'),
    Field('parallelization', String, 'Parallelization',
        hint: 'Parallel build capabilities'),
    Field('justification', String, 'Justification',
        hint: 'Reason for selecting this tool'),
    Field('notes', String, 'Notes', hint: 'Additional toolchain notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Deployment target specification entry.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'A single deployment target with its platform, build output, requirements, process and compliance details.',
)
@SectionId('DEPTARENT')
class DeploymentTargetEntry {
  @Form([
    Field('targetName', String, 'Target Name',
        required: true, hint: 'E.g., Production Web, iOS App Store, Docker Hub'),
    Field('targetCategory', String, 'Category',
        hint: 'Web, Mobile App, Desktop App, Cloud Service, Container, Embedded'),
    Field('targetEnvironment', String, 'Environment',
        hint: 'Development, Staging, Production'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Platform specifics.
  @SerializationOrder(1)
  DeploymentTargetEntryPlatform platform = DeploymentTargetEntryPlatform();

  /// Build output configuration.
  @SerializationOrder(2)
  DeploymentTargetEntryBuildOutput buildOutput =
      DeploymentTargetEntryBuildOutput();

  /// Platform requirements.
  @SerializationOrder(3)
  DeploymentTargetEntryRequirements requirements =
      DeploymentTargetEntryRequirements();

  /// Deployment process configuration.
  @SerializationOrder(4)
  DeploymentTargetEntryProcess process = DeploymentTargetEntryProcess();

  /// Compliance and notes.
  @SerializationOrder(5)
  DeploymentTargetEntryCompliance compliance =
      DeploymentTargetEntryCompliance();
}

/// Platform specifics for deployment target.
@StandardReferences(
  ['ISO/IEC 25010 — portability/compatibility'],
  'The platform target and distribution channel of a deployment target.',
)
@SectionId('DTEP')
class DeploymentTargetEntryPlatform {
  @Form([
    Field('platformTarget', String, 'Platform Target',
        hint: 'Specific platform/OS this deployment targets'),
    Field('distributionChannel', String, 'Distribution Channel',
        hint: 'App Store, Play Store, Web hosting, Container registry'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Build output configuration for deployment target.
@StandardReferences(
  ['ISO/IEC 12207 — software lifecycle processes'],
  'The artifact format, naming, signing, size limit and performance targets for a deployment target build output.',
)
@SectionId('DTEBO')
class DeploymentTargetEntryBuildOutput {
  @Form([
    Field('artifactFormat', String, 'Artifact Format',
        hint: 'E.g., APK, AAB, IPA, EXE, Docker image, WASM'),
    Field('artifactNaming', String, 'Artifact Naming',
        hint: 'Naming convention for artifacts'),
    Field('signingRequirements', String, 'Signing Requirements',
        hint: 'Code signing requirements'),
    Field('sizeLimit', String, 'Size Limit',
        hint: 'Maximum artifact size'),
    Field('performanceTargets', String, 'Performance Targets',
        hint: 'Startup time, memory footprint targets'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Platform requirements for deployment target.
@StandardReferences(
  ['ISO/IEC 25010 — portability/compatibility'],
  'The minimum OS version, target SDK, permissions and capabilities a deployment target requires.',
)
@SectionId('DTER')
class DeploymentTargetEntryRequirements {
  @Form([
    Field('minimumOsVersion', String, 'Minimum OS Version',
        hint: 'Minimum target OS version'),
    Field('targetSdkVersion', String, 'Target SDK Version',
        hint: 'Target SDK/API level'),
    Field('requiredPermissions', String, 'Required Permissions',
        hint: 'Platform permissions needed'),
    Field('requiredCapabilities', String, 'Required Capabilities',
        hint: 'Platform capabilities needed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Deployment process configuration.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'The deployment method, rollback strategy and feature-flag support for a deployment target.',
)
@SectionId('DETAENPR')
class DeploymentTargetEntryProcess {
  @Form([
    Field('deploymentMethod', String, 'Deployment Method',
        hint: 'Manual, CI/CD, Blue-green, Rolling'),
    Field('rollbackStrategy', String, 'Rollback Strategy',
        hint: 'How to rollback failed deployments'),
    Field('featureFlagsSupport', String, 'Feature Flags Support',
        hint: 'Feature flag implementation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance and notes for deployment target.
@StandardReferences(
  ['ISO/IEC 12207 — software lifecycle processes'],
  'The compliance, privacy, priority and launch-date details for a deployment target.',
)
@SectionId('DTEC')
class DeploymentTargetEntryCompliance {
  @Form([
    Field('complianceRequirements', String, 'Compliance Requirements',
        hint: 'Store guidelines, regulatory requirements'),
    Field('privacyRequirements', String, 'Privacy Requirements',
        hint: 'Privacy manifest, tracking transparency'),
    Field('priority', String, 'Priority',
        hint: 'Primary, Secondary, Future'),
    Field('targetLaunchDate', String, 'Target Launch Date',
        hint: 'Target date for this deployment'),
    Field('notes', String, 'Notes', hint: 'Additional deployment notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dependency management configuration.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'Semantic Versioning (SemVer) — version numbering',
  ],
  'The dependency management strategy: package managers, registries, versioning, security, internal packages and operations.',
)
@SectionId('DEMA')
class DependencyManagement {
  @Form([
    // Package manager
    Field('primaryPackageManager', String, 'Primary Package Manager',
        hint: 'E.g., pub.dev, npm, pip, Maven'),
    Field('secondaryPackageManagers', String, 'Secondary Package Managers',
        hint: 'Additional package managers used'),
    Field('registryUrls', String, 'Registry URLs',
        hint: 'Package registry URLs (public and private)'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Versioning and update policy.
  @SerializationOrder(1)
  DependencyManagementVersioning versioning =
    DependencyManagementVersioning();

  /// Security and trust controls.
  @SerializationOrder(2)
  DependencyManagementSecurity security = DependencyManagementSecurity();

  /// Internal package and workspace strategy.
  @SerializationOrder(3)
  DependencyManagementInternal internal = DependencyManagementInternal();

  /// Caching and offline behavior.
  @SerializationOrder(4)
  DependencyManagementOperations operations = DependencyManagementOperations();
}

/// Versioning and update policy.
@StandardReferences(
  ['Semantic Versioning (SemVer) — version numbering'],
  'The versioning, update and lockfile policies for managing dependencies.',
)
@SectionId('DEMAVE')
class DependencyManagementVersioning {
  @Form([
  Field('versioningPolicy', String, 'Versioning Policy',
    hint: 'SemVer, CalVer, custom'),
  Field('dependencyUpdatePolicy', String, 'Update Policy',
    hint: 'How and when to update dependencies'),
  Field('lockfilePolicy', String, 'Lockfile Policy',
    hint: 'Required, Recommended, Optional'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security and trust controls.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'ISO/IEC 25010 — product quality (maintainability/portability)',
  ],
  'The security scanning, license compliance and source-trust controls applied to dependencies.',
)
@SectionId('DEMASE')
class DependencyManagementSecurity {
  @Form([
  Field('securityScanning', String, 'Security Scanning',
    hint: 'Dependency vulnerability scanning requirements'),
  Field('licenseCompliance', String, 'License Compliance',
    hint: 'Allowed and prohibited licenses'),
  Field('sourceTrust', String, 'Source Trust',
    hint: 'Trusted sources and verification'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Internal package and workspace strategy.
@StandardReferences(
  [
    'Domain-Driven Design — layered/hexagonal architecture',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'The internal package and monorepo/workspace strategy for managing dependencies.',
)
@SectionId('DEMAIN')
class DependencyManagementInternal {
  @Form([
  Field('internalPackages', String, 'Internal Packages',
    hint: 'Internal/private packages to use'),
  Field('monorepoStrategy', String, 'Monorepo Strategy',
    hint: 'Workspace/monorepo dependency management'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Caching and offline behavior.
@StandardReferences(
  ['Twelve-Factor App — cloud-native methodology'],
  'The caching and offline-build behavior for managing dependencies.',
)
@SectionId('DEMAOP')
class DependencyManagementOperations {
  @Form([
  Field('cachingStrategy', String, 'Caching Strategy',
    hint: 'Dependency caching approach'),
  Field('offlineSupport', String, 'Offline Support',
    hint: 'Offline build requirements'),
  Field('notes', String, 'Notes',
    hint: 'Additional dependency management notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Runtime environment constraints.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality (maintainability/portability)',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'The runtime environment constraints: memory, CPU, storage, network, environment variables, dependencies and scaling.',
)
@SectionId('RUEN')
class RuntimeEnvironment {
  @Form([
    Field('minimumMemory', String, 'Minimum Memory',
        hint: 'Minimum RAM for runtime'),
    Field('recommendedMemory', String, 'Recommended Memory',
        hint: 'Recommended RAM for optimal performance'),
    Field('minimumCpuCores', String, 'Minimum CPU Cores',
        hint: 'Minimum CPU cores required'),
    Field('minimumDiskSpace', String, 'Minimum Disk Space',
        hint: 'Minimum disk space for installation'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Memory limits.
  @SerializationOrder(1)
  RuntimeEnvironmentMemory memory = RuntimeEnvironmentMemory();

  /// CPU and graphics requirements.
  @SerializationOrder(2)
  RuntimeEnvironmentCpu cpu = RuntimeEnvironmentCpu();

  /// Storage requirements.
  @SerializationOrder(3)
  RuntimeEnvironmentStorage storage = RuntimeEnvironmentStorage();

  /// Network requirements.
  @SerializationOrder(4)
  RuntimeEnvironmentNetwork network = RuntimeEnvironmentNetwork();

  /// Environment variables.
  @SerializationOrder(5)
  RuntimeEnvironmentVariables variables = RuntimeEnvironmentVariables();

  /// Runtime dependencies.
  @SerializationOrder(6)
  RuntimeEnvironmentDependencies dependencies =
      RuntimeEnvironmentDependencies();

  /// Scaling characteristics.
  @SerializationOrder(7)
  RuntimeEnvironmentScaling scaling = RuntimeEnvironmentScaling();

  /// Additional notes.
  @SerializationOrder(8)
  RuntimeEnvironmentNotes runtimeNotes = RuntimeEnvironmentNotes();
}

/// Memory limits.
@StandardReferences(
  ['ISO/IEC 25010 — product quality (maintainability/portability)'],
  'The hard memory limits or caps for the runtime environment.',
)
@SectionId('RUENME')
class RuntimeEnvironmentMemory {
  @Form([
    Field('memoryLimits', String, 'Memory Limits',
        hint: 'Hard memory limits or caps'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// CPU and graphics requirements.
@StandardReferences(
  ['ISO/IEC 25010 — portability/compatibility'],
  'The required CPU architecture and GPU/graphics requirements of the runtime environment.',
)
@SectionId('RUENCP')
class RuntimeEnvironmentCpu {
  @Form([
    Field('cpuArchitecture', String, 'CPU Architecture',
        hint: 'Required CPU architecture'),
    Field('gpuRequirements', String, 'GPU Requirements',
        hint: 'GPU/graphics requirements if any'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Storage requirements.
@StandardReferences(
  ['ISO/IEC 25010 — product quality (maintainability/portability)'],
  'The temporary space and storage type required by the runtime environment.',
)
@SectionId('RUENST')
class RuntimeEnvironmentStorage {
  @Form([
    Field('temporarySpace', String, 'Temporary Space',
        hint: 'Temporary storage requirements'),
    Field('storageType', String, 'Storage Type',
        hint: 'SSD required, HDD acceptable'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Network requirements.
@StandardReferences(
  ['Twelve-Factor App — cloud-native methodology'],
  'The connectivity, bandwidth and latency requirements of the runtime environment.',
)
@SectionId('RUENNE')
class RuntimeEnvironmentNetwork {
  @Form([
    Field('networkRequirements', String, 'Network Requirements',
        hint: 'Connectivity requirements'),
    Field('bandwidthRequirements', String, 'Bandwidth Requirements',
        hint: 'Minimum bandwidth'),
    Field('latencyRequirements', String, 'Latency Requirements',
        hint: 'Maximum acceptable latency'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Environment variables.
@StandardReferences(
  ['Twelve-Factor App — cloud-native methodology'],
  'The required and optional environment variables that configure the runtime environment.',
)
@SectionId('RUENVA')
class RuntimeEnvironmentVariables {
  @Form([
    Field('requiredEnvVariables', String, 'Required Environment Variables',
        hint: 'Mandatory environment variables'),
    Field('optionalEnvVariables', String, 'Optional Environment Variables',
        hint: 'Optional configuration variables'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Runtime dependencies.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'Domain-Driven Design — layered/hexagonal architecture',
  ],
  'The system libraries and external services the runtime environment depends on.',
)
@SectionId('RUENDE')
class RuntimeEnvironmentDependencies {
  @Form([
    Field('systemDependencies', String, 'System Dependencies',
        hint: 'Required system libraries or services'),
    Field('externalServices', String, 'External Services',
        hint: 'Required external services (DB, cache, etc.)'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scaling characteristics.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 25010 — product quality (maintainability/portability)',
  ],
  'The horizontal, vertical and auto-scaling characteristics of the runtime environment.',
)
@SectionId('RUENSC')
class RuntimeEnvironmentScaling {
  @Form([
    Field('horizontalScaling', String, 'Horizontal Scaling',
        hint: 'Horizontal scaling support'),
    Field('verticalScaling', String, 'Vertical Scaling',
        hint: 'Vertical scaling support'),
    Field('autoScalingRules', String, 'Auto-Scaling Rules',
        hint: 'Auto-scaling triggers and limits'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Additional notes.
@StandardReferences(
  ['arc42 — architecture documentation template'],
  'Additional free-form notes about the runtime environment.',
)
@SectionId('RUENNO')
class RuntimeEnvironmentNotes {
  @Form([
    Field('notes', String, 'Notes',
        hint: 'Additional runtime environment notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// =============================================================================
// 8.1.2. Architecture Style
// =============================================================================

/// 8.1.2. Architecture Style.
///
/// Target architecture style specification: monolith, modular monolith,
/// microservices, event-driven, serverless, or hybrid. Includes justification
/// based on project requirements, architectural principles, and design decisions.
@ContentHelp('''
Define the system's architectural style and structural organization.
Architecture decisions have long-lasting impacts on maintainability,
scalability, team structure, and operational complexity.

**Architectural Styles**:
- **Monolith**: Single deployable unit; simple operations, harder to scale
  teams; suitable for small-medium applications
- **Modular Monolith**: Monolith with internal module boundaries; clean
  architecture within single deployment; migration path to microservices
- **Microservices**: Independent services; team autonomy, operational
  complexity; requires mature DevOps practices
- **Event-Driven**: Loosely coupled via events; async communication,
  eventual consistency; CQRS/Event Sourcing patterns
- **Serverless**: FaaS (Functions as a Service); auto-scaling, cold starts,
  vendor lock-in considerations
- **Hybrid**: Combination of styles for different system parts

**Architecture Artifacts**:
- Component diagrams (C4 model: Context, Container, Component, Code)
- Data flow diagrams and integration maps
- Deployment topology and infrastructure architecture
- Architecture Decision Records (ADRs)
- Quality attribute scenarios (performance, security, availability)

**Reference**: ISO/IEC 42010, TOGAF ADM, arc42 template, C4 model.
''')
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
    'C4 model — software architecture diagrams',
  ],
  'The overall architecture style and structural organization chosen for the system.',
)
@SectionId('AS')
class ArchitectureStyle {
  @ContentHelp('''
Provide the architectural vision and primary style selection rationale.

**Include**:
- Primary architectural style with justification
- Key architectural drivers (business and technical)
- Quality attribute requirements (availability, performance, security)
- Architectural trade-offs accepted and their rationale
- Evolution path and migration strategy

**Best Practices**:
- Use Architecture Trade-off Analysis Method (ATAM)
- Document quality attribute scenarios with measurable targets
- Consider Conway's Law and team organization
- Plan for architectural fitness functions
- Establish architectural governance process
''')
  @SerializationOrder(0)
  String? content;

  /// Architecture overview and primary style selection.
  @SerializationOrder(1)
  ArchitectureOverview overview = ArchitectureOverview();

  /// Architecture principles guiding design decisions.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'ISO/IEC 25010 — architectural quality attributes',
    ],
    'The guiding architecture principles the design adheres to.',
  )
  @SectionId('ARPR-PRIN-LST')
  @SectionIdPattern('ARPR-PRIN-xxx')
  @ContentHelp('Add one entry per architecture principle.')
  @SerializationOrder(2)
  List<ArchitecturePrincipleEntry> principles = [];

  /// System component organization and boundaries.
  @SerializationOrder(3)
  ComponentOrganization componentOrganization = ComponentOrganization();

  /// Component/service catalog.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'arc42 — architecture documentation template',
      'C4 model — software architecture diagrams',
    ],
    'The catalog of components and services that make up the architecture.',
  )
  @SectionId('ARCM-COMP-LST')
  @SectionIdPattern('ARCM-COMP-xxx')
  @ContentHelp('Add one entry per architecture component or service.')
  @SerializationOrder(4)
  List<ArchitectureComponentEntry> components = [];

  /// Communication patterns between components.
  @SerializationOrder(5)
  CommunicationPatterns communicationPatterns = CommunicationPatterns();

  /// Data management architecture.
  @SerializationOrder(6)
  DataArchitecture dataArchitecture = DataArchitecture();

  /// Scalability and performance architecture.
  @SerializationOrder(7)
  ScalabilityArchitecture scalabilityArchitecture = ScalabilityArchitecture();

  /// Integration architecture with external systems.
  @SerializationOrder(8)
  IntegrationArchitecture integrationArchitecture = IntegrationArchitecture();

  /// Deployment topology and infrastructure.
  @SerializationOrder(9)
  DeploymentTopology deploymentTopology = DeploymentTopology();

  /// Architecture decision records.
  @StandardReferences(
    [
      'ADR (Architecture Decision Records) — decision capture',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The recorded architecture decisions and their rationale.',
  )
  @SectionId('ARDE-DECI-LST')
  @SectionIdPattern('ARDE-DECI-xxx')
  @ContentHelp('Add one entry per architecture decision record.')
  @SerializationOrder(10)
  List<ArchitectureDecisionRecord> decisionRecords = [];
}

/// Architecture overview and primary style selection.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
    'C4 model — software architecture diagrams',
  ],
  'The high-level overview of the primary architecture style and its selection.',
)
@SectionId('AROV')
class ArchitectureOverview {
  @Form([
    Field('primaryStyle', String, 'Primary Architecture Style',
        required: true,
        hint:
            'Monolith, Modular Monolith, Microservices, Event-Driven, Serverless, Hybrid'),
    Field('secondaryStyles', String, 'Secondary Styles',
        hint: 'Additional architectural patterns used'),
    Field('styleSummary', String, 'Style Summary',
        hint: 'Brief description of the chosen architecture'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Architecture drivers.
  @SerializationOrder(1)
  ArchitectureOverviewDrivers drivers = ArchitectureOverviewDrivers();

  /// Trade-offs and alternatives.
  @SerializationOrder(2)
  ArchitectureOverviewTradeOffs tradeOffs = ArchitectureOverviewTradeOffs();

  /// Evolution planning.
  @SerializationOrder(3)
  ArchitectureOverviewEvolution evolution = ArchitectureOverviewEvolution();

  /// Compliance considerations.
  @SerializationOrder(4)
  ArchitectureOverviewCompliance compliance = ArchitectureOverviewCompliance();
}

/// Architecture drivers.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
  ],
  'The business and technical drivers that justify the architecture choice.',
)
@SectionId('AROVDR')
class ArchitectureOverviewDrivers {
  @Form([
    Field('justification', String, 'Justification',
        required: true,
        hint: 'Why this architecture style was chosen'),
    Field('businessDrivers', String, 'Business Drivers',
        hint: 'Business requirements driving the choice'),
    Field('technicalDrivers', String, 'Technical Drivers',
        hint: 'Technical requirements driving the choice'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Trade-offs and alternatives.
@StandardReferences(
  [
    'ADR (Architecture Decision Records) — decision capture',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The trade-offs accepted and the alternatives considered and rejected.',
)
@SectionId('AOTO')
class ArchitectureOverviewTradeOffs {
  @Form([
    Field('benefitsExpected', String, 'Expected Benefits',
        hint: 'Advantages of this architecture'),
    Field('tradeOffsAccepted', String, 'Trade-offs Accepted',
        hint: 'Known compromises and their rationale'),
    Field('risksIdentified', String, 'Risks Identified',
        hint: 'Architectural risks and mitigation'),
    Field('alternativesConsidered', String, 'Alternatives Considered',
        hint: 'Other architectures evaluated'),
    Field('rejectionReasons', String, 'Rejection Reasons',
        hint: 'Why alternatives were not chosen'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Evolution planning.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
  ],
  'The planned evolution path and migration strategy for the architecture.',
)
@SectionId('AROVEV')
class ArchitectureOverviewEvolution {
  @Form([
    Field('evolutionPath', String, 'Evolution Path',
        hint: 'How the architecture may evolve'),
    Field('migrationStrategy', String, 'Migration Strategy',
        hint: 'Strategy for migrating from current state'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance considerations.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — architectural quality attributes',
  ],
  'The compliance requirements and industry benchmarks that constrain the architecture.',
)
@SectionId('AROVCO')
class ArchitectureOverviewCompliance {
  @Form([
    Field('complianceRequirements', String, 'Compliance Requirements',
        hint: 'Regulatory or compliance constraints'),
    Field('industryBenchmarks', String, 'Industry Benchmarks',
        hint: 'Reference to industry-standard architectures'),
    Field('notes', String, 'Notes', hint: 'Additional architecture notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Architecture principle entry.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — architectural quality attributes',
  ],
  'A single architecture principle guiding design decisions.',
)
@SectionId('ARPR')
class ArchitecturePrincipleEntry {
  @Form([
    Field('principleName', String, 'Principle Name',
        required: true, hint: 'E.g., Separation of Concerns, DRY, SOLID'),
    Field('category', String, 'Category',
        hint:
            'Design, Implementation, Deployment, Security, Performance, Data'),
    Field('statement', String, 'Statement',
        required: true, hint: 'Clear statement of the principle'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Rationale and practical implications.
  @SerializationOrder(1)
  ArchitecturePrincipleEntryGuidance guidance =
    ArchitecturePrincipleEntryGuidance();

  /// Enforcement and applicability context.
  @SerializationOrder(2)
  ArchitecturePrincipleEntryGovernance governance =
    ArchitecturePrincipleEntryGovernance();
}

/// Rationale and practical implications.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — architectural quality attributes',
  ],
  'The rationale and practical implications of following this architecture principle.',
)
@SectionId('APEG')
class ArchitecturePrincipleEntryGuidance {
  @Form([
  Field('rationale', String, 'Rationale', hint: 'Why this principle matters'),
  Field('implications', String, 'Implications',
    hint: 'What following this principle means in practice'),
  Field('violations', String, 'Violation Examples',
    hint: 'Examples of what would violate this principle'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Enforcement and applicability context.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — architectural quality attributes',
  ],
  'The enforcement level, mechanism, and applicable scope of this architecture principle.',
)
@SectionId('ARPRENGO')
class ArchitecturePrincipleEntryGovernance {
  @Form([
  Field('enforcementLevel', String, 'Enforcement Level',
    hint: 'Mandatory, Recommended, Advisory'),
  Field('enforcementMechanism', String, 'Enforcement Mechanism',
    hint: 'How compliance is ensured (review, linting, etc.)'),
  Field('applicableScope', String, 'Applicable Scope',
    hint: 'Where this principle applies'),
  Field('exceptions', String, 'Exceptions',
    hint: 'Allowed exceptions to this principle'),
  Field('relatedPrinciples', String, 'Related Principles',
    hint: 'Other principles that relate to this one'),
  Field('notes', String, 'Notes', hint: 'Additional principle notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Component organization and boundaries.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
    'C4 model — software architecture diagrams',
  ],
  'How system components are organized and how their boundaries are defined.',
)
@SectionId('COOR')
class ComponentOrganization {
  @Form([
    Field('organizationStrategy', String, 'Organization Strategy',
        hint: 'By feature, by layer, by domain, hybrid'),
    Field('boundaryDefinition', String, 'Boundary Definition',
        hint: 'How component boundaries are defined'),
    Field('modularityApproach', String, 'Modularity Approach',
        hint: 'How modules/components are structured'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Layering rules.
  @SerializationOrder(1)
  ComponentOrganizationLayering layering = ComponentOrganizationLayering();

  /// Domain boundaries.
  @SerializationOrder(2)
  ComponentOrganizationDomain domain = ComponentOrganizationDomain();

  /// Coupling guidance.
  @SerializationOrder(3)
  ComponentOrganizationCoupling coupling = ComponentOrganizationCoupling();

  /// Dependency management rules.
  @SerializationOrder(4)
  ComponentOrganizationDependencies dependencies =
      ComponentOrganizationDependencies();
}

/// Layering rules.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
    'C4 model — software architecture diagrams',
  ],
  'The architectural layers and the allowed dependencies between them.',
)
@SectionId('COORLA')
class ComponentOrganizationLayering {
  @Form([
    Field('layerStructure', String, 'Layer Structure',
        hint: 'Architectural layers (presentation, domain, data, infra)'),
    Field('layerDependencies', String, 'Layer Dependencies',
        hint: 'Allowed dependencies between layers'),
    Field('crossCuttingConcerns', String, 'Cross-Cutting Concerns',
        hint: 'How cross-cutting concerns are handled'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Domain boundaries.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / layered architecture',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The domain boundaries, shared kernel, and anti-corruption layers between contexts.',
)
@SectionId('COORDO')
class ComponentOrganizationDomain {
  @Form([
    Field('domainBoundaries', String, 'Domain Boundaries',
        hint: 'Bounded contexts or domain boundaries'),
    Field('sharedKernel', String, 'Shared Kernel',
        hint: 'Components shared across domains'),
    Field('antiCorruptionLayers', String, 'Anti-Corruption Layers',
        hint: 'Isolation between different domains/systems'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Coupling guidance.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'Domain-Driven Design — bounded contexts / layered architecture',
  ],
  'The guidance on minimizing coupling and maximizing cohesion between components.',
)
@SectionId('COORCO')
class ComponentOrganizationCoupling {
  @Form([
    Field('couplingGuidelines', String, 'Coupling Guidelines',
        hint: 'How to minimize coupling'),
    Field('cohesionGuidelines', String, 'Cohesion Guidelines',
        hint: 'How to maximize cohesion'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dependency management rules.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
  ],
  'The rules governing dependency direction, interface contracts, and versioning between components.',
)
@SectionId('COORDE')
class ComponentOrganizationDependencies {
  @Form([
    Field('dependencyDirection', String, 'Dependency Direction',
        hint: 'Rules for dependency direction'),
    Field('interfaceContracts', String, 'Interface Contracts',
        hint: 'How interfaces between components are defined'),
    Field('versioningStrategy', String, 'Versioning Strategy',
        hint: 'How component versions are managed'),
    Field('notes', String, 'Notes', hint: 'Additional organization notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Architecture component/service entry.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
    'C4 model — software architecture diagrams',
  ],
  'A single component or service in the architecture and its defining attributes.',
)
@SectionId('ARCM')
class ArchitectureComponentEntry {
  @Form([
    Field('componentName', String, 'Component Name',
        required: true, hint: 'Unique name for this component'),
    Field('componentType', String, 'Component Type',
        required: true,
        hint: 'Service, Module, Library, Package, Microservice, Function'),
    Field('domain', String, 'Domain', hint: 'Business domain this belongs to'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Purpose and ownership boundaries.
  @SerializationOrder(1)
  ArchitectureComponentEntryPurpose purpose =
      ArchitectureComponentEntryPurpose();

  /// Public and private boundaries.
  @SerializationOrder(2)
  ArchitectureComponentEntryBoundaries boundaries =
      ArchitectureComponentEntryBoundaries();

  /// Dependency relationships.
  @SerializationOrder(3)
  ArchitectureComponentEntryDependencies dependencies =
      ArchitectureComponentEntryDependencies();

  /// Technical delivery characteristics.
  @SerializationOrder(4)
  ArchitectureComponentEntryTechnical technical =
      ArchitectureComponentEntryTechnical();

  /// Team ownership and service expectations.
  @SerializationOrder(5)
  ArchitectureComponentEntryOwnership ownership =
      ArchitectureComponentEntryOwnership();
}

/// Purpose and ownership boundaries.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
  ],
  'The purpose and responsibilities of a component and what it is not responsible for.',
)
@SectionId('ACEP')
class ArchitectureComponentEntryPurpose {
  @Form([
    Field('purpose', String, 'Purpose',
        required: true, hint: 'What this component does'),
    Field('responsibilities', String, 'Responsibilities',
        hint: 'List of responsibilities'),
    Field('notResponsibleFor', String, 'Not Responsible For',
        hint: 'Explicitly out of scope'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Public and private boundaries.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'C4 model — software architecture diagrams',
  ],
  'The public interface and private implementation boundaries of a component.',
)
@SectionId('ACEB')
class ArchitectureComponentEntryBoundaries {
  @Form([
    Field('publicInterface', String, 'Public Interface',
        hint: 'Exposed APIs or interfaces'),
    Field('privateImplementation', String, 'Private Implementation',
        hint: 'Internal implementation details'),
    Field('dataOwnership', String, 'Data Ownership',
        hint: 'Data entities this component owns'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dependency relationships.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'C4 model — software architecture diagrams',
  ],
  'The upstream, downstream, and external dependency relationships of a component.',
)
@SectionId('ACED')
class ArchitectureComponentEntryDependencies {
  @Form([
    Field('upstreamDependencies', String, 'Upstream Dependencies',
        hint: 'Components this depends on'),
    Field('downstreamDependents', String, 'Downstream Dependents',
        hint: 'Components that depend on this'),
    Field('externalDependencies', String, 'External Dependencies',
        hint: 'External systems this integrates with'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Technical delivery characteristics.
@StandardReferences(
  [
    'REST / microservices — architectural style',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'The technology stack, deployment unit, and scaling characteristics of a component.',
)
@SectionId('ACET')
class ArchitectureComponentEntryTechnical {
  @Form([
    Field('technology', String, 'Technology Stack',
        hint: 'Specific technologies used'),
    Field('deploymentUnit', String, 'Deployment Unit',
        hint: 'Is this separately deployable?'),
    Field('scalingCharacteristics', String, 'Scaling Characteristics',
        hint: 'How this component scales'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Team ownership and service expectations.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — architectural quality attributes',
  ],
  'The team ownership and expected service level for a component.',
)
@SectionId('ACEO')
class ArchitectureComponentEntryOwnership {
  @Form([
    Field('teamOwnership', String, 'Team Ownership',
        hint: 'Team responsible for this component'),
    Field('serviceLevel', String, 'Service Level',
        hint: 'Expected availability and performance'),
    Field('notes', String, 'Notes', hint: 'Additional component notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Communication patterns between components.
@StandardReferences(
  [
    'REST / microservices — architectural style',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The communication patterns and protocols used between components.',
)
@SectionId('COMPAT')
class CommunicationPatterns {
  @Form([
    Field('primaryPattern', String, 'Primary Communication Pattern',
        hint: 'Synchronous REST, Async messaging, Event-driven, RPC'),
    Field('secondaryPatterns', String, 'Secondary Patterns',
        hint: 'Additional patterns used'),
    Field('syncProtocols', String, 'Synchronous Protocols',
        hint: 'REST, gRPC, GraphQL, SOAP'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Synchronous communication details.
  @SerializationOrder(1)
  CommunicationPatternsSynchronous synchronous =
      CommunicationPatternsSynchronous();

  /// Asynchronous communication details.
  @SerializationOrder(2)
  CommunicationPatternsAsynchronous asynchronous =
      CommunicationPatternsAsynchronous();

  /// Data exchange contracts.
  @SerializationOrder(3)
  CommunicationPatternsDataExchange dataExchange =
      CommunicationPatternsDataExchange();

  /// Reliability controls.
  @SerializationOrder(4)
  CommunicationPatternsReliability reliability =
      CommunicationPatternsReliability();

  /// Observability settings.
  @SerializationOrder(5)
  CommunicationPatternsObservability observability =
      CommunicationPatternsObservability();
}

/// Synchronous communication details.
@StandardReferences(
  [
    'REST / microservices — architectural style',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The synchronous request-response patterns and API gateway details.',
)
@SectionId('COPASY')
class CommunicationPatternsSynchronous {
  @Form([
    Field('syncPatterns', String, 'Synchronous Patterns',
        hint: 'Request-response, Service mesh'),
    Field('apiGateway', String, 'API Gateway',
        hint: 'Central gateway pattern details'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Asynchronous communication details.
@StandardReferences(
  [
    'REST / microservices — architectural style',
    'POSA — patterns of software architecture',
  ],
  'The asynchronous messaging protocols and event patterns used between components.',
)
@SectionId('COPAAS')
class CommunicationPatternsAsynchronous {
  @Form([
    Field('asyncProtocols', String, 'Asynchronous Protocols',
        hint: 'Message brokers, event streaming'),
    Field('messageFormats', String, 'Message Formats',
        hint: 'JSON, Protobuf, Avro, MessagePack'),
    Field('eventPatterns', String, 'Event Patterns',
        hint: 'Pub/Sub, Event sourcing, CQRS'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data exchange contracts.
@StandardReferences(
  [
    'REST / microservices — architectural style',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The data contracts, schema evolution, and serialization used in component communication.',
)
@SectionId('CPDE')
class CommunicationPatternsDataExchange {
  @Form([
    Field('dataContracts', String, 'Data Contracts',
        hint: 'API contracts and schemas'),
    Field('schemaEvolution', String, 'Schema Evolution',
        hint: 'How schemas evolve over time'),
    Field('serialization', String, 'Serialization',
        hint: 'Serialization approach'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reliability controls.
@StandardReferences(
  [
    'POSA — patterns of software architecture',
    'ISO/IEC 25010 — architectural quality attributes',
  ],
  'The reliability controls such as retries, circuit breakers, timeouts, and idempotency.',
)
@SectionId('COPARE')
class CommunicationPatternsReliability {
  @Form([
    Field('retryPolicies', String, 'Retry Policies',
        hint: 'Retry and backoff strategies'),
    Field('circuitBreakers', String, 'Circuit Breakers',
        hint: 'Circuit breaker patterns'),
    Field('timeouts', String, 'Timeouts', hint: 'Timeout strategies'),
    Field('idempotency', String, 'Idempotency', hint: 'Idempotency guarantees'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Observability settings.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 25010 — architectural quality attributes',
  ],
  'The tracing, logging, and metrics settings for observing component communication.',
)
@SectionId('COPAOB')
class CommunicationPatternsObservability {
  @Form([
    Field('tracing', String, 'Distributed Tracing',
        hint: 'Tracing approach'),
    Field('logging', String, 'Logging Strategy', hint: 'Logging approach'),
    Field('metrics', String, 'Metrics', hint: 'Metrics collection'),
    Field('notes', String, 'Notes', hint: 'Additional communication notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data architecture decisions.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'Domain-Driven Design — bounded contexts / layered architecture',
  ],
  'The data strategy, ownership model, and governance that shape the data architecture.',
)
@SectionId('DAAR')
class DataArchitecture {
  @Form([
    Field('dataStrategy', String, 'Data Strategy',
        hint: 'Centralized, Distributed, Federated, Mesh'),
    Field('dataOwnership', String, 'Data Ownership Model',
        hint: 'How data ownership is assigned'),
    Field('dataGovernance', String, 'Data Governance',
        hint: 'Governance policies'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Storage decisions.
  @SerializationOrder(1)
  DataArchitectureStorage storage = DataArchitectureStorage();

  /// Data access patterns.
  @SerializationOrder(2)
  DataArchitectureAccess access = DataArchitectureAccess();

  /// Consistency model and transactions.
  @SerializationOrder(3)
  DataArchitectureConsistency consistency = DataArchitectureConsistency();

  /// Lifecycle controls.
  @SerializationOrder(4)
  DataArchitectureLifecycle lifecycle = DataArchitectureLifecycle();

  /// Privacy and security controls.
  @SerializationOrder(5)
  DataArchitectureSecurity security = DataArchitectureSecurity();
}

/// Storage decisions.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
  ],
  'The primary and secondary storage choices and storage topology.',
)
@SectionId('DAARST')
class DataArchitectureStorage {
  @Form([
    Field('primaryStorage', String, 'Primary Storage',
        hint: 'Main database type and technology'),
    Field('secondaryStorage', String, 'Secondary Storage',
        hint: 'Additional storage (cache, search, etc.)'),
    Field('storageTopology', String, 'Storage Topology',
        hint: 'Single, Replicated, Sharded, Multi-region'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data access patterns.
@StandardReferences(
  [
    'POSA — patterns of software architecture',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The data access, query, and caching patterns used against the data stores.',
)
@SectionId('DAARAC')
class DataArchitectureAccess {
  @Form([
    Field('dataAccessPatterns', String, 'Data Access Patterns',
        hint: 'CRUD, CQRS, Event sourcing'),
    Field('queryPatterns', String, 'Query Patterns',
        hint: 'How data is queried'),
    Field('caching', String, 'Caching Strategy', hint: 'Caching approach'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Consistency model and transactions.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — architectural quality attributes',
  ],
  'The consistency model, transaction scope, and conflict resolution for data.',
)
@SectionId('DAARCO')
class DataArchitectureConsistency {
  @Form([
    Field('consistencyModel', String, 'Consistency Model',
        hint: 'Strong, Eventual, Causal'),
    Field('transactionScope', String, 'Transaction Scope',
        hint: 'Local, Distributed, Saga'),
    Field('conflictResolution', String, 'Conflict Resolution',
        hint: 'How conflicts are resolved'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Lifecycle controls.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — architectural quality attributes',
  ],
  'The data retention, archiving, and recovery controls over the data lifecycle.',
)
@SectionId('DAARLI')
class DataArchitectureLifecycle {
  @Form([
    Field('dataRetention', String, 'Data Retention',
        hint: 'Retention policies'),
    Field('archiving', String, 'Archiving Strategy',
        hint: 'How old data is archived'),
    Field('dataRecovery', String, 'Data Recovery',
        hint: 'Recovery point and time objectives'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Privacy and security controls.
@StandardReferences(
  [
    'ISO/IEC 25010 — architectural quality attributes',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The data classification, encryption, and access-control security controls.',
)
@SectionId('DAARSE')
class DataArchitectureSecurity {
  @Form([
    Field('dataClassification', String, 'Data Classification',
        hint: 'Classification levels'),
    Field('encryptionStrategy', String, 'Encryption Strategy',
        hint: 'At-rest and in-transit encryption'),
    Field('accessControl', String, 'Access Control',
        hint: 'Data access control model'),
    Field('notes', String, 'Notes', hint: 'Additional data architecture notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scalability and performance architecture.
@StandardReferences(
  [
    'ISO/IEC 25010 — architectural quality attributes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'The scalability model, elasticity approach, and scaling triggers of the architecture.',
)
@SectionId('SCAR')
class ScalabilityArchitecture {
  @Form([
    Field('scalabilityModel', String, 'Scalability Model',
        hint: 'Horizontal, Vertical, Both'),
    Field('elasticityApproach', String, 'Elasticity Approach',
        hint: 'Manual, Auto-scaling, Serverless'),
    Field('scalingTriggers', String, 'Scaling Triggers',
        hint: 'What triggers scaling actions'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Capacity planning assumptions.
  @SerializationOrder(1)
  ScalabilityArchitectureCapacity capacity = ScalabilityArchitectureCapacity();

  /// Performance targets.
  @SerializationOrder(2)
  ScalabilityArchitectureTargets targets = ScalabilityArchitectureTargets();

  /// Performance patterns.
  @SerializationOrder(3)
  ScalabilityArchitecturePatterns patterns = ScalabilityArchitecturePatterns();

  /// Resource optimization controls.
  @SerializationOrder(4)
  ScalabilityArchitectureOptimization optimization =
      ScalabilityArchitectureOptimization();

  /// Testing and benchmarks.
  @SerializationOrder(5)
  ScalabilityArchitectureTesting testing = ScalabilityArchitectureTesting();
}

/// Capacity planning assumptions.
@StandardReferences(
  [
    'ISO/IEC 25010 — architectural quality attributes',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The expected load, peak load, and growth projections used for capacity planning.',
)
@SectionId('SCARCA')
class ScalabilityArchitectureCapacity {
  @Form([
    Field('expectedLoad', String, 'Expected Load',
        hint: 'Expected concurrent users/requests'),
    Field('peakLoad', String, 'Peak Load', hint: 'Peak load expectations'),
    Field('growthProjection', String, 'Growth Projection',
        hint: 'Expected growth over time'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Performance targets.
@StandardReferences(
  [
    'ISO/IEC 25010 — architectural quality attributes',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The response-time, throughput, and availability targets for the architecture.',
)
@SectionId('SCARTA')
class ScalabilityArchitectureTargets {
  @Form([
    Field('responseTimeTargets', String, 'Response Time Targets',
        hint: 'Target response times by tier'),
    Field('throughputTargets', String, 'Throughput Targets',
        hint: 'Target transactions per second'),
    Field('availabilityTarget', String, 'Availability Target',
        hint: 'Target availability (e.g., 99.9%)'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Performance patterns.
@StandardReferences(
  [
    'POSA — patterns of software architecture',
    'ISO/IEC 25010 — architectural quality attributes',
  ],
  'The caching, load-balancing, and queueing patterns used to meet performance goals.',
)
@SectionId('SCARPA')
class ScalabilityArchitecturePatterns {
  @Form([
    Field('cachingStrategy', String, 'Caching Strategy',
        hint: 'Multi-level caching approach'),
    Field('loadBalancing', String, 'Load Balancing',
        hint: 'Load balancing approach'),
    Field('queueingStrategy', String, 'Queueing Strategy',
        hint: 'Request queueing and throttling'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Resource optimization controls.
@StandardReferences(
  [
    'ISO/IEC 25010 — architectural quality attributes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'The connection pooling, resource limits, and graceful-degradation controls under load.',
)
@SectionId('SCAROP')
class ScalabilityArchitectureOptimization {
  @Form([
    Field('connectionPooling', String, 'Connection Pooling',
        hint: 'Connection pool management'),
    Field('resourceLimits', String, 'Resource Limits',
        hint: 'Per-component resource limits'),
    Field('gracefulDegradation', String, 'Graceful Degradation',
        hint: 'How system degrades under load'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing and benchmarks.
@StandardReferences(
  [
    'ISO/IEC 25010 — architectural quality attributes',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The performance and load testing approach and benchmarks the architecture must meet.',
)
@SectionId('SCARTE')
class ScalabilityArchitectureTesting {
  @Form([
    Field('performanceTesting', String, 'Performance Testing',
        hint: 'Performance testing approach'),
    Field('loadTesting', String, 'Load Testing', hint: 'Load testing approach'),
    Field('benchmarks', String, 'Benchmarks',
        hint: 'Performance benchmarks to meet'),
    Field('notes', String, 'Notes',
        hint: 'Additional scalability/performance notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Integration architecture with external systems.
@StandardReferences(
  [
    'REST / microservices — architectural style',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The integration strategy, patterns, and API management for external systems.',
)
@SectionId('INAR')
class IntegrationArchitecture {
  @Form([
    Field('integrationStrategy', String, 'Integration Strategy',
        hint: 'Point-to-point, Hub-and-spoke, ESB, API-led'),
    Field('integrationPatterns', String, 'Integration Patterns',
        hint: 'Adapters, Facades, Gateways'),
    Field('apiManagement', String, 'API Management',
        hint: 'How APIs are managed'),
  ])
  @SerializationOrder(0)
  String? content;

  /// External system landscape.
  @SerializationOrder(1)
  IntegrationArchitectureSystems systems = IntegrationArchitectureSystems();

  /// Data exchange approach.
  @SerializationOrder(2)
  IntegrationArchitectureData data = IntegrationArchitectureData();

  /// Security model for integrations.
  @SerializationOrder(3)
  IntegrationArchitectureSecurity security =
      IntegrationArchitectureSecurity();

  /// Reliability controls.
  @SerializationOrder(4)
  IntegrationArchitectureReliability reliability =
      IntegrationArchitectureReliability();

  /// Monitoring and SLA management.
  @SerializationOrder(5)
  IntegrationArchitectureOperations operations =
      IntegrationArchitectureOperations();
}

/// External system landscape.
@StandardReferences(
  [
    'REST / microservices — architectural style',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The landscape of external systems, their integration types, and real-time needs.',
)
@SectionId('INARSY')
class IntegrationArchitectureSystems {
  @Form([
    Field('externalSystemCount', String, 'External System Count',
        hint: 'Number of external integrations'),
    Field('integrationTypes', String, 'Integration Types',
        hint: 'REST, SOAP, File, Database, Events'),
    Field('realTimeIntegrations', String, 'Real-Time Integrations',
        hint: 'Integrations requiring real-time sync'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data exchange approach.
@StandardReferences(
  [
    'REST / microservices — architectural style',
    'POSA — patterns of software architecture',
  ],
  'The data transformation, master-data management, and synchronization across systems.',
)
@SectionId('INARDA')
class IntegrationArchitectureData {
  @Form([
    Field('dataTransformation', String, 'Data Transformation',
        hint: 'How data is transformed between systems'),
    Field('masterDataManagement', String, 'Master Data Management',
        hint: 'How master data is managed across systems'),
    Field('dataSynchronization', String, 'Data Synchronization',
        hint: 'Synchronization patterns and frequency'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security model for integrations.
@StandardReferences(
  [
    'ISO/IEC 25010 — architectural quality attributes',
    'REST / microservices — architectural style',
  ],
  'The authentication, authorization, and transport-security model for integrations.',
)
@SectionId('INARSE')
class IntegrationArchitectureSecurity {
  @Form([
    Field('authenticationApproach', String, 'Authentication Approach',
        hint: 'How integrations are authenticated'),
    Field('authorizationApproach', String, 'Authorization Approach',
        hint: 'How integrations are authorized'),
    Field('secureTransport', String, 'Secure Transport',
        hint: 'Transport security (TLS, VPN)'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reliability controls.
@StandardReferences(
  [
    'POSA — patterns of software architecture',
    'ISO/IEC 25010 — architectural quality attributes',
  ],
  'The error handling, retry, and compensating-action controls for integration reliability.',
)
@SectionId('INARRE')
class IntegrationArchitectureReliability {
  @Form([
    Field('errorHandling', String, 'Error Handling',
        hint: 'How integration errors are handled'),
    Field('retryStrategy', String, 'Retry Strategy',
        hint: 'Retry policies for failed integrations'),
    Field('compensatingActions', String, 'Compensating Actions',
        hint: 'Actions when integration fails'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Monitoring and SLA management.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 25010 — architectural quality attributes',
  ],
  'The monitoring and SLA management for external integrations.',
)
@SectionId('INAROP')
class IntegrationArchitectureOperations {
  @Form([
    Field('integrationMonitoring', String, 'Integration Monitoring',
        hint: 'How integrations are monitored'),
    Field('slaManagement', String, 'SLA Management',
        hint: 'Integration SLAs'),
    Field('notes', String, 'Notes',
        hint: 'Additional integration architecture notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Deployment topology and infrastructure.
@StandardReferences(
  [
    'REST / microservices — architectural style',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'The deployment topology, deployment model, and cloud providers for the system.',
)
@SectionId('DETO')
class DeploymentTopology {
  @Form([
    Field('topologyType', String, 'Topology Type',
        hint: 'Single-tier, Multi-tier, Distributed, Cloud-native'),
    Field('deploymentModel', String, 'Deployment Model',
        hint: 'On-premise, Cloud, Hybrid, Multi-cloud'),
    Field('cloudProviders', String, 'Cloud Providers',
        hint: 'Cloud providers used'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Infrastructure layout.
  @SerializationOrder(1)
  DeploymentTopologyInfrastructure infrastructure =
      DeploymentTopologyInfrastructure();

  /// Environment layout.
  @SerializationOrder(2)
  DeploymentTopologyEnvironments environmentsConfig =
      DeploymentTopologyEnvironments();

  /// High-availability settings.
  @SerializationOrder(3)
  DeploymentTopologyAvailability availability =
      DeploymentTopologyAvailability();

  /// Geographic distribution.
  @SerializationOrder(4)
  DeploymentTopologyGeography geography = DeploymentTopologyGeography();

  /// Infrastructure-as-code strategy.
  @SerializationOrder(5)
  DeploymentTopologyInfrastructureAsCode infrastructureAsCode =
      DeploymentTopologyInfrastructureAsCode();
}

/// Infrastructure layout.
@StandardReferences(
  [
    'REST / microservices — architectural style',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'The compute model, network topology, and storage infrastructure layout.',
)
@SectionId('DETOIN')
class DeploymentTopologyInfrastructure {
  @Form([
    Field('computeModel', String, 'Compute Model',
        hint: 'VMs, Containers, Serverless, Kubernetes'),
    Field('networkTopology', String, 'Network Topology',
        hint: 'Network architecture'),
    Field('storageInfrastructure', String, 'Storage Infrastructure',
        hint: 'Storage systems used'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Environment layout.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'REST / microservices — architectural style',
  ],
  'The environments, their isolation, and per-environment configuration management.',
)
@SectionId('DETOEN')
class DeploymentTopologyEnvironments {
  @Form([
    Field('environments', String, 'Environments',
        hint: 'Dev, Test, Staging, Production'),
    Field('environmentIsolation', String, 'Environment Isolation',
        hint: 'How environments are isolated'),
    Field('configurationManagement', String, 'Configuration Management',
        hint: 'How configuration differs per environment'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// High-availability settings.
@StandardReferences(
  [
    'ISO/IEC 25010 — architectural quality attributes',
    'REST / microservices — architectural style',
  ],
  'The redundancy model, failover strategy, and disaster recovery for high availability.',
)
@SectionId('DETOAV')
class DeploymentTopologyAvailability {
  @Form([
    Field('redundancyModel', String, 'Redundancy Model',
        hint: 'Active-passive, Active-active'),
    Field('failoverStrategy', String, 'Failover Strategy',
        hint: 'How failover is handled'),
    Field('disasterRecovery', String, 'Disaster Recovery',
        hint: 'DR strategy and targets'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Geographic distribution.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'REST / microservices — architectural style',
  ],
  'The geographic distribution, data residency, and latency considerations for deployment.',
)
@SectionId('DETOGE')
class DeploymentTopologyGeography {
  @Form([
    Field('geographicDistribution', String, 'Geographic Distribution',
        hint: 'Single-region, Multi-region, Global'),
    Field('dataResidency', String, 'Data Residency',
        hint: 'Data residency requirements'),
    Field('latencyConsiderations', String, 'Latency Considerations',
        hint: 'Geographic latency requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Infrastructure-as-code strategy.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'REST / microservices — architectural style',
  ],
  'The infrastructure-as-code approach, immutability, and versioning strategy.',
)
@SectionId('DTIAC')
class DeploymentTopologyInfrastructureAsCode {
  @Form([
    Field('iacApproach', String, 'IaC Approach',
        hint: 'Terraform, CloudFormation, Pulumi'),
    Field('immutableInfrastructure', String, 'Immutable Infrastructure',
        hint: 'Immutable infrastructure approach'),
    Field('infrastructureVersioning', String, 'Infrastructure Versioning',
        hint: 'How infrastructure is versioned'),
    Field('notes', String, 'Notes', hint: 'Additional deployment topology notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Architecture Decision Record (ADR) entry.
@StandardReferences(
  [
    'ADR (Architecture Decision Records) — decision capture',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'A single architecture decision record capturing a decision, its status, and identity.',
)
@SectionId('ARDE')
class ArchitectureDecisionRecord {
  @Form([
    Field('decisionId', String, 'Decision ID',
        required: true, hint: 'Unique identifier (e.g., ADR-001)'),
    Field('title', String, 'Title',
        required: true, hint: 'Short title of the decision'),
    Field('date', String, 'Date',
        required: true, hint: 'When the decision was made'),
    Field('status', String, 'Status',
        required: true,
        hint: 'Proposed, Accepted, Deprecated, Superseded'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Decision context and constraints.
  @SerializationOrder(1)
  ArchitectureDecisionRecordContext contextDetails =
      ArchitectureDecisionRecordContext();

  /// Decision outcome and rationale.
  @SerializationOrder(2)
  ArchitectureDecisionRecordOutcome outcome =
      ArchitectureDecisionRecordOutcome();

  /// Consequences and review.
  @SerializationOrder(3)
  ArchitectureDecisionRecordConsequences consequences =
      ArchitectureDecisionRecordConsequences();

  /// Related decision links.
  @SerializationOrder(4)
  ArchitectureDecisionRecordRelations relations =
      ArchitectureDecisionRecordRelations();
}

/// Decision context and constraints.
@StandardReferences(
  [
    'ADR (Architecture Decision Records) — decision capture',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The context, problem, and constraints that prompted an architecture decision.',
)
@SectionId('ADRC')
class ArchitectureDecisionRecordContext {
  @Form([
    Field('context', String, 'Context',
        required: true, hint: 'What prompted this decision'),
    Field('problem', String, 'Problem Statement',
        hint: 'The specific problem being addressed'),
    Field('constraints', String, 'Constraints',
        hint: 'Constraints that influenced the decision'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Decision outcome and rationale.
@StandardReferences(
  [
    'ADR (Architecture Decision Records) — decision capture',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The decision made, its rationale, alternatives considered, and decision makers.',
)
@SectionId('ADRO')
class ArchitectureDecisionRecordOutcome {
  @Form([
    Field('decision', String, 'Decision',
        required: true, hint: 'What was decided'),
    Field('rationale', String, 'Rationale',
        required: true, hint: 'Why this decision was made'),
    Field('alternativesConsidered', String, 'Alternatives Considered',
        hint: 'Other options that were evaluated'),
    Field('decisionMakers', String, 'Decision Makers',
        hint: 'Who made this decision'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Consequences and review.
@StandardReferences(
  [
    'ADR (Architecture Decision Records) — decision capture',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The positive and negative consequences of an architecture decision and its review date.',
)
@SectionId('ARDERECO')
class ArchitectureDecisionRecordConsequences {
  @Form([
    Field('consequences', String, 'Consequences',
        hint: 'Impact of this decision'),
    Field('positiveConsequences', String, 'Positive Consequences',
        hint: 'Benefits of this decision'),
    Field('negativeConsequences', String, 'Negative Consequences',
        hint: 'Drawbacks of this decision'),
    Field('reviewDate', String, 'Review Date',
        hint: 'When this decision should be reviewed'),
    Field('notes', String, 'Notes', hint: 'Additional decision notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Related decision links.
@StandardReferences(
  [
    'ADR (Architecture Decision Records) — decision capture',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'The links between an architecture decision and related, superseded, or superseding decisions.',
)
@SectionId('ADRR')
class ArchitectureDecisionRecordRelations {
  @Form([
    Field('relatedDecisions', String, 'Related Decisions',
        hint: 'Other ADRs related to this one'),
    Field('supersedes', String, 'Supersedes',
        hint: 'Previous decisions this supersedes'),
    Field('supersededBy', String, 'Superseded By',
        hint: 'Decision that supersedes this one'),
  ])
  @SerializationOrder(0)
  String? content;
}

// =============================================================================
// 8.1.3. Design Patterns and Standards
// =============================================================================

/// 8.1.3. Design Patterns and Standards.
///
/// Required design patterns, coding standards, development conventions, and
/// applicable industry standards (ISO, OWASP, IEEE).
@ContentHelp('''
Specify required design patterns, coding standards, development conventions,
and industry standards compliance. Consistent patterns improve code
quality, maintainability, and team productivity.

**Design Patterns**:
- **Creational**: Factory, Builder, Singleton, Dependency Injection
- **Structural**: Adapter, Decorator, Facade, Proxy, Composite
- **Behavioral**: Observer, Strategy, Command, State, Chain of Responsibility
- **Architectural**: Repository, Unit of Work, CQRS, Event Sourcing
- **Concurrency**: Thread Pool, Producer-Consumer, Async/Await patterns
- **Integration**: API Gateway, Circuit Breaker, Retry, Bulkhead

**Coding Standards**:
- Language-specific style guides (PEP 8, Google Style, Airbnb)
- Naming conventions and code organization
- Documentation requirements (doc comments, README standards)
- Testing requirements (unit, integration, e2e coverage targets)
- Code review checklist and approval criteria

**Industry Standards**:
- **Security**: OWASP Top 10, OWASP ASVS, CWE
- **Quality**: ISO/IEC 25010, CMMI
- **Documentation**: IEEE 830, ISO/IEC 26514
- **Process**: ISO 27001, SOC 2, GDPR, HIPAA

**Enforcement**: Linters, static analysis, automated checks in CI/CD.
''')
@StandardReferences(
  [
    'GoF design patterns — reusable OO design',
    'coding standards (e.g. Effective Dart / language style guide)',
    'industry standards compliance (ISO/IEC / W3C / IETF)',
  ],
  'Defines the design patterns, coding standards, development conventions, and industry standards the implementation must follow.',
)
@SectionId('DPAS')
class DesignPatternsAndStandards {
  @ContentHelp('''
Provide an overview of the design patterns and standards approach.

**Include**:
- Core pattern library with usage guidelines
- Coding standards summary with enforcement mechanisms
- Industry compliance requirements and evidence
- Code quality metrics and thresholds
- Exception handling and error patterns

**Best Practices**:
- Create pattern catalog with examples and anti-patterns
- Automate standards enforcement in CI/CD pipeline
- Document when NOT to use certain patterns
- Plan regular pattern and standards reviews
- Establish technical debt tracking for standards violations
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of design patterns and standards approach.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Required design patterns catalog.
  @StandardReferences(
    [
      'GoF design patterns — reusable OO design',
      'POSA — patterns of software architecture',
      'Domain-Driven Design — tactical patterns (entities/aggregates/repositories)',
    ],
    'The design patterns the implementation is expected to apply.',
  )
  @SectionId('DSPT-DESI-LST')
  @SectionIdPattern('DSPT-DESI-xxx')
  @ContentHelp('Add one entry per design pattern.')
  @SerializationOrder(2)
  List<DesignPatternEntry> designPatterns = [];

  /// Coding standards and style guidelines.
  @StandardReferences(
    [
      'coding standards (e.g. Effective Dart / language style guide)',
      'SOLID principles — object-oriented design',
    ],
    'The coding standards and style guidelines the code must comply with.',
  )
  @SectionId('COSTEN-CODI-LST')
  @SectionIdPattern('COSTEN-CODI-xxx')
  @ContentHelp('Add one entry per coding standard.')
  @SerializationOrder(3)
  List<CodingStandardEntry> codingStandards = [];

  /// Development conventions and best practices.
  @StandardReferences(
    [
      'coding standards (e.g. Effective Dart / language style guide)',
      'SOLID principles — object-oriented design',
    ],
    'The development practices and workflow conventions the team must follow.',
  )
  @SectionId('DECOEN-DEVE-LST')
  @SectionIdPattern('DECOEN-DEVE-xxx')
  @ContentHelp('Add one entry per development convention.')
  @SerializationOrder(4)
  List<DevelopmentConventionEntry> developmentConventions = [];

  /// Industry standards compliance requirements.
  @StandardReferences(
    [
      'industry standards compliance (ISO/IEC / W3C / IETF)',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'The industry standards the system is required to comply with.',
  )
  @SectionId('INSTEN-INDU-LST')
  @SectionIdPattern('INSTEN-INDU-xxx')
  @ContentHelp('Add one entry per industry standard.')
  @SerializationOrder(5)
  List<IndustryStandardEntry> industryStandards = [];

  /// Code quality metrics and thresholds.
  @SerializationOrder(6)
  CodeQualityMetrics codeQualityMetrics = CodeQualityMetrics();

  /// Documentation standards.
  @SerializationOrder(7)
  DocumentationStandards documentationStandards = DocumentationStandards();

  /// Error handling and exception patterns.
  @SerializationOrder(8)
  ErrorHandlingStandards errorHandlingStandards = ErrorHandlingStandards();

  /// Testing standards and requirements.
  @SerializationOrder(9)
  TestingStandards testingStandards = TestingStandards();
}

/// Design pattern entry — a specific design pattern to be used.
@StandardReferences(
  [
    'GoF design patterns — reusable OO design',
    'POSA — patterns of software architecture',
    'Domain-Driven Design — tactical patterns (entities/aggregates/repositories)',
  ],
  'A single design pattern the implementation is expected to apply.',
)
@SectionId('DSPT')
class DesignPatternEntry {
  @Form([
    Field('patternName', String, 'Pattern Name',
        required: true,
        hint: 'E.g., Repository, Factory, Observer, State, Command'),
    Field('patternCategory', String, 'Category',
        required: true,
        hint: 'Creational, Structural, Behavioral, Architectural, UI'),
    Field('patternSource', String, 'Source',
        hint: 'GoF, Enterprise Patterns, DDD, UI Patterns'),
    Field('purpose', String, 'Purpose',
        required: true, hint: 'What problem this pattern solves'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Applicability guidance.
  @SerializationOrder(1)
  DesignPatternEntryApplicability applicability =
      DesignPatternEntryApplicability();

  /// Structural composition.
  @SerializationOrder(2)
  DesignPatternEntryStructure structure = DesignPatternEntryStructure();

  /// Implementation guidance.
  @SerializationOrder(3)
  DesignPatternEntryImplementation implementation =
      DesignPatternEntryImplementation();

  /// Architectural context.
  @SerializationOrder(4)
  DesignPatternEntryContext context = DesignPatternEntryContext();

  /// Enforcement and notes.
  @SerializationOrder(5)
  DesignPatternEntryEnforcement enforcement =
      DesignPatternEntryEnforcement();
}

/// Applicability guidance.
@StandardReferences(
  [
    'GoF design patterns — reusable OO design',
    'POSA — patterns of software architecture',
  ],
  'Describes when a design pattern applies and when it should be avoided.',
)
@SectionId('DPEA')
class DesignPatternEntryApplicability {
  @Form([
    Field('applicability', String, 'When to Use',
        hint: 'Situations where this pattern applies'),
    Field('notApplicable', String, 'When NOT to Use',
        hint: 'Situations where this pattern should be avoided'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Structural composition.
@StandardReferences(
  [
    'GoF design patterns — reusable OO design',
    'POSA — patterns of software architecture',
  ],
  'Describes the participants, collaborations, and variations of a design pattern.',
)
@SectionId('DEPAENST')
class DesignPatternEntryStructure {
  @Form([
    Field('participants', String, 'Participants',
        hint: 'Key classes/objects involved in this pattern'),
    Field('collaborations', String, 'Collaborations',
        hint: 'How participants interact'),
    Field('variations', String, 'Variations',
        hint: 'Supported variations of this pattern'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Implementation guidance.
@StandardReferences(
  [
    'GoF design patterns — reusable OO design',
    'Domain-Driven Design — tactical patterns (entities/aggregates/repositories)',
  ],
  'Describes how a design pattern is implemented within the project.',
)
@SectionId('DPEI')
class DesignPatternEntryImplementation {
  @Form([
    Field('implementationGuidelines', String, 'Implementation Guidelines',
        hint: 'How to implement this pattern in the project'),
    Field('codeTemplate', String, 'Code Template/Example',
        hint: 'Reference to template or example code'),
    Field('frameworkSupport', String, 'Framework Support',
        hint: 'How the framework supports this pattern'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Architectural context.
@StandardReferences(
  [
    'POSA — patterns of software architecture',
    'GoF design patterns — reusable OO design',
  ],
  'Describes where a design pattern applies in the architecture and related patterns.',
)
@SectionId('DEPAENCO')
class DesignPatternEntryContext {
  @Form([
    Field('usageScope', String, 'Usage Scope',
        hint: 'Where in the architecture this pattern applies'),
    Field('relatedPatterns', String, 'Related Patterns',
        hint: 'Other patterns commonly used with this one'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Enforcement and notes.
@StandardReferences(
  [
    'GoF design patterns — reusable OO design',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Describes how design-pattern compliance is enforced and verified.',
)
@SectionId('DPEE')
class DesignPatternEntryEnforcement {
  @Form([
    Field('enforcementLevel', String, 'Enforcement Level',
        hint: 'Mandatory, Recommended, Optional'),
    Field('verificationMethod', String, 'Verification Method',
        hint: 'How compliance is verified'),
    Field('notes', String, 'Notes', hint: 'Additional pattern notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Coding standard entry — a coding style or convention requirement.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ],
  'A single coding style or convention requirement the code must satisfy.',
)
@SectionId('CSE')
class CodingStandardEntry {
  @Form([
    Field('standardName', String, 'Standard Name',
        required: true, hint: 'E.g., Effective Dart, Clean Code, Project-specific'),
    Field('standardCategory', String, 'Category',
        required: true,
        hint: 'Naming, Formatting, Comments, Structure, Imports'),
    Field('applicableLanguage', String, 'Applicable Language',
        hint: 'Which programming language(s) this applies to'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Rule description.
  @SerializationOrder(1)
  CodingStandardEntryRuleDetails ruleDetails = CodingStandardEntryRuleDetails();

  /// Naming requirements.
  @SerializationOrder(2)
  CodingStandardEntryNaming naming = CodingStandardEntryNaming();

  /// Formatting requirements.
  @SerializationOrder(3)
  CodingStandardEntryFormatting formatting = CodingStandardEntryFormatting();

  /// Enforcement details.
  @SerializationOrder(4)
  CodingStandardEntryEnforcement enforcement =
      CodingStandardEntryEnforcement();
}

/// Rule description.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ],
  'States a coding rule together with its rationale and examples.',
)
@SectionId('CSERD')
class CodingStandardEntryRuleDetails {
  @Form([
    Field('rule', String, 'Rule',
        required: true, hint: 'Clear statement of the coding rule'),
    Field('rationale', String, 'Rationale', hint: 'Why this rule matters'),
    Field('examples', String, 'Examples', hint: 'Good and bad code examples'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Naming requirements.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ],
  'Defines the naming conventions and prefix/suffix rules for identifiers.',
)
@SectionId('CSEN')
class CodingStandardEntryNaming {
  @Form([
    Field('namingConvention', String, 'Naming Convention',
        hint: 'camelCase, PascalCase, snake_case rules'),
    Field('prefixSuffix', String, 'Prefix/Suffix Rules',
        hint: 'Required prefixes or suffixes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Formatting requirements.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ],
  'Defines indentation, line-length, and bracing formatting rules for the code.',
)
@SectionId('CSEF')
class CodingStandardEntryFormatting {
  @Form([
    Field('indentation', String, 'Indentation',
        hint: 'Spaces vs tabs, indentation size'),
    Field('lineLength', String, 'Line Length', hint: 'Maximum line length'),
    Field('bracingStyle', String, 'Bracing Style',
        hint: 'Where braces should appear'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Enforcement details.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ],
  'Describes how a coding standard is enforced via linters, severity, and CI checks.',
)
@SectionId('CSEE')
class CodingStandardEntryEnforcement {
  @Form([
    Field('linterRule', String, 'Linter Rule',
        hint: 'Corresponding linter rule name'),
    Field('severity', String, 'Severity',
        hint: 'Error, Warning, Info'),
    Field('enforcementMethod', String, 'Enforcement Method',
        hint: 'Linter, Code review, CI check'),
    Field('autoFixable', bool, 'Auto-Fixable',
        hint: 'Can be automatically fixed'),
    Field('notes', String, 'Notes', hint: 'Additional standard notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Development convention entry — a development practice or workflow convention.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ],
  'A single development practice or workflow convention the team must follow.',
)
@SectionId('DCE')
class DevelopmentConventionEntry {
  @Form([
    Field('conventionName', String, 'Convention Name',
        required: true, hint: 'Name of the development convention'),
    Field('conventionCategory', String, 'Category',
        required: true,
        hint:
            'Version Control, Code Review, Branching, Commit, CI/CD, Deployment'),
    Field('description', String, 'Description',
        required: true, hint: 'What the convention requires'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Background and workflow.
  @SerializationOrder(1)
  DevelopmentConventionEntryOverview overview =
      DevelopmentConventionEntryOverview();

  /// Version control requirements.
  @SerializationOrder(2)
  DevelopmentConventionEntryVersionControl versionControl =
      DevelopmentConventionEntryVersionControl();

  /// Code review expectations.
  @SerializationOrder(3)
  DevelopmentConventionEntryReview review =
      DevelopmentConventionEntryReview();

  /// Automation integration.
  @SerializationOrder(4)
  DevelopmentConventionEntryAutomation automation =
      DevelopmentConventionEntryAutomation();

  /// Enforcement and exceptions.
  @SerializationOrder(5)
  DevelopmentConventionEntryEnforcement enforcement =
      DevelopmentConventionEntryEnforcement();
}

/// Background and workflow.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ],
  'Explains the rationale and step-by-step workflow behind a development convention.',
)
@SectionId('DCEO')
class DevelopmentConventionEntryOverview {
  @Form([
    Field('rationale', String, 'Rationale',
        hint: 'Why this convention is important'),
    Field('workflow', String, 'Workflow',
        hint: 'Step-by-step workflow if applicable'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Version control requirements.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ],
  'Defines branching, commit, and pull-request requirements for version control.',
)
@SectionId('DCEVC')
class DevelopmentConventionEntryVersionControl {
  @Form([
    Field('branchingStrategy', String, 'Branching Strategy',
        hint: 'GitFlow, trunk-based, feature branches'),
    Field('branchNaming', String, 'Branch Naming',
        hint: 'Branch naming convention'),
    Field('commitFormat', String, 'Commit Message Format',
        hint: 'Conventional commits, custom format'),
    Field('prProcess', String, 'PR Process',
        hint: 'Pull request requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Code review expectations.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ],
  'Defines the code-review requirements and checklist the team applies.',
)
@SectionId('DCER')
class DevelopmentConventionEntryReview {
  @Form([
    Field('reviewRequirements', String, 'Review Requirements',
        hint: 'Minimum reviewers, approval rules'),
    Field('reviewChecklist', String, 'Review Checklist',
        hint: 'Items to check during review'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Automation integration.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ],
  'Describes how a development convention integrates with CI/CD automation and triggers.',
)
@SectionId('DCEA')
class DevelopmentConventionEntryAutomation {
  @Form([
    Field('automationIntegration', String, 'Automation Integration',
        hint: 'How this integrates with CI/CD'),
    Field('triggers', String, 'Triggers',
        hint: 'What triggers this convention'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Enforcement and exceptions.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ],
  'Describes how a development convention is enforced and which exceptions are allowed.',
)
@SectionId('DCEE')
class DevelopmentConventionEntryEnforcement {
  @Form([
    Field('enforcementLevel', String, 'Enforcement Level',
        hint: 'Mandatory, Recommended, Advisory'),
    Field('enforcementMethod', String, 'Enforcement Method',
        hint: 'Git hooks, CI checks, manual'),
    Field('exceptions', String, 'Exceptions',
        hint: 'Allowed exceptions to this convention'),
    Field('notes', String, 'Notes', hint: 'Additional convention notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Industry standard entry — compliance with industry standards.
@StandardReferences(
  [
    'industry standards compliance (ISO/IEC / W3C / IETF)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'A single industry standard the system is required to comply with.',
)
@SectionId('ISE')
class IndustryStandardEntry {
  @Form([
    Field('standardName', String, 'Standard Name',
        required: true, hint: 'E.g., ISO 27001, OWASP, IEEE 830, GDPR'),
    Field('standardBody', String, 'Standard Body',
        hint: 'ISO, IEEE, OWASP, NIST, ECMA'),
    Field('version', String, 'Version',
        hint: 'Version of the standard'),
    Field('publicationDate', String, 'Publication Date',
        hint: 'Standard publication date'),
    Field('category', String, 'Category',
        required: true,
        hint: 'Security, Quality, Process, Documentation, Accessibility'),
    Field('complianceLevel', String, 'Compliance Level',
        required: true, hint: 'Full, Partial, Certified, In Progress'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Scope details.
  @SerializationOrder(1)
  IndustryStandardEntryScope scope = IndustryStandardEntryScope();

  /// Requirement applicability.
  @SerializationOrder(2)
  IndustryStandardEntryCompliance compliance =
      IndustryStandardEntryCompliance();

  /// Certification details.
  @SerializationOrder(3)
  IndustryStandardEntryCertification certification =
      IndustryStandardEntryCertification();

  /// Verification settings.
  @SerializationOrder(4)
  IndustryStandardEntryVerification verification =
      IndustryStandardEntryVerification();

  /// Reference metadata.
  @SerializationOrder(5)
  IndustryStandardEntryReference reference = IndustryStandardEntryReference();
}

/// Scope details.
@StandardReferences(
  [
    'industry standards compliance (ISO/IEC / W3C / IETF)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Defines which parts of the system an industry standard applies to.',
)
@SectionId('ISES')
class IndustryStandardEntryScope {
  @Form([
    Field('applicableAreas', String, 'Applicable Areas',
        hint: 'Which parts of the system this applies to'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Requirement applicability.
@StandardReferences(
  [
    'industry standards compliance (ISO/IEC / W3C / IETF)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Identifies which requirements of an industry standard apply and which are excluded.',
)
@SectionId('ISEC')
class IndustryStandardEntryCompliance {
  @Form([
    Field('applicableRequirements', String, 'Applicable Requirements',
        hint: 'Specific sections or requirements that apply'),
    Field('excludedRequirements', String, 'Excluded Requirements',
        hint: 'Requirements that do not apply'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Certification details.
@StandardReferences(
  [
    'industry standards compliance (ISO/IEC / W3C / IETF)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Describes whether formal certification is required for an industry standard and its scope.',
)
@SectionId('INSTENCE')
class IndustryStandardEntryCertification {
  @Form([
    Field('certificationRequired', bool, 'Certification Required',
        hint: 'Is formal certification required?'),
    Field('certificationBody', String, 'Certification Body',
        hint: 'Who provides certification'),
    Field('certificationScope', String, 'Certification Scope',
        hint: 'Scope of certification'),
    Field('certificationTarget', String, 'Certification Target Date',
        hint: 'Target date for certification'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Verification settings.
@StandardReferences(
  [
    'industry standards compliance (ISO/IEC / W3C / IETF)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Defines how compliance with an industry standard is audited and evidenced.',
)
@SectionId('ISEV')
class IndustryStandardEntryVerification {
  @Form([
    Field('auditFrequency', String, 'Audit Frequency',
        hint: 'How often compliance is audited'),
    Field('verificationMethod', String, 'Verification Method',
        hint: 'How compliance is verified'),
    Field('evidenceRequired', String, 'Evidence Required',
        hint: 'Documentation required for compliance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reference metadata.
@StandardReferences(
  [
    'industry standards compliance (ISO/IEC / W3C / IETF)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Holds reference links and notes for an industry standard.',
)
@SectionId('ISER')
class IndustryStandardEntryReference {
  @Form([
    Field('referenceUrl', String, 'Reference URL',
        hint: 'Link to standard documentation'),
    Field('notes', String, 'Notes', hint: 'Additional compliance notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Code quality metrics and thresholds.
@StandardReferences(
  [
    'ISO/IEC 25010 — maintainability quality attributes',
    'coding standards (e.g. Effective Dart / language style guide)',
  ],
  'Defines the code-quality metrics and thresholds the codebase must meet.',
)
@SectionId('COQUME')
class CodeQualityMetrics {
  @Form([
    Field('testCoverageMinimum', String, 'Test Coverage Minimum',
        hint: 'Minimum test coverage percentage'),
    Field('branchCoverageMinimum', String, 'Branch Coverage Minimum',
        hint: 'Minimum branch coverage percentage'),
    Field('mutationScoreMinimum', String, 'Mutation Score Minimum',
        hint: 'Minimum mutation testing score'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Complexity limits.
  @SerializationOrder(1)
  CodeQualityMetricsComplexity complexity = CodeQualityMetricsComplexity();

  /// Coupling metrics.
  @SerializationOrder(2)
  CodeQualityMetricsCoupling coupling = CodeQualityMetricsCoupling();

  /// Duplication thresholds.
  @SerializationOrder(3)
  CodeQualityMetricsDuplication duplication =
      CodeQualityMetricsDuplication();

  /// Static analysis thresholds.
  @SerializationOrder(4)
  CodeQualityMetricsStaticAnalysis staticAnalysis =
      CodeQualityMetricsStaticAnalysis();

  /// Tooling and reporting.
  @SerializationOrder(5)
  CodeQualityMetricsTooling tooling = CodeQualityMetricsTooling();
}

/// Complexity limits.
@StandardReferences(
  [
    'ISO/IEC 25010 — maintainability quality attributes',
    'coding standards (e.g. Effective Dart / language style guide)',
  ],
  'Defines maximum complexity and length limits per method and class.',
)
@SectionId('CQMC')
class CodeQualityMetricsComplexity {
  @Form([
    Field('cyclomaticComplexityMax', String, 'Cyclomatic Complexity Max',
        hint: 'Maximum cyclomatic complexity per method'),
    Field('cognitiveComplexityMax', String, 'Cognitive Complexity Max',
        hint: 'Maximum cognitive complexity per method'),
    Field('methodLengthMax', String, 'Method Length Max',
        hint: 'Maximum lines of code per method'),
    Field('classLengthMax', String, 'Class Length Max',
        hint: 'Maximum lines of code per class'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Coupling metrics.
@StandardReferences(
  [
    'ISO/IEC 25010 — maintainability quality attributes',
    'SOLID principles — object-oriented design',
  ],
  'Defines acceptable afferent/efferent coupling and instability ranges.',
)
@SectionId('COQUMECO')
class CodeQualityMetricsCoupling {
  @Form([
    Field('afferentCouplingMax', String, 'Afferent Coupling Max',
        hint: 'Maximum incoming dependencies'),
    Field('efferentCouplingMax', String, 'Efferent Coupling Max',
        hint: 'Maximum outgoing dependencies'),
    Field('instabilityRange', String, 'Instability Range',
        hint: 'Acceptable instability range'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Duplication thresholds.
@StandardReferences(
  [
    'ISO/IEC 25010 — maintainability quality attributes',
    'coding standards (e.g. Effective Dart / language style guide)',
  ],
  'Defines the maximum acceptable code duplication and detection block size.',
)
@SectionId('CQMD')
class CodeQualityMetricsDuplication {
  @Form([
    Field('duplicationMax', String, 'Code Duplication Max',
        hint: 'Maximum code duplication percentage'),
    Field('duplicationBlockSize', String, 'Duplication Block Size',
        hint: 'Minimum lines to consider duplication'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Static analysis thresholds.
@StandardReferences(
  [
    'ISO/IEC 25010 — maintainability quality attributes',
    'coding standards (e.g. Effective Dart / language style guide)',
  ],
  'Defines allowed static-analysis warnings, critical issues, and technical-debt targets.',
)
@SectionId('CQMSA')
class CodeQualityMetricsStaticAnalysis {
  @Form([
    Field('warningsAllowed', String, 'Warnings Allowed',
        hint: 'Maximum allowed static analysis warnings'),
    Field('criticalIssuesAllowed', String, 'Critical Issues Allowed',
        hint: 'Maximum critical issues allowed (usually 0)'),
    Field('technicalDebtTarget', String, 'Technical Debt Target',
        hint: 'Target technical debt ratio'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Tooling and reporting.
@StandardReferences(
  [
    'ISO/IEC 25010 — maintainability quality attributes',
    'coding standards (e.g. Effective Dart / language style guide)',
  ],
  'Defines the tools, frequency, and trend monitoring used to measure code quality.',
)
@SectionId('CQMT')
class CodeQualityMetricsTooling {
  @Form([
    Field('analysisTools', String, 'Analysis Tools',
        hint: 'Tools used for quality measurement'),
    Field('reportingFrequency', String, 'Reporting Frequency',
        hint: 'How often metrics are reported'),
    Field('trendMonitoring', String, 'Trend Monitoring',
        hint: 'How quality trends are monitored'),
    Field('notes', String, 'Notes', hint: 'Additional quality metrics notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation standards and requirements.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Defines the documentation standards and requirements the codebase must follow.',
)
@SectionId('DOST')
class DocumentationStandards {
  @Form([
    Field('publicApiDocRequired', bool, 'Public API Doc Required',
        hint: 'All public APIs must be documented'),
    Field('docCommentFormat', String, 'Doc Comment Format',
        hint: 'Dartdoc, JSDoc, Javadoc format'),
    Field('parameterDocRequired', bool, 'Parameter Doc Required',
        hint: 'Parameters must be documented'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Code documentation requirements.
  @SerializationOrder(1)
  DocumentationStandardsCodeDocs codeDocs = DocumentationStandardsCodeDocs();

  /// Content requirements.
  @SerializationOrder(2)
  DocumentationStandardsContent contentRequirements =
      DocumentationStandardsContent();

  /// Architecture documentation requirements.
  @SerializationOrder(3)
  DocumentationStandardsArchitecture architecture =
      DocumentationStandardsArchitecture();

  /// Changelog and versioning requirements.
  @SerializationOrder(4)
  DocumentationStandardsVersioning versioning =
      DocumentationStandardsVersioning();

  /// Review and publication settings.
  @SerializationOrder(5)
  DocumentationStandardsProcess process = DocumentationStandardsProcess();
}

/// Code documentation requirements.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Defines requirements for documenting return values and examples in code.',
)
@SectionId('DSCD')
class DocumentationStandardsCodeDocs {
  @Form([
    Field('returnDocRequired', bool, 'Return Doc Required',
        hint: 'Return values must be documented'),
    Field('exampleRequired', bool, 'Example Required',
        hint: 'Examples required for complex APIs'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Content requirements.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Defines minimum content, cross-referencing, and deprecation-notice requirements for docs.',
)
@SectionId('DOSTCO')
class DocumentationStandardsContent {
  @Form([
    Field('minimumDescription', String, 'Minimum Description',
        hint: 'Minimum description length/content'),
    Field('crossReferenceRequired', bool, 'Cross-Reference Required',
        hint: 'Related items must be cross-referenced'),
    Field('deprecationNotice', String, 'Deprecation Notice',
        hint: 'How to document deprecations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Architecture documentation requirements.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'coding standards (e.g. Effective Dart / language style guide)',
  ],
  'Defines the required architecture documentation, diagrams, and READMEs.',
)
@SectionId('DOSTAR')
class DocumentationStandardsArchitecture {
  @Form([
    Field('architectureDocRequired', bool, 'Architecture Doc Required',
        hint: 'Architecture documentation required'),
    Field('diagramsRequired', String, 'Diagrams Required',
        hint: 'Required diagram types'),
    Field('readmeRequired', bool, 'README Required',
        hint: 'README required for each package/module'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Changelog and versioning requirements.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Defines the changelog and versioning-scheme requirements for the project.',
)
@SectionId('DOSTVE')
class DocumentationStandardsVersioning {
  @Form([
    Field('changelogRequired', bool, 'Changelog Required',
        hint: 'Changelog must be maintained'),
    Field('changelogFormat', String, 'Changelog Format',
        hint: 'Keep a Changelog, custom format'),
    Field('versioningScheme', String, 'Versioning Scheme',
        hint: 'Semantic versioning, CalVer'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Review and publication settings.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Defines documentation review, generation tooling, and publishing requirements.',
)
@SectionId('DOSTPR')
class DocumentationStandardsProcess {
  @Form([
    Field('docReviewRequired', bool, 'Doc Review Required',
        hint: 'Documentation changes require review'),
    Field('technicalWriterReview', bool, 'Technical Writer Review',
        hint: 'Professional tech writer review'),
    Field('docGenerationTool', String, 'Doc Generation Tool',
        hint: 'Tool for generating documentation'),
    Field('publishingLocation', String, 'Publishing Location',
        hint: 'Where documentation is published'),
    Field('notes', String, 'Notes',
        hint: 'Additional documentation standards notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Error handling and exception patterns.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ],
  'Defines the error-handling philosophy, fail-fast approach, and graceful-degradation standards.',
)
@SectionId('ERHAST')
class ErrorHandlingStandards {
  @Form([
    Field('errorPhilosophy', String, 'Error Handling Philosophy',
        hint: 'Exceptions, Result types, Either, Error codes'),
    Field('failFastApproach', String, 'Fail-Fast Approach',
        hint: 'When and how to fail fast'),
    Field('gracefulDegradation', String, 'Graceful Degradation',
        hint: 'How to degrade gracefully'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Exception type conventions.
  @SerializationOrder(1)
  ErrorHandlingStandardsExceptions exceptions =
      ErrorHandlingStandardsExceptions();

  /// Handling pattern defaults.
  @SerializationOrder(2)
  ErrorHandlingStandardsPatterns patterns =
      ErrorHandlingStandardsPatterns();

  /// Reporting standards.
  @SerializationOrder(3)
  ErrorHandlingStandardsReporting reporting =
      ErrorHandlingStandardsReporting();

  /// User-facing communication rules.
  @SerializationOrder(4)
  ErrorHandlingStandardsUserCommunication userCommunication =
      ErrorHandlingStandardsUserCommunication();

  /// Recovery guidance.
  @SerializationOrder(5)
  ErrorHandlingStandardsRecovery recovery =
      ErrorHandlingStandardsRecovery();
}

/// Exception type conventions.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ],
  'Defines the exception hierarchy, custom-exception policy, and naming conventions.',
)
@SectionId('EHSE')
class ErrorHandlingStandardsExceptions {
  @Form([
    Field('exceptionHierarchy', String, 'Exception Hierarchy',
        hint: 'Base exception class structure'),
    Field('customExceptions', String, 'Custom Exceptions',
        hint: 'When to create custom exceptions'),
    Field('exceptionNaming', String, 'Exception Naming',
        hint: 'Naming convention for exceptions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Handling pattern defaults.
@StandardReferences(
  [
    'GoF design patterns — reusable OO design',
    'POSA — patterns of software architecture',
  ],
  'Defines default handling patterns such as catch-all policy, retry, and circuit breaker.',
)
@SectionId('EHSP')
class ErrorHandlingStandardsPatterns {
  @Form([
    Field('catchAllPolicy', String, 'Catch-All Policy',
        hint: 'Policy on catch-all handlers'),
    Field('retryPolicy', String, 'Retry Policy',
        hint: 'When and how to retry operations'),
    Field('circuitBreakerPolicy', String, 'Circuit Breaker Policy',
        hint: 'Circuit breaker implementation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reporting standards.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Defines how errors are logged, tracked, and how sensitive data is handled in reports.',
)
@SectionId('EHSR')
class ErrorHandlingStandardsReporting {
  @Form([
    Field('errorLogging', String, 'Error Logging',
        hint: 'How errors are logged'),
    Field('errorTracking', String, 'Error Tracking',
        hint: 'Error tracking service/approach'),
    Field('sensitiveDataHandling', String, 'Sensitive Data Handling',
        hint: 'How to handle sensitive data in errors'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// User-facing communication rules.
@StandardReferences(
  [
    'coding standards (e.g. Effective Dart / language style guide)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Defines standards for user-facing error messages, error codes, and localization.',
)
@SectionId('EHSUC')
class ErrorHandlingStandardsUserCommunication {
  @Form([
    Field('userErrorMessages', String, 'User Error Messages',
        hint: 'User-facing error message standards'),
    Field('errorCodes', String, 'Error Codes',
        hint: 'Error code format and catalog'),
    Field('localization', String, 'Localization',
        hint: 'Error message localization'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Recovery guidance.
@StandardReferences(
  [
    'POSA — patterns of software architecture',
    'GoF design patterns — reusable OO design',
  ],
  'Defines standard recovery strategies and compensating actions for partial failures.',
)
@SectionId('ERHASTRE')
class ErrorHandlingStandardsRecovery {
  @Form([
    Field('recoveryStrategies', String, 'Recovery Strategies',
        hint: 'Standard recovery strategies'),
    Field('compensatingActions', String, 'Compensating Actions',
        hint: 'How to handle partial failures'),
    Field('notes', String, 'Notes',
        hint: 'Additional error handling notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing standards and requirements.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 — software testing',
    'xUnit / test patterns — automated testing',
  ],
  'Defines the testing standards and required test types for the implementation.',
)
@SectionId('TS')
class TestingStandards {
  @Form([
    Field('unitTestRequired', bool, 'Unit Test Required',
        hint: 'Unit tests required for all code'),
    Field('integrationTestRequired', bool, 'Integration Test Required',
        hint: 'Integration tests required'),
    Field('e2eTestRequired', bool, 'E2E Test Required',
        hint: 'End-to-end tests required'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Additional test types and organization.
  @SerializationOrder(1)
  TestingStandardsOrganization organization = TestingStandardsOrganization();

  /// Preferred testing patterns.
  @SerializationOrder(2)
  TestingStandardsPatterns patterns = TestingStandardsPatterns();

  /// Quality requirements for tests.
  @SerializationOrder(3)
  TestingStandardsQuality quality = TestingStandardsQuality();

  /// Testing tools and CI integration.
  @SerializationOrder(4)
  TestingStandardsTooling tooling = TestingStandardsTooling();
}

/// Additional test types and organization.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 — software testing',
    'xUnit / test patterns — automated testing',
  ],
  'Defines additional test types, naming conventions, and test-file organization.',
)
@SectionId('TESTOR')
class TestingStandardsOrganization {
  @Form([
    Field('performanceTestRequired', bool, 'Performance Test Required',
        hint: 'Performance tests required'),
    Field('testNamingConvention', String, 'Test Naming Convention',
        hint: 'How tests should be named'),
    Field('testFileOrganization', String, 'Test File Organization',
        hint: 'How test files are organized'),
    Field('testDataManagement', String, 'Test Data Management',
        hint: 'How test data is managed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Preferred testing patterns.
@StandardReferences(
  [
    'xUnit / test patterns — automated testing',
    'ISO/IEC/IEEE 29119 — software testing',
  ],
  'Defines preferred testing patterns such as Arrange-Act-Assert, Given-When-Then, and mocking strategy.',
)
@SectionId('TESTPA')
class TestingStandardsPatterns {
  @Form([
    Field('arrangActAssert', bool, 'Arrange-Act-Assert',
        hint: 'Use AAA pattern'),
    Field('givenWhenThen', bool, 'Given-When-Then',
        hint: 'Use GWT pattern for BDD'),
    Field('mockingStrategy', String, 'Mocking Strategy',
        hint: 'When and how to use mocks'),
    Field('stubStrategy', String, 'Stub Strategy',
        hint: 'When to use stubs vs mocks'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Quality requirements for tests.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 — software testing',
    'xUnit / test patterns — automated testing',
  ],
  'Defines test-quality requirements such as isolation, determinism, and flaky-test policy.',
)
@SectionId('TESTQU')
class TestingStandardsQuality {
  @Form([
    Field('testIsolation', String, 'Test Isolation',
        hint: 'Test isolation requirements'),
    Field('deterministicTests', bool, 'Deterministic Tests Required',
        hint: 'Tests must be deterministic'),
    Field('flakyTestPolicy', String, 'Flaky Test Policy',
        hint: 'How to handle flaky tests'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing tools and CI integration.
@StandardReferences(
  [
    'ISO/IEC/IEEE 29119 — software testing',
    'xUnit / test patterns — automated testing',
  ],
  'Defines the testing frameworks, coverage tools, and CI test-execution approach.',
)
@SectionId('TESTTO')
class TestingStandardsTooling {
  @Form([
    Field('testFramework', String, 'Test Framework',
        hint: 'Testing framework to use'),
    Field('mockingFramework', String, 'Mocking Framework',
        hint: 'Mocking framework to use'),
    Field('coverageTools', String, 'Coverage Tools',
        hint: 'Code coverage tools'),
    Field('ciTestExecution', String, 'CI Test Execution',
        hint: 'How tests run in CI'),
    Field('parallelExecution', String, 'Parallel Execution',
        hint: 'Test parallelization approach'),
    Field('testReporting', String, 'Test Reporting',
        hint: 'Test report format and location'),
    Field('notes', String, 'Notes', hint: 'Additional testing standards notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 8.2. Software Design Requirements.
@DetailedIn(D06ArchitectureTechnologySpecification)
@SecondLevelSectionId(D06ArchitectureTechnologySpecification, 'ATS-SOF')
@ContentHelp('''
Define software architecture, development environment, and component
reusability requirements. These decisions shape developer experience,
productivity, and code maintainability.

**Subsections**:
- **Layering and Module Structure**: Clean architecture, DDD bounded
  contexts, package organization, dependency rules
- **Development Environment**: IDEs, build tools, version control, CI/CD
  pipelines, code review process, local development setup
- **Reusable Components**: Shared libraries, UI components, business logic
  extraction, component governance and discovery

**Key Considerations**:
- Developer productivity and fast feedback loops
- Onboarding time for new team members
- Code sharing and duplication prevention
- Build and test execution performance
- Local development parity with production

**Reference**: Clean Architecture (Uncle Bob), Domain-Driven Design,
SOLID principles, Twelve-Factor App methodology.
''')
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'SOLID principles — object-oriented design',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Defines the software architecture, development environment, and component-reuse requirements.',
)
@SectionId('SDR')
class SoftwareDesignRequirements {
  @ContentHelp('''
Provide an overview of software design approach and key decisions.

**Include**:
- Software layering strategy summary
- Development environment philosophy
- Component reuse strategy and governance
- Key design principles adopted
- Developer experience priorities

**Best Practices**:
- Document dependency direction rules
- Define clear module boundaries and contracts
- Establish internal open-source practices for shared code
- Plan for refactoring and architecture evolution
- Create architecture fitness functions
''')
  @SerializationOrder(0)
  String? content;

  /// 8.2.1. Layering and Module Structure.
  @SerializationOrder(1)
  LayeringAndModuleStructure layeringAndModuleStructure =
      LayeringAndModuleStructure();

  /// 8.2.2. Development Environment.
  @SerializationOrder(2)
  DevelopmentEnvironment developmentEnvironment = DevelopmentEnvironment();

  /// 8.2.3. Reusable Components.
  @SerializationOrder(3)
  ReusableComponentsSection reusableComponents = ReusableComponentsSection();
}

// =============================================================================
// 8.2.1. Layering and Module Structure
// =============================================================================

/// 8.2.1. Layering and Module Structure.
///
/// Software layering (presentation, business logic, data access, infrastructure)
/// and module structure (bounded contexts, packages, libraries).
@ContentHelp('''
Define software layering approach, module organization, and dependency
management rules. Clear boundaries prevent spaghetti architecture and
enable independent development and testing.

**Common Layering Approaches**:
- **Clean Architecture**: Entities → Use Cases → Interface Adapters →
  Frameworks & Drivers (dependencies point inward)
- **Hexagonal (Ports & Adapters)**: Domain core with ports (interfaces)
  and adapters (implementations)
- **Onion Architecture**: Domain Model → Domain Services → Application
  Services → Infrastructure
- **Traditional N-Tier**: Presentation → Business Logic → Data Access

**Module Organization**:
- **By Feature/Domain**: Vertical slices containing all layers for a feature
- **By Layer**: Horizontal separation (all controllers, all repositories)
- **Bounded Contexts (DDD)**: Independent modules with clear context maps
- **Package-by-Component**: Self-contained components with public APIs

**Dependency Rules**:
- Define allowed and forbidden dependencies between layers/modules
- Enforce with architecture tests (ArchUnit, deptry, import linters)
- Use interfaces/abstractions for cross-cutting concerns
- Keep domain logic independent of frameworks

**Best Practices**: SOLID, DRY, KISS, YAGNI, Dependency Inversion.
''')
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the overall software layering approach and module structure of the system.',
)
@SectionId('LAMS')
class LayeringAndModuleStructure {
  @ContentHelp('''
Provide an overview of the layering and modularization strategy.

**Include**:
- Chosen layering approach with rationale
- Module organization principles
- Dependency rules and enforcement mechanism
- Cross-cutting concerns handling (logging, auth, transactions)
- Module communication patterns

**Best Practices**:
- Create layer/module diagrams with dependency arrows
- Define public API contracts for each module
- Use automated architecture tests
- Document exception cases and technical debt
- Plan for module extraction and scaling
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of the layering and modularization approach.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Software layer definitions.
  @StandardReferences(
    ['Clean Architecture — dependency rule / layering'],
    'The software layers that make up the application.',
  )
  @SectionId('SOLAEN-SOFT-LST')
  @SectionIdPattern('SOLAEN-SOFT-xxx')
  @ContentHelp('Add one entry per software layer.')
  @SerializationOrder(2)
  List<SoftwareLayerEntry> softwareLayers = [];

  /// Layer communication rules and constraints.
  @SerializationOrder(3)
  LayerCommunicationRules layerCommunicationRules = LayerCommunicationRules();

  /// Bounded contexts (DDD) definitions.
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'SOLID principles — object-oriented design',
    ],
    'The DDD bounded contexts that partition the application domain.',
  )
  @SectionId('BOCOEN-BOUN-LST')
  @SectionIdPattern('BOCOEN-BOUN-xxx')
  @ContentHelp('Add one entry per bounded context.')
  @SerializationOrder(4)
  List<BoundedContextEntry> boundedContexts = [];

  /// Package organization and structure.
  @SerializationOrder(5)
  PackageOrganization packageOrganization = PackageOrganization();

  /// Module catalog with dependency information.
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'SOLID principles — object-oriented design',
    ],
    'The modules that make up the application and their dependency information.',
  )
  @SectionId('MOEN1-MODU-LST')
  @SectionIdPattern('MOEN1-MODU-xxx')
  @ContentHelp('Add one entry per module.')
  @SerializationOrder(6)
  List<ModuleEntry> modules = [];

  /// Shared libraries and common code.
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability / modularity quality attributes',
    ],
    'The shared libraries and common code reused across the application.',
  )
  @SectionId('SHLIB-SHAR-LST')
  @SectionIdPattern('SHLIB-SHAR-xxx')
  @ContentHelp('Add one entry per shared library.')
  @SerializationOrder(7)
  List<SharedLibraryEntry> sharedLibraries = [];

  /// Dependency injection configuration.
  @SerializationOrder(8)
  DependencyInjectionStructure dependencyInjection =
      DependencyInjectionStructure();

  /// Cross-cutting concerns organization.
  @SerializationOrder(9)
  CrossCuttingConcerns crossCuttingConcerns = CrossCuttingConcerns();

  /// Feature module definitions (vertical slices).
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability / modularity quality attributes',
    ],
    'The feature modules that make up the application as vertical slices.',
  )
  @SectionId('FTRMOD-FEAT-LST')
  @SectionIdPattern('FTRMOD-FEAT-xxx')
  @ContentHelp('Add one entry per feature module.')
  @SerializationOrder(10)
  List<FeatureModuleEntry> featureModules = [];

  /// Module versioning and compatibility strategy.
  @SerializationOrder(11)
  ModuleVersioningStrategy moduleVersioningStrategy =
      ModuleVersioningStrategy();
}

/// Software layer entry — a horizontal layer in the architecture.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'C4 model — software architecture diagrams',
  ],
  'Describes a single horizontal software layer such as presentation, domain, or infrastructure.',
)
@SectionId('SLE')
class SoftwareLayerEntry {
  @Form([
    Field('layerName', String, 'Layer Name',
        required: true,
        hint:
            'E.g., Presentation, Application, Domain, Infrastructure, Data Access'),
    Field('layerLevel', String, 'Level',
        hint: 'Numeric level (0 = bottom, higher = top)'),
    Field('layerPattern', String, 'Pattern',
        hint: 'E.g., Clean Architecture, Onion, Hexagonal, N-Tier'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Responsibilities and constraints.
  @SerializationOrder(1)
  SoftwareLayerEntryResponsibilities responsibilities =
      SoftwareLayerEntryResponsibilities();

  /// Typical components and organization.
  @SerializationOrder(2)
  SoftwareLayerEntryComponents components = SoftwareLayerEntryComponents();

  /// Dependency rules.
  @SerializationOrder(3)
  SoftwareLayerEntryDependencies dependencies =
      SoftwareLayerEntryDependencies();

  /// Technology and testing notes.
  @SerializationOrder(4)
  SoftwareLayerEntryTechnology technology = SoftwareLayerEntryTechnology();
}

/// Responsibilities and constraints.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Defines the purpose, key responsibilities, and prohibitions of a software layer.',
)
@SectionId('SLER')
class SoftwareLayerEntryResponsibilities {
  @Form([
    Field('purpose', String, 'Purpose',
        required: true, hint: 'Primary responsibility of this layer'),
    Field('responsibilities', String, 'Key Responsibilities',
        hint: 'Specific functions this layer handles'),
    Field('prohibitions', String, 'Prohibitions',
        hint: 'What this layer must NOT do'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Typical components and organization.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'C4 model — software architecture diagrams',
  ],
  'Describes the typical components, naming conventions, and folder structure of a software layer.',
)
@SectionId('SLEC')
class SoftwareLayerEntryComponents {
  @Form([
    Field('typicalComponents', String, 'Typical Components',
        hint: 'Types of classes/components in this layer'),
    Field('namingConventions', String, 'Naming Conventions',
        hint: 'Naming patterns for components in this layer'),
    Field('folderStructure', String, 'Folder Structure',
        hint: 'Directory organization for this layer'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dependency rules.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'C4 model — software architecture diagrams',
  ],
  'Defines the allowed, forbidden, and external dependencies of a software layer.',
)
@SectionId('SLED')
class SoftwareLayerEntryDependencies {
  @Form([
    Field('allowedDependencies', String, 'Allowed Dependencies',
        hint: 'Layers this layer may depend on'),
    Field('forbiddenDependencies', String, 'Forbidden Dependencies',
        hint: 'Layers this layer must NOT depend on'),
    Field('externalDependencies', String, 'External Dependencies',
        hint: 'External packages allowed in this layer'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Technology and testing notes.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the frameworks, implementation notes, and testing approach for a software layer.',
)
@SectionId('SLET')
class SoftwareLayerEntryTechnology {
  @Form([
    Field('frameworksUsed', String, 'Frameworks Used',
        hint: 'Frameworks applicable to this layer'),
    Field('implementationNotes', String, 'Implementation Notes',
        hint: 'Specific implementation guidelines'),
    Field('testingApproach', String, 'Testing Approach',
        hint: 'How components in this layer are tested'),
    Field('notes', String, 'Notes', hint: 'Additional layer notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Layer communication rules and constraints.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'C4 model — software architecture diagrams',
  ],
  'Defines the direction, dependency rules, and abstraction principles that govern communication between layers.',
)
@SectionId('LACORU')
class LayerCommunicationRules {
  @Form([
    Field('communicationDirection', String, 'Communication Direction',
        hint: 'Top-down only, bottom-up callbacks, etc.'),
    Field('dependencyRule', String, 'Dependency Rule',
        hint: 'Dependencies always point inward/downward'),
    Field('abstractionPrinciple', String, 'Abstraction Principle',
        hint: 'Dependency inversion, interface segregation'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Interface requirements between layers.
  @SerializationOrder(1)
  LayerCommunicationRulesInterfaces interfaces =
    LayerCommunicationRulesInterfaces();

  /// Cross-layer event and exception flow.
  @SerializationOrder(2)
  LayerCommunicationRulesFlow flow = LayerCommunicationRulesFlow();

  /// Boundary enforcement and validation rules.
  @SerializationOrder(3)
  LayerCommunicationRulesGovernance governance =
    LayerCommunicationRulesGovernance();
}

/// Interface requirements between layers.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'SOLID principles — object-oriented design',
  ],
  'Defines the interface, DTO, and mapping requirements at boundaries between layers.',
)
@SectionId('LCRI')
class LayerCommunicationRulesInterfaces {
  @Form([
  Field('interfaceRequirements', String, 'Interface Requirements',
    hint: 'Whether interfaces required at boundaries'),
  Field('dtoUsage', String, 'DTO Usage',
    hint: 'Data Transfer Object patterns between layers'),
  Field('mappingStrategy', String, 'Mapping Strategy',
    hint: 'How data is mapped between layers'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cross-layer event and exception flow.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'C4 model — software architecture diagrams',
  ],
  'Describes how events, exceptions, and logging context propagate across layers.',
)
@SectionId('LCRF')
class LayerCommunicationRulesFlow {
  @Form([
  Field('eventPropagation', String, 'Event Propagation',
    hint: 'How events flow across layers'),
  Field('exceptionHandling', String, 'Exception Handling',
    hint: 'How exceptions propagate across layers'),
  Field('loggingPropagation', String, 'Logging Propagation',
    hint: 'How logging context flows'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Boundary enforcement and validation rules.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'C4 model — software architecture diagrams',
  ],
  'Defines how layer boundaries and validation responsibilities are enforced and violations detected.',
)
@SectionId('LCRG')
class LayerCommunicationRulesGovernance {
  @Form([
  Field('validationResponsibility', String, 'Validation Responsibility',
    hint: 'Which layer validates what'),
  Field('boundaryEnforcement', String, 'Boundary Enforcement',
    hint: 'How layer boundaries are enforced'),
  Field('violationDetection', String, 'Violation Detection',
    hint: 'How boundary violations are detected'),
  Field('notes', String, 'Notes',
    hint: 'Additional layer communication notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Bounded context entry — a DDD bounded context.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ],
  'Describes a single DDD bounded context, its domain area, and owning team.',
)
@SectionId('BCE')
class BoundedContextEntry {
  @Form([
    Field('contextName', String, 'Context Name',
        required: true, hint: 'E.g., Order, Inventory, Customer, Billing'),
    Field('domainArea', String, 'Domain Area',
        required: true, hint: 'Business domain this context covers'),
    Field('owningTeam', String, 'Owning Team',
        hint: 'Team responsible for this context'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Scope and language definitions.
  @SerializationOrder(1)
  BoundedContextEntryScope scope = BoundedContextEntryScope();

  /// Boundary relationships.
  @SerializationOrder(2)
  BoundedContextEntryBoundaries boundaries = BoundedContextEntryBoundaries();

  /// Implementation footprint.
  @SerializationOrder(3)
  BoundedContextEntryImplementation implementation =
      BoundedContextEntryImplementation();

  /// Integration and notes.
  @SerializationOrder(4)
  BoundedContextEntryIntegration integration =
      BoundedContextEntryIntegration();
}

/// Scope and language definitions.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ],
  'Defines the scope, included/excluded concepts, and ubiquitous language of a bounded context.',
)
@SectionId('BCES')
class BoundedContextEntryScope {
  @Form([
    Field('purpose', String, 'Purpose', hint: 'Why this context exists'),
    Field('includedConcepts', String, 'Included Concepts',
        hint: 'Domain concepts within this context'),
    Field('excludedConcepts', String, 'Excluded Concepts',
        hint: 'Domain concepts explicitly outside this context'),
    Field('ubiquitousLanguage', String, 'Ubiquitous Language',
        hint: 'Key terms and their definitions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Boundary relationships.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ],
  'Describes the boundary type and upstream/downstream relationships of a bounded context.',
)
@SectionId('BCEB')
class BoundedContextEntryBoundaries {
  @Form([
    Field('boundaryType', String, 'Boundary Type',
        hint: 'Conformist, Anti-corruption layer, Open-host, etc.'),
    Field('upstreamContexts', String, 'Upstream Contexts',
        hint: 'Contexts this one depends on'),
    Field('downstreamContexts', String, 'Downstream Contexts',
        hint: 'Contexts that depend on this one'),
    Field('sharedKernel', String, 'Shared Kernel',
        hint: 'Shared code with other contexts'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Implementation footprint.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ],
  'Records the code location, schema, and published/consumed events that implement a bounded context.',
)
@SectionId('BCEI')
class BoundedContextEntryImplementation {
  @Form([
    Field('repositoryNamespace', String, 'Repository/Namespace',
        hint: 'Code location for this context'),
    Field('databaseSchema', String, 'Database Schema',
        hint: 'Database schema or partition'),
    Field('publishedEvents', String, 'Published Events',
        hint: 'Domain events this context publishes'),
    Field('consumedEvents', String, 'Consumed Events',
        hint: 'Domain events this context subscribes to'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Integration and notes.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ],
  'Describes the API endpoints and integration patterns through which a bounded context connects to others.',
)
@SectionId('BOCOENIN')
class BoundedContextEntryIntegration {
  @Form([
    Field('apiEndpoints', String, 'API Endpoints',
        hint: 'Public API endpoints exposed'),
    Field('integrationPatterns', String, 'Integration Patterns',
        hint: 'How this context integrates with others'),
    Field('notes', String, 'Notes', hint: 'Additional context notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Package organization and naming structure.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Describes the overall package organization, naming, and structure conventions.',
)
@SectionId('PAOR')
class PackageOrganization {
  @Form([
    Field('namingConvention', String, 'Naming Convention',
        hint: 'Package/module naming pattern'),
    Field('prefixStrategy', String, 'Prefix Strategy',
        hint: 'Prefix for all packages (e.g., org name)'),
    Field('suffixConventions', String, 'Suffix Conventions',
        hint: 'Standard suffixes (_core, _ui, _api, etc.)'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Repository and directory structure.
  @SerializationOrder(1)
  PackageOrganizationStructure structure = PackageOrganizationStructure();

  /// Package categorization.
  @SerializationOrder(2)
  PackageOrganizationTypes types = PackageOrganizationTypes();

  /// Dependency management rules.
  @SerializationOrder(3)
  PackageOrganizationDependencies dependencies =
      PackageOrganizationDependencies();

  /// Documentation expectations.
  @SerializationOrder(4)
  PackageOrganizationDocumentation documentation =
      PackageOrganizationDocumentation();
}

/// Repository and directory structure.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Describes the repository and directory layout used to organize packages.',
)
@SectionId('PAORST')
class PackageOrganizationStructure {
  @Form([
    Field('monorepoVsPolyrepo', String, 'Monorepo vs Polyrepo',
        hint: 'Single vs multiple repositories'),
    Field('directoryLayout', String, 'Directory Layout',
        hint: 'Top-level directory organization'),
    Field('featureGrouping', String, 'Feature Grouping',
        hint: 'How features are grouped in structure'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Package categorization.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Categorizes packages into core, feature, shared, and platform types.',
)
@SectionId('PAORTY')
class PackageOrganizationTypes {
  @Form([
    Field('corePackages', String, 'Core Packages',
        hint: 'Foundation packages required by all'),
    Field('featurePackages', String, 'Feature Packages',
        hint: 'Business feature packages'),
    Field('sharedPackages', String, 'Shared Packages',
        hint: 'Shared utility packages'),
    Field('platformPackages', String, 'Platform Packages',
        hint: 'Platform-specific packages'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dependency management rules.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ],
  'Defines how internal and external package dependencies are managed and versioned.',
)
@SectionId('PAORDE')
class PackageOrganizationDependencies {
  @Form([
    Field('dependencyManagement', String, 'Dependency Management',
        hint: 'How package dependencies are managed'),
    Field('internalDependencyRules', String, 'Internal Dependency Rules',
        hint: 'Rules for internal package dependencies'),
    Field('externalDependencyPolicy', String, 'External Dependency Policy',
        hint: 'Policy for external dependencies'),
    Field('versioningStrategy', String, 'Versioning Strategy',
        hint: 'Semantic versioning or other scheme'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation expectations.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Defines the documentation and dependency-diagram expectations for each package.',
)
@SectionId('PAORDO')
class PackageOrganizationDocumentation {
  @Form([
    Field('packageDocumentation', String, 'Package Documentation',
        hint: 'Required documentation per package'),
    Field('dependencyDiagram', String, 'Dependency Diagram',
        hint: 'Package dependency visualization'),
    Field('notes', String, 'Notes', hint: 'Additional organization notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Module entry — a discrete module or component.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ],
  'Describes a single discrete module or component in the module catalog.',
)
@SectionId('MODENT')
class ModuleEntry {
  @Form([
    Field('moduleName', String, 'Module Name',
        required: true, hint: 'Unique module identifier'),
    Field('moduleType', String, 'Module Type',
        hint: 'Core, Feature, Shared, Platform, Plugin'),
    Field('version', String, 'Version', hint: 'Current module version'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Purpose and API.
  @SerializationOrder(1)
  ModuleEntryDescription description = ModuleEntryDescription();

  /// Dependency information.
  @SerializationOrder(2)
  ModuleEntryDependencies dependencies = ModuleEntryDependencies();

  /// Ownership information.
  @SerializationOrder(3)
  ModuleEntryOwnership ownership = ModuleEntryOwnership();

  /// Configuration settings.
  @SerializationOrder(4)
  ModuleEntryConfiguration configuration = ModuleEntryConfiguration();

  /// Testing and notes.
  @SerializationOrder(5)
  ModuleEntryTesting testing = ModuleEntryTesting();
}

/// Purpose and API.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ],
  'Describes the purpose, functionality, public API, and entry points of a module.',
)
@SectionId('MOENDE')
class ModuleEntryDescription {
  @Form([
    Field('purpose', String, 'Purpose',
        required: true, hint: 'What this module provides'),
    Field('functionality', String, 'Functionality',
        hint: 'Specific features/functions'),
    Field('publicApi', String, 'Public API',
        hint: 'Key public interfaces/classes'),
    Field('entryPoints', String, 'Entry Points',
        hint: 'Main entry points to the module'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dependency information.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ],
  'Records the required, optional, external, and peer dependencies of a module.',
)
@SectionId('MOEND1')
class ModuleEntryDependencies {
  @Form([
    Field('requiredModules', String, 'Required Modules',
        hint: 'Internal modules this depends on'),
    Field('optionalModules', String, 'Optional Modules',
        hint: 'Optional internal dependencies'),
    Field('externalDependencies', String, 'External Dependencies',
        hint: 'Third-party dependencies'),
    Field('peerDependencies', String, 'Peer Dependencies',
        hint: 'Required peer modules'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Ownership information.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ],
  'Records which context, team, and maintainer own a module.',
)
@SectionId('MOENOW')
class ModuleEntryOwnership {
  @Form([
    Field('owningContext', String, 'Owning Context',
        hint: 'Bounded context this belongs to'),
    Field('owningTeam', String, 'Owning Team',
        hint: 'Team responsible for this module'),
    Field('maintainer', String, 'Maintainer', hint: 'Primary maintainer'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Configuration settings.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ],
  'Describes the configuration options, feature flags, and environment variables of a module.',
)
@SectionId('MOENCO')
class ModuleEntryConfiguration {
  @Form([
    Field('configurationOptions', String, 'Configuration Options',
        hint: 'Available configuration settings'),
    Field('featureFlags', String, 'Feature Flags',
        hint: 'Feature flags controlling behavior'),
    Field('environmentVariables', String, 'Environment Variables',
        hint: 'Required environment variables'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing and notes.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ],
  'Captures the test-coverage and integration-testing expectations for a module.',
)
@SectionId('MOENTE')
class ModuleEntryTesting {
  @Form([
    Field('testCoverage', String, 'Test Coverage',
        hint: 'Required test coverage level'),
    Field('integrationTests', String, 'Integration Tests',
        hint: 'Integration test requirements'),
    Field('notes', String, 'Notes', hint: 'Additional module notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Shared library entry — a reusable library or utility.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Describes a single reusable shared library or utility available across the software.',
)
@SectionId('SHLIEN')
class SharedLibraryEntry {
  @Form([
    Field('libraryName', String, 'Library Name',
        required: true, hint: 'Library identifier'),
    Field('libraryType', String, 'Library Type',
        hint: 'Utility, Domain, Infrastructure, UI'),
    Field('version', String, 'Version', hint: 'Current version'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Description and usage.
  @SerializationOrder(1)
  SharedLibraryEntryDescription description = SharedLibraryEntryDescription();

  /// API details.
  @SerializationOrder(2)
  SharedLibraryEntryApi api = SharedLibraryEntryApi();

  /// Constraints and lifecycle.
  @SerializationOrder(3)
  SharedLibraryEntryLifecycle lifecycle = SharedLibraryEntryLifecycle();
}

/// Description and usage.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Captures the purpose, target consumers, and usage guidelines of a shared library.',
)
@SectionId('SHLIENDE')
class SharedLibraryEntryDescription {
  @Form([
  Field('purpose', String, 'Purpose',
    required: true, hint: 'What the library provides'),
  Field('targetConsumers', String, 'Target Consumers',
    hint: 'Modules/contexts that should use this'),
  Field('usageGuidelines', String, 'Usage Guidelines',
    hint: 'How to properly use this library'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// API details.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Describes the public classes, functions, and extension points exposed by a shared library.',
)
@SectionId('SLEA')
class SharedLibraryEntryApi {
  @Form([
  Field('publicClasses', String, 'Public Classes',
    hint: 'Key public classes/interfaces'),
  Field('publicFunctions', String, 'Public Functions',
    hint: 'Key public functions'),
  Field('extensionPoints', String, 'Extension Points',
    hint: 'How consumers can extend'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Constraints and lifecycle.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Captures the compatibility, performance, thread-safety, and deprecation lifecycle of a shared library.',
)
@SectionId('SLEL')
class SharedLibraryEntryLifecycle {
  @Form([
  Field('compatibilityRequirements', String, 'Compatibility Requirements',
    hint: 'Platform/version requirements'),
  Field('performanceCharacteristics', String, 'Performance Characteristics',
    hint: 'Expected performance profile'),
  Field('threadSafety', String, 'Thread Safety',
    hint: 'Thread safety guarantees'),
  Field('deprecationPolicy', String, 'Deprecation Policy',
    hint: 'How APIs are deprecated'),
  Field('changelogLocation', String, 'Changelog Location',
    hint: 'Where changes are documented'),
  Field('notes', String, 'Notes', hint: 'Additional library notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dependency injection structure and configuration.
@StandardReferences(
  [
    'SOLID principles — object-oriented design',
    'Clean Architecture — dependency rule / layering',
  ],
  'Describes the overall dependency-injection approach, framework, and scope management for the software.',
)
@SectionId('DEINST')
class DependencyInjectionStructure {
  @Form([
    Field('diFramework', String, 'DI Framework',
        hint: 'GetIt, Riverpod, Provider, Injectable, etc.'),
    Field('registrationPattern', String, 'Registration Pattern',
        hint: 'How dependencies are registered'),
    Field('scopeManagement', String, 'Scope Management',
        hint: 'Singleton, factory, scoped, lazy'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Registration organization.
  @SerializationOrder(1)
  DependencyInjectionStructureRegistration registration =
      DependencyInjectionStructureRegistration();

  /// Interface binding rules.
  @SerializationOrder(2)
  DependencyInjectionStructureBinding binding =
      DependencyInjectionStructureBinding();

  /// Environment-specific configuration.
  @SerializationOrder(3)
  DependencyInjectionStructureConfiguration configuration =
      DependencyInjectionStructureConfiguration();

  /// Troubleshooting support.
  @SerializationOrder(4)
  DependencyInjectionStructureTroubleshooting troubleshooting =
      DependencyInjectionStructureTroubleshooting();
}

/// Registration organization.
@StandardReferences(
  [
    'SOLID principles — object-oriented design',
    'Clean Architecture — dependency rule / layering',
  ],
  'Describes how modules register their dependencies, in what order, and which are lazily initialized.',
)
@SectionId('DISR')
class DependencyInjectionStructureRegistration {
  @Form([
    Field('moduleRegistration', String, 'Module Registration',
        hint: 'How modules register their dependencies'),
    Field('registrationOrder', String, 'Registration Order',
        hint: 'Order of dependency registration'),
    Field('lazyInitialization', String, 'Lazy Initialization',
        hint: 'Which dependencies are lazy'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Interface binding rules.
@StandardReferences(
  [
    'SOLID principles — object-oriented design',
    'Clean Architecture — dependency rule / layering',
  ],
  'Defines when interfaces are bound to implementations and how they are swapped for testing.',
)
@SectionId('DISB')
class DependencyInjectionStructureBinding {
  @Form([
    Field('interfaceBindingRule', String, 'Interface Binding Rule',
        hint: 'When to use interface bindings'),
    Field('mockingStrategy', String, 'Mocking Strategy',
        hint: 'How to swap implementations for testing'),
    Field('overrideCapability', String, 'Override Capability',
        hint: 'How to override registrations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Environment-specific configuration.
@StandardReferences(
  [
    'SOLID principles — object-oriented design',
    'Clean Architecture — dependency rule / layering',
  ],
  'Describes how dependency-injection registrations vary by environment, feature flag, and platform.',
)
@SectionId('DISC')
class DependencyInjectionStructureConfiguration {
  @Form([
    Field('environmentConfiguration', String, 'Environment Configuration',
        hint: 'Different configs per environment'),
    Field('featureFlagIntegration', String, 'Feature Flag Integration',
        hint: 'How feature flags affect DI'),
    Field('conditionalRegistration', String, 'Conditional Registration',
        hint: 'Platform/config conditional registration'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Troubleshooting support.
@StandardReferences(
  [
    'SOLID principles — object-oriented design',
    'Clean Architecture — dependency rule / layering',
  ],
  'Describes how dependency-injection problems such as circular dependencies are debugged and prevented.',
)
@SectionId('DIST')
class DependencyInjectionStructureTroubleshooting {
  @Form([
    Field('debugSupport', String, 'Debug Support',
        hint: 'Debugging DI issues'),
    Field('circularDependencyHandling', String, 'Circular Dependency Handling',
        hint: 'How circular deps are prevented/detected'),
    Field('notes', String, 'Notes', hint: 'Additional DI notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cross-cutting concerns organization.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'SOLID principles — object-oriented design',
  ],
  'Organizes the cross-cutting concerns such as logging that span all layers of the software.',
)
@SectionId('CRCUCO')
class CrossCuttingConcerns {
  @Form([
    Field('loggingStrategy', String, 'Logging Strategy',
        hint: 'Centralized logging approach'),
    Field('logLevels', String, 'Log Levels',
        hint: 'Available log levels and usage'),
    Field('logFormat', String, 'Log Format', hint: 'Log message format'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Error handling concerns.
  @SerializationOrder(1)
  CrossCuttingConcernsErrors errors = CrossCuttingConcernsErrors();

  /// Security concerns.
  @SerializationOrder(2)
  CrossCuttingConcernsSecurity security = CrossCuttingConcernsSecurity();

  /// Caching approach.
  @SerializationOrder(3)
  CrossCuttingConcernsCaching caching = CrossCuttingConcernsCaching();

  /// Observability capabilities.
  @SerializationOrder(4)
  CrossCuttingConcernsObservability observability =
      CrossCuttingConcernsObservability();

  /// Other shared capabilities.
  @SerializationOrder(5)
  CrossCuttingConcernsShared shared = CrossCuttingConcernsShared();
}

/// Error handling concerns.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'SOLID principles — object-oriented design',
  ],
  'Describes the centralized error-handling, reporting, and user-notification cross-cutting concern.',
)
@SectionId('CCCE')
class CrossCuttingConcernsErrors {
  @Form([
    Field('errorHandlingStrategy', String, 'Error Handling Strategy',
        hint: 'Centralized error handling'),
    Field('errorReporting', String, 'Error Reporting',
        hint: 'How errors are reported/collected'),
    Field('userNotification', String, 'User Notification',
        hint: 'How users are notified of errors'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security concerns.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'SOLID principles — object-oriented design',
  ],
  'Describes how authentication and authorization flow across layers as a cross-cutting concern.',
)
@SectionId('CCCS')
class CrossCuttingConcernsSecurity {
  @Form([
    Field('securityConcerns', String, 'Security Concerns',
        hint: 'Cross-cutting security aspects'),
    Field('authenticationIntegration', String, 'Authentication Integration',
        hint: 'How auth flows through layers'),
    Field('authorizationIntegration', String, 'Authorization Integration',
        hint: 'How authz is checked across layers'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Caching approach.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'SOLID principles — object-oriented design',
  ],
  'Describes the caching strategy and invalidation applied across layers as a cross-cutting concern.',
)
@SectionId('CCCC')
class CrossCuttingConcernsCaching {
  @Form([
    Field('cachingStrategy', String, 'Caching Strategy',
        hint: 'Cross-cutting caching approach'),
    Field('cacheInvalidation', String, 'Cache Invalidation',
        hint: 'How cache is invalidated'),
    Field('cacheLayers', String, 'Cache Layers',
        hint: 'Where caching is applied'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Observability capabilities.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'SOLID principles — object-oriented design',
  ],
  'Describes the metrics, tracing, and health-check capabilities applied as a cross-cutting concern.',
)
@SectionId('CCCO')
class CrossCuttingConcernsObservability {
  @Form([
    Field('metricsCollection', String, 'Metrics Collection',
        hint: 'Performance and business metrics'),
    Field('tracing', String, 'Tracing', hint: 'Distributed tracing approach'),
    Field('healthChecks', String, 'Health Checks',
        hint: 'Health check implementation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Other shared capabilities.
@StandardReferences(
  [
    'Clean Architecture — dependency rule / layering',
    'SOLID principles — object-oriented design',
  ],
  'Captures additional shared cross-cutting capabilities such as localization and validation.',
)
@SectionId('CRCUCOSH')
class CrossCuttingConcernsShared {
  @Form([
    Field('localization', String, 'Localization',
        hint: 'i18n/l10n implementation'),
    Field('validation', String, 'Validation',
        hint: 'Cross-cutting validation'),
    Field('notes', String, 'Notes', hint: 'Additional cross-cutting notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Feature module entry — a vertical slice feature.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Describes a single feature module as a self-contained vertical slice of the application.',
)
@SectionId('FTRMOD')
class FeatureModuleEntry {
  @Form([
    Field('featureName', String, 'Feature Name',
        required: true, hint: 'Feature identifier'),
    Field('featureArea', String, 'Feature Area',
        hint: 'Business area this feature belongs to'),
    Field('boundedContext', String, 'Bounded Context',
        hint: 'Owning bounded context'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Purpose and value.
  @SerializationOrder(1)
  FeatureModuleEntryDescription description = FeatureModuleEntryDescription();

  /// Structural scope.
  @SerializationOrder(2)
  FeatureModuleEntryStructure structure = FeatureModuleEntryStructure();

  /// Dependencies.
  @SerializationOrder(3)
  FeatureModuleEntryDependencies dependencies =
      FeatureModuleEntryDependencies();

  /// Feature configuration.
  @SerializationOrder(4)
  FeatureModuleEntryConfiguration configuration =
      FeatureModuleEntryConfiguration();

  /// Navigation and notes.
  @SerializationOrder(5)
  FeatureModuleEntryNavigation navigation = FeatureModuleEntryNavigation();
}

/// Purpose and value.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Captures the purpose, user stories, and business value delivered by a feature module.',
)
@SectionId('FMED')
class FeatureModuleEntryDescription {
  @Form([
    Field('purpose', String, 'Purpose', hint: 'What the feature provides'),
    Field('userStories', String, 'User Stories',
        hint: 'Supported user stories/use cases'),
    Field('businessValue', String, 'Business Value',
        hint: 'Business value delivered'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Structural scope.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'Clean Architecture — dependency rule / layering',
  ],
  'Describes the UI, domain, data, and API components that make up a feature module vertical slice.',
)
@SectionId('FMES')
class FeatureModuleEntryStructure {
  @Form([
    Field('uiComponents', String, 'UI Components',
        hint: 'Screens, widgets, views in this feature'),
    Field('domainLogic', String, 'Domain Logic',
        hint: 'Business logic in this feature'),
    Field('dataAccess', String, 'Data Access',
        hint: 'Data access components'),
    Field('apiEndpoints', String, 'API Endpoints',
        hint: 'API endpoints related to this feature'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dependencies.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ],
  'Records the shared, feature, and external dependencies a feature module relies on.',
)
@SectionId('FEMOENDE')
class FeatureModuleEntryDependencies {
  @Form([
    Field('sharedDependencies', String, 'Shared Dependencies',
        hint: 'Shared modules this feature uses'),
    Field('featureDependencies', String, 'Feature Dependencies',
        hint: 'Other features this depends on'),
    Field('externalIntegrations', String, 'External Integrations',
        hint: 'External systems integrated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Feature configuration.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Defines the flags, options, and enablement criteria that configure a feature module.',
)
@SectionId('FMEC')
class FeatureModuleEntryConfiguration {
  @Form([
    Field('featureFlags', String, 'Feature Flags',
        hint: 'Flags controlling this feature'),
    Field('configurationOptions', String, 'Configuration Options',
        hint: 'Feature-specific configuration'),
    Field('enablementCriteria', String, 'Enablement Criteria',
        hint: 'When this feature is available'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Navigation and notes.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Captures the navigation routes and deep-linking behaviour exposed by a feature module.',
)
@SectionId('FMEN')
class FeatureModuleEntryNavigation {
  @Form([
    Field('routeDefinitions', String, 'Route Definitions',
        hint: 'Navigation routes for this feature'),
    Field('deepLinkSupport', String, 'Deep Link Support',
        hint: 'Deep linking patterns'),
    Field('notes', String, 'Notes', hint: 'Additional feature notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Module versioning and compatibility strategy.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Describes the overall strategy for versioning modules and keeping them compatible.',
)
@SectionId('MOVEST')
class ModuleVersioningStrategy {
  @Form([
    Field('versioningScheme', String, 'Versioning Scheme',
        hint: 'SemVer, CalVer, custom'),
    Field('majorVersionPolicy', String, 'Major Version Policy',
        hint: 'When to bump major version'),
    Field('minorVersionPolicy', String, 'Minor Version Policy',
        hint: 'When to bump minor version'),
    Field('patchVersionPolicy', String, 'Patch Version Policy',
        hint: 'When to bump patch version'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Compatibility policy.
  @SerializationOrder(1)
  ModuleVersioningStrategyCompatibility compatibility =
      ModuleVersioningStrategyCompatibility();

  /// Release management process.
  @SerializationOrder(2)
  ModuleVersioningStrategyReleaseManagement releaseManagement =
      ModuleVersioningStrategyReleaseManagement();

  /// Dependency versioning rules.
  @SerializationOrder(3)
  ModuleVersioningStrategyDependencies dependencies =
      ModuleVersioningStrategyDependencies();

  /// Cross-module coordination.
  @SerializationOrder(4)
  ModuleVersioningStrategyCoordination coordination =
      ModuleVersioningStrategyCoordination();
}

/// Compatibility policy.
@StandardReferences(
  [
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
    'Domain-Driven Design — bounded contexts / modules',
  ],
  'Defines the backwards-compatibility guarantees and breaking-change handling for modules.',
)
@SectionId('MVSC')
class ModuleVersioningStrategyCompatibility {
  @Form([
    Field('backwardsCompatibility', String, 'Backwards Compatibility',
        hint: 'Compatibility guarantees'),
    Field('breakingChangePolicy', String, 'Breaking Change Policy',
        hint: 'How breaking changes are handled'),
    Field('deprecationTimeline', String, 'Deprecation Timeline',
        hint: 'Timeline for deprecated APIs'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Release management process.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Domain-Driven Design — bounded contexts / modules',
  ],
  'Describes how module versions are released, labelled, and documented.',
)
@SectionId('MVSRM')
class ModuleVersioningStrategyReleaseManagement {
  @Form([
    Field('releaseProcess', String, 'Release Process',
        hint: 'How versions are released'),
    Field('preReleaseLabels', String, 'Pre-Release Labels',
        hint: 'alpha, beta, rc conventions'),
    Field('releaseNotes', String, 'Release Notes',
        hint: 'Release notes requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dependency versioning rules.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Defines how module dependency versions are specified, locked, and updated.',
)
@SectionId('MVSD')
class ModuleVersioningStrategyDependencies {
  @Form([
    Field('dependencyVersioning', String, 'Dependency Versioning',
        hint: 'How dependency versions are specified'),
    Field('lockfilePolicy', String, 'Lockfile Policy',
        hint: 'Lockfile usage and update policy'),
    Field('updateStrategy', String, 'Update Strategy',
        hint: 'How dependencies are updated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cross-module coordination.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ],
  'Captures how module versions are coordinated and constrained across the module set.',
)
@SectionId('MOVESTCO')
class ModuleVersioningStrategyCoordination {
  @Form([
    Field('crossModuleCoordination', String, 'Cross-Module Coordination',
        hint: 'Coordinating versions across modules'),
    Field('versionConstraints', String, 'Version Constraints',
        hint: 'Constraints between module versions'),
    Field('notes', String, 'Notes', hint: 'Additional versioning notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// =============================================================================
// 8.2.2. Development Environment
// =============================================================================

/// 8.2.2. Development Environment.
///
/// Required IDEs, build tools, version control, CI/CD pipeline, code review
/// process, and development workflow.
@ContentHelp('''
Specify development tools, workflows, and environment requirements.
A well-defined development environment accelerates onboarding and
ensures consistent quality across the team.

**IDE and Editor Requirements**:
- Recommended/required IDEs (VS Code, IntelliJ, Android Studio)
- Required extensions and plugins
- Code formatting and linting configuration
- Shared editor settings and configuration files

**Build Tools and Automation**:
- Build systems (Gradle, Maven, Make, Bazel, Melos)
- Code generation and preprocessing
- Dependency management and lockfiles
- Build profiles (debug, release, profile)

**Version Control**:
- Git workflow (trunk-based, Gitflow, GitHub Flow)
- Branch naming and commit message conventions
- Pull request / merge request requirements
- Code ownership and CODEOWNERS

**CI/CD Pipeline**:
- Pipeline stages and gates
- Automated testing requirements
- Quality gates and metrics thresholds
- Deployment automation and approvals

**Local Development**:
- Docker Compose / local Kubernetes setup
- Database seeding and test data
- Service stubbing and mocking
- Hot reload and fast feedback loops
''')
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Describes the development environment including required IDEs, build tools, version control, CI/CD, and workflow.',
)
@SectionId('DEEN')
class DevelopmentEnvironment {
  @ContentHelp('''
Provide an overview of the development environment philosophy.

**Include**:
- Tooling philosophy and selection criteria
- Developer onboarding target time
- "Works on my machine" prevention strategy
- Environment parity across dev/staging/production
- Development metrics and productivity tracking

**Best Practices**:
- Use devcontainers or Nix for reproducible environments
- Document "getting started" in under 30 minutes
- Automate environment setup scripts
- Establish development environment SLAs
- Regular tooling retrospectives and updates
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of development environment requirements.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// IDE and editor requirements.
  @StandardReferences(
    ['Twelve-Factor App — cloud-native methodology'],
    'The IDEs and editors required for the development environment.',
  )
  @SectionId('IDREEN-IDER-LST')
  @SectionIdPattern('IDREEN-IDER-xxx')
  @ContentHelp('Add one entry per IDE or editor.')
  @SerializationOrder(2)
  List<IdeRequirementEntry> ideRequirements = [];

  /// Build tools and automation.
  @SerializationOrder(3)
  BuildToolsConfiguration buildTools = BuildToolsConfiguration();

  /// Version control configuration.
  @SerializationOrder(4)
  VersionControlConfiguration versionControl = VersionControlConfiguration();

  /// CI/CD pipeline requirements.
  @SerializationOrder(5)
  CiCdPipelineConfiguration cicdPipeline = CiCdPipelineConfiguration();

  /// Code review process requirements.
  @SerializationOrder(6)
  CodeReviewProcess codeReviewProcess = CodeReviewProcess();

  /// Local development setup.
  @SerializationOrder(7)
  LocalDevelopmentSetup localDevelopmentSetup = LocalDevelopmentSetup();

  /// Debugging configuration.
  @SerializationOrder(8)
  DebuggingConfiguration debugging = DebuggingConfiguration();

  /// Environment management.
  @SerializationOrder(9)
  EnvironmentManagement environmentManagement = EnvironmentManagement();

  /// Developer onboarding requirements.
  @SerializationOrder(10)
  DeveloperOnboarding developerOnboarding = DeveloperOnboarding();

  /// Development metrics and quality gates.
  @SerializationOrder(11)
  DevelopmentQualityGates qualityGates = DevelopmentQualityGates();
}

/// IDE requirement entry — a required IDE or editor.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Describes a single required IDE or editor including its name, version requirements, and platform.',
)
@SectionId('IRE')
class IdeRequirementEntry {
  @Form([
    // Identity
    Field('ideName', String, 'IDE/Editor Name',
        required: true, hint: 'E.g., VS Code, IntelliJ IDEA, Android Studio'),
    Field('version', String, 'Version Requirements',
        hint: 'Minimum version or version range'),
    Field('platform', String, 'Platform',
        hint: 'Windows, macOS, Linux, Web'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Extension and workspace configuration.
  @SerializationOrder(1)
  IdeRequirementEntryConfiguration configuration =
    IdeRequirementEntryConfiguration();

  /// Debugger, linting, and formatting integration.
  @SerializationOrder(2)
  IdeRequirementEntryIntegration integration =
    IdeRequirementEntryIntegration();

  /// Shared team standardization settings.
  @SerializationOrder(3)
  IdeRequirementEntryStandardization standardization =
    IdeRequirementEntryStandardization();
}

/// Extension and workspace configuration.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures IDE extension and workspace configuration including required extensions and settings templates.',
)
@SectionId('IREC')
class IdeRequirementEntryConfiguration {
  @Form([
  Field('requiredExtensions', String, 'Required Extensions',
    hint: 'Extensions/plugins that must be installed'),
  Field('recommendedExtensions', String, 'Recommended Extensions',
    hint: 'Optional but helpful extensions'),
  Field('settingsTemplate', String, 'Settings Template',
    hint: 'Reference to shared settings file'),
  Field('workspaceConfiguration', String, 'Workspace Configuration',
    hint: 'Required workspace setup'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Debugger, linting, and formatting integration.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures IDE integration for debuggers, linters, format-on-save, and Git tooling.',
)
@SectionId('IREI')
class IdeRequirementEntryIntegration {
  @Form([
  Field('debuggerSupport', String, 'Debugger Support',
    hint: 'Required debugger integration'),
  Field('linterIntegration', String, 'Linter Integration',
    hint: 'How linter integrates with IDE'),
  Field('formatOnSave', bool, 'Format on Save',
    hint: 'Require format on save'),
  Field('gitIntegration', String, 'Git Integration',
    hint: 'Required Git tooling'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Shared team standardization settings.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures shared team IDE standardization settings including config location and sync mechanism.',
)
@SectionId('IRES')
class IdeRequirementEntryStandardization {
  @Form([
  Field('sharedConfigLocation', String, 'Shared Config Location',
    hint: 'Where team configs are stored'),
  Field('syncMechanism', String, 'Sync Mechanism',
    hint: 'How settings are synced across team'),
  Field('notes', String, 'Notes', hint: 'Additional IDE notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Build tools configuration.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Describes build tools configuration including package manager, versions, and lockfile management.',
)
@SectionId('BUTOCO')
class BuildToolsConfiguration {
  @Form([
    Field('packageManager', String, 'Package Manager',
        hint: 'Pub, npm, yarn, pnpm, Gradle'),
    Field('packageManagerVersion', String, 'Package Manager Version',
        hint: 'Required version'),
    Field('lockfileManagement', String, 'Lockfile Management',
        hint: 'Lockfile policies'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Build system settings.
  @SerializationOrder(1)
  BuildToolsConfigurationBuildSystem buildSystemSettings =
      BuildToolsConfigurationBuildSystem();

  /// Compilation settings.
  @SerializationOrder(2)
  BuildToolsConfigurationCompilation compilation =
      BuildToolsConfigurationCompilation();

  /// Script integration.
  @SerializationOrder(3)
  BuildToolsConfigurationScripts scripts = BuildToolsConfigurationScripts();

  /// Artifact management.
  @SerializationOrder(4)
  BuildToolsConfigurationArtifacts artifacts =
      BuildToolsConfigurationArtifacts();
}

/// Build system settings.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures build system settings including the build system, version, and build configuration files.',
)
@SectionId('BTCBS')
class BuildToolsConfigurationBuildSystem {
  @Form([
    Field('buildSystem', String, 'Build System',
        hint: 'Flutter build, Gradle, Make, Melos'),
    Field('buildSystemVersion', String, 'Build System Version',
        hint: 'Required version'),
    Field('buildConfiguration', String, 'Build Configuration',
        hint: 'Build configuration files'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compilation settings.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures compilation settings including compiler/SDK version, compilation mode, and optimization level.',
)
@SectionId('BTCC')
class BuildToolsConfigurationCompilation {
  @Form([
    Field('compilerVersion', String, 'Compiler/SDK Version',
        hint: 'Dart SDK, JDK version'),
    Field('compilationMode', String, 'Compilation Mode',
        hint: 'JIT, AOT, mixed'),
    Field('optimizationLevel', String, 'Optimization Level',
        hint: 'Debug, profile, release settings'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Script integration.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures build script integration including build scripts, pre-commit hooks, and post-build actions.',
)
@SectionId('BTCS')
class BuildToolsConfigurationScripts {
  @Form([
    Field('buildScripts', String, 'Build Scripts',
        hint: 'Custom build scripts location'),
    Field('preCommitHooks', String, 'Pre-Commit Hooks',
        hint: 'Pre-commit hook configuration'),
    Field('postBuildActions', String, 'Post-Build Actions',
        hint: 'Actions after successful build'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Artifact management.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Semantic Versioning (SemVer) — build / release versioning',
  ],
  'Captures build artifact management including artifact location, naming, and cache policies.',
)
@SectionId('BTCA')
class BuildToolsConfigurationArtifacts {
  @Form([
    Field('artifactLocation', String, 'Artifact Location',
        hint: 'Where build artifacts are stored'),
    Field('artifactNaming', String, 'Artifact Naming',
        hint: 'Artifact naming convention'),
    Field('cacheManagement', String, 'Cache Management',
        hint: 'Build cache policies'),
    Field('notes', String, 'Notes', hint: 'Additional build tool notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Version control configuration.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Describes version control configuration including the VCS system, version, and hosting platform.',
)
@SectionId('VECOCO')
class VersionControlConfiguration {
  @Form([
    Field('vcsSystem', String, 'VCS System', hint: 'Git, Mercurial, SVN'),
    Field('vcsVersion', String, 'VCS Version', hint: 'Minimum version required'),
    Field('hostingPlatform', String, 'Hosting Platform',
        hint: 'GitHub, GitLab, Bitbucket, Azure DevOps'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Repository structure settings.
  @SerializationOrder(1)
  VersionControlConfigurationRepository repository =
      VersionControlConfigurationRepository();

  /// Branching policy.
  @SerializationOrder(2)
  VersionControlConfigurationBranching branching =
      VersionControlConfigurationBranching();

  /// Commit and merge policy.
  @SerializationOrder(3)
  VersionControlConfigurationCommits commits =
      VersionControlConfigurationCommits();

  /// Tagging and file attribute settings.
  @SerializationOrder(4)
  VersionControlConfigurationMetadata metadata =
      VersionControlConfigurationMetadata();
}

/// Repository structure settings.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures repository structure settings such as monorepo/polyrepo layout, submodule policy, and LFS usage.',
)
@SectionId('VCCR')
class VersionControlConfigurationRepository {
  @Form([
    Field('repositoryStructure', String, 'Repository Structure',
        hint: 'Monorepo, polyrepo, hybrid'),
    Field('submodulePolicy', String, 'Submodule Policy',
        hint: 'Use of Git submodules'),
    Field('lfsUsage', String, 'LFS Usage',
        hint: 'Git LFS for large files'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Branching policy.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Semantic Versioning (SemVer) — build / release versioning',
  ],
  'Captures branching policy including branching strategy, branch naming, and hotfix workflow.',
)
@SectionId('VCCB')
class VersionControlConfigurationBranching {
  @Form([
    Field('branchingStrategy', String, 'Branching Strategy',
        hint: 'GitFlow, trunk-based, GitHub Flow'),
    Field('mainBranchName', String, 'Main Branch Name',
        hint: 'main, master, develop'),
    Field('featureBranchNaming', String, 'Feature Branch Naming',
        hint: 'feature/TICKET-description'),
    Field('releaseBranchNaming', String, 'Release Branch Naming',
        hint: 'release/v1.2.3'),
    Field('hotfixPolicy', String, 'Hotfix Policy',
        hint: 'Hotfix branch workflow'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Commit and merge policy.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Semantic Versioning (SemVer) — build / release versioning',
  ],
  'Captures commit and merge policy including message format, commit signing, and squash/merge rules.',
)
@SectionId('VCCC')
class VersionControlConfigurationCommits {
  @Form([
    Field('commitMessageFormat', String, 'Commit Message Format',
        hint: 'Conventional Commits, custom format'),
    Field('commitSigningRequired', bool, 'Commit Signing Required',
        hint: 'GPG signing requirement'),
    Field('squashMergePolicy', String, 'Squash/Merge Policy',
        hint: 'When to squash vs merge'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Tagging and file attribute settings.
@StandardReferences(
  [
    'Semantic Versioning (SemVer) — build / release versioning',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures tagging conventions, tag signing, and file attribute settings for the repository.',
)
@SectionId('VCCM')
class VersionControlConfigurationMetadata {
  @Form([
    Field('tagNamingConvention', String, 'Tag Naming Convention',
        hint: 'v1.2.3, yyyy-MM-dd, custom'),
    Field('tagSigningRequired', bool, 'Tag Signing Required',
        hint: 'GPG signing for tags'),
    Field('gitignoreTemplate', String, 'Gitignore Template',
        hint: 'Standard gitignore file'),
    Field('gitattributes', String, 'Git Attributes',
        hint: 'Line endings, merge drivers'),
    Field('notes', String, 'Notes', hint: 'Additional VCS notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// CI/CD pipeline configuration.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Describes the CI/CD pipeline configuration including platform, config location, and secrets management.',
)
@SectionId('CCPC')
class CiCdPipelineConfiguration {
  @Form([
    // Platform
    Field('cicdPlatform', String, 'CI/CD Platform',
        hint: 'GitHub Actions, GitLab CI, Jenkins, CircleCI'),
    Field('configurationLocation', String, 'Configuration Location',
        hint: 'Where pipeline configs live'),
    Field('secretsManagement', String, 'Secrets Management',
        hint: 'How secrets are stored and accessed'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Pipeline stages.
  @StandardReferences(
    ['CI/CD — continuous integration / delivery pipelines'],
    'The stages that make up the delivery pipeline.',
  )
  @SectionId('PISTEN-STAG-LST')
  @SectionIdPattern('PISTEN-STAG-xxx')
  @ContentHelp('Add one entry per pipeline stage.')
  @SerializationOrder(1)
  List<PipelineStageEntry> stages = [];

  /// Build jobs.
  @StandardReferences(
    ['CI/CD — continuous integration / delivery pipelines'],
    'The build jobs that run within the delivery pipeline.',
  )
  @SectionId('PIJOEN-JOBS-LST')
  @SectionIdPattern('PIJOEN-JOBS-xxx')
  @ContentHelp('Add one entry per pipeline job.')
  @SerializationOrder(2)
  List<PipelineJobEntry> jobs = [];

  /// Deployment environments.
  @StandardReferences(
    ['CI/CD — continuous integration / delivery pipelines'],
    'The deployment environments targeted by the pipeline.',
  )
  @SectionId('DEENEN-ENVI-LST')
  @SectionIdPattern('DEENEN-ENVI-xxx')
  @ContentHelp('Add one entry per deployment environment.')
  @SerializationOrder(3)
  List<DeploymentEnvironmentEntry> environments = [];
}

/// Pipeline stage entry.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Describes a single pipeline stage including its name, order, and purpose.',
)
@SectionId('PSE')
class PipelineStageEntry {
  @Form([
    // Identity
    Field('stageName', String, 'Stage Name',
        required: true, hint: 'E.g., Build, Test, Deploy, Release'),
    Field('stageOrder', String, 'Order', hint: 'Execution order'),
    Field('description', String, 'Description', hint: 'What this stage does'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Triggering conditions and approval gates.
  @SerializationOrder(1)
  PipelineStageEntryTrigger trigger = PipelineStageEntryTrigger();

  /// Execution environment and job strategy.
  @SerializationOrder(2)
  PipelineStageEntryExecution execution = PipelineStageEntryExecution();

  /// Artifact flow between stages.
  @SerializationOrder(3)
  PipelineStageEntryArtifacts artifacts = PipelineStageEntryArtifacts();

  /// Failure handling and retry behavior.
  @SerializationOrder(4)
  PipelineStageEntryFailure failure = PipelineStageEntryFailure();
}

/// Triggering conditions and approval gates.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures pipeline stage triggering conditions and manual approval gates.',
)
@SectionId('PSET')
class PipelineStageEntryTrigger {
  @Form([
    Field('triggers', String, 'Triggers',
        hint: 'What triggers this stage (push, PR, schedule)'),
    Field('conditions', String, 'Conditions',
        hint: 'Conditions for stage to run'),
    Field('manualApproval', bool, 'Manual Approval',
        hint: 'Requires human approval'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Execution environment and job strategy.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures pipeline stage execution including runner requirements, timeouts, and parallel job strategy.',
)
@SectionId('PSEE')
class PipelineStageEntryExecution {
  @Form([
    Field('runnerRequirements', String, 'Runner Requirements',
        hint: 'Required runner type/labels'),
    Field('timeoutMinutes', String, 'Timeout',
        hint: 'Stage timeout in minutes'),
    Field('parallelJobs', bool, 'Parallel Jobs',
        hint: 'Jobs in stage run in parallel'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Artifact flow between stages.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures artifact flow between pipeline stages including input and output artifacts.',
)
@SectionId('PSEA')
class PipelineStageEntryArtifacts {
  @Form([
    Field('inputArtifacts', String, 'Input Artifacts',
        hint: 'Required artifacts from previous stages'),
    Field('outputArtifacts', String, 'Output Artifacts',
        hint: 'Artifacts produced by this stage'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Failure handling and retry behavior.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures pipeline stage failure behavior and retry policy.',
)
@SectionId('PSEF')
class PipelineStageEntryFailure {
  @Form([
    Field('failureBehavior', String, 'Failure Behavior',
        hint: 'Continue, stop, retry'),
    Field('retryPolicy', String, 'Retry Policy',
        hint: 'Automatic retry configuration'),
    Field('notes', String, 'Notes', hint: 'Additional stage notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Pipeline job entry.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Describes a single pipeline job including its name, parent stage, and purpose.',
)
@SectionId('PJE')
class PipelineJobEntry {
  @Form([
    Field('jobName', String, 'Job Name', required: true, hint: 'Job identifier'),
    Field('parentStage', String, 'Parent Stage', hint: 'Stage this job belongs to'),
    Field('description', String, 'Description', hint: 'What this job does'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Execution environment.
    @SerializationOrder(1)
    PipelineJobEntryEnvironment environment = PipelineJobEntryEnvironment();

    /// Job steps.
    @SerializationOrder(2)
    PipelineJobEntrySteps steps = PipelineJobEntrySteps();

    /// Job dependencies.
    @SerializationOrder(3)
    PipelineJobEntryDependencies dependencies = PipelineJobEntryDependencies();

    /// Outputs and notes.
    @SerializationOrder(4)
    PipelineJobEntryOutputs outputs = PipelineJobEntryOutputs();
}

/// Execution environment.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures the pipeline job execution environment including runner type, container image, and environment variables.',
)
@SectionId('PJEE')
class PipelineJobEntryEnvironment {
    @Form([
        Field('runnerType', String, 'Runner Type',
                hint: 'Self-hosted, cloud, container'),
        Field('containerImage', String, 'Container Image',
                hint: 'Docker image if containerized'),
        Field('environmentVariables', String, 'Environment Variables',
                hint: 'Required environment variables'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Job steps.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures pipeline job steps including setup, main, and cleanup steps.',
)
@SectionId('PJES')
class PipelineJobEntrySteps {
    @Form([
        Field('setupSteps', String, 'Setup Steps',
                hint: 'Checkout, install dependencies'),
        Field('mainSteps', String, 'Main Steps', hint: 'Main job steps'),
        Field('cleanupSteps', String, 'Cleanup Steps', hint: 'Cleanup after job'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Job dependencies.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures pipeline job dependencies including upstream jobs, backing services, and caching.',
)
@SectionId('PJED')
class PipelineJobEntryDependencies {
    @Form([
        Field('dependsOn', String, 'Depends On', hint: 'Other jobs this depends on'),
        Field('services', String, 'Services', hint: 'Required services (DB, cache)'),
        Field('caching', String, 'Caching', hint: 'Cache configuration'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Outputs and notes.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures pipeline job outputs such as test reports, coverage reports, and artifacts.',
)
@SectionId('PJEO')
class PipelineJobEntryOutputs {
    @Form([
        Field('testReports', String, 'Test Reports', hint: 'Test report locations'),
        Field('coverageReports', String, 'Coverage Reports',
                hint: 'Coverage report locations'),
        Field('artifacts', String, 'Artifacts', hint: 'Produced artifacts'),
        Field('notes', String, 'Notes', hint: 'Additional job notes'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Deployment environment entry.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'CI/CD — continuous integration / delivery pipelines',
  ],
  'Describes a single deployment environment including its name, type, and URL.',
)
@SectionId('DEE')
class DeploymentEnvironmentEntry {
  @Form([
    // Identity
    Field('environmentName', String, 'Environment Name',
        required: true, hint: 'E.g., dev, staging, production'),
    Field('environmentType', String, 'Type',
        hint: 'Development, Staging, Production'),
    Field('url', String, 'URL', hint: 'Environment URL'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Deployment method and rollback controls.
  @SerializationOrder(1)
  DeploymentEnvironmentEntryDeployment deployment =
    DeploymentEnvironmentEntryDeployment();

  /// Approval and protection rules.
  @SerializationOrder(2)
  DeploymentEnvironmentEntryProtection protection =
    DeploymentEnvironmentEntryProtection();

  /// Configuration and secrets sourcing.
  @SerializationOrder(3)
  DeploymentEnvironmentEntryConfiguration configuration =
    DeploymentEnvironmentEntryConfiguration();

  /// Health verification and environment notes.
  @SerializationOrder(4)
  DeploymentEnvironmentEntryMonitoring monitoring =
    DeploymentEnvironmentEntryMonitoring();
}

/// Deployment method and rollback controls.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures the deployment method, deployment configuration, and rollback strategy for an environment.',
)
@SectionId('DEED')
class DeploymentEnvironmentEntryDeployment {
  @Form([
  Field('deploymentMethod', String, 'Deployment Method',
    hint: 'Kubernetes, serverless, VM, container'),
  Field('deploymentConfig', String, 'Deployment Config',
    hint: 'Reference to deployment configuration'),
  Field('rollbackStrategy', String, 'Rollback Strategy',
    hint: 'How to rollback failed deployments'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Approval and protection rules.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures deployment protection rules including required approvers and self-approval prevention.',
)
@SectionId('DEEP')
class DeploymentEnvironmentEntryProtection {
  @Form([
  Field('protectionRules', String, 'Protection Rules',
    hint: 'Required reviewers, branch protection'),
  Field('requiredApprovers', String, 'Required Approvers',
    hint: 'Who must approve deployments'),
  Field('preventSelfApproval', bool, 'Prevent Self-Approval',
    hint: 'Cannot approve own deployments'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Configuration and secrets sourcing.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'CI/CD — continuous integration / delivery pipelines',
  ],
  'Captures per-environment configuration source and secrets scoping.',
)
@SectionId('DEEC')
class DeploymentEnvironmentEntryConfiguration {
  @Form([
  Field('secretsScope', String, 'Secrets Scope',
    hint: 'Environment-specific secrets'),
  Field('configurationSource', String, 'Configuration Source',
    hint: 'Where config comes from'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Health verification and environment notes.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'CI/CD — continuous integration / delivery pipelines',
  ],
  'Captures deployment health verification via health check URLs and post-deployment checks.',
)
@SectionId('DEEM')
class DeploymentEnvironmentEntryMonitoring {
  @Form([
  Field('healthCheckUrl', String, 'Health Check URL',
    hint: 'URL for health verification'),
  Field('deploymentVerification', String, 'Deployment Verification',
    hint: 'Post-deployment checks'),
  Field('notes', String, 'Notes', hint: 'Additional environment notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Code review process configuration.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'CI/CD — continuous integration / delivery pipelines',
  ],
  'Describes the code review process including PR requirements, templates, naming conventions, and draft PRs.',
)
@SectionId('COREPR')
class CodeReviewProcess {
  @Form([
    Field('prRequired', bool, 'PR Required', hint: 'All changes via PR'),
    Field('prTemplate', String, 'PR Template', hint: 'Pull request template'),
    Field('prNamingConvention', String, 'PR Naming Convention',
        hint: 'PR title format'),
    Field('draftPrSupport', bool, 'Draft PR Support', hint: 'Use draft PRs'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Reviewer requirements.
  @SerializationOrder(1)
  CodeReviewProcessRequirements requirements =
      CodeReviewProcessRequirements();

  /// Review workflow.
  @SerializationOrder(2)
  CodeReviewProcessWorkflow workflow = CodeReviewProcessWorkflow();

  /// Automation requirements.
  @SerializationOrder(3)
  CodeReviewProcessAutomation automation = CodeReviewProcessAutomation();

  /// Merge policy.
  @SerializationOrder(4)
  CodeReviewProcessMerge merge = CodeReviewProcessMerge();
}

/// Reviewer requirements.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'CI/CD — continuous integration / delivery pipelines',
  ],
  'Captures reviewer requirements including minimum reviewers, code owners, and reviewer assignment.',
)
@SectionId('CRPR')
class CodeReviewProcessRequirements {
  @Form([
    Field('minimumReviewers', String, 'Minimum Reviewers',
        hint: 'Required number of approvals'),
    Field('codeOwners', String, 'Code Owners',
        hint: 'CODEOWNERS file usage'),
    Field('automaticReviewerAssignment', String, 'Auto-Assignment',
        hint: 'How reviewers are assigned'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Review workflow.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'CI/CD — continuous integration / delivery pipelines',
  ],
  'Captures the review workflow including checklists, inline comments, suggestion format, and discussion resolution.',
)
@SectionId('CRPW')
class CodeReviewProcessWorkflow {
  @Form([
    Field('reviewChecklist', String, 'Review Checklist',
        hint: 'Standard review checklist'),
    Field('inlineComments', bool, 'Inline Comments Required',
        hint: 'Must use inline comments'),
    Field('suggestionFormat', String, 'Suggestion Format',
        hint: 'Format for code suggestions'),
    Field('discussionResolution', String, 'Discussion Resolution',
        hint: 'How discussions are resolved'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Automation requirements.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures review automation such as required automated checks, linting, tests, and coverage thresholds.',
)
@SectionId('CRPA')
class CodeReviewProcessAutomation {
  @Form([
    Field('automatedChecks', String, 'Automated Checks',
        hint: 'Required automated checks'),
    Field('lintingRequired', bool, 'Linting Required',
        hint: 'Linting must pass'),
    Field('testsRequired', bool, 'Tests Required', hint: 'Tests must pass'),
    Field('coverageThreshold', String, 'Coverage Threshold',
        hint: 'Minimum coverage for approval'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Merge policy.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'CI/CD — continuous integration / delivery pipelines',
  ],
  'Captures the merge policy including merge strategy, branch deletion, and required status checks.',
)
@SectionId('CRPM')
class CodeReviewProcessMerge {
  @Form([
    Field('mergeStrategy', String, 'Merge Strategy',
        hint: 'Squash, merge, rebase'),
    Field('deleteSourceBranch', bool, 'Delete Source Branch',
        hint: 'Auto-delete after merge'),
    Field('requiredStatusChecks', String, 'Required Status Checks',
        hint: 'Checks that must pass before merge'),
    Field('notes', String, 'Notes', hint: 'Additional review process notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Local development setup configuration.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Describes the local development setup including system requirements, prerequisite software, and SDK versions.',
)
@SectionId('LODESE')
class LocalDevelopmentSetup {
  @Form([
    Field('systemRequirements', String, 'System Requirements',
        hint: 'OS, RAM, disk space requirements'),
    Field('prerequisiteSoftware', String, 'Prerequisite Software',
        hint: 'Required software before setup'),
    Field('sdkVersions', String, 'SDK Versions',
        hint: 'Required SDK versions'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Setup workflow.
  @SerializationOrder(1)
  LocalDevelopmentSetupWorkflow workflow = LocalDevelopmentSetupWorkflow();

  /// Dependencies and local services.
  @SerializationOrder(2)
  LocalDevelopmentSetupDependencies dependencies =
      LocalDevelopmentSetupDependencies();

  /// Running configuration.
  @SerializationOrder(3)
  LocalDevelopmentSetupRunning running = LocalDevelopmentSetupRunning();

  /// Test setup.
  @SerializationOrder(4)
  LocalDevelopmentSetupTesting testing = LocalDevelopmentSetupTesting();

  /// Troubleshooting details.
  @SerializationOrder(5)
  LocalDevelopmentSetupTroubleshooting troubleshooting =
      LocalDevelopmentSetupTroubleshooting();
}

/// Setup workflow.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures the local setup workflow including clone instructions, setup scripts, and configuration files.',
)
@SectionId('LDSW')
class LocalDevelopmentSetupWorkflow {
  @Form([
    Field('cloneInstructions', String, 'Clone Instructions',
        hint: 'How to clone the repository'),
    Field('setupScript', String, 'Setup Script',
        hint: 'Automated setup script location'),
    Field('manualSetupSteps', String, 'Manual Setup Steps',
        hint: 'Manual steps if needed'),
    Field('configurationFiles', String, 'Configuration Files',
        hint: 'Config files to create/modify'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dependencies and local services.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures dependency installation and local backing services such as databases and Docker Compose.',
)
@SectionId('LDSD')
class LocalDevelopmentSetupDependencies {
  @Form([
    Field('dependencyInstallation', String, 'Dependency Installation',
        hint: 'How to install dependencies'),
    Field('localServices', String, 'Local Services',
        hint: 'Required local services (DB, Redis)'),
    Field('dockerCompose', String, 'Docker Compose',
        hint: 'Docker Compose for services'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Running configuration.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures how the application is run locally including run commands, hot reload, and watch mode.',
)
@SectionId('LDSR')
class LocalDevelopmentSetupRunning {
  @Form([
    Field('runCommands', String, 'Run Commands',
        hint: 'Commands to run the application'),
    Field('hotReload', bool, 'Hot Reload Available',
        hint: 'Hot reload support'),
    Field('watchMode', String, 'Watch Mode',
        hint: 'File watching configuration'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Test setup.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures local test setup including running tests locally, test databases, and mock services.',
)
@SectionId('LDST')
class LocalDevelopmentSetupTesting {
  @Form([
    Field('runTestsLocally', String, 'Run Tests Locally',
        hint: 'How to run tests locally'),
    Field('testDatabaseSetup', String, 'Test Database Setup',
        hint: 'Test database configuration'),
    Field('mockServices', String, 'Mock Services',
        hint: 'How to use mock services'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Troubleshooting details.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures local-setup troubleshooting including common issues and support channels.',
)
@SectionId('LODESETR')
class LocalDevelopmentSetupTroubleshooting {
  @Form([
    Field('commonIssues', String, 'Common Issues',
        hint: 'Common setup issues and solutions'),
    Field('supportChannel', String, 'Support Channel',
        hint: 'Where to get help'),
    Field('notes', String, 'Notes', hint: 'Additional setup notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Debugging configuration.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Describes the debugging configuration including debugger tooling, launch configurations, and remote debugging.',
)
@SectionId('DECO')
class DebuggingConfiguration {
  @Form([
    Field('debuggerTool', String, 'Debugger Tool',
        hint: 'IDE debugger, DevTools, custom'),
    Field('debuggerConfiguration', String, 'Debugger Configuration',
        hint: 'Launch configurations'),
    Field('remoteDebugging', String, 'Remote Debugging',
        hint: 'Remote debugging setup'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Breakpoint and watch setup.
  @SerializationOrder(1)
  DebuggingConfigurationBreakpoints breakpoints =
      DebuggingConfigurationBreakpoints();

  /// Logging setup for debugging.
  @SerializationOrder(2)
  DebuggingConfigurationLogging logging = DebuggingConfigurationLogging();

  /// State and runtime inspection.
  @SerializationOrder(3)
  DebuggingConfigurationInspection inspection =
      DebuggingConfigurationInspection();

  /// Flutter-specific tooling.
  @SerializationOrder(4)
  DebuggingConfigurationFlutter flutter = DebuggingConfigurationFlutter();

  /// Error tracking details.
  @SerializationOrder(5)
  DebuggingConfigurationErrors errors = DebuggingConfigurationErrors();
}

/// Breakpoint and watch setup.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures breakpoint types, log points, and standard watch expressions for debugging.',
)
@SectionId('DECOBR')
class DebuggingConfigurationBreakpoints {
  @Form([
    Field('breakpointTypes', String, 'Breakpoint Types',
        hint: 'Line, conditional, exception breakpoints'),
    Field('logPoints', String, 'Log Points', hint: 'Non-breaking log points'),
    Field('watchExpressions', String, 'Watch Expressions',
        hint: 'Standard watch expressions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Logging setup for debugging.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures debug logging configuration, log levels, and structured logging options.',
)
@SectionId('DECOLO')
class DebuggingConfigurationLogging {
  @Form([
    Field('loggingConfiguration', String, 'Logging Configuration',
        hint: 'Debug logging setup'),
    Field('logLevels', String, 'Log Levels',
        hint: 'Available log levels'),
    Field('structuredLogging', bool, 'Structured Logging',
        hint: 'JSON/structured logs'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// State and runtime inspection.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures state, network, and performance inspection tooling used during debugging.',
)
@SectionId('DECOIN')
class DebuggingConfigurationInspection {
  @Form([
    Field('stateInspection', String, 'State Inspection',
        hint: 'How to inspect app state'),
    Field('networkInspection', String, 'Network Inspection',
        hint: 'Network call debugging'),
    Field('performanceInspection', String, 'Performance Inspection',
        hint: 'Performance profiling tools'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Flutter-specific tooling.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures Flutter-specific debugging tooling such as the widget inspector, DevTools features, and repaint rainbow.',
)
@SectionId('DECOFL')
class DebuggingConfigurationFlutter {
  @Form([
    Field('widgetInspector', String, 'Widget Inspector',
        hint: 'Flutter widget inspector'),
    Field('devToolsFeatures', String, 'DevTools Features',
        hint: 'Required DevTools features'),
    Field('repaintRainbow', bool, 'Repaint Rainbow',
        hint: 'Visual repaint debugging'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Error tracking details.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures development-time error tracking and local crash reporting setup.',
)
@SectionId('DECOER')
class DebuggingConfigurationErrors {
  @Form([
    Field('errorTrackingSetup', String, 'Error Tracking Setup',
        hint: 'Error tracking in development'),
    Field('crashReporting', String, 'Crash Reporting',
        hint: 'Local crash reporting'),
    Field('notes', String, 'Notes', hint: 'Additional debugging notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Environment management configuration.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'CI/CD — continuous integration / delivery pipelines',
  ],
  'Describes environment management including environment types, naming, and per-environment purposes.',
)
@SectionId('ENMA')
class EnvironmentManagement {
  @Form([
    Field('environmentTypes', String, 'Environment Types',
        hint: 'development, staging, production, etc.'),
    Field('environmentNaming', String, 'Environment Naming',
        hint: 'Naming convention for environments'),
    Field('environmentPurposes', String, 'Environment Purposes',
        hint: 'Purpose of each environment'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Configuration settings.
  @SerializationOrder(1)
  EnvironmentManagementConfiguration configuration =
      EnvironmentManagementConfiguration();

  /// Secrets handling.
  @SerializationOrder(2)
  EnvironmentManagementSecrets secrets = EnvironmentManagementSecrets();

  /// Environment switching.
  @SerializationOrder(3)
  EnvironmentManagementSwitching switching = EnvironmentManagementSwitching();

  /// Parity and notes.
  @SerializationOrder(4)
  EnvironmentManagementParity parity = EnvironmentManagementParity();
}

/// Configuration settings.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'CI/CD — continuous integration / delivery pipelines',
  ],
  'Captures the configuration method, config file formats, and configuration hierarchy across environments.',
)
@SectionId('ENMACO')
class EnvironmentManagementConfiguration {
  @Form([
    Field('configurationMethod', String, 'Configuration Method',
        hint: 'Environment variables, files, remote'),
    Field('configFileFormat', String, 'Config File Format',
        hint: '.env, YAML, JSON'),
    Field('configurationHierarchy', String, 'Configuration Hierarchy',
        hint: 'Default → environment → local'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Secrets handling.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'CI/CD — continuous integration / delivery pipelines',
  ],
  'Captures local secrets management, secrets templates, and never-commit rules per environment.',
)
@SectionId('ENMASE')
class EnvironmentManagementSecrets {
  @Form([
    Field('localSecretsManagement', String, 'Local Secrets Management',
        hint: 'How secrets are managed locally'),
    Field('secretsTemplate', String, 'Secrets Template',
        hint: 'Template for required secrets'),
    Field('secretsNeverCommit', String, 'Never Commit',
        hint: 'Secrets that must never be committed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Environment switching.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'CI/CD — continuous integration / delivery pipelines',
  ],
  'Captures the mechanism for switching environments, build flavor support, and runtime switching.',
)
@SectionId('ENMASW')
class EnvironmentManagementSwitching {
  @Form([
    Field('switchingMechanism', String, 'Switching Mechanism',
        hint: 'How to switch environments'),
    Field('flavorSupport', String, 'Flavor/Variant Support',
        hint: 'Build flavors for environments'),
    Field('runtimeSwitching', bool, 'Runtime Switching',
        hint: 'Can switch at runtime'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Parity and notes.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'CI/CD — continuous integration / delivery pipelines',
  ],
  'Captures dev-prod parity, data seeding, and mocking strategy across environments.',
)
@SectionId('ENMAPA')
class EnvironmentManagementParity {
  @Form([
    Field('devProdParity', String, 'Dev-Prod Parity',
        hint: 'How similar dev is to prod'),
    Field('dataSeeding', String, 'Data Seeding',
        hint: 'Test data for environments'),
    Field('mockingStrategy', String, 'Mocking Strategy',
        hint: 'Service mocking per environment'),
    Field('notes', String, 'Notes',
        hint: 'Additional environment management notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Developer onboarding requirements.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Describes developer onboarding requirements including guides, architecture overviews, and coding standards references.',
)
@SectionId('DEON')
class DeveloperOnboarding {
  @Form([
    Field('onboardingGuide', String, 'Onboarding Guide',
        hint: 'Location of onboarding documentation'),
    Field('architectureOverview', String, 'Architecture Overview',
        hint: 'System architecture docs'),
    Field('codingStandardsDocs', String, 'Coding Standards Docs',
        hint: 'Where to find coding standards'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Setup expectations.
  @SerializationOrder(1)
  DeveloperOnboardingSetup setup = DeveloperOnboardingSetup();

  /// Access provisioning.
  @SerializationOrder(2)
  DeveloperOnboardingAccess access = DeveloperOnboardingAccess();

  /// Learning support.
  @SerializationOrder(3)
  DeveloperOnboardingLearning learning = DeveloperOnboardingLearning();

  /// Early task expectations.
  @SerializationOrder(4)
  DeveloperOnboardingFirstTasks firstTasks = DeveloperOnboardingFirstTasks();

  /// Completion verification.
  @SerializationOrder(5)
  DeveloperOnboardingVerification verification =
      DeveloperOnboardingVerification();
}

/// Setup expectations.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures onboarding setup expectations including estimated setup time and automated setup availability.',
)
@SectionId('DEONSE')
class DeveloperOnboardingSetup {
  @Form([
    Field('estimatedSetupTime', String, 'Estimated Setup Time',
        hint: 'How long initial setup takes'),
    Field('automatedSetup', bool, 'Automated Setup',
        hint: 'Setup is automated'),
    Field('setupVideoGuide', String, 'Setup Video Guide',
        hint: 'Video walkthrough if available'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access provisioning.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures onboarding access provisioning such as required access, request processes, and VPN setup.',
)
@SectionId('DEONAC')
class DeveloperOnboardingAccess {
  @Form([
    Field('requiredAccess', String, 'Required Access',
        hint: 'Access needed (repos, services, tools)'),
    Field('accessRequestProcess', String, 'Access Request Process',
        hint: 'How to request access'),
    Field('vpnSetup', String, 'VPN Setup',
        hint: 'VPN configuration if needed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Learning support.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures onboarding learning support including required reading, code walkthroughs, and pairing buddies.',
)
@SectionId('DEONLE')
class DeveloperOnboardingLearning {
  @Form([
    Field('requiredReading', String, 'Required Reading',
        hint: 'Must-read documentation'),
    Field('codeWalkthrough', String, 'Code Walkthrough',
        hint: 'Guided code tour'),
    Field('pairProgrammingBuddy', bool, 'Pair Programming Buddy',
        hint: 'Assigned onboarding buddy'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Early task expectations.
@StandardReferences(
  [
    'ISO/IEC 12207 — software lifecycle processes',
    'Twelve-Factor App — cloud-native methodology',
  ],
  'Captures early-task expectations for new developers such as starter tasks, shadowing, and first-PR timing.',
)
@SectionId('DOFT')
class DeveloperOnboardingFirstTasks {
  @Form([
    Field('starterTasks', String, 'Starter Tasks',
        hint: 'Good first issues'),
    Field('shadowingPeriod', String, 'Shadowing Period',
        hint: 'Time spent shadowing'),
    Field('firstPrExpectation', String, 'First PR Expectation',
        hint: 'Expected time to first PR'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Completion verification.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures onboarding completion verification via checklists and defined completion criteria.',
)
@SectionId('DEONVE')
class DeveloperOnboardingVerification {
  @Form([
    Field('onboardingChecklist', String, 'Onboarding Checklist',
        hint: 'Checklist to complete'),
    Field('completionCriteria', String, 'Completion Criteria',
        hint: 'When onboarding is complete'),
    Field('notes', String, 'Notes', hint: 'Additional onboarding notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Development quality gates and metrics.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Describes the development quality gates and metrics enforced across static analysis, linting, and formatting.',
)
@SectionId('DEQUGA')
class DevelopmentQualityGates {
  @Form([
    Field('staticAnalysis', String, 'Static Analysis',
        hint: 'Required static analysis tools'),
    Field('linterConfiguration', String, 'Linter Configuration',
        hint: 'Linter rules and configuration'),
    Field('formatterConfiguration', String, 'Formatter Configuration',
        hint: 'Code formatter settings'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Coverage requirements.
  @SerializationOrder(1)
  DevelopmentQualityGatesCoverage coverage =
      DevelopmentQualityGatesCoverage();

  /// Complexity thresholds.
  @SerializationOrder(2)
  DevelopmentQualityGatesComplexity complexity =
      DevelopmentQualityGatesComplexity();

  /// Security checks.
  @SerializationOrder(3)
  DevelopmentQualityGatesSecurity security =
      DevelopmentQualityGatesSecurity();

  /// Documentation requirements.
  @SerializationOrder(4)
  DevelopmentQualityGatesDocumentation documentation =
      DevelopmentQualityGatesDocumentation();

  /// Performance checks.
  @SerializationOrder(5)
  DevelopmentQualityGatesPerformance performance =
      DevelopmentQualityGatesPerformance();
}

/// Coverage requirements.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures test coverage quality gates including minimum coverage thresholds and coverage exclusions.',
)
@SectionId('DQGC')
class DevelopmentQualityGatesCoverage {
  @Form([
    Field('unitTestCoverageMinimum', String, 'Unit Test Coverage Minimum',
        hint: 'Minimum unit test coverage'),
    Field('integrationTestRequirement', String, 'Integration Test Requirement',
        hint: 'Integration test requirements'),
    Field('coverageExclusions', String, 'Coverage Exclusions',
        hint: 'What is excluded from coverage'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Complexity thresholds.
@StandardReferences(
  [
    'ISO/IEC 25010 — maintainability quality attributes',
    'CI/CD — continuous integration / delivery pipelines',
  ],
  'Captures complexity quality gates such as cyclomatic complexity, file size, and function size limits.',
)
@SectionId('DEQUGACO')
class DevelopmentQualityGatesComplexity {
  @Form([
    Field('complexityThresholds', String, 'Complexity Thresholds',
        hint: 'Max cyclomatic complexity'),
    Field('fileSizeLimit', String, 'File Size Limit',
        hint: 'Maximum lines per file'),
    Field('functionSizeLimit', String, 'Function Size Limit',
        hint: 'Maximum lines per function'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security checks.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures security quality gates including dependency scanning, secrets scanning, and license compliance.',
)
@SectionId('DQGS')
class DevelopmentQualityGatesSecurity {
  @Form([
    Field('dependencyScanning', String, 'Dependency Scanning',
        hint: 'Vulnerability scanning'),
    Field('secretsScanning', bool, 'Secrets Scanning',
        hint: 'Check for leaked secrets'),
    Field('licenseCompliance', String, 'License Compliance',
        hint: 'OSS license checking'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — maintainability quality attributes',
    'CI/CD — continuous integration / delivery pipelines',
  ],
  'Captures documentation quality gates such as required API docs, changelog, and README updates.',
)
@SectionId('DQGD')
class DevelopmentQualityGatesDocumentation {
  @Form([
    Field('apiDocumentation', String, 'API Documentation',
        hint: 'Required API documentation'),
    Field('changelogRequired', bool, 'Changelog Required',
        hint: 'Must update changelog'),
    Field('readmeRequired', bool, 'README Required',
        hint: 'README for new features'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Performance checks.
@StandardReferences(
  [
    'CI/CD — continuous integration / delivery pipelines',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures performance quality gates such as budgets, bundle size, and startup time limits enforced in the pipeline.',
)
@SectionId('DQGP')
class DevelopmentQualityGatesPerformance {
  @Form([
    Field('performanceBudgets', String, 'Performance Budgets',
        hint: 'Performance constraints'),
    Field('bundleSizeLimit', String, 'Bundle Size Limit',
        hint: 'Maximum bundle size'),
    Field('startupTimeLimit', String, 'Startup Time Limit',
        hint: 'Maximum startup time'),
    Field('notes', String, 'Notes', hint: 'Additional quality gate notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// =============================================================================
// 8.2.3. Reusable Components
// =============================================================================

/// 8.2.3. Reusable Components.
///
/// Components, libraries, or frameworks designed for reuse across projects
/// or modules.
@ContentHelp('''
Define strategy for creating and managing reusable components across
projects and modules. Effective reuse reduces duplication, ensures
consistency, and accelerates development.

**Component Categories**:
- **UI Components**: Design system components, widgets, layouts, themes
- **Business Logic**: Domain services, validation rules, calculations
- **Infrastructure**: Logging, caching, HTTP clients, database access
- **Utilities**: String manipulation, date handling, formatters
- **Third-Party Wrappers**: Abstraction layers over external libraries

**Reusability Principles**:
- Extract when used 3+ times (Rule of Three)
- Prefer composition over inheritance
- Design for extension, closed for modification (Open/Closed)
- Keep components focused (Single Responsibility)
- Version independently when appropriate

**Component Governance**:
- Ownership and maintenance responsibilities
- Contribution and review process
- Deprecation and migration policies
- Documentation requirements
- Testing and quality standards

**Discovery and Registry**:
- Component catalog and documentation portal
- Searchable API documentation
- Usage examples and integration guides
- Version compatibility matrix
''')
@StandardReferences(
  [
    'DRY — reusable component design',
    'ISO/IEC 25010 — reusability / maintainability quality attributes',
  ],
  'Captures the overall strategy for creating, cataloguing, and governing reusable components across the system.',
)
@SectionId('RCS')
class ReusableComponentsSection {
  @ContentHelp('''
Provide an overview of the reusability strategy and component library.

**Include**:
- Reuse-first culture and policies
- Component library organization
- Contribution and adoption process
- Success metrics (reuse rate, contribution rate)
- Key shared components and their purposes

**Best Practices**:
- Start with "extract when needed" not "build speculatively"
- Establish inner-source practices for contributions
- Create component design guidelines
- Track component usage and dependencies
- Plan for breaking change management
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of reusability strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Reusability principles and guidelines.
  @SerializationOrder(2)
  ReusabilityPrinciples principles = ReusabilityPrinciples();

  /// Shared component library catalog.
  @StandardReferences(
    [
      'DRY — reusable component design',
      'Semantic Versioning (SemVer) — library versioning',
    ],
    'The shared libraries reused across the system.',
  )
  @SectionId('SHLCP-SHAR-LST')
  @SectionIdPattern('SHLCP-SHAR-xxx')
  @ContentHelp('Add one entry per shared library.')
  @SerializationOrder(3)
  List<SharedLibraryComponentEntry> sharedLibraries = [];

  /// UI component library entries.
  @StandardReferences(
    [
      'DRY — reusable component design',
      'SOLID principles — object-oriented design',
    ],
    'The reusable UI components shared across the system.',
  )
  @SectionId('RUICMP-UICO-LST')
  @SectionIdPattern('RUICMP-UICO-xxx')
  @ContentHelp('Add one entry per UI component.')
    @SerializationOrder(4)
    List<ReusableUiComponentEntry> uiComponents = [];

  /// Business logic components.
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — reusability quality attributes',
    ],
    'The reusable business logic components shared across the system.',
  )
  @SectionId('BUCOEN-BUSI-LST')
  @SectionIdPattern('BUCOEN-BUSI-xxx')
  @ContentHelp('Add one entry per business component.')
  @SerializationOrder(5)
  List<BusinessComponentEntry> businessComponents = [];

  /// Infrastructure components.
  @StandardReferences(
    [
      'DRY — reusable component design',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'The reusable infrastructure components shared across the system.',
  )
  @SectionId('INCOEN-INFR-LST')
  @SectionIdPattern('INCOEN-INFR-xxx')
  @ContentHelp('Add one entry per infrastructure component.')
  @SerializationOrder(6)
  List<InfrastructureComponentEntry> infrastructureComponents = [];

  /// Third-party frameworks and libraries.
  @StandardReferences(
    [
      'package management (pub / npm / Maven) — dependency management',
      'Semantic Versioning (SemVer) — library versioning',
    ],
    'The third-party frameworks and libraries reused across the system.',
  )
  @SectionId('THPALI-THIR-LST')
  @SectionIdPattern('THPALI-THIR-xxx')
  @ContentHelp('Add one entry per third-party library.')
  @SerializationOrder(7)
  List<ThirdPartyLibraryEntry> thirdPartyLibraries = [];

  /// Component governance and maintenance.
  @SerializationOrder(8)
  ComponentGovernance governance = ComponentGovernance();

  /// Component discovery and registry.
  @SerializationOrder(9)
  ComponentRegistry registry = ComponentRegistry();
}

/// Reusability principles and guidelines.
@StandardReferences(
  [
    'DRY — reusable component design',
    'SOLID principles — object-oriented design',
  ],
  'Captures the guiding principles and guidelines governing how reusable components are designed.',
)
@SectionId('REPR')
class ReusabilityPrinciples {
  @Form([
    Field('reuseFirstPolicy', String, 'Reuse-First Policy',
        hint: 'Policy on preferring existing components'),
    Field('extractionCriteria', String, 'Extraction Criteria',
        hint: 'When to extract code into reusable components'),
    Field('granularityGuidelines', String, 'Granularity Guidelines',
        hint: 'Right size for reusable components'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Abstraction rules.
  @SerializationOrder(1)
  ReusabilityPrinciplesAbstraction abstraction =
    ReusabilityPrinciplesAbstraction();

  /// Quality expectations.
  @SerializationOrder(2)
  ReusabilityPrinciplesQuality quality = ReusabilityPrinciplesQuality();

  /// Versioning policy.
  @SerializationOrder(3)
  ReusabilityPrinciplesVersioning versioning =
    ReusabilityPrinciplesVersioning();

  /// Ownership and contribution.
  @SerializationOrder(4)
  ReusabilityPrinciplesOwnership ownership = ReusabilityPrinciplesOwnership();
}

/// Abstraction rules.
@StandardReferences(
  [
    'DRY — reusable component design',
    'SOLID principles — object-oriented design',
  ],
  'Captures the abstraction level, interface standards, and dependency rules for reusable components.',
)
@SectionId('REPRAB')
class ReusabilityPrinciplesAbstraction {
  @Form([
  Field('abstractionLevel', String, 'Abstraction Level',
    hint: 'Required abstraction for reusability'),
  Field('interfaceStandards', String, 'Interface Standards',
    hint: 'Standards for component interfaces'),
  Field('dependencyRules', String, 'Dependency Rules',
    hint: 'Rules for component dependencies'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Quality expectations.
@StandardReferences(
  [
    'DRY — reusable component design',
    'SOLID principles — object-oriented design',
  ],
  'Captures the documentation, testing, and code-review quality requirements for reusable components.',
)
@SectionId('REPRQU')
class ReusabilityPrinciplesQuality {
  @Form([
  Field('documentationRequirements', String, 'Documentation Requirements',
    hint: 'Required documentation for reusable components'),
  Field('testingRequirements', String, 'Testing Requirements',
    hint: 'Test coverage for reusable components'),
  Field('codeReviewProcess', String, 'Code Review Process',
    hint: 'Review process for shared components'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Versioning policy.
@StandardReferences(
  [
    'Semantic Versioning (SemVer) — library versioning',
    'DRY — reusable component design',
  ],
  'Captures the versioning, breaking-change, and deprecation policies for reusable components.',
)
@SectionId('REPRVE')
class ReusabilityPrinciplesVersioning {
  @Form([
  Field('versioningPolicy', String, 'Versioning Policy',
    hint: 'How reusable components are versioned'),
  Field('breakingChangePolicy', String, 'Breaking Change Policy',
    hint: 'Handling breaking changes in shared components'),
  Field('deprecationProcess', String, 'Deprecation Process',
    hint: 'How components are deprecated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Ownership and contribution.
@StandardReferences(
  [
    'DRY — reusable component design',
    'SOLID principles — object-oriented design',
  ],
  'Captures the ownership model and contribution process for reusable components.',
)
@SectionId('REPROW')
class ReusabilityPrinciplesOwnership {
  @Form([
  Field('ownershipModel', String, 'Ownership Model',
    hint: 'Who owns shared components'),
  Field('contributionProcess', String, 'Contribution Process',
    hint: 'How to contribute to shared components'),
  Field('notes', String, 'Notes', hint: 'Additional principles notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Shared library component entry.
@StandardReferences(
  [
    'DRY — reusable component design',
    'Semantic Versioning (SemVer) — library versioning',
    'package management (pub / npm / Maven) — dependency management',
  ],
  'Captures a shared library reused across the system, its type, and its version.',
)
@SectionId('SHLCP')
class SharedLibraryComponentEntry {
  @Form([
    Field('componentName', String, 'Component Name',
        required: true, hint: 'Unique library name'),
    Field('componentType', String, 'Component Type',
        hint: 'Core, Utility, Domain, Integration, Extension'),
    Field('version', String, 'Version', hint: 'Current version'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Purpose and consumers.
  @SerializationOrder(1)
  SharedLibraryComponentEntryDescription description =
      SharedLibraryComponentEntryDescription();

  /// Technical API details.
  @SerializationOrder(2)
  SharedLibraryComponentEntryTechnical technical =
      SharedLibraryComponentEntryTechnical();

  /// Quality and documentation.
  @SerializationOrder(3)
  SharedLibraryComponentEntryQuality quality =
      SharedLibraryComponentEntryQuality();

  /// Ownership and lifecycle.
  @SerializationOrder(4)
  SharedLibraryComponentEntryOwnership ownership =
      SharedLibraryComponentEntryOwnership();
}

/// Purpose and consumers for shared library component.
@StandardReferences(
  [
    'DRY — reusable component design',
    'Semantic Versioning (SemVer) — library versioning',
  ],
  'Captures the package name, purpose, functionality, and target consumers of the shared library component.',
)
@SectionId('SLCED')
class SharedLibraryComponentEntryDescription {
  @Form([
    Field('packageName', String, 'Package/Module Name',
        hint: 'Package identifier'),
    Field('purpose', String, 'Purpose',
        required: true, hint: 'What problem this component solves'),
    Field('functionality', String, 'Functionality',
        hint: 'Key features provided'),
    Field('targetConsumers', String, 'Target Consumers',
        hint: 'Who should use this component'),
    Field('useCases', String, 'Use Cases', hint: 'Example use cases'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Technical API details for shared library component.
@StandardReferences(
  [
    'DRY — reusable component design',
    'package management (pub / npm / Maven) — dependency management',
  ],
  'Captures the public API, extension points, configuration, and dependencies of the shared library component.',
)
@SectionId('SLCET')
class SharedLibraryComponentEntryTechnical {
  @Form([
    Field('publicApi', String, 'Public API',
        hint: 'Key public classes/functions'),
    Field('extensionPoints', String, 'Extension Points',
        hint: 'How consumers can extend'),
    Field('configuration', String, 'Configuration Options',
        hint: 'Available configuration'),
    Field('dependencies', String, 'Dependencies',
        hint: 'Required dependencies'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Quality and documentation for shared library component.
@StandardReferences(
  [
    'DRY — reusable component design',
    'package management (pub / npm / Maven) — dependency management',
  ],
  'Captures the test coverage, documentation, and examples location for the shared library component.',
)
@SectionId('SLCEQ')
class SharedLibraryComponentEntryQuality {
  @Form([
    Field('testCoverage', String, 'Test Coverage', hint: 'Current coverage'),
    Field('documentationUrl', String, 'Documentation URL',
        hint: 'Link to documentation'),
    Field('examplesLocation', String, 'Examples Location',
        hint: 'Where to find examples'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Ownership and lifecycle for shared library component.
@StandardReferences(
  [
    'DRY — reusable component design',
    'Semantic Versioning (SemVer) — library versioning',
  ],
  'Captures the owner, maintainers, support channel, and maturity level of the shared library component.',
)
@SectionId('SLCEO')
class SharedLibraryComponentEntryOwnership {
  @Form([
    Field('owner', String, 'Owner', hint: 'Team/person responsible'),
    Field('maintainers', String, 'Maintainers', hint: 'List of maintainers'),
    Field('supportChannel', String, 'Support Channel',
        hint: 'Where to get help'),
    Field('maturityLevel', String, 'Maturity Level',
        hint: 'Experimental, Beta, Stable, Deprecated'),
    Field('lastUpdated', String, 'Last Updated', hint: 'Last update date'),
    Field('notes', String, 'Notes', hint: 'Additional component notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// UI component entry — a reusable UI widget or pattern.
@StandardReferences(
  [
    'DRY — reusable component design',
    'SOLID principles — object-oriented design',
  ],
  'Captures a reusable UI widget or pattern, its category, and its purpose within the design system.',
)
@SectionId('RUCE')
class ReusableUiComponentEntry {
  @Form([
    Field('componentName', String, 'Component Name',
        required: true, hint: 'Widget or pattern name'),
    Field('componentCategory', String, 'Category',
        hint: 'Input, Display, Navigation, Layout, Feedback, Data'),
    Field('purpose', String, 'Purpose', hint: 'What this component does'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Description and use cases.
    @SerializationOrder(1)
    ReusableUiComponentEntryDescription description =
            ReusableUiComponentEntryDescription();

  /// Design specifications.
    @SerializationOrder(2)
    ReusableUiComponentEntryDesign design = ReusableUiComponentEntryDesign();

  /// Interaction and accessibility.
    @SerializationOrder(3)
    ReusableUiComponentEntryInteraction interaction =
            ReusableUiComponentEntryInteraction();

  /// Component API.
    @SerializationOrder(4)
    ReusableUiComponentEntryApi api = ReusableUiComponentEntryApi();

  /// Implementation details.
    @SerializationOrder(5)
    ReusableUiComponentEntryImplementation implementation =
            ReusableUiComponentEntryImplementation();
}

/// Description and use cases for UI component.
@StandardReferences(
  [
    'DRY — reusable component design',
    'SOLID principles — object-oriented design',
  ],
  'Captures the visual description, use cases, and anti-patterns for the UI component.',
)
@SectionId('RUCED')
class ReusableUiComponentEntryDescription {
  @Form([
    Field('version', String, 'Version', hint: 'Component version'),
    Field('visualDescription', String, 'Visual Description',
        hint: 'How it looks and behaves'),
    Field('useCases', String, 'Use Cases',
        hint: 'When to use this component'),
    Field('antiPatterns', String, 'Anti-Patterns',
        hint: 'When NOT to use this component'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Design specifications for UI component.
@StandardReferences(
  [
    'DRY — reusable component design',
    'SOLID principles — object-oriented design',
  ],
  'Captures the design tokens, variants, states, and responsive behavior of the UI component.',
)
@SectionId('REUICOENDE')
class ReusableUiComponentEntryDesign {
  @Form([
    Field('designTokens', String, 'Design Tokens Used',
        hint: 'Colors, spacing, typography tokens'),
    Field('variants', String, 'Variants',
        hint: 'Available variants (size, style)'),
    Field('states', String, 'States',
        hint: 'Supported states (disabled, loading, error)'),
    Field('responsiveBehavior', String, 'Responsive Behavior',
        hint: 'How component adapts to screen sizes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Interaction and accessibility for UI component.
@StandardReferences(
  [
    'DRY — reusable component design',
    'SOLID principles — object-oriented design',
  ],
  'Captures the interaction patterns, accessibility features, and animations of the UI component.',
)
@SectionId('RUCEI')
class ReusableUiComponentEntryInteraction {
  @Form([
    Field('interactionPatterns', String, 'Interaction Patterns',
        hint: 'Touch, keyboard, mouse behaviors'),
    Field('accessibility', String, 'Accessibility',
        hint: 'A11y features and requirements'),
    Field('animations', String, 'Animations',
        hint: 'Animation specifications'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Component API for UI component.
@StandardReferences(
  [
    'DRY — reusable component design',
    'SOLID principles — object-oriented design',
  ],
  'Captures the required/optional properties, callbacks, and slots forming the UI component API.',
)
@SectionId('RUCEA')
class ReusableUiComponentEntryApi {
  @Form([
    Field('requiredProperties', String, 'Required Properties',
        hint: 'Required parameters'),
    Field('optionalProperties', String, 'Optional Properties',
        hint: 'Optional parameters'),
    Field('callbacks', String, 'Callbacks',
        hint: 'Event callbacks supported'),
    Field('slots', String, 'Slots/Children',
        hint: 'Child content areas'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Implementation details for UI component.
@StandardReferences(
  [
    'DRY — reusable component design',
    'SOLID principles — object-oriented design',
  ],
  'Captures the implementing widget class, example code, and demo references for the UI component.',
)
@SectionId('REUICOENIM')
class ReusableUiComponentEntryImplementation {
  @Form([
    Field('flutterWidget', String, 'Flutter Widget Class',
        hint: 'Implementing Flutter widget'),
    Field('exampleCode', String, 'Example Code',
        hint: 'Code snippet or reference'),
    Field('storybook', String, 'Storybook/Demo',
        hint: 'Link to component demo'),
    Field('notes', String, 'Notes', hint: 'Additional UI component notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Business logic component entry.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — reusability quality attributes',
  ],
  'Captures a reusable business logic component such as a service, repository, use case, or validator.',
)
@SectionId('BUSCOMENT')
class BusinessComponentEntry {
  @Form([
    Field('componentName', String, 'Component Name',
        required: true, hint: 'Business component name'),
    Field('componentType', String, 'Component Type',
        hint: 'Service, Repository, UseCase, Validator, Calculator'),
    Field('boundedContext', String, 'Bounded Context',
        hint: 'Domain area this belongs to'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Purpose and business rules.
  @SerializationOrder(1)
  BusinessComponentEntryDescription description =
      BusinessComponentEntryDescription();

  /// Public interface details.
  @SerializationOrder(2)
  BusinessComponentEntryInterface interface =
      BusinessComponentEntryInterface();

  /// Dependency mapping.
  @SerializationOrder(3)
  BusinessComponentEntryDependencies dependencies =
      BusinessComponentEntryDependencies();

  /// Testing details.
  @SerializationOrder(4)
  BusinessComponentEntryTesting testing = BusinessComponentEntryTesting();

  /// Reuse and customization notes.
  @SerializationOrder(5)
  BusinessComponentEntryReuse reuse = BusinessComponentEntryReuse();
}

/// Purpose and business rules.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — reusability quality attributes',
  ],
  'Captures the purpose, business rules, and capabilities of the business logic component.',
)
@SectionId('BCED')
class BusinessComponentEntryDescription {
  @Form([
    Field('purpose', String, 'Purpose',
        hint: 'Business problem this solves'),
    Field('businessRules', String, 'Business Rules',
        hint: 'Key business rules implemented'),
    Field('capabilities', String, 'Capabilities',
        hint: 'What operations this provides'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Public interface details.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures the public interface, input/output types, and error handling of the business component.',
)
@SectionId('BUCOENIN')
class BusinessComponentEntryInterface {
  @Form([
    Field('publicInterface', String, 'Public Interface',
        hint: 'Key public methods'),
    Field('inputTypes', String, 'Input Types', hint: 'Expected inputs'),
    Field('outputTypes', String, 'Output Types', hint: 'Produced outputs'),
    Field('errorHandling', String, 'Error Handling',
        hint: 'How errors are handled'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dependency mapping.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures the required services, data access, and external integrations of the business component.',
)
@SectionId('BUCOENDE')
class BusinessComponentEntryDependencies {
  @Form([
    Field('requiredServices', String, 'Required Services',
        hint: 'Services this depends on'),
    Field('dataAccess', String, 'Data Access',
        hint: 'Data repositories used'),
    Field('externalIntegrations', String, 'External Integrations',
        hint: 'External systems accessed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing details.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures the test strategy, mockable interfaces, and test data requirements of the business component.',
)
@SectionId('BCET')
class BusinessComponentEntryTesting {
  @Form([
    Field('testStrategy', String, 'Test Strategy',
        hint: 'How this is tested'),
    Field('mockableInterfaces', String, 'Mockable Interfaces',
        hint: 'Interfaces for testing'),
    Field('testDataRequirements', String, 'Test Data Requirements',
        hint: 'Required test data'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reuse and customization notes.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — reusability quality attributes',
  ],
  'Captures the reuse scenarios and customization points of the business logic component.',
)
@SectionId('BCER')
class BusinessComponentEntryReuse {
  @Form([
    Field('reuseScenarios', String, 'Reuse Scenarios',
        hint: 'Where this can be reused'),
    Field('customizationPoints', String, 'Customization Points',
        hint: 'How behavior can be customized'),
    Field('notes', String, 'Notes',
        hint: 'Additional business component notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Infrastructure component entry.
@StandardReferences(
  [
    'DRY — reusable component design',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures a reusable infrastructure component such as logging, caching, messaging, or storage.',
)
@SectionId('INFCOMENT')
class InfrastructureComponentEntry {
  @Form([
    Field('componentName', String, 'Component Name',
        required: true, hint: 'Infrastructure component name'),
    Field('componentType', String, 'Component Type',
        hint: 'Logging, Caching, Messaging, Storage, Network'),
    Field('layer', String, 'Layer', hint: 'Infrastructure layer'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Purpose and technology choices.
  @SerializationOrder(1)
  InfrastructureComponentEntryDescription description =
      InfrastructureComponentEntryDescription();

  /// Configuration requirements.
  @SerializationOrder(2)
  InfrastructureComponentEntryConfiguration configuration =
      InfrastructureComponentEntryConfiguration();

  /// Integration lifecycle.
  @SerializationOrder(3)
  InfrastructureComponentEntryIntegration integration =
      InfrastructureComponentEntryIntegration();

  /// Operational behavior.
  @SerializationOrder(4)
  InfrastructureComponentEntryOperations operations =
      InfrastructureComponentEntryOperations();

  /// Resiliency behavior.
  @SerializationOrder(5)
  InfrastructureComponentEntryResiliency resiliency =
      InfrastructureComponentEntryResiliency();
}

/// Purpose and technology choices.
@StandardReferences(
  [
    'DRY — reusable component design',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures the purpose, capabilities, and technology stack of the infrastructure component.',
)
@SectionId('ICED')
class InfrastructureComponentEntryDescription {
  @Form([
    Field('purpose', String, 'Purpose',
        hint: 'What infrastructure need this addresses'),
    Field('capabilities', String, 'Capabilities',
        hint: 'Infrastructure capabilities provided'),
    Field('technologyStack', String, 'Technology Stack',
        hint: 'Underlying technologies'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Configuration requirements.
@StandardReferences(
  [
    'DRY — reusable component design',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures the configuration options, environment variables, and secrets required by the infrastructure component.',
)
@SectionId('ICEC')
class InfrastructureComponentEntryConfiguration {
  @Form([
    Field('configurationOptions', String, 'Configuration Options',
        hint: 'Available configuration'),
    Field('environmentVariables', String, 'Environment Variables',
        hint: 'Required environment variables'),
    Field('secrets', String, 'Secrets', hint: 'Required secrets'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Integration lifecycle.
@StandardReferences(
  [
    'DRY — reusable component design',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures the service interface and initialization/shutdown lifecycle of the infrastructure component.',
)
@SectionId('ICEI')
class InfrastructureComponentEntryIntegration {
  @Form([
    Field('serviceInterface', String, 'Service Interface',
        hint: 'Public service interface'),
    Field('initializationProcess', String, 'Initialization Process',
        hint: 'How to initialize'),
    Field('shutdownProcess', String, 'Shutdown Process',
        hint: 'Graceful shutdown procedure'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Operational behavior.
@StandardReferences(
  [
    'DRY — reusable component design',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures the monitoring, health-check, and scalability operational behavior of the infrastructure component.',
)
@SectionId('ICEO')
class InfrastructureComponentEntryOperations {
  @Form([
    Field('monitoring', String, 'Monitoring',
        hint: 'Monitoring and observability'),
    Field('healthCheck', String, 'Health Check',
        hint: 'Health check implementation'),
    Field('scalability', String, 'Scalability',
        hint: 'Scaling considerations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Resiliency behavior.
@StandardReferences(
  [
    'DRY — reusable component design',
    'ISO/IEC 25010 — reliability quality attributes',
  ],
  'Captures the failure handling, retry, and circuit-breaker resiliency behavior of the infrastructure component.',
)
@SectionId('ICER')
class InfrastructureComponentEntryResiliency {
  @Form([
    Field('failureHandling', String, 'Failure Handling',
        hint: 'How failures are handled'),
    Field('retryPolicy', String, 'Retry Policy',
        hint: 'Retry configuration'),
    Field('circuitBreaker', String, 'Circuit Breaker',
        hint: 'Circuit breaker configuration'),
    Field('notes', String, 'Notes',
        hint: 'Additional infrastructure notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Third-party library entry.
@StandardReferences(
  [
    'package management (pub / npm / Maven) — dependency management',
    'Semantic Versioning (SemVer) — library versioning',
  ],
  'Captures a third-party framework or library, its source, version, and evaluation for reuse.',
)
@SectionId('THPALI')
class ThirdPartyLibraryEntry {
  @Form([
    Field('libraryName', String, 'Library Name',
        required: true, hint: 'Package name'),
    Field('packageSource', String, 'Package Source',
        hint: 'pub.dev, npm, Maven, GitHub'),
    Field('version', String, 'Version',
        required: true, hint: 'Version constraint'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Evaluation and selection.
  @SerializationOrder(1)
  ThirdPartyLibraryEntryEvaluation evaluation =
      ThirdPartyLibraryEntryEvaluation();

  /// Licensing details.
  @SerializationOrder(2)
  ThirdPartyLibraryEntryLicense licenseInfo =
      ThirdPartyLibraryEntryLicense();

  /// Risk profile.
  @SerializationOrder(3)
  ThirdPartyLibraryEntryRisk risk = ThirdPartyLibraryEntryRisk();

  /// Usage and upgrade strategy.
  @SerializationOrder(4)
  ThirdPartyLibraryEntryUsage usage = ThirdPartyLibraryEntryUsage();

  /// Monitoring and notes.
  @SerializationOrder(5)
  ThirdPartyLibraryEntryMonitoring monitoring =
      ThirdPartyLibraryEntryMonitoring();
}

/// Evaluation and selection.
@StandardReferences(
  [
    'package management (pub / npm / Maven) — dependency management',
    'Semantic Versioning (SemVer) — library versioning',
  ],
  'Captures the evaluation, alternatives considered, and rationale for selecting the third-party library.',
)
@SectionId('TPLEE')
class ThirdPartyLibraryEntryEvaluation {
  @Form([
    Field('homepage', String, 'Homepage', hint: 'Library homepage URL'),
    Field('purpose', String, 'Purpose', hint: 'Why this library is used'),
    Field('alternatives', String, 'Alternatives Considered',
        hint: 'Other options evaluated'),
    Field('selectionRationale', String, 'Selection Rationale',
        hint: 'Why this was chosen'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Licensing details.
@StandardReferences(
  [
    'package management (pub / npm / Maven) — dependency management',
    'Semantic Versioning (SemVer) — library versioning',
  ],
  'Captures the license, compliance status, and attribution requirements of the third-party library.',
)
@SectionId('TPLEL')
class ThirdPartyLibraryEntryLicense {
  @Form([
    Field('license', String, 'License',
        required: true, hint: 'MIT, Apache, GPL, BSD'),
    Field('licenseCompliance', String, 'License Compliance',
        hint: 'Compliance status'),
    Field('attributionRequired', bool, 'Attribution Required',
        hint: 'Requires attribution'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Risk profile.
@StandardReferences(
  [
    'package management (pub / npm / Maven) — dependency management',
    'Semantic Versioning (SemVer) — library versioning',
  ],
  'Captures the maintenance, community, security, and lock-in risk profile of the third-party library.',
)
@SectionId('TPLER')
class ThirdPartyLibraryEntryRisk {
  @Form([
    Field('maintenanceStatus', String, 'Maintenance Status',
        hint: 'Active, Maintained, Stale, Abandoned'),
    Field('communitySize', String, 'Community Size',
        hint: 'Community support level'),
    Field('securityHistory', String, 'Security History',
        hint: 'Known security issues'),
    Field('vendorLockIn', String, 'Vendor Lock-In Risk',
        hint: 'Lock-in considerations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Usage and upgrade strategy.
@StandardReferences(
  [
    'package management (pub / npm / Maven) — dependency management',
    'Semantic Versioning (SemVer) — library versioning',
  ],
  'Captures where the third-party library is used and the strategy for wrapping and upgrading it.',
)
@SectionId('TPLEU')
class ThirdPartyLibraryEntryUsage {
  @Form([
    Field('usageScope', String, 'Usage Scope',
        hint: 'Where in project this is used'),
    Field('wrapperRequired', bool, 'Wrapper Required',
        hint: 'Should be wrapped in abstraction'),
    Field('upgradeStrategy', String, 'Upgrade Strategy',
        hint: 'How upgrades are handled'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Monitoring and notes.
@StandardReferences(
  [
    'package management (pub / npm / Maven) — dependency management',
    'Semantic Versioning (SemVer) — library versioning',
  ],
  'Captures how updates and deprecations of the third-party library are monitored and handled.',
)
@SectionId('TPLEM')
class ThirdPartyLibraryEntryMonitoring {
  @Form([
    Field('updateNotifications', String, 'Update Notifications',
        hint: 'How updates are monitored'),
    Field('deprecationHandling', String, 'Deprecation Handling',
        hint: 'Plan if library deprecated'),
    Field('notes', String, 'Notes', hint: 'Additional library notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Component governance and maintenance policies.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures the ownership model and governance policies for maintaining the shared component library.',
)
@SectionId('COGO')
class ComponentGovernance {
  @Form([
    Field('ownershipModel', String, 'Ownership Model',
        hint: 'Central team, federated, individual'),
    Field('sharedComponentsTeam', String, 'Shared Components Team',
        hint: 'Team responsible for shared components'),
    Field('escalationPath', String, 'Escalation Path',
        hint: 'How issues are escalated'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Contribution governance.
  @SerializationOrder(1)
  ComponentGovernanceContribution contribution =
      ComponentGovernanceContribution();

  /// Quality expectations.
  @SerializationOrder(2)
  ComponentGovernanceQuality quality = ComponentGovernanceQuality();

  /// Lifecycle policies.
  @SerializationOrder(3)
  ComponentGovernanceLifecycle lifecycle = ComponentGovernanceLifecycle();

  /// Metrics and notes.
  @SerializationOrder(4)
  ComponentGovernanceMetrics metrics = ComponentGovernanceMetrics();
}

/// Contribution governance.
@StandardReferences(
  [
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures the contribution guidelines, review process, and acceptance criteria for shared components.',
)
@SectionId('COGOCO')
class ComponentGovernanceContribution {
  @Form([
    Field('contributionGuidelines', String, 'Contribution Guidelines',
        hint: 'How to contribute'),
    Field('reviewProcess', String, 'Review Process',
        hint: 'Review process for contributions'),
    Field('acceptanceCriteria', String, 'Acceptance Criteria',
        hint: 'Criteria for accepting components'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Quality expectations.
@StandardReferences(
  [
    'ISO/IEC 25010 — maintainability quality attributes',
    'Domain-Driven Design — bounded contexts / modules',
  ],
  'Captures the quality, testing, and documentation standards required of governed shared components.',
)
@SectionId('COGOQU')
class ComponentGovernanceQuality {
  @Form([
    Field('qualityStandards', String, 'Quality Standards',
        hint: 'Quality requirements for shared components'),
    Field('testingRequirements', String, 'Testing Requirements',
        hint: 'Required test coverage'),
    Field('documentationRequirements', String, 'Documentation Requirements',
        hint: 'Required documentation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Lifecycle policies.
@StandardReferences(
  [
    'ISO/IEC 25010 — maintainability quality attributes',
    'Domain-Driven Design — bounded contexts / modules',
  ],
  'Captures the promotion, deprecation, and retirement policies governing the component lifecycle.',
)
@SectionId('COGOLI')
class ComponentGovernanceLifecycle {
  @Form([
    Field('promotionProcess', String, 'Promotion Process',
        hint: 'How components move to production'),
    Field('deprecationProcess', String, 'Deprecation Process',
        hint: 'How components are deprecated'),
    Field('retirementProcess', String, 'Retirement Process',
        hint: 'How components are retired'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Metrics and notes.
@StandardReferences(
  [
    'ISO/IEC 25010 — maintainability quality attributes',
    'Domain-Driven Design — bounded contexts / modules',
  ],
  'Captures the metrics and success criteria used to measure component adoption and quality.',
)
@SectionId('COGOME')
class ComponentGovernanceMetrics {
  @Form([
    Field('adoptionMetrics', String, 'Adoption Metrics',
        hint: 'How usage is tracked'),
    Field('qualityMetrics', String, 'Quality Metrics',
        hint: 'Quality measurements'),
    Field('successCriteria', String, 'Success Criteria',
        hint: 'How success is measured'),
    Field('notes', String, 'Notes', hint: 'Additional governance notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Component discovery and registry configuration.
@StandardReferences(
  [
    'DRY — reusable component design',
    'ISO/IEC 25010 — reusability quality attributes',
  ],
  'Captures the registry infrastructure enabling discovery, cataloguing, and reuse of shared components.',
)
@SectionId('CORE')
class ComponentRegistry {
  @Form([
    Field('registryType', String, 'Registry Type',
        hint: 'Wiki, catalog tool, package registry'),
    Field('registryLocation', String, 'Registry Location',
        hint: 'URL or location of registry'),
    Field('searchCapabilities', String, 'Search Capabilities',
        hint: 'How to search for components'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Metadata requirements.
  @SerializationOrder(1)
  ComponentRegistryMetadata metadata = ComponentRegistryMetadata();

  /// Discovery workflow.
  @SerializationOrder(2)
  ComponentRegistryDiscovery discovery = ComponentRegistryDiscovery();

  /// Documentation requirements.
  @SerializationOrder(3)
  ComponentRegistryDocumentation documentation =
      ComponentRegistryDocumentation();

  /// Update communication.
  @SerializationOrder(4)
  ComponentRegistryUpdates updates = ComponentRegistryUpdates();
}

/// Metadata requirements.
@StandardReferences(
  [
    'DRY — reusable component design',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures the metadata, tagging, and categorization requirements for components in the registry.',
)
@SectionId('COREME')
class ComponentRegistryMetadata {
  @Form([
    Field('requiredMetadata', String, 'Required Metadata',
        hint: 'Metadata required for each component'),
    Field('taggingConventions', String, 'Tagging Conventions',
        hint: 'How components are tagged'),
    Field('categorizationScheme', String, 'Categorization Scheme',
        hint: 'How components are categorized'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Discovery workflow.
@StandardReferences(
  [
    'DRY — reusable component design',
    'ISO/IEC 25010 — reusability quality attributes',
  ],
  'Captures the workflow by which developers discover and are recommended existing reusable components.',
)
@SectionId('COREDI')
class ComponentRegistryDiscovery {
  @Form([
    Field('discoveryProcess', String, 'Discovery Process',
        hint: 'How developers find components'),
    Field('recommendationEngine', String, 'Recommendation Engine',
        hint: 'Component recommendations'),
    Field('integration', String, 'IDE Integration',
        hint: 'Integration with development tools'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation requirements.
@StandardReferences(
  [
    'DRY — reusable component design',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures the documentation standards and formats required for registered reusable components.',
)
@SectionId('COREDO')
class ComponentRegistryDocumentation {
  @Form([
    Field('documentationFormat', String, 'Documentation Format',
        hint: 'Standard documentation format'),
    Field('exampleRequirements', String, 'Example Requirements',
        hint: 'Required examples'),
    Field('apiDocGeneration', String, 'API Doc Generation',
        hint: 'Automated API documentation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Update communication.
@StandardReferences(
  [
    'DRY — reusable component design',
    'ISO/IEC 25010 — maintainability quality attributes',
  ],
  'Captures how component updates and changes are communicated to consumers through the registry.',
)
@SectionId('COREUP')
class ComponentRegistryUpdates {
  @Form([
    Field('updateNotifications', String, 'Update Notifications',
        hint: 'How updates are communicated'),
    Field('changelogRequirements', String, 'Changelog Requirements',
        hint: 'Changelog format'),
    Field('migrationGuides', String, 'Migration Guides',
        hint: 'Migration documentation'),
    Field('notes', String, 'Notes', hint: 'Additional registry notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 8.3. Standard Application Software Requirements.
@DetailedIn(D06ArchitectureTechnologySpecification)
@SecondLevelSectionId(D06ArchitectureTechnologySpecification, 'ATS-STA')
@ContentHelp('''
Define requirements for standard software, third-party components, and
compatibility with existing IT infrastructure. Enterprise integration
often requires alignment with established platforms and protocols.

**Subsections**:
- **Compatibility Requirements**: OS compatibility, browser support,
  database compatibility, enterprise system integration
- **Standards Compliance**: IT standards (ISO, IEEE, NIST), industry
  protocols, regulatory requirements, certification needs

**Evaluation Criteria for Commercial/Open-Source Software**:
- Functional fit with requirements
- Total cost of ownership (license, support, training)
- Vendor stability and roadmap alignment
- Community health and update frequency
- Security track record and vulnerability response
- Integration capabilities and API availability
- Data portability and exit strategy

**Enterprise Considerations**:
- Existing enterprise licenses and preferred vendors
- IT governance and procurement processes
- Support agreements and SLAs
- Training and documentation availability
- Scalability and high-availability options
''')
@StandardReferences(
  [
    'package management (pub / npm / Maven) — dependency management',
    'Semantic Versioning (SemVer) — library versioning',
  ],
  'Captures requirements for standard, third-party, and commercial software and their compatibility with existing infrastructure.',
)
@SectionId('SSR')
class StandardSoftwareRequirements {
  @ContentHelp('''
Provide an overview of standard software requirements approach.

**Include**:
- Build vs. buy decision criteria
- Preferred vendor and technology partners
- Compatibility priority matrix
- Standards compliance roadmap
- Migration plans for legacy systems

**Best Practices**:
- Create technology evaluation scorecards
- Document vendor relationship management
- Plan for software sunset and replacement
- Maintain compatibility testing matrix
- Establish proof-of-concept requirements
''')
  @SerializationOrder(0)
  String? content;

  /// 8.3.1. Compatibility Requirements.
  @SerializationOrder(1)
  CompatibilityRequirementsSection compatibilityRequirements =
      CompatibilityRequirementsSection();

  /// 8.3.2. Standards Compliance.
  @SerializationOrder(2)
  StandardsComplianceSection standardsCompliance = StandardsComplianceSection();
}

// =============================================================================
// 8.3.1. Compatibility Requirements
// =============================================================================

/// 8.3.1. Compatibility Requirements.
///
/// Compatibility requirements with existing IT infrastructure, standard software,
/// and enterprise systems.
@ContentHelp('''
Specify compatibility requirements with existing infrastructure, software,
and enterprise systems. Compatibility ensures smooth integration and
avoids costly surprises during deployment.

**Compatibility Dimensions**:
- **Operating System**: Desktop OS (Windows, macOS, Linux), server OS,
  mobile OS (iOS, Android), embedded systems
- **Browser**: Chrome, Firefox, Safari, Edge with version minimums;
  progressive enhancement vs. graceful degradation strategy
- **Database**: RDBMS (PostgreSQL, MySQL, SQL Server, Oracle), NoSQL
  (MongoDB, Redis, Elasticsearch), compatibility modes and drivers
- **Enterprise Systems**: ERP (SAP, Oracle), CRM (Salesforce), LDAP/AD,
  SSO providers, message queues, API gateways

**Compatibility Testing**:
- Browser testing matrix and automation (Playwright, Selenium)
- OS compatibility testing (virtual machines, device farms)
- Database compatibility and migration testing
- Integration testing with enterprise systems
- Backward compatibility verification

**Versioning Strategy**:
- API versioning approach (URL, header, media type)
- Database schema version management
- Client version compatibility windows
- Feature flags for gradual rollouts
''')
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the compatibility requirements with existing OS, browsers, databases, enterprise and legacy systems, and third-party software.',
)
@SectionId('CRS')
class CompatibilityRequirementsSection {
  @ContentHelp('''
Provide an overview of compatibility requirements and testing strategy.

**Include**:
- Critical compatibility requirements
- Testing approach and coverage
- Known compatibility limitations
- Browser/OS support policy
- Deprecation and sunset timeline

**Best Practices**:
- Maintain live compatibility matrix
- Automate compatibility testing in CI
- Define clear support tiers (full, limited, best-effort)
- Plan for mobile OS release cycles
- Document workarounds for known issues
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of compatibility strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Operating system compatibility requirements.
  @StandardReferences(
    [
      'POSIX / ISO/IEC 9945 — operating-system interface',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'The operating systems the system must support.',
  )
  @SectionId('OSCOEN-OSCO-LST')
  @SectionIdPattern('OSCOEN-OSCO-xxx')
  @ContentHelp('Add one entry per supported operating system.')
  @SerializationOrder(2)
  List<OsCompatibilityEntry> osCompatibility = [];

  /// Browser compatibility requirements.
  @StandardReferences(
    [
      'WHATWG / W3C — web platform / browser standards',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'The browsers the system must support.',
  )
  @SectionId('BRCOEN-BROW-LST')
  @SectionIdPattern('BRCOEN-BROW-xxx')
  @ContentHelp('Add one entry per supported browser.')
  @SerializationOrder(3)
  List<BrowserCompatibilityEntry> browserCompatibility = [];

  /// Database compatibility requirements.
  @StandardReferences(
    [
      'ISO/IEC 9075 (SQL) — relational database standard',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'The databases the system must remain compatible with.',
  )
  @SectionId('DACOEN-DATA-LST')
  @SectionIdPattern('DACOEN-DATA-xxx')
  @ContentHelp('Add one entry per supported database.')
  @SerializationOrder(4)
  List<DatabaseCompatibilityEntry> databaseCompatibility = [];

  /// Enterprise system compatibility requirements.
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The enterprise systems the system must integrate with.',
  )
  @SectionId('ESCE-ENTE-LST')
  @SectionIdPattern('ESCE-ENTE-xxx')
  @ContentHelp('Add one entry per enterprise system.')
  @SerializationOrder(5)
  List<EnterpriseSystemCompatibilityEntry> enterpriseSystemCompatibility = [];

  /// API and protocol compatibility requirements.
  @StandardReferences(
    [
      'OpenAPI / REST — API interoperability',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'The APIs and protocols the system must remain compatible with.',
  )
  @SectionId('APCP-APIC-LST')
  @SectionIdPattern('APCP-APIC-xxx')
  @ContentHelp('Add one entry per API or protocol.')
  @SerializationOrder(6)
  List<ApiCompatibilityEntry> apiCompatibility = [];

  /// Legacy system compatibility requirements.
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The legacy systems the system must remain compatible with.',
  )
  @SectionId('LECOEN-LEGA-LST')
  @SectionIdPattern('LECOEN-LEGA-xxx')
  @ContentHelp('Add one entry per legacy system.')
  @SerializationOrder(7)
  List<LegacyCompatibilityEntry> legacyCompatibility = [];

  /// Mobile device compatibility requirements.
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The mobile platforms the system must support.',
  )
  @SectionId('MOCOEN-MOBI-LST')
  @SectionIdPattern('MOCOEN-MOBI-xxx')
  @ContentHelp('Add one entry per supported mobile platform.')
  @SerializationOrder(8)
  List<MobileCompatibilityEntry> mobileCompatibility = [];

  /// Third-party software compatibility requirements.
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The third-party software the system must co-exist with.',
  )
  @SectionId('TPCE-THIR-LST')
  @SectionIdPattern('TPCE-THIR-xxx')
  @ContentHelp('Add one entry per third-party software product.')
  @SerializationOrder(9)
  List<ThirdPartyCompatibilityEntry> thirdPartyCompatibility = [];

  /// Data format and encoding compatibility.
  @SerializationOrder(10)
  DataFormatCompatibility dataFormatCompatibility = DataFormatCompatibility();

  /// Backwards compatibility requirements.
  @SerializationOrder(11)
  BackwardsCompatibilityRequirements backwardsCompatibility =
      BackwardsCompatibilityRequirements();

  /// Interoperability requirements.
  @SerializationOrder(12)
  InteroperabilityRequirements interoperability = InteroperabilityRequirements();
}

/// Operating system compatibility entry.
@StandardReferences(
  [
    'POSIX / ISO/IEC 9945 — operating-system interface',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Describes an operating system and version range the system must remain compatible with.',
)
@SectionId('OCE')
class OsCompatibilityEntry {
  @Form([
    Field('osName', String, 'Operating System',
        required: true, hint: 'E.g., Windows, macOS, Linux, iOS, Android'),
    Field('osFamily', String, 'OS Family',
        hint: 'Windows, Unix, Mobile'),
    Field('minVersion', String, 'Minimum Version',
        required: true, hint: 'Minimum supported version'),
    Field('maxVersion', String, 'Maximum Version',
        hint: 'Maximum tested version'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Support level and prioritization.
  @SerializationOrder(1)
  OsCompatibilityEntrySupport support = OsCompatibilityEntrySupport();

  /// Platform requirements.
  @SerializationOrder(2)
  OsCompatibilityEntryRequirements requirements =
      OsCompatibilityEntryRequirements();

  /// Testing expectations.
  @SerializationOrder(3)
  OsCompatibilityEntryTesting testing = OsCompatibilityEntryTesting();

  /// Lifecycle notes.
  @SerializationOrder(4)
  OsCompatibilityEntryLifecycle lifecycle = OsCompatibilityEntryLifecycle();
}

/// Support level and prioritization.
@StandardReferences(
  [
    'POSIX / ISO/IEC 9945 — operating-system interface',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures the support level, priority, and target market share for the operating system.',
)
@SectionId('OCES')
class OsCompatibilityEntrySupport {
  @Form([
    Field('supportLevel', String, 'Support Level',
        hint: 'Full, Partial, Best-effort, Unsupported'),
    Field('priority', String, 'Priority',
        hint: 'Primary, Secondary, Edge case'),
    Field('marketShare', String, 'Market Share',
        hint: 'Target market share percentage'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Platform requirements.
@StandardReferences(
  [
    'POSIX / ISO/IEC 9945 — operating-system interface',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures the CPU architectures, memory, storage, and prerequisites required on the operating system.',
)
@SectionId('OCER')
class OsCompatibilityEntryRequirements {
  @Form([
    Field('architectures', String, 'Architectures',
        hint: 'x64, ARM64, x86'),
    Field('minMemory', String, 'Minimum Memory',
        hint: 'Minimum RAM required'),
    Field('minStorage', String, 'Minimum Storage',
        hint: 'Minimum disk space required'),
    Field('prerequisites', String, 'Prerequisites',
        hint: 'Required runtime, frameworks'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing expectations.
@StandardReferences(
  [
    'POSIX / ISO/IEC 9945 — operating-system interface',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures the test environment, frequency, and known issues for the operating system.',
)
@SectionId('OCET')
class OsCompatibilityEntryTesting {
  @Form([
    Field('testEnvironment', String, 'Test Environment',
        hint: 'VM, physical, cloud'),
    Field('testFrequency', String, 'Test Frequency',
        hint: 'Every release, periodic, on-demand'),
    Field('knownIssues', String, 'Known Issues',
        hint: 'OS-specific issues'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Lifecycle notes.
@StandardReferences(
  [
    'POSIX / ISO/IEC 9945 — operating-system interface',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures special handling and end-of-life planning for the operating system.',
)
@SectionId('OCEL')
class OsCompatibilityEntryLifecycle {
  @Form([
    Field('specialConsiderations', String, 'Special Considerations',
        hint: 'Special handling for this OS'),
    Field('eolPlanning', String, 'EOL Planning',
        hint: 'Plan for OS end-of-life'),
    Field('notes', String, 'Notes', hint: 'Additional OS compatibility notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Browser compatibility entry.
@StandardReferences(
  [
    'WHATWG / W3C — web platform / browser standards',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Describes a browser and version range the system must remain compatible with.',
)
@SectionId('BROCOMENT')
class BrowserCompatibilityEntry {
  @Form([
    Field('browserName', String, 'Browser',
        required: true, hint: 'E.g., Chrome, Firefox, Safari, Edge'),
    Field('browserEngine', String, 'Browser Engine',
        hint: 'Chromium, Gecko, WebKit'),
    Field('minVersion', String, 'Minimum Version',
        required: true, hint: 'Minimum supported version'),
    Field('maxVersion', String, 'Maximum Version',
        hint: 'Maximum tested version'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Support level and priority.
  @SerializationOrder(1)
  BrowserCompatibilityEntrySupport support = BrowserCompatibilityEntrySupport();

  /// Feature support requirements.
  @SerializationOrder(2)
  BrowserCompatibilityEntryFeatures features = BrowserCompatibilityEntryFeatures();

  /// Mobile and PWA support.
  @SerializationOrder(3)
  BrowserCompatibilityEntryMobile mobile = BrowserCompatibilityEntryMobile();

  /// Testing notes.
  @SerializationOrder(4)
  BrowserCompatibilityEntryTesting testing = BrowserCompatibilityEntryTesting();
}

/// Support level and priority.
@StandardReferences(
  [
    'WHATWG / W3C — web platform / browser standards',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures the support level, priority, and expected user share for the browser.',
)
@SectionId('BRCOENSU')
class BrowserCompatibilityEntrySupport {
  @Form([
    Field('supportLevel', String, 'Support Level',
        hint: 'Full, Partial, Polyfill required, Unsupported'),
    Field('priority', String, 'Priority',
        hint: 'Primary, Secondary, Edge case'),
    Field('userShare', String, 'User Share',
        hint: 'Expected user share percentage'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Feature support requirements.
@StandardReferences(
  [
    'WHATWG / W3C — web platform / browser standards',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures the required browser features, polyfills, and graceful-degradation strategy.',
)
@SectionId('BCEF')
class BrowserCompatibilityEntryFeatures {
  @Form([
    Field('requiredFeatures', String, 'Required Features',
        hint: 'JS features, APIs required'),
    Field('polyfills', String, 'Polyfills Required',
        hint: 'Polyfills needed'),
    Field('gracefulDegradation', String, 'Graceful Degradation',
        hint: 'Fallback behavior'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Mobile and PWA support.
@StandardReferences(
  [
    'WHATWG / W3C — web platform / browser standards',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures mobile-browser support, PWA capability, and offline support requirements.',
)
@SectionId('BCEM')
class BrowserCompatibilityEntryMobile {
  @Form([
    Field('mobileSupport', String, 'Mobile Support',
        hint: 'Mobile browser support level'),
    Field('pwa', String, 'PWA Support',
        hint: 'Progressive Web App support'),
    Field('offlineSupport', String, 'Offline Support',
        hint: 'Offline capability'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing notes.
@StandardReferences(
  [
    'WHATWG / W3C — web platform / browser standards',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures where and how the browser is tested, including automation and known issues.',
)
@SectionId('BRCOENTE')
class BrowserCompatibilityEntryTesting {
  @Form([
    Field('testPlatforms', String, 'Test Platforms',
        hint: 'Where browser is tested'),
    Field('automatedTesting', String, 'Automated Testing',
        hint: 'Automated browser testing'),
    Field('knownIssues', String, 'Known Issues',
        hint: 'Browser-specific issues'),
    Field('notes', String, 'Notes',
        hint: 'Additional browser compatibility notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Database compatibility entry.
@StandardReferences(
  [
    'ISO/IEC 9075 (SQL) — relational database standard',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Describes a database engine and version range the system must remain compatible with.',
)
@SectionId('DATCOMENT')
class DatabaseCompatibilityEntry {
  @Form([
    Field('databaseName', String, 'Database',
        required: true, hint: 'E.g., PostgreSQL, MySQL, MongoDB, SQLite'),
    Field('databaseType', String, 'Type',
        hint: 'RDBMS, Document, Key-Value, Graph'),
    Field('minVersion', String, 'Minimum Version',
        required: true, hint: 'Minimum supported version'),
    Field('maxVersion', String, 'Maximum Version',
        hint: 'Maximum tested version'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Support options.
  @SerializationOrder(1)
  DatabaseCompatibilityEntrySupport support =
      DatabaseCompatibilityEntrySupport();

  /// Feature requirements.
  @SerializationOrder(2)
  DatabaseCompatibilityEntryFeatures features =
      DatabaseCompatibilityEntryFeatures();

  /// Connection requirements.
  @SerializationOrder(3)
  DatabaseCompatibilityEntryConnection connection =
      DatabaseCompatibilityEntryConnection();

  /// Performance and notes.
  @SerializationOrder(4)
  DatabaseCompatibilityEntryPerformance performance =
      DatabaseCompatibilityEntryPerformance();
}

/// Support options.
@StandardReferences(
  [
    'ISO/IEC 9075 (SQL) — relational database standard',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures the support level and cloud-hosted variants for the database.',
)
@SectionId('DCES')
class DatabaseCompatibilityEntrySupport {
  @Form([
    Field('supportLevel', String, 'Support Level',
        hint: 'Primary, Secondary, Experimental'),
    Field('cloudVariants', String, 'Cloud Variants',
        hint: 'AWS RDS, Azure SQL, Cloud SQL'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Feature requirements.
@StandardReferences(
  [
    'ISO/IEC 9075 (SQL) — relational database standard',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures the required and optional database features and extensions the system depends on.',
)
@SectionId('DCEF')
class DatabaseCompatibilityEntryFeatures {
  @Form([
    Field('requiredFeatures', String, 'Required Features',
        hint: 'Required database features'),
    Field('optionalFeatures', String, 'Optional Features',
        hint: 'Optional performance features'),
    Field('extensions', String, 'Extensions',
        hint: 'Required extensions/plugins'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Connection requirements.
@StandardReferences(
  [
    'ISO/IEC 9075 (SQL) — relational database standard',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures the connection driver, pooling, and SSL/TLS requirements for the database.',
)
@SectionId('DCEC')
class DatabaseCompatibilityEntryConnection {
  @Form([
    Field('connectionDriver', String, 'Connection Driver',
        hint: 'Driver/client library'),
    Field('connectionPooling', String, 'Connection Pooling',
        hint: 'Pooling requirements'),
    Field('ssl', String, 'SSL Requirements',
        hint: 'SSL/TLS requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Performance and notes.
@StandardReferences(
  [
    'ISO/IEC 9075 (SQL) — relational database standard',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures database-specific performance notes, scaling considerations, and known limitations.',
)
@SectionId('DCEP')
class DatabaseCompatibilityEntryPerformance {
  @Form([
    Field('performanceNotes', String, 'Performance Notes',
        hint: 'DB-specific performance'),
    Field('scalingConsiderations', String, 'Scaling Considerations',
        hint: 'Scaling with this database'),
    Field('knownLimitations', String, 'Known Limitations',
        hint: 'Database-specific limitations'),
    Field('notes', String, 'Notes',
        hint: 'Additional database compatibility notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Enterprise system compatibility entry.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Describes an enterprise system (ERP, CRM, etc.) the solution must integrate and remain compatible with.',
)
@SectionId('ENSYCOEN')
class EnterpriseSystemCompatibilityEntry {
  @Form([
    Field('systemName', String, 'System Name',
        required: true, hint: 'E.g., SAP, Salesforce, Oracle ERP'),
    Field('systemType', String, 'System Type',
        hint: 'ERP, CRM, HR, Finance, Supply Chain'),
    Field('vendor', String, 'Vendor', hint: 'System vendor'),
    Field('version', String, 'Version', hint: 'Supported versions'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Integration details.
  @SerializationOrder(1)
  EnterpriseSystemCompatibilityEntryIntegration integration =
      EnterpriseSystemCompatibilityEntryIntegration();

  /// Authentication and access.
  @SerializationOrder(2)
  EnterpriseSystemCompatibilityEntrySecurity security =
      EnterpriseSystemCompatibilityEntrySecurity();

  /// Setup requirements.
  @SerializationOrder(3)
  EnterpriseSystemCompatibilityEntryRequirements requirements =
      EnterpriseSystemCompatibilityEntryRequirements();

  /// Testing and notes.
  @SerializationOrder(4)
  EnterpriseSystemCompatibilityEntryTesting testing =
      EnterpriseSystemCompatibilityEntryTesting();
}

/// Integration details.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the integration method, protocol, data exchanged, and frequency for the enterprise system.',
)
@SectionId('ESCEI')
class EnterpriseSystemCompatibilityEntryIntegration {
  @Form([
    Field('integrationMethod', String, 'Integration Method',
        hint: 'API, File transfer, Middleware, Direct'),
    Field('integrationProtocol', String, 'Integration Protocol',
        hint: 'REST, SOAP, OData, BAPI'),
    Field('dataExchange', String, 'Data Exchange',
        hint: 'Data exchanged with system'),
    Field('frequency', String, 'Frequency',
        hint: 'Real-time, batch, on-demand'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Authentication and access.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the authentication, authorization, and SSO integration with the enterprise system.',
)
@SectionId('ESCES')
class EnterpriseSystemCompatibilityEntrySecurity {
  @Form([
    Field('authentication', String, 'Authentication',
        hint: 'Auth method for system'),
    Field('authorization', String, 'Authorization',
        hint: 'Required permissions/roles'),
    Field('sso', String, 'SSO Integration',
        hint: 'Single sign-on support'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Setup requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the prerequisites, configuration, and customization needed to integrate the enterprise system.',
)
@SectionId('ESCER')
class EnterpriseSystemCompatibilityEntryRequirements {
  @Form([
    Field('prerequisites', String, 'Prerequisites',
        hint: 'Required adapters, middleware'),
    Field('configuration', String, 'Configuration',
        hint: 'Required configuration'),
    Field('customization', String, 'Customization',
        hint: 'Required customizations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing and notes.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the test environment and approach for verifying enterprise-system integration.',
)
@SectionId('ESCET')
class EnterpriseSystemCompatibilityEntryTesting {
  @Form([
    Field('testEnvironment', String, 'Test Environment',
        hint: 'Sandbox, dev instance'),
    Field('testApproach', String, 'Test Approach',
        hint: 'Integration testing approach'),
    Field('notes', String, 'Notes',
        hint: 'Additional enterprise compatibility notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// API and protocol compatibility entry.
@StandardReferences(
  [
    'OpenAPI / REST — API interoperability',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Describes an API or protocol and version range the system must remain compatible with.',
)
@SectionId('APCP')
class ApiCompatibilityEntry {
  @Form([
    Field('apiName', String, 'API/Protocol Name',
        required: true, hint: 'Name of API or protocol'),
    Field('apiType', String, 'API Type',
        hint: 'REST, GraphQL, gRPC, SOAP, WebSocket'),
    Field('version', String, 'Version',
        required: true, hint: 'Supported API versions'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Compatibility policy.
  @SerializationOrder(1)
  ApiCompatibilityEntryPolicy policy = ApiCompatibilityEntryPolicy();

  /// Data-format requirements.
  @SerializationOrder(2)
  ApiCompatibilityEntryFormat format = ApiCompatibilityEntryFormat();

  /// Transport requirements.
  @SerializationOrder(3)
  ApiCompatibilityEntryTransport transportDetails =
      ApiCompatibilityEntryTransport();

  /// Specification references.
  @SerializationOrder(4)
  ApiCompatibilityEntrySpecification specification =
      ApiCompatibilityEntrySpecification();
}

/// Compatibility policy.
@StandardReferences(
  [
    'OpenAPI / REST — API interoperability',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures the API versioning strategy, backwards-compatibility stance, and deprecation policy.',
)
@SectionId('APCOENPO')
class ApiCompatibilityEntryPolicy {
  @Form([
    Field('versioningStrategy', String, 'Versioning Strategy',
        hint: 'URL path, header, query param'),
    Field('backwardsCompatibility', String, 'Backwards Compatibility',
        hint: 'Support for older versions'),
    Field('deprecationPolicy', String, 'Deprecation Policy',
        hint: 'How deprecated APIs handled'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data-format requirements.
@StandardReferences(
  [
    'OpenAPI / REST — API interoperability',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures the data format, encoding, and compression the API must interoperate with.',
)
@SectionId('ACEF')
class ApiCompatibilityEntryFormat {
  @Form([
    Field('dataFormat', String, 'Data Format',
        hint: 'JSON, XML, Protobuf'),
    Field('encoding', String, 'Encoding',
        hint: 'UTF-8, character encoding'),
    Field('compression', String, 'Compression',
        hint: 'gzip, deflate support'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Transport requirements.
@StandardReferences(
  [
    'OpenAPI / REST — API interoperability',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures the transport, security, and authentication requirements for the API.',
)
@SectionId('APCOENTR')
class ApiCompatibilityEntryTransport {
  @Form([
    Field('transport', String, 'Transport',
        hint: 'HTTP, HTTPS, WebSocket'),
    Field('security', String, 'Security',
        hint: 'TLS version, certificates'),
    Field('authentication', String, 'Authentication',
        hint: 'OAuth, API key, JWT'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Specification references.
@StandardReferences(
  [
    'OpenAPI / REST — API interoperability',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures the API specification references, schema validation, and conformance level required.',
)
@SectionId('ACES')
class ApiCompatibilityEntrySpecification {
  @Form([
    Field('specificationUrl', String, 'Specification URL',
        hint: 'OpenAPI, AsyncAPI URL'),
    Field('schemaValidation', String, 'Schema Validation',
        hint: 'Schema validation requirements'),
    Field('conformanceLevel', String, 'Conformance Level',
        hint: 'Strict, relaxed'),
    Field('notes', String, 'Notes', hint: 'Additional API compatibility notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Legacy system compatibility entry.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Describes a legacy system the solution must remain compatible with, including its age and technology.',
)
@SectionId('LCE')
class LegacyCompatibilityEntry {
  @Form([
    Field('systemName', String, 'System Name',
        required: true, hint: 'Legacy system name'),
    Field('systemAge', String, 'System Age',
        hint: 'How old the system is'),
    Field('technology', String, 'Technology',
        hint: 'COBOL, mainframe, etc.'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Integration approach.
  @SerializationOrder(1)
  LegacyCompatibilityEntryIntegration integration =
    LegacyCompatibilityEntryIntegration();

  /// Constraints and limitations.
  @SerializationOrder(2)
  LegacyCompatibilityEntryConstraints constraintsSection =
    LegacyCompatibilityEntryConstraints();

  /// Migration planning.
  @SerializationOrder(3)
  LegacyCompatibilityEntryMigration migration =
    LegacyCompatibilityEntryMigration();

  /// Risk management.
  @SerializationOrder(4)
  LegacyCompatibilityEntryRisk risk = LegacyCompatibilityEntryRisk();
}

/// Integration approach.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures how the system integrates with the legacy system, including the adapter approach and data access.',
)
@SectionId('LCEI')
class LegacyCompatibilityEntryIntegration {
  @Form([
  Field('integrationApproach', String, 'Integration Approach',
    hint: 'Wrapper, adapter, gateway'),
  Field('dataAccess', String, 'Data Access',
    hint: 'How legacy data is accessed'),
  Field('bidirectional', bool, 'Bidirectional',
    hint: 'Two-way data flow'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Constraints and limitations.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the constraints, limitations, and performance impact of integrating with the legacy system.',
)
@SectionId('LCEC')
class LegacyCompatibilityEntryConstraints {
  @Form([
  Field('constraints', String, 'Constraints',
    hint: 'Legacy system constraints'),
  Field('limitations', String, 'Limitations',
    hint: 'Integration limitations'),
  Field('performanceImpact', String, 'Performance Impact',
    hint: 'Impact on performance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Migration planning.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the migration path away from the legacy system, coexistence period, and data-sync approach.',
)
@SectionId('LCEM')
class LegacyCompatibilityEntryMigration {
  @Form([
  Field('migrationPath', String, 'Migration Path',
    hint: 'Path to replace legacy'),
  Field('coexistencePeriod', String, 'Coexistence Period',
    hint: 'How long systems coexist'),
  Field('dataSync', String, 'Data Synchronization',
    hint: 'How data stays in sync'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Risk management.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the risks of integrating with the legacy system and the fallback plan if integration fails.',
)
@SectionId('LCER')
class LegacyCompatibilityEntryRisk {
  @Form([
  Field('riskAssessment', String, 'Risk Assessment',
    hint: 'Risks of integration'),
  Field('fallbackPlan', String, 'Fallback Plan',
    hint: 'If integration fails'),
  Field('notes', String, 'Notes',
    hint: 'Additional legacy compatibility notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Mobile device compatibility entry.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Describes a mobile platform and OS-version range the system must remain compatible with.',
)
@SectionId('MOBCOMENT')
class MobileCompatibilityEntry {
  @Form([
    Field('platform', String, 'Platform',
        required: true, hint: 'iOS, Android, Cross-platform'),
    Field('minVersion', String, 'Minimum Version',
        required: true, hint: 'Minimum OS version'),
    Field('maxVersion', String, 'Maximum Version',
        hint: 'Maximum tested version'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Supported devices.
  @SerializationOrder(1)
  MobileCompatibilityEntryDevices devices = MobileCompatibilityEntryDevices();

  /// Hardware requirements.
  @SerializationOrder(2)
  MobileCompatibilityEntryHardware hardware =
      MobileCompatibilityEntryHardware();

  /// Platform capabilities.
  @SerializationOrder(3)
  MobileCompatibilityEntryCapabilities capabilities =
      MobileCompatibilityEntryCapabilities();

  /// Distribution details.
  @SerializationOrder(4)
  MobileCompatibilityEntryDistribution distribution =
      MobileCompatibilityEntryDistribution();
}

/// Supported devices.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the device types, screen sizes, and specific named devices the mobile app must support.',
)
@SectionId('MCED')
class MobileCompatibilityEntryDevices {
  @Form([
    Field('deviceTypes', String, 'Device Types',
        hint: 'Phone, tablet, foldable'),
    Field('screenSizes', String, 'Screen Sizes',
        hint: 'Supported screen sizes'),
    Field('specificDevices', String, 'Specific Devices',
        hint: 'Named device support'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Hardware requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the minimum device hardware (RAM, storage, sensors) required on the mobile platform.',
)
@SectionId('MCEH')
class MobileCompatibilityEntryHardware {
  @Form([
    Field('minRam', String, 'Minimum RAM', hint: 'Minimum device RAM'),
    Field('minStorage', String, 'Minimum Storage',
        hint: 'Minimum storage needed'),
    Field('requiredHardware', String, 'Required Hardware',
        hint: 'Camera, GPS, biometric'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Platform capabilities.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the mobile-platform capabilities the app relies on, such as permissions, background mode, and push.',
)
@SectionId('MCEC')
class MobileCompatibilityEntryCapabilities {
  @Form([
    Field('permissions', String, 'Permissions Required',
        hint: 'App permissions needed'),
    Field('backgroundMode', String, 'Background Mode',
        hint: 'Background execution'),
    Field('offlineSupport', String, 'Offline Support',
        hint: 'Offline capabilities'),
    Field('pushNotifications', String, 'Push Notifications',
        hint: 'Push notification support'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Distribution details.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the app-store and enterprise distribution channels for the mobile platform.',
)
@SectionId('MOCOENDI')
class MobileCompatibilityEntryDistribution {
  @Form([
    Field('appStore', String, 'App Store', hint: 'Distribution channels'),
    Field('enterpriseDistribution', String, 'Enterprise Distribution',
        hint: 'MDM, enterprise deployment'),
    Field('notes', String, 'Notes',
        hint: 'Additional mobile compatibility notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Third-party software compatibility entry.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Describes a third-party product the system must co-exist with, such as antivirus, firewall, or MDM software.',
)
@SectionId('THPACOEN')
class ThirdPartyCompatibilityEntry {
  @Form([
    Field('softwareName', String, 'Software Name',
        required: true, hint: 'Third-party software name'),
    Field('vendor', String, 'Vendor', hint: 'Software vendor'),
    Field('category', String, 'Category',
        hint: 'Antivirus, Firewall, MDM, Office'),
    Field('version', String, 'Version', hint: 'Supported versions'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Compatibility characteristics.
  @SerializationOrder(1)
  ThirdPartyCompatibilityEntryCompatibility compatibility =
      ThirdPartyCompatibilityEntryCompatibility();

  /// Integration characteristics.
  @SerializationOrder(2)
  ThirdPartyCompatibilityEntryIntegration integration =
      ThirdPartyCompatibilityEntryIntegration();

  /// Testing and certification details.
  @SerializationOrder(3)
  ThirdPartyCompatibilityEntryTesting testing =
      ThirdPartyCompatibilityEntryTesting();

  /// Support and escalation.
  @SerializationOrder(4)
  ThirdPartyCompatibilityEntrySupport support =
      ThirdPartyCompatibilityEntrySupport();
}

/// Compatibility characteristics.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the compatibility level, co-existence behavior, and known conflicts with third-party software.',
)
@SectionId('TPCEC')
class ThirdPartyCompatibilityEntryCompatibility {
  @Form([
    Field('compatibilityLevel', String, 'Compatibility Level',
        hint: 'Certified, Compatible, Known issues'),
    Field('coexistence', String, 'Coexistence',
        hint: 'How they work together'),
    Field('conflicts', String, 'Known Conflicts',
        hint: 'Known compatibility issues'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Integration characteristics.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the integration points, shared data, and operational coordination with third-party software.',
)
@SectionId('TPCEI')
class ThirdPartyCompatibilityEntryIntegration {
  @Form([
    Field('integrationPoints', String, 'Integration Points',
        hint: 'Where systems integrate'),
    Field('sharedData', String, 'Shared Data',
        hint: 'Data shared between systems'),
    Field('coordination', String, 'Coordination',
        hint: 'How operations coordinate'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing and certification details.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the test matrix, vendor certification status, and testing cadence for third-party co-existence.',
)
@SectionId('TPCET')
class ThirdPartyCompatibilityEntryTesting {
  @Form([
    Field('testMatrix', String, 'Test Matrix',
        hint: 'Combinations tested'),
    Field('certificationStatus', String, 'Certification Status',
        hint: 'Vendor certification'),
    Field('testFrequency', String, 'Test Frequency',
        hint: 'How often tested'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Support and escalation.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the joint support arrangement and escalation path for co-existing third-party software.',
)
@SectionId('TPCES')
class ThirdPartyCompatibilityEntrySupport {
  @Form([
    Field('supportArrangement', String, 'Support Arrangement',
        hint: 'Joint support process'),
    Field('escalationPath', String, 'Escalation Path',
        hint: 'Issue escalation'),
    Field('notes', String, 'Notes',
        hint: 'Additional third-party compatibility notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data format and encoding compatibility.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the character encodings and data formats the system must accept and produce for interoperability.',
)
@SectionId('DAFOCO')
class DataFormatCompatibility {
  @Form([
    Field('defaultEncoding', String, 'Default Encoding',
        hint: 'UTF-8, UTF-16, ISO-8859-1'),
    Field('supportedEncodings', String, 'Supported Encodings',
        hint: 'All supported encodings'),
    Field('encodingConversion', String, 'Encoding Conversion',
        hint: 'How encoding conversion handled'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Data format compatibility.
  @SerializationOrder(1)
  DataFormatCompatibilityFormats formats = DataFormatCompatibilityFormats();

  /// Date and time formatting.
  @SerializationOrder(2)
  DataFormatCompatibilityDateTime dateTime = DataFormatCompatibilityDateTime();

  /// Numeric formatting.
  @SerializationOrder(3)
  DataFormatCompatibilityNumbers numbers = DataFormatCompatibilityNumbers();

  /// Locale settings.
  @SerializationOrder(4)
  DataFormatCompatibilityLocale locale = DataFormatCompatibilityLocale();
}

/// Data format compatibility.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'OpenAPI / REST — API interoperability',
  ],
  'Captures the primary and supported data formats and how the system converts between them.',
)
@SectionId('DFCF')
class DataFormatCompatibilityFormats {
  @Form([
    Field('primaryFormat', String, 'Primary Data Format',
        hint: 'JSON, XML, CSV, Binary'),
    Field('supportedFormats', String, 'Supported Formats',
        hint: 'All supported formats'),
    Field('formatConversion', String, 'Format Conversion',
        hint: 'Format conversion support'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Date and time formatting.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures date/time formats, time-zone handling, and calendar systems the system must remain compatible with.',
)
@SectionId('DFCDT')
class DataFormatCompatibilityDateTime {
  @Form([
    Field('dateFormat', String, 'Date Format',
        hint: 'ISO 8601, locale-specific'),
    Field('timeZoneHandling', String, 'Time Zone Handling',
        hint: 'UTC, local, configurable'),
    Field('calendarSystems', String, 'Calendar Systems',
        hint: 'Gregorian, other calendars'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Numeric formatting.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures number, currency, and precision formatting the system must interoperate with.',
)
@SectionId('DFCN')
class DataFormatCompatibilityNumbers {
  @Form([
    Field('numberFormat', String, 'Number Format',
        hint: 'Decimal separator, grouping'),
    Field('currencyFormat', String, 'Currency Format',
        hint: 'Currency representation'),
    Field('precision', String, 'Numeric Precision',
        hint: 'Decimal precision handling'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Locale settings.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures locale handling, right-to-left support, and the Unicode version the system supports.',
)
@SectionId('DFCL')
class DataFormatCompatibilityLocale {
  @Form([
    Field('localeSupport', String, 'Locale Support',
        hint: 'Locale handling'),
    Field('rtlSupport', bool, 'RTL Support',
        hint: 'Right-to-left languages'),
    Field('unicodeSupport', String, 'Unicode Support',
        hint: 'Unicode version, emoji'),
    Field('notes', String, 'Notes',
        hint: 'Additional data format notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Backwards compatibility requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures the policy for supporting older versions, breaking changes, and deprecation timelines.',
)
@SectionId('BACORE')
class BackwardsCompatibilityRequirements {
  @Form([
    Field('compatibilityPolicy', String, 'Compatibility Policy',
        hint: 'How many versions supported'),
    Field('breakingChangePolicy', String, 'Breaking Change Policy',
        hint: 'When breaking changes allowed'),
    Field('deprecationTimeline', String, 'Deprecation Timeline',
        hint: 'Deprecation notice period'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Data compatibility requirements.
  @SerializationOrder(1)
  BackwardsCompatibilityRequirementsData data =
      BackwardsCompatibilityRequirementsData();

  /// API compatibility requirements.
  @SerializationOrder(2)
  BackwardsCompatibilityRequirementsApi api =
      BackwardsCompatibilityRequirementsApi();

  /// Database compatibility requirements.
  @SerializationOrder(3)
  BackwardsCompatibilityRequirementsDatabase database =
      BackwardsCompatibilityRequirementsDatabase();

  /// Communication and support requirements.
  @SerializationOrder(4)
  BackwardsCompatibilityRequirementsCommunication communication =
      BackwardsCompatibilityRequirementsCommunication();
}

/// Data compatibility requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures how stored data formats stay compatible across versions, including migration and rollback support.',
)
@SectionId('BCRD')
class BackwardsCompatibilityRequirementsData {
  @Form([
    Field('dataCompatibility', String, 'Data Compatibility',
        hint: 'Data format compatibility'),
    Field('migrationSupport', String, 'Migration Support',
        hint: 'Automatic migration support'),
    Field('rollbackSupport', String, 'Rollback Support',
        hint: 'Can rollback to older version'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// API compatibility requirements.
@StandardReferences(
  [
    'OpenAPI / REST — API interoperability',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures the API versioning approach, multi-version support, and client grace periods for backwards compatibility.',
)
@SectionId('BCRA')
class BackwardsCompatibilityRequirementsApi {
  @Form([
    Field('apiVersioning', String, 'API Versioning',
        hint: 'API versioning approach'),
    Field('multipleVersionSupport', String, 'Multiple Version Support',
        hint: 'Supporting multiple versions'),
    Field('clientUpdateGracePeriod', String, 'Client Update Grace Period',
        hint: 'Time for clients to update'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Database compatibility requirements.
@StandardReferences(
  [
    'ISO/IEC 9075 (SQL) — relational database standard',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ],
  'Captures how database schema evolution, data migration, and backfill preserve backwards compatibility.',
)
@SectionId('BACOREDA')
class BackwardsCompatibilityRequirementsDatabase {
  @Form([
    Field('schemaEvolution', String, 'Schema Evolution',
        hint: 'Database schema changes'),
    Field('dataMigration', String, 'Data Migration',
        hint: 'Data migration approach'),
    Field('backfillStrategy', String, 'Backfill Strategy',
        hint: 'New field population'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Communication and support requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC 12207 — software lifecycle processes',
  ],
  'Captures how backwards-compatibility changes are communicated, documented, and supported for consumers.',
)
@SectionId('BCRC')
class BackwardsCompatibilityRequirementsCommunication {
  @Form([
    Field('changeNotification', String, 'Change Notification',
        hint: 'How changes communicated'),
    Field('documentation', String, 'Documentation',
        hint: 'Migration documentation'),
    Field('supportChannels', String, 'Support Channels',
        hint: 'Migration support'),
    Field('notes', String, 'Notes',
        hint: 'Additional backwards compatibility notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// System interoperability requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the overall interoperability strategy, integration patterns, and communication protocols with other systems.',
)
@SectionId('INRE')
class InteroperabilityRequirements {
  @Form([
    Field('interopStrategy', String, 'Interoperability Strategy',
        hint: 'Overall interop approach'),
    Field('integrationPatterns', String, 'Integration Patterns',
        hint: 'API, Events, File, Message'),
    Field('communicationProtocols', String, 'Communication Protocols',
        hint: 'Supported protocols'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Data-exchange definitions.
  @SerializationOrder(1)
  InteroperabilityRequirementsDataExchange dataExchange =
      InteroperabilityRequirementsDataExchange();

  /// Standards and certifications.
  @SerializationOrder(2)
  InteroperabilityRequirementsStandards standards =
      InteroperabilityRequirementsStandards();

  /// Interoperability testing.
  @SerializationOrder(3)
  InteroperabilityRequirementsTesting testing =
      InteroperabilityRequirementsTesting();

  /// Governance and fallback behavior.
  @SerializationOrder(4)
  InteroperabilityRequirementsGovernance governance =
      InteroperabilityRequirementsGovernance();
}

/// Data-exchange definitions.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'OpenAPI / REST — API interoperability',
  ],
  'Captures the data-exchange formats, schema registry, and data contracts used for interoperability.',
)
@SectionId('IRDE')
class InteroperabilityRequirementsDataExchange {
  @Form([
    Field('dataExchangeFormats', String, 'Data Exchange Formats',
        hint: 'JSON, XML, Protobuf, Avro'),
    Field('schemaRegistry', String, 'Schema Registry',
        hint: 'Schema management'),
    Field('dataContracts', String, 'Data Contracts',
        hint: 'Contract definition approach'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Standards and certifications.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the industry and open standards the system conforms to and any interoperability certifications.',
)
@SectionId('INREST')
class InteroperabilityRequirementsStandards {
  @Form([
    Field('industryStandards', String, 'Industry Standards',
        hint: 'HL7, EDI, SWIFT'),
    Field('openStandards', String, 'Open Standards',
        hint: 'Open standard adoption'),
    Field('certifications', String, 'Certifications',
        hint: 'Interop certifications'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Interoperability testing.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'OpenAPI / REST — API interoperability',
  ],
  'Captures how interoperability is verified, including partner testing and conformance to standards.',
)
@SectionId('INRETE')
class InteroperabilityRequirementsTesting {
  @Form([
    Field('interopTesting', String, 'Interoperability Testing',
        hint: 'Testing approach'),
    Field('testPartners', String, 'Test Partners',
        hint: 'Partners for testing'),
    Field('conformanceTests', String, 'Conformance Tests',
        hint: 'Standard conformance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Governance and fallback behavior.
@StandardReferences(
  [
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures how interface changes are managed and how the system degrades when interoperability fails.',
)
@SectionId('INREGO')
class InteroperabilityRequirementsGovernance {
  @Form([
    Field('changeManagement', String, 'Change Management',
        hint: 'Managing interface changes'),
    Field('versionNegotiation', String, 'Version Negotiation',
        hint: 'How versions negotiated'),
    Field('fallbackBehavior', String, 'Fallback Behavior',
        hint: 'When interop fails'),
    Field('notes', String, 'Notes',
        hint: 'Additional interoperability notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// =============================================================================
// 8.3.2. Standards Compliance
// =============================================================================

/// 8.3.2. Standards Compliance.
///
/// Required compliance with IT standards, industry protocols, and interface
/// specifications.
@ContentHelp('''
Specify compliance requirements with IT standards, industry protocols,
regulatory frameworks, and certification requirements. Standards compliance
is often mandatory for enterprise and regulated industries.

**IT Standards**:
- **ISO/IEC**: 27001 (InfoSec), 9001 (Quality), 22301 (Business Continuity),
  25010 (Software Quality), 12207 (Lifecycle)
- **IEEE**: 830 (Requirements), 1471 (Architecture), 29148 (Requirements)
- **NIST**: Cybersecurity Framework, SP 800-53 controls

**Industry Protocols**:
- **API**: REST, GraphQL, gRPC, OpenAPI/Swagger specifications
- **Data**: JSON, XML, Protocol Buffers, Avro schemas
- **Security**: OAuth 2.0, OIDC, SAML, JWT, mTLS
- **Messaging**: AMQP, MQTT, WebSocket, Server-Sent Events

**Regulatory Compliance**:
- **Privacy**: GDPR, CCPA, PIPEDA, LGPD, HIPAA
- **Financial**: PCI-DSS, SOX, Basel III
- **Industry**: FedRAMP, HITRUST, PSD2, MiFID II

**Certification Requirements**:
- SOC 2 Type I/II
- ISO 27001 certification
- Industry-specific certifications
- Third-party security assessments
''')
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC 27001 — information security management',
  ],
  'Describes the IT, industry, regulatory, security, accessibility, and quality standards the system must comply with.',
)
@SectionId('STCOSE')
class StandardsComplianceSection {
  @ContentHelp('''
Provide an overview of standards compliance strategy and roadmap.

**Include**:
- Applicable standards and regulations
- Current compliance status
- Gap analysis and remediation plan
- Certification timeline and budget
- Ongoing compliance maintenance

**Best Practices**:
- Map standards to specific controls
- Automate compliance evidence collection
- Schedule regular compliance reviews
- Train team on compliance requirements
- Engage compliance consultants for audits
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of standards compliance strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// IT standards compliance (ISO, IEEE, NIST).
  @StandardReferences(
    [
      'ISO/IEC 25010 — product quality model',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The IT standards the system must comply with.',
  )
  @SectionId('ISCE-ITST-LST')
  @SectionIdPattern('ISCE-ITST-xxx')
  @ContentHelp('Add one entry per IT standard.')
  @SerializationOrder(2)
  List<ItStandardComplianceEntry> itStandards = [];

  /// Industry protocols compliance.
  @StandardReferences(
    [
      'HL7 / FHIR / ISO 20022 — industry data-exchange standards',
      'ISO 9001 — quality management systems',
    ],
    'The industry protocols the system must comply with.',
  )
  @SectionId('IPCE-INDU-LST')
  @SectionIdPattern('IPCE-INDU-xxx')
  @ContentHelp('Add one entry per industry protocol.')
  @SerializationOrder(3)
  List<IndustryProtocolComplianceEntry> industryProtocols = [];

  /// Interface specification standards.
  @StandardReferences(
    [
      'ISO/IEC 25010 — product quality model',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The interface specification standards the system must follow.',
  )
  @SectionId('INSPEN-INTE-LST')
  @SectionIdPattern('INSPEN-INTE-xxx')
  @ContentHelp('Add one entry per interface specification.')
  @SerializationOrder(4)
  List<InterfaceSpecificationEntry> interfaceSpecifications = [];

  /// Regulatory compliance requirements.
  @StandardReferences(
    [
      'GDPR — data protection regulation',
      'ISO/IEC 27001 — information security management',
    ],
    'The regulatory frameworks the system must comply with.',
  )
  @SectionId('RECOEN-REGU-LST')
  @SectionIdPattern('RECOEN-REGU-xxx')
  @ContentHelp('Add one entry per regulation.')
  @SerializationOrder(5)
  List<RegulatoryComplianceEntry> regulatoryCompliance = [];

  /// Security standards compliance.
  @StandardReferences(
    [
      'ISO/IEC 27001 — information security management',
      'ISO/IEC 27002 — information security controls',
    ],
    'The security standards the system must comply with.',
  )
  @SectionId('SSCE-SECU-LST')
  @SectionIdPattern('SSCE-SECU-xxx')
  @ContentHelp('Add one entry per security standard.')
  @SerializationOrder(6)
  List<SecurityStandardComplianceEntry> securityStandards = [];

  /// Accessibility standards compliance.
  @StandardReferences(
    ['WCAG 2.2 — web content accessibility'],
    'The accessibility standards the system must conform to.',
  )
  @SectionId('ACCSTD-ACCE-LST')
  @SectionIdPattern('ACCSTD-ACCE-xxx')
  @ContentHelp('Add one entry per accessibility standard.')
  @SerializationOrder(7)
  List<AccessibilityStandardEntry> accessibilityStandards = [];

  /// Quality management standards.
  @StandardReferences(
    [
      'ISO 9001 — quality management systems',
      'ISO/IEC 25010 — product quality model',
    ],
    'The quality management standards the system must comply with.',
  )
  @SectionId('QLSTD-QUAL-LST')
  @SectionIdPattern('QLSTD-QUAL-xxx')
  @ContentHelp('Add one entry per quality standard.')
  @SerializationOrder(8)
  List<QualityStandardEntry> qualityStandards = [];

  /// Documentation standards.
  @SerializationOrder(9)
  DocumentationStandardsSection documentationStandards =
      DocumentationStandardsSection();

  /// Coding standards and conventions.
  @SerializationOrder(10)
  CodingStandardsSection codingStandards = CodingStandardsSection();

  /// Certification requirements.
  @SerializationOrder(11)
  CertificationRequirementsSection certificationRequirements =
      CertificationRequirementsSection();

  /// Compliance verification and auditing.
  @SerializationOrder(12)
  ComplianceVerificationSection complianceVerification =
      ComplianceVerificationSection();
}

/// IT standard compliance entry (ISO, IEEE, NIST, OASIS).
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Describes a single IT standard the system must comply with.',
)
@SectionId('ITSTCOEN')
class ItStandardComplianceEntry {
  @Form([
    Field('standardName', String, 'Standard Name',
        required: true, hint: 'E.g., ISO 27001, IEEE 802.11, NIST SP 800-53'),
    Field('standardBody', String, 'Standard Body',
        required: true, hint: 'ISO, IEEE, NIST, OASIS, W3C'),
    Field('standardId', String, 'Standard ID',
        hint: 'Official standard identifier'),
    Field('version', String, 'Version', hint: 'Standard version'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Applicability and priority.
  @SerializationOrder(1)
  ItStandardComplianceEntryScope scope = ItStandardComplianceEntryScope();

  /// Control requirements.
  @SerializationOrder(2)
  ItStandardComplianceEntryRequirements requirements =
      ItStandardComplianceEntryRequirements();

  /// Compliance timeline.
  @SerializationOrder(3)
  ItStandardComplianceEntryTimeline timeline =
      ItStandardComplianceEntryTimeline();

  /// Ownership and support.
  @SerializationOrder(4)
  ItStandardComplianceEntryOwnership ownership =
      ItStandardComplianceEntryOwnership();

  /// Evidence and notes.
  @SerializationOrder(5)
  ItStandardComplianceEntryEvidence evidence =
      ItStandardComplianceEntryEvidence();
}

/// Applicability and priority.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the applicability scope and priority of an IT standard.',
)
@SectionId('ISCES')
class ItStandardComplianceEntryScope {
  @Form([
    Field('applicabilityScope', String, 'Applicability Scope',
        hint: 'Which parts of the system this applies to'),
    Field('complianceLevel', String, 'Compliance Level',
        hint: 'Full, Partial, Target'),
    Field('priority', String, 'Priority',
        hint: 'Critical, High, Medium, Low'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Control requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the applicable controls and exclusions for an IT standard.',
)
@SectionId('ISCER')
class ItStandardComplianceEntryRequirements {
  @Form([
    Field('controlsApplicable', String, 'Applicable Controls',
        hint: 'Specific controls that apply'),
    Field('exclusions', String, 'Exclusions',
        hint: 'Controls not applicable'),
    Field('customizations', String, 'Customizations',
        hint: 'Organization-specific adaptations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance timeline.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the target date and current status for IT standard compliance.',
)
@SectionId('ISCET')
class ItStandardComplianceEntryTimeline {
  @Form([
    Field('targetDate', String, 'Target Compliance Date',
        hint: 'When to achieve compliance'),
    Field('currentStatus', String, 'Current Status',
        hint: 'Not started, In progress, Compliant'),
    Field('lastAssessment', String, 'Last Assessment Date',
        hint: 'Date of last assessment'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Ownership and support.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the compliance owner and external support for an IT standard.',
)
@SectionId('ISCEO')
class ItStandardComplianceEntryOwnership {
  @Form([
    Field('complianceOwner', String, 'Compliance Owner',
        hint: 'Responsible person/team'),
    Field('externalSupport', String, 'External Support',
        hint: 'External consultants if any'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Evidence and notes.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the evidence required to demonstrate IT standard compliance.',
)
@SectionId('ISCEE')
class ItStandardComplianceEntryEvidence {
  @Form([
    Field('evidenceRequired', String, 'Evidence Required',
        hint: 'Documentation needed for compliance'),
    Field('notes', String, 'Notes',
        hint: 'Additional IT standard notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Industry protocol compliance entry.
@StandardReferences(
  [
    'HL7 / FHIR / ISO 20022 — industry data-exchange standards',
    'ISO 9001 — quality management systems',
  ],
  'Describes a single industry protocol the system complies with.',
)
@SectionId('INPRCOEN')
class IndustryProtocolComplianceEntry {
  @Form([
    Field('protocolName', String, 'Protocol Name',
        required: true, hint: 'E.g., HTTP/2, MQTT, AMQP, WebSocket'),
    Field('category', String, 'Category',
        hint: 'Network, Messaging, Security, Data exchange'),
    Field('specificationVersion', String, 'Specification Version',
        required: true, hint: 'Protocol version'),
    Field('specificationUrl', String, 'Specification URL',
        hint: 'Link to official specification'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Compliance scope and features.
  @SerializationOrder(1)
  IndustryProtocolComplianceEntryScope scope =
      IndustryProtocolComplianceEntryScope();

  /// Implementation details.
  @SerializationOrder(2)
  IndustryProtocolComplianceEntryImplementation implementation =
      IndustryProtocolComplianceEntryImplementation();

  /// Testing details.
  @SerializationOrder(3)
  IndustryProtocolComplianceEntryTesting testing =
      IndustryProtocolComplianceEntryTesting();

  /// Interoperability notes.
  @SerializationOrder(4)
  IndustryProtocolComplianceEntryInteroperability interoperability =
      IndustryProtocolComplianceEntryInteroperability();
}

/// Compliance scope and features.
@StandardReferences(
  [
    'HL7 / FHIR / ISO 20022 — industry data-exchange standards',
    'ISO 9001 — quality management systems',
  ],
  'Captures the mandatory and optional protocol features implemented.',
)
@SectionId('IPCES')
class IndustryProtocolComplianceEntryScope {
  @Form([
    Field('complianceScope', String, 'Compliance Scope',
        hint: 'Which features are implemented'),
    Field('mandatoryFeatures', String, 'Mandatory Features',
        hint: 'Required protocol features'),
    Field('optionalFeatures', String, 'Optional Features',
        hint: 'Optional features implemented'),
    Field('extensionsUsed', String, 'Extensions Used',
        hint: 'Protocol extensions used'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Implementation details.
@StandardReferences(
  [
    'HL7 / FHIR / ISO 20022 — industry data-exchange standards',
    'ISO 9001 — quality management systems',
  ],
  'Captures the implementation library and performance profile for a protocol.',
)
@SectionId('IPCEI')
class IndustryProtocolComplianceEntryImplementation {
  @Form([
    Field('implementationLibrary', String, 'Implementation Library',
        hint: 'Library used for implementation'),
    Field('implementationNotes', String, 'Implementation Notes',
        hint: 'Specific implementation details'),
    Field('performanceProfile', String, 'Performance Profile',
        hint: 'Expected performance characteristics'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing details.
@StandardReferences(
  [
    'HL7 / FHIR / ISO 20022 — industry data-exchange standards',
    'ISO 9001 — quality management systems',
  ],
  'Captures how protocol conformance is tested and certified.',
)
@SectionId('IPCET')
class IndustryProtocolComplianceEntryTesting {
  @Form([
    Field('conformanceTest', String, 'Conformance Testing',
        hint: 'How conformance is tested'),
    Field('testTools', String, 'Test Tools',
        hint: 'Tools for testing compliance'),
    Field('certificationStatus', String, 'Certification Status',
        hint: 'Official certification if any'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Interoperability notes.
@StandardReferences(
  [
    'HL7 / FHIR / ISO 20022 — industry data-exchange standards',
    'ISO 9001 — quality management systems',
  ],
  'Captures the interoperability partners and known issues for a protocol.',
)
@SectionId('INPRCOENIN')
class IndustryProtocolComplianceEntryInteroperability {
  @Form([
    Field('interopPartners', String, 'Interop Partners',
        hint: 'Partners tested for interop'),
    Field('knownIssues', String, 'Known Issues',
        hint: 'Known interoperability issues'),
    Field('notes', String, 'Notes',
        hint: 'Additional protocol compliance notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Interface specification entry (REST, GraphQL, gRPC, SOAP).
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Describes a single interface specification the system implements.',
)
@SectionId('INTSPEENT')
class InterfaceSpecificationEntry {
  @Form([
    Field('specificationName', String, 'Specification Name',
        required: true, hint: 'E.g., REST, GraphQL, gRPC, SOAP'),
    Field('specificationVersion', String, 'Version',
        hint: 'Specification version'),
    Field('standardsBody', String, 'Standards Body',
        hint: 'IETF, W3C, OASIS, etc.'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Definition storage and validation.
  @SerializationOrder(1)
  InterfaceSpecificationEntryDefinition definition =
      InterfaceSpecificationEntryDefinition();

  /// Interface conventions.
  @SerializationOrder(2)
  InterfaceSpecificationEntryConventions conventions =
      InterfaceSpecificationEntryConventions();

  /// Documentation expectations.
  @SerializationOrder(3)
  InterfaceSpecificationEntryDocumentation documentation =
      InterfaceSpecificationEntryDocumentation();

  /// Tooling and notes.
  @SerializationOrder(4)
  InterfaceSpecificationEntryTooling tooling =
      InterfaceSpecificationEntryTooling();
}

/// Definition storage and validation.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures how an interface definition is stored and validated.',
)
@SectionId('ISED')
class InterfaceSpecificationEntryDefinition {
  @Form([
    Field('definitionFormat', String, 'Definition Format',
        hint: 'OpenAPI, AsyncAPI, GraphQL SDL, WSDL'),
    Field('definitionLocation', String, 'Definition Location',
        hint: 'Where spec is stored'),
    Field('schemaValidation', String, 'Schema Validation',
        hint: 'How schemas are validated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Interface conventions.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the naming, versioning, and error-handling conventions for an interface.',
)
@SectionId('INSPENCO')
class InterfaceSpecificationEntryConventions {
  @Form([
    Field('namingConventions', String, 'Naming Conventions',
        hint: 'API naming conventions'),
    Field('versioningStrategy', String, 'Versioning Strategy',
        hint: 'URL path, header, query'),
    Field('errorHandling', String, 'Error Handling',
        hint: 'Error format/codes'),
    Field('pagination', String, 'Pagination',
        hint: 'Pagination approach'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation expectations.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the documentation expectations for an interface specification.',
)
@SectionId('INSPENDO')
class InterfaceSpecificationEntryDocumentation {
  @Form([
    Field('documentationFormat', String, 'Documentation Format',
        hint: 'Swagger UI, ReDoc, etc.'),
    Field('examplesRequired', bool, 'Examples Required',
        hint: 'Require request/response examples'),
    Field('changelogMaintained', bool, 'Changelog Maintained',
        hint: 'Maintain API changelog'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Tooling and notes.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the tooling supporting an interface specification.',
)
@SectionId('ISET')
class InterfaceSpecificationEntryTooling {
  @Form([
    Field('generatedClients', String, 'Generated Clients',
        hint: 'Client SDKs generated'),
    Field('mockServer', String, 'Mock Server',
        hint: 'Mock server for testing'),
    Field('gatewayIntegration', String, 'Gateway Integration',
        hint: 'API gateway used'),
    Field('notes', String, 'Notes',
        hint: 'Additional interface spec notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Regulatory compliance entry (GDPR, HIPAA, PCI-DSS, SOX).
@StandardReferences(
  [
    'GDPR — data protection regulation',
    'PCI DSS — payment card data security',
    'ISO/IEC 27001 — information security management',
  ],
  'Describes a single regulation the system must comply with.',
)
@SectionId('RCE')
class RegulatoryComplianceEntry {
  @Form([
    Field('regulationName', String, 'Regulation Name',
        required: true, hint: 'E.g., GDPR, HIPAA, PCI-DSS, SOX'),
    Field('jurisdiction', String, 'Jurisdiction',
        required: true, hint: 'Geographic/industry scope'),
    Field('regulatoryBody', String, 'Regulatory Body',
        hint: 'Authority enforcing regulation'),
    Field('effectiveDate', String, 'Effective Date',
        hint: 'When regulation took effect'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Applicability analysis.
  @SerializationOrder(1)
  RegulatoryComplianceEntryApplicability applicability =
      RegulatoryComplianceEntryApplicability();

  /// Compliance requirements.
  @SerializationOrder(2)
  RegulatoryComplianceEntryRequirements requirements =
      RegulatoryComplianceEntryRequirements();

  /// Penalties and reporting.
  @SerializationOrder(3)
  RegulatoryComplianceEntryPenalties penalties =
      RegulatoryComplianceEntryPenalties();

  /// Ownership and review.
  @SerializationOrder(4)
  RegulatoryComplianceEntryOwnership ownership =
      RegulatoryComplianceEntryOwnership();
}

/// Applicability analysis.
@StandardReferences(
  [
    'GDPR — data protection regulation',
    'ISO/IEC 27001 — information security management',
  ],
  'Captures why a regulation applies and the data categories it covers.',
)
@SectionId('RECOENAP')
class RegulatoryComplianceEntryApplicability {
  @Form([
    Field('applicabilityReason', String, 'Why Applicable',
        hint: 'Why this regulation applies'),
    Field('dataCategories', String, 'Data Categories',
        hint: 'Types of data covered'),
    Field('processesAffected', String, 'Processes Affected',
        hint: 'Business processes affected'),
    Field('userRights', String, 'User Rights',
        hint: 'Rights granted to users'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance requirements.
@StandardReferences(
  [
    'GDPR — data protection regulation',
    'ISO/IEC 27001 — information security management',
  ],
  'Captures the technical and procedural controls required by a regulation.',
)
@SectionId('RECOENRE')
class RegulatoryComplianceEntryRequirements {
  @Form([
    Field('keyRequirements', String, 'Key Requirements',
        hint: 'Main requirements to meet'),
    Field('technicalControls', String, 'Technical Controls',
        hint: 'Required technical measures'),
    Field('proceduralControls', String, 'Procedural Controls',
        hint: 'Required procedures'),
    Field('documentationRequired', String, 'Documentation Required',
        hint: 'Required documentation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Penalties and reporting.
@StandardReferences(
  [
    'GDPR — data protection regulation',
    'ISO/IEC 27001 — information security management',
  ],
  'Captures the penalties and breach reporting obligations for a regulation.',
)
@SectionId('RCEP')
class RegulatoryComplianceEntryPenalties {
  @Form([
    Field('penaltiesForNonCompliance', String, 'Penalties',
        hint: 'Consequences of non-compliance'),
    Field('reportingObligations', String, 'Reporting Obligations',
        hint: 'Breach reporting requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Ownership and review.
@StandardReferences(
  [
    'GDPR — data protection regulation',
    'ISO/IEC 27001 — information security management',
  ],
  'Captures the compliance officer and legal review for a regulation.',
)
@SectionId('RCEO')
class RegulatoryComplianceEntryOwnership {
  @Form([
    Field('dpo', String, 'DPO/Compliance Officer',
        hint: 'Responsible officer'),
    Field('legalReview', String, 'Legal Review',
        hint: 'Legal review status'),
    Field('notes', String, 'Notes',
        hint: 'Additional regulatory compliance notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security standard compliance entry (SOC2, ISO 27001, CIS).
@StandardReferences(
  [
    'ISO/IEC 27001 — information security management',
    'ISO/IEC 27002 — information security controls',
  ],
  'Describes a single security standard the system must comply with.',
)
@SectionId('SESTCOEN')
class SecurityStandardComplianceEntry {
  @Form([
    Field('standardName', String, 'Standard Name',
        required: true, hint: 'E.g., SOC 2, ISO 27001, CIS Controls'),
    Field('standardType', String, 'Standard Type',
        hint: 'Framework, Certification, Benchmark'),
    Field('version', String, 'Version', hint: 'Standard version'),
    Field('trustServiceCriteria', String, 'Trust Service Criteria',
        hint: 'For SOC 2: Security, Availability, etc.'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Scope details.
  @SerializationOrder(1)
  SecurityStandardComplianceEntryScope scope =
      SecurityStandardComplianceEntryScope();

  /// Control definitions.
  @SerializationOrder(2)
  SecurityStandardComplianceEntryControls controls =
      SecurityStandardComplianceEntryControls();

  /// Assessment schedule.
  @SerializationOrder(3)
  SecurityStandardComplianceEntryAssessment assessment =
      SecurityStandardComplianceEntryAssessment();

  /// Overall status.
  @SerializationOrder(4)
  SecurityStandardComplianceEntryStatus status =
      SecurityStandardComplianceEntryStatus();
}

/// Scope details.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security management',
    'ISO/IEC 27002 — information security controls',
  ],
  'Captures the systems and data in scope for a security standard.',
)
@SectionId('SESTCOENSC')
class SecurityStandardComplianceEntryScope {
  @Form([
    Field('systemsInScope', String, 'Systems in Scope',
        hint: 'Systems covered'),
    Field('dataInScope', String, 'Data in Scope',
        hint: 'Data categories covered'),
    Field('exclusions', String, 'Exclusions',
        hint: 'What is excluded'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Control definitions.
@StandardReferences(
  [
    'ISO/IEC 27002 — information security controls',
    'ISO/IEC 27001 — information security management',
  ],
  'Captures the control framework and categories for a security standard.',
)
@SectionId('SSCEC')
class SecurityStandardComplianceEntryControls {
  @Form([
    Field('controlFramework', String, 'Control Framework',
        hint: 'Framework used'),
    Field('controlCategories', String, 'Control Categories',
        hint: 'Categories of controls'),
    Field('highRiskControls', String, 'High-Risk Controls',
        hint: 'Critical controls'),
    Field('compensatingControls', String, 'Compensating Controls',
        hint: 'Alternative controls'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Assessment schedule.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security management',
    'ISO/IEC 27002 — information security controls',
  ],
  'Captures the assessment schedule and auditor for a security standard.',
)
@SectionId('SSCEA')
class SecurityStandardComplianceEntryAssessment {
  @Form([
    Field('assessmentFrequency', String, 'Assessment Frequency',
        hint: 'How often assessed'),
    Field('lastAuditDate', String, 'Last Audit Date',
        hint: 'Date of last audit'),
    Field('nextAuditDate', String, 'Next Audit Date',
        hint: 'Date of next audit'),
    Field('auditor', String, 'Auditor',
        hint: 'External auditor'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Overall status.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security management',
    'ISO/IEC 27002 — information security controls',
  ],
  'Captures the overall compliance status for a security standard.',
)
@SectionId('SESTCOENST')
class SecurityStandardComplianceEntryStatus {
  @Form([
    Field('complianceStatus', String, 'Compliance Status',
        hint: 'Current compliance status'),
    Field('notes', String, 'Notes',
        hint: 'Additional security standard notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Accessibility standard entry (WCAG, Section 508, ADA).
@StandardReferences(
  ['WCAG 2.2 — web content accessibility'],
  'Describes a single accessibility standard the system must conform to.',
)
@SectionId('ACCSTD')
class AccessibilityStandardEntry {
  @Form([
    Field('standardName', String, 'Standard Name',
        required: true, hint: 'E.g., WCAG 2.1, Section 508, EN 301 549'),
    Field('version', String, 'Version', hint: 'Standard version'),
    Field('conformanceLevel', String, 'Conformance Level',
        required: true, hint: 'A, AA, AAA for WCAG'),
    Field('jurisdiction', String, 'Jurisdiction',
        hint: 'Legal requirement region'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Scope and affected users.
  @SerializationOrder(1)
  AccessibilityStandardEntryScope scope = AccessibilityStandardEntryScope();

  /// Conformance requirements.
  @SerializationOrder(2)
  AccessibilityStandardEntryRequirements requirements =
      AccessibilityStandardEntryRequirements();

  /// Testing approach.
  @SerializationOrder(3)
  AccessibilityStandardEntryTesting testing = AccessibilityStandardEntryTesting();

  /// Documentation artifacts.
  @SerializationOrder(4)
  AccessibilityStandardEntryDocumentation documentation =
      AccessibilityStandardEntryDocumentation();
}

/// Scope and affected users.
@StandardReferences(
  ['WCAG 2.2 — web content accessibility'],
  'Captures the content scope and user groups an accessibility standard covers.',
)
@SectionId('ASES')
class AccessibilityStandardEntryScope {
  @Form([
    Field('applicableContent', String, 'Applicable Content',
        hint: 'Web, mobile, documents'),
    Field('userGroups', String, 'User Groups',
        hint: 'Disability types accommodated'),
    Field('assistiveTechnologies', String, 'Assistive Technologies',
        hint: 'Screen readers, etc. supported'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Conformance requirements.
@StandardReferences(
  ['WCAG 2.2 — web content accessibility'],
  'Captures the perceivable, operable, understandable, and robust conformance requirements.',
)
@SectionId('ASER')
class AccessibilityStandardEntryRequirements {
  @Form([
    Field('perceivableRequirements', String, 'Perceivable Requirements',
        hint: 'Alt text, captions, contrast'),
    Field('operableRequirements', String, 'Operable Requirements',
        hint: 'Keyboard, timing, navigation'),
    Field('understandableRequirements', String, 'Understandable Requirements',
        hint: 'Readable, predictable'),
    Field('robustRequirements', String, 'Robust Requirements',
        hint: 'Compatible with AT'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing approach.
@StandardReferences(
  ['WCAG 2.2 — web content accessibility'],
  'Captures the testing approach and tools used to verify accessibility.',
)
@SectionId('ASET')
class AccessibilityStandardEntryTesting {
  @Form([
    Field('testingApproach', String, 'Testing Approach',
        hint: 'Manual, automated, user testing'),
    Field('testingTools', String, 'Testing Tools',
        hint: 'axe, WAVE, NVDA, VoiceOver'),
    Field('userTesting', String, 'User Testing',
        hint: 'Testing with disabled users'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation artifacts.
@StandardReferences(
  ['WCAG 2.2 — web content accessibility'],
  'Captures the accessibility conformance reports and statements produced.',
)
@SectionId('ASED')
class AccessibilityStandardEntryDocumentation {
  @Form([
    Field('vpat', String, 'VPAT/ACR',
        hint: 'Accessibility conformance report'),
    Field('accessibilityStatement', String, 'Accessibility Statement',
        hint: 'Public statement URL'),
    Field('notes', String, 'Notes',
        hint: 'Additional accessibility notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Quality standard entry (CMMI, ISO 9001).
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Describes a single quality standard the system must comply with.',
)
@SectionId('QLSTD')
class QualityStandardEntry {
  @Form([
    Field('standardName', String, 'Standard Name',
        required: true, hint: 'E.g., CMMI, ISO 9001, Six Sigma'),
    Field('maturityLevel', String, 'Maturity Level',
        hint: 'For CMMI: Level 1-5'),
    Field('version', String, 'Version', hint: 'Standard version'),
    Field('scope', String, 'Scope',
        hint: 'Organization-wide or project-specific'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Process coverage.
  @SerializationOrder(1)
  QualityStandardEntryProcesses processes = QualityStandardEntryProcesses();

  /// Improvement implementation.
  @SerializationOrder(2)
  QualityStandardEntryImplementation implementation =
      QualityStandardEntryImplementation();

  /// Certification status.
  @SerializationOrder(3)
  QualityStandardEntryCertification certification =
      QualityStandardEntryCertification();

  /// Maintenance expectations.
  @SerializationOrder(4)
  QualityStandardEntryMaintenance maintenance =
      QualityStandardEntryMaintenance();
}

/// Process coverage.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Captures the process areas and quality objectives covered by a quality standard.',
)
@SectionId('QSEP')
class QualityStandardEntryProcesses {
  @Form([
    Field('processAreas', String, 'Process Areas',
        hint: 'Covered process areas'),
    Field('qualityObjectives', String, 'Quality Objectives',
        hint: 'Measurable quality goals'),
    Field('kpis', String, 'KPIs',
        hint: 'Key performance indicators'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Improvement implementation.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Captures the maturity gap analysis and improvement plan for a quality standard.',
)
@SectionId('QSEI')
class QualityStandardEntryImplementation {
  @Form([
    Field('currentLevel', String, 'Current Level',
        hint: 'Current maturity'),
    Field('targetLevel', String, 'Target Level',
        hint: 'Target maturity'),
    Field('gapAnalysis', String, 'Gap Analysis',
        hint: 'Identified gaps'),
    Field('improvementPlan', String, 'Improvement Plan',
        hint: 'Plan to close gaps'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Certification status.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Captures the certification status for a quality standard.',
)
@SectionId('QSEC')
class QualityStandardEntryCertification {
  @Form([
    Field('certificationBody', String, 'Certification Body',
        hint: 'Who certifies'),
    Field('certificationStatus', String, 'Certification Status',
        hint: 'Current certification'),
    Field('certificationExpiry', String, 'Certification Expiry',
        hint: 'When certification expires'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Maintenance expectations.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Captures the audit frequency and continuous improvement for a quality standard.',
)
@SectionId('QSEM')
class QualityStandardEntryMaintenance {
  @Form([
    Field('auditFrequency', String, 'Audit Frequency',
        hint: 'How often audited'),
    Field('continuousImprovement', String, 'Continuous Improvement',
        hint: 'Improvement process'),
    Field('notes', String, 'Notes',
        hint: 'Additional quality standard notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation standards section.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Describes the documentation standards the project must follow.',
)
@SectionId('DOSTSE')
class DocumentationStandardsSection {
  @Form([
    Field('documentationPolicy', String, 'Documentation Policy',
        hint: 'Overall documentation policy'),
    Field('templateStandards', String, 'Template Standards',
        hint: 'Required templates'),
    Field('styleGuide', String, 'Style Guide',
        hint: 'Writing style guide'),
    Field('terminology', String, 'Terminology',
        hint: 'Standard terminology/glossary'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Technical documentation standards.
  @SerializationOrder(1)
  DocumentationStandardsSectionTechnical technical =
      DocumentationStandardsSectionTechnical();

  /// User documentation standards.
  @SerializationOrder(2)
  DocumentationStandardsSectionUser user = DocumentationStandardsSectionUser();

  /// Documentation process rules.
  @SerializationOrder(3)
  DocumentationStandardsSectionProcess process =
      DocumentationStandardsSectionProcess();

  /// Documentation quality rules.
  @SerializationOrder(4)
  DocumentationStandardsSectionQuality quality =
      DocumentationStandardsSectionQuality();
}

/// Technical documentation standards.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Captures the standards for technical documentation and API docs.',
)
@SectionId('DSST')
class DocumentationStandardsSectionTechnical {
  @Form([
    Field('technicalDocFormat', String, 'Technical Doc Format',
        hint: 'Markdown, Confluence, etc.'),
    Field('apiDocStandard', String, 'API Doc Standard',
        hint: 'OpenAPI, JSDoc, etc.'),
    Field('codeCommentStyle', String, 'Code Comment Style',
        hint: 'Comment style guide'),
    Field('inlineDocRequirements', String, 'Inline Doc Requirements',
        hint: 'Required inline documentation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// User documentation standards.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Captures the standards for user-facing documentation and help systems.',
)
@SectionId('DSSU')
class DocumentationStandardsSectionUser {
  @Form([
    Field('userDocFormat', String, 'User Doc Format',
        hint: 'User documentation format'),
    Field('helpSystemStandard', String, 'Help System Standard',
        hint: 'Contextual help approach'),
    Field('localizationRequirements', String, 'Localization Requirements',
        hint: 'Translation requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation process rules.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Captures the review, versioning, and archival process for documentation.',
)
@SectionId('DSSP')
class DocumentationStandardsSectionProcess {
  @Form([
    Field('reviewProcess', String, 'Review Process',
        hint: 'Documentation review process'),
    Field('versionControl', String, 'Version Control',
        hint: 'Doc version control'),
    Field('archivalPolicy', String, 'Archival Policy',
        hint: 'How docs are archived'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation quality rules.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Captures the quality rules documentation must satisfy.',
)
@SectionId('DSSQ')
class DocumentationStandardsSectionQuality {
  @Form([
    Field('spellCheckRequired', bool, 'Spell Check Required',
        hint: 'Require spell checking'),
    Field('accessibilityRequired', bool, 'Accessibility Required',
        hint: 'Accessible documents'),
    Field('notes', String, 'Notes',
        hint: 'Additional documentation standard notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Coding standards section.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Describes the coding standards and conventions the codebase must follow.',
)
@SectionId('COSTSE')
class CodingStandardsSection {
  @Form([
    Field('primaryLanguages', String, 'Primary Languages',
        hint: 'Main programming languages'),
    Field('styleGuide', String, 'Style Guide',
        hint: 'Official style guide'),
    Field('linterTool', String, 'Linter Tool',
        hint: 'Required linter'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Formatting and layout rules.
  @SerializationOrder(1)
  CodingStandardsSectionFormatting formatting =
      CodingStandardsSectionFormatting();

  /// Naming and structure rules.
  @SerializationOrder(2)
  CodingStandardsSectionNaming naming = CodingStandardsSectionNaming();

  /// Static quality checks.
  @SerializationOrder(3)
  CodingStandardsSectionQuality quality = CodingStandardsSectionQuality();

  /// Development practices.
  @SerializationOrder(4)
  CodingStandardsSectionPractices practices =
      CodingStandardsSectionPractices();

  /// Review expectations.
  @SerializationOrder(5)
  CodingStandardsSectionReview review = CodingStandardsSectionReview();
}

/// Formatting and layout rules.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Captures the formatting and layout rules for source code.',
)
@SectionId('CSSF')
class CodingStandardsSectionFormatting {
  @Form([
    Field('indentation', String, 'Indentation',
        hint: 'Spaces vs tabs, count'),
    Field('lineLength', String, 'Max Line Length',
        hint: 'Maximum line length'),
    Field('formatterTool', String, 'Formatter Tool',
        hint: 'Code formatter'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Naming and structure rules.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Captures the naming conventions and directory structure rules for code.',
)
@SectionId('CSSN')
class CodingStandardsSectionNaming {
  @Form([
    Field('namingConventions', String, 'Naming Conventions',
        hint: 'Variable, class, method naming'),
    Field('fileNaming', String, 'File Naming',
        hint: 'File naming conventions'),
    Field('directoryStructure', String, 'Directory Structure',
        hint: 'Required directory layout'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Static quality checks.
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality model',
    'ISO 9001 — quality management systems',
  ],
  'Captures the static analysis and complexity checks applied to code.',
)
@SectionId('CSSQ')
class CodingStandardsSectionQuality {
  @Form([
    Field('staticAnalysis', String, 'Static Analysis',
        hint: 'Static analysis tools'),
    Field('complexityLimits', String, 'Complexity Limits',
        hint: 'Cyclomatic complexity limits'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Development practices.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Captures the development practices for error handling, logging, testing, and security.',
)
@SectionId('CSSP')
class CodingStandardsSectionPractices {
  @Form([
    Field('errorHandling', String, 'Error Handling',
        hint: 'Error handling patterns'),
    Field('loggingStandard', String, 'Logging Standard',
        hint: 'Logging conventions'),
    Field('testingRequirements', String, 'Testing Requirements',
        hint: 'Required test coverage'),
    Field('securityPractices', String, 'Security Practices',
        hint: 'Secure coding practices'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Review expectations.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ],
  'Captures the code review expectations and checklists.',
)
@SectionId('CSSR')
class CodingStandardsSectionReview {
  @Form([
    Field('codeReviewChecklist', String, 'Code Review Checklist',
        hint: 'Review checklist'),
    Field('pairProgramming', String, 'Pair Programming',
        hint: 'Pair programming policy'),
    Field('notes', String, 'Notes',
        hint: 'Additional coding standard notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Certification requirements section.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ],
  'Describes the certifications the system must obtain and maintain.',
)
@SectionId('CERESE')
class CertificationRequirementsSection {
  @Form([
    Field('requiredCertifications', String, 'Required Certifications',
        hint: 'List of required certs'),
    Field('targetCertifications', String, 'Target Certifications',
        hint: 'Future certifications'),
    Field('industryMandates', String, 'Industry Mandates',
        hint: 'Industry-required certs'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Certification process.
  @SerializationOrder(1)
  CertificationRequirementsSectionProcess process =
      CertificationRequirementsSectionProcess();

  /// Timeline requirements.
  @SerializationOrder(2)
  CertificationRequirementsSectionTimeline timeline =
      CertificationRequirementsSectionTimeline();

  /// Cost requirements.
  @SerializationOrder(3)
  CertificationRequirementsSectionCosts costs =
      CertificationRequirementsSectionCosts();

  /// Marketing and notes.
  @SerializationOrder(4)
  CertificationRequirementsSectionMarketing marketing =
      CertificationRequirementsSectionMarketing();
}

/// Certification process.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ],
  'Captures the process steps for achieving certification.',
)
@SectionId('CRSP')
class CertificationRequirementsSectionProcess {
  @Form([
    Field('certificationProcess', String, 'Certification Process',
        hint: 'Steps to get certified'),
    Field('preAssessment', String, 'Pre-Assessment',
        hint: 'Internal assessment first'),
    Field('gapRemediation', String, 'Gap Remediation',
        hint: 'How to fix gaps'),
    Field('auditorSelection', String, 'Auditor Selection',
        hint: 'How auditors chosen'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Timeline requirements.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ],
  'Captures the timeline and renewal schedule for certification.',
)
@SectionId('CRST')
class CertificationRequirementsSectionTimeline {
  @Form([
    Field('certificationTimeline', String, 'Certification Timeline',
        hint: 'Timeline for certification'),
    Field('renewalSchedule', String, 'Renewal Schedule',
        hint: 'When certs must renew'),
    Field('maintenanceRequirements', String, 'Maintenance Requirements',
        hint: 'Ongoing maintenance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cost requirements.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ],
  'Captures the budget and resource requirements for certification.',
)
@SectionId('CRSC')
class CertificationRequirementsSectionCosts {
  @Form([
    Field('certificationBudget', String, 'Certification Budget',
        hint: 'Budget for certification'),
    Field('ongoingCosts', String, 'Ongoing Costs',
        hint: 'Recurring costs'),
    Field('resourceRequirements', String, 'Resource Requirements',
        hint: 'Personnel needed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Marketing and notes.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ],
  'Captures how achieved certifications are displayed and used in marketing.',
)
@SectionId('CRSM')
class CertificationRequirementsSectionMarketing {
  @Form([
    Field('certificationDisplay', String, 'Certification Display',
        hint: 'How to display certs'),
    Field('marketingUse', String, 'Marketing Use',
        hint: 'Use in marketing'),
    Field('notes', String, 'Notes',
        hint: 'Additional certification notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance verification section.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ],
  'Describes how compliance is verified through review, auditing, and reporting.',
)
@SectionId('COVESE')
class ComplianceVerificationSection {
  @Form([
    Field('verificationStrategy', String, 'Verification Strategy',
        hint: 'Overall verification approach'),
    Field('frequencyOfReview', String, 'Review Frequency',
        hint: 'How often to verify'),
    Field('automatedChecks', String, 'Automated Checks',
        hint: 'Automated compliance checks'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Manual review procedures.
  @SerializationOrder(1)
  ComplianceVerificationSectionReview review =
      ComplianceVerificationSectionReview();

  /// Tooling and dashboards.
  @SerializationOrder(2)
  ComplianceVerificationSectionTools tools =
      ComplianceVerificationSectionTools();

  /// Audit procedures.
  @SerializationOrder(3)
  ComplianceVerificationSectionAuditing auditing =
      ComplianceVerificationSectionAuditing();

  /// Reporting requirements.
  @SerializationOrder(4)
  ComplianceVerificationSectionReporting reporting =
      ComplianceVerificationSectionReporting();

  /// Continuous monitoring and improvement.
  @SerializationOrder(5)
  ComplianceVerificationSectionContinuous continuous =
      ComplianceVerificationSectionContinuous();
}

/// Manual review procedures.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ],
  'Captures the manual review procedures for verifying compliance.',
)
@SectionId('CVSR')
class ComplianceVerificationSectionReview {
  @Form([
    Field('manualReviews', String, 'Manual Reviews',
        hint: 'Manual review process'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Tooling and dashboards.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security management',
    'ISO 9001 — quality management systems',
  ],
  'Captures the tooling and dashboards used to track compliance.',
)
@SectionId('CVST')
class ComplianceVerificationSectionTools {
  @Form([
    Field('complianceTools', String, 'Compliance Tools',
        hint: 'Tools for compliance tracking'),
    Field('dashboards', String, 'Compliance Dashboards',
        hint: 'Compliance dashboards'),
    Field('alerting', String, 'Alerting',
        hint: 'Compliance alert mechanism'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Audit procedures.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ],
  'Captures the internal and external audit procedures for compliance verification.',
)
@SectionId('CVSA')
class ComplianceVerificationSectionAuditing {
  @Form([
    Field('internalAuditProcess', String, 'Internal Audit Process',
        hint: 'Internal audit approach'),
    Field('externalAuditProcess', String, 'External Audit Process',
        hint: 'External audit approach'),
    Field('auditTrail', String, 'Audit Trail',
        hint: 'Audit trail requirements'),
    Field('findingsResolution', String, 'Findings Resolution',
        hint: 'How findings are resolved'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reporting requirements.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ],
  'Captures compliance, management, and regulatory reporting requirements.',
)
@SectionId('COVESERE')
class ComplianceVerificationSectionReporting {
  @Form([
    Field('complianceReporting', String, 'Compliance Reporting',
        hint: 'Reporting requirements'),
    Field('managementReporting', String, 'Management Reporting',
        hint: 'Reports to management'),
    Field('regulatoryReporting', String, 'Regulatory Reporting',
        hint: 'Reports to regulators'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Continuous monitoring and improvement.
@StandardReferences(
  [
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ],
  'Captures continuous monitoring and improvement of compliance posture.',
)
@SectionId('CVSC')
class ComplianceVerificationSectionContinuous {
  @Form([
    Field('continuousMonitoring', String, 'Continuous Monitoring',
        hint: 'Ongoing monitoring'),
    Field('improvementProcess', String, 'Improvement Process',
        hint: 'Continuous improvement'),
    Field('notes', String, 'Notes',
        hint: 'Additional compliance verification notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 8.4. Hardware Concept Requirements.
@DetailedIn(D06ArchitectureTechnologySpecification)
@SecondLevelSectionId(D06ArchitectureTechnologySpecification, 'ATS-HAR')
@ContentHelp('''
Define hardware infrastructure requirements for servers, clients, and
network. Hardware decisions impact performance, availability, cost,
and operational complexity.

**Subsections**:
- **Server Requirements**: Compute (CPU, memory, GPU), storage, load
  profiles, scaling, virtualization, cloud providers
- **Client Requirements**: Browser requirements, desktop/mobile devices,
  display specifications, accessibility devices
- **Network Requirements**: Bandwidth, latency, availability, geographic
  distribution, VPN, firewall, CDN

**Deployment Models**:
- **On-Premises**: Full control, capital expenditure, data sovereignty
- **Cloud (IaaS)**: Virtual machines, managed infrastructure, OpEx model
- **Cloud (PaaS)**: Managed services, less control, faster development
- **Hybrid**: Mix of on-prem and cloud for compliance/optimization
- **Edge**: Distributed compute for latency-sensitive applications

**Capacity Planning Considerations**:
- Current and projected user load
- Data growth rate and retention
- Peak vs. average utilization
- Burst capacity requirements
- Geographic distribution needs
''')
@StandardReferences(
  [
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the hardware infrastructure requirements for servers, clients, and network.',
)
@SectionId('HR')
class HardwareRequirements {
  @ContentHelp('''
Provide an overview of hardware strategy and infrastructure approach.

**Include**:
- Infrastructure strategy (cloud, on-prem, hybrid)
- Key capacity requirements
- Cost optimization approach
- Disaster recovery infrastructure
- Hardware refresh and upgrade plan

**Best Practices**:
- Use Infrastructure as Code (Terraform, Pulumi)
- Plan for 3x peak capacity
- Implement auto-scaling where possible
- Document hardware assumptions and risks
- Regular capacity reviews and forecasting
''')
  @SerializationOrder(0)
  String? content;

  /// 8.4.1. Server Requirements.
  @SerializationOrder(1)
  ServerRequirementsSection serverRequirements = ServerRequirementsSection();

  /// 8.4.2. Client Requirements.
  @SerializationOrder(2)
  ClientRequirementsSection clientRequirements = ClientRequirementsSection();

  /// 8.4.3. Network Requirements.
  @SerializationOrder(3)
  NetworkRequirementsSection networkRequirements = NetworkRequirementsSection();
}

// =============================================================================
// 8.4.1. Server Requirements
// =============================================================================

/// 8.4.1. Server Requirements.
///
/// Server compute requirements: CPU, memory, storage, expected load profile,
/// and scaling requirements.
@ContentHelp('''
Specify server infrastructure requirements including compute, storage,
scaling, and high availability. Server sizing directly impacts
performance, cost, and reliability.

**Compute Requirements**:
- CPU: Core count, clock speed, architecture (x86, ARM, GPU)
- Memory: RAM size, memory-to-CPU ratio, swap configuration
- GPU: For ML/AI workloads, graphics processing, video transcoding

**Storage Requirements**:
- Storage type: SSD, NVMe, HDD, network storage (NAS, SAN)
- IOPS and throughput requirements
- Storage tiers (hot, warm, cold, archive)
- Backup and snapshot storage

**Environment Tiers**:
- Production: Full capacity, HA, all security controls
- Staging: Production-like for final testing
- Development: Minimal resources, rapid iteration
- Disaster Recovery: Standby capacity for failover

**Scaling Strategy**:
- Vertical scaling limits and upgrade paths
- Horizontal scaling: stateless design, load balancing
- Auto-scaling triggers and limits
- Database scaling: read replicas, sharding

**Cloud Provider Services**:
- Compute: EC2, Cloud Compute, Azure VMs, Cloud Run, Lambda
- Managed Kubernetes: EKS, GKE, AKS
- Serverless: Lambda, Cloud Functions, Azure Functions
''')
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'IaaS / cloud infrastructure — server provisioning',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the overall server infrastructure requirements: compute, storage, scaling, and high availability.',
)
@SectionId('SRS')
class ServerRequirementsSection {
  @ContentHelp('''
Provide an overview of server infrastructure strategy.

**Include**:
- Server tier definitions and sizing
- Scaling strategy and limits
- High availability approach
- Cloud provider selection rationale
- Cost estimates and optimization plan

**Best Practices**:
- Right-size instances based on actual usage
- Use reserved instances for stable workloads
- Implement cost allocation tagging
- Plan for zone and region redundancy
- Document capacity planning assumptions
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of server infrastructure strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Server environment tiers (dev, staging, production, DR).
  @StandardReferences(
    ['IaaS / cloud infrastructure — server provisioning'],
    'The server environments the system is deployed to.',
  )
  @SectionId('SEENEN-ENVI-LST')
  @SectionIdPattern('SEENEN-ENVI-xxx')
  @ContentHelp('Add one entry per server environment.')
  @SerializationOrder(2)
  List<ServerEnvironmentEntry> environments = [];

  /// Server role definitions (app server, db server, web server).
  @StandardReferences(
    ['ISO/IEC/IEEE 42010 — architecture description'],
    'The server roles that make up the deployment.',
  )
  @SectionId('SEROEN-SERV-LST')
  @SectionIdPattern('SEROEN-SERV-xxx')
  @ContentHelp('Add one entry per server role.')
  @SerializationOrder(3)
  List<ServerRoleEntry> serverRoles = [];

  /// Compute resource requirements.
  @SerializationOrder(4)
  ComputeResourceRequirements computeResources = ComputeResourceRequirements();

  /// Storage requirements.
  @SerializationOrder(5)
  ServerStorageRequirements storageRequirements = ServerStorageRequirements();

  /// Load profile and capacity planning.
  @SerializationOrder(6)
  LoadProfileRequirements loadProfile = LoadProfileRequirements();

  /// Scaling requirements and strategy.
  @SerializationOrder(7)
  ScalingRequirements scalingRequirements = ScalingRequirements();

  /// High availability requirements.
  @SerializationOrder(8)
  HighAvailabilityRequirements highAvailability = HighAvailabilityRequirements();

  /// Virtualization and containerization requirements.
  @SerializationOrder(9)
  VirtualizationRequirements virtualization = VirtualizationRequirements();

  /// Cloud provider requirements.
  @SerializationOrder(10)
  CloudProviderRequirements cloudProvider = CloudProviderRequirements();

  /// Operating system requirements.
  @SerializationOrder(11)
  ServerOsRequirements osRequirements = ServerOsRequirements();
}

/// Server environment entry (development, staging, production, DR).
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'C4 model — deployment diagrams',
  ],
  'Captures a single server environment tier and its location, scale, and lifecycle.',
)
@SectionId('SEE')
class ServerEnvironmentEntry {
  @Form([
    Field('environmentName', String, 'Environment Name',
        required: true, hint: 'E.g., Development, Staging, Production'),
    Field('environmentType', String, 'Environment Type',
        hint: 'Development, QA, UAT, Staging, Production, DR'),
    Field('environmentCode', String, 'Environment Code',
        hint: 'dev, stg, prod, dr'),
    Field('purpose', String, 'Purpose',
        hint: 'Primary purpose of this environment'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Location details.
  @SerializationOrder(1)
  ServerEnvironmentEntryLocation location = ServerEnvironmentEntryLocation();

  /// Scale expectations.
  @SerializationOrder(2)
  ServerEnvironmentEntryScale scale = ServerEnvironmentEntryScale();

  /// Access rules.
  @SerializationOrder(3)
  ServerEnvironmentEntryAccess access = ServerEnvironmentEntryAccess();

  /// Lifecycle rules.
  @SerializationOrder(4)
  ServerEnvironmentEntryLifecycle lifecycle = ServerEnvironmentEntryLifecycle();
}

/// Location details.
@StandardReferences(
  [
    'TIA-942 — data center infrastructure',
    'IaaS / cloud infrastructure — server provisioning',
  ],
  'Captures the region, data center, and availability zone for a server environment.',
)
@SectionId('SEEL')
class ServerEnvironmentEntryLocation {
  @Form([
    Field('region', String, 'Region',
        hint: 'Geographic region'),
    Field('dataCenter', String, 'Data Center',
        hint: 'Data center location'),
    Field('availabilityZone', String, 'Availability Zone',
        hint: 'Availability zone'),
    Field('cloudRegion', String, 'Cloud Region',
        hint: 'Cloud provider region'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scale expectations.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the server count, expected users, and load for a server environment.',
)
@SectionId('SEES')
class ServerEnvironmentEntryScale {
  @Form([
    Field('serverCount', int, 'Server Count',
        hint: 'Number of servers in environment'),
    Field('expectedUsers', String, 'Expected Users',
        hint: 'Concurrent users expected'),
    Field('expectedLoad', String, 'Expected Load',
        hint: 'Requests per second'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access rules.
@StandardReferences(
  [
    'ISO/IEC 27033 — network / infrastructure security',
  ],
  'Captures the access restrictions, network segment, and VPN requirements for a server environment.',
)
@SectionId('SEEA')
class ServerEnvironmentEntryAccess {
  @Form([
    Field('accessRestrictions', String, 'Access Restrictions',
        hint: 'Who can access this environment'),
    Field('networkSegment', String, 'Network Segment',
        hint: 'VPC/network segment'),
    Field('vpnRequired', bool, 'VPN Required',
        hint: 'VPN access required'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Lifecycle rules.
@StandardReferences(
  [
    'IaaS / cloud infrastructure — server provisioning',
    'Twelve-Factor App — cloud-native deployment',
  ],
  'Captures the refresh schedule and retention policy for a server environment.',
)
@SectionId('SEENENLI')
class ServerEnvironmentEntryLifecycle {
  @Form([
    Field('refreshSchedule', String, 'Refresh Schedule',
        hint: 'Data refresh schedule'),
    Field('retentionPolicy', String, 'Retention Policy',
        hint: 'Data retention policy'),
    Field('notes', String, 'Notes',
        hint: 'Additional environment notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Server role entry (application server, database server, web server).
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'C4 model — deployment diagrams',
  ],
  'Captures a single server role definition and its associated capacity and networking.',
)
@SectionId('SRE')
class ServerRoleEntry {
  @Form([
    Field('roleName', String, 'Role Name',
        required: true, hint: 'E.g., Application Server, Database Server'),
    Field('roleType', String, 'Role Type',
        hint: 'App, Web, Database, Cache, Queue, Gateway'),
    Field('roleAbbreviation', String, 'Abbreviation',
        hint: 'Short code for role'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Software stack details.
  @SerializationOrder(1)
  ServerRoleEntrySoftware software = ServerRoleEntrySoftware();

  /// Capacity requirements.
  @SerializationOrder(2)
  ServerRoleEntryCapacity capacity = ServerRoleEntryCapacity();

  /// Storage requirements.
  @SerializationOrder(3)
  ServerRoleEntryStorage storage = ServerRoleEntryStorage();

  /// Networking requirements.
  @SerializationOrder(4)
  ServerRoleEntryNetworking networking = ServerRoleEntryNetworking();
}

/// Software stack details.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'C4 model — deployment diagrams',
  ],
  'Captures the software stack, runtime, and OS for a server role.',
)
@SectionId('SRES')
class ServerRoleEntrySoftware {
  @Form([
    Field('softwareStack', String, 'Software Stack',
        hint: 'Software installed on this server'),
    Field('runtimeEnvironment', String, 'Runtime Environment',
        hint: 'JVM, Node.js, .NET, Python'),
    Field('osType', String, 'Operating System',
        hint: 'Linux distro, Windows Server'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Capacity requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the CPU architecture and memory sizing for a server role.',
)
@SectionId('SREC')
class ServerRoleEntryCapacity {
  @Form([
    Field('cpuArchitecture', String, 'CPU Architecture',
        hint: 'x64, ARM64'),
    Field('minMemoryGb', int, 'Minimum Memory (GB)',
        hint: 'Minimum RAM in GB'),
    Field('recommendedMemoryGb', int, 'Recommended Memory (GB)',
        hint: 'Recommended RAM in GB'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Storage requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'TIA-942 — data center infrastructure',
  ],
  'Captures the storage type, capacity, and IOPS for a server role.',
)
@SectionId('SEROENST')
class ServerRoleEntryStorage {
  @Form([
    Field('storageType', String, 'Storage Type',
        hint: 'SSD, HDD, NVMe'),
    Field('storageCapacityGb', int, 'Storage Capacity (GB)',
        hint: 'Required storage in GB'),
    Field('iopsRequired', int, 'IOPS Required',
        hint: 'Required I/O operations per second'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Networking requirements.
@StandardReferences(
  [
    'ISO/IEC 27033 — network / infrastructure security',
    'C4 model — deployment diagrams',
  ],
  'Captures the network bandwidth and exposed ports for a server role.',
)
@SectionId('SREN')
class ServerRoleEntryNetworking {
  @Form([
    Field('networkBandwidth', String, 'Network Bandwidth',
        hint: 'Required network bandwidth'),
    Field('exposedPorts', String, 'Exposed Ports',
        hint: 'Ports exposed by this server'),
    Field('notes', String, 'Notes', hint: 'Additional server role notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compute resource requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the CPU core, architecture, and benchmark requirements for server compute.',
)
@SectionId('CORERE')
class ComputeResourceRequirements {
  @Form([
    Field('minCpuCores', String, 'Minimum CPU Cores',
        hint: 'Total minimum CPU cores'),
    Field('recommendedCpuCores', String, 'Recommended CPU Cores',
        hint: 'Recommended CPU cores'),
    Field('cpuArchitecture', String, 'CPU Architecture',
        hint: 'x64, ARM64, or both'),
    Field('cpuGeneration', String, 'CPU Generation',
        hint: 'Intel Xeon, AMD EPYC'),
    Field('specIntBenchmark', String, 'SPECint Benchmark',
        hint: 'Minimum SPECint score'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Memory requirements.
  @SerializationOrder(1)
  ComputeResourceRequirementsMemory memory =
      ComputeResourceRequirementsMemory();

  /// GPU requirements.
  @SerializationOrder(2)
  ComputeResourceRequirementsGpu gpu = ComputeResourceRequirementsGpu();

  /// Special hardware requirements.
  @SerializationOrder(3)
  ComputeResourceRequirementsSpecial special =
      ComputeResourceRequirementsSpecial();
}

/// Memory requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the server memory sizing, type, and ECC requirements.',
)
@SectionId('CRRM')
class ComputeResourceRequirementsMemory {
  @Form([
    Field('minMemoryGb', String, 'Minimum Memory (GB)',
        hint: 'Total minimum RAM'),
    Field('recommendedMemoryGb', String, 'Recommended Memory (GB)',
        hint: 'Recommended RAM'),
    Field('memoryType', String, 'Memory Type',
        hint: 'DDR4, DDR5'),
    Field('eccRequired', bool, 'ECC Required',
        hint: 'Error-correcting memory'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// GPU requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the GPU type, memory, and count required for compute-intensive workloads.',
)
@SectionId('CRRG')
class ComputeResourceRequirementsGpu {
  @Form([
    Field('gpuRequired', bool, 'GPU Required',
        hint: 'GPU computation needed'),
    Field('gpuType', String, 'GPU Type',
        hint: 'NVIDIA A100, T4, etc.'),
    Field('gpuMemoryGb', int, 'GPU Memory (GB)',
        hint: 'GPU memory required'),
    Field('gpuCount', int, 'GPU Count',
        hint: 'Number of GPUs'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Special hardware requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'ISO/IEC 27033 — network / infrastructure security',
  ],
  'Captures special hardware needs such as TPM and secure enclave requirements.',
)
@SectionId('CRRS')
class ComputeResourceRequirementsSpecial {
  @Form([
    Field('tpmRequired', bool, 'TPM Required',
        hint: 'Trusted Platform Module'),
    Field('secureEnclaveRequired', bool, 'Secure Enclave Required',
        hint: 'SGX or similar'),
    Field('notes', String, 'Notes',
        hint: 'Additional compute notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Server storage requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'TIA-942 — data center infrastructure',
  ],
  'Captures the primary server storage type, capacity, IOPS, and read/write profile.',
)
@SectionId('SESTRE')
class ServerStorageRequirements {
  @Form([
    Field('primaryStorageType', String, 'Primary Storage Type',
        hint: 'SSD, NVMe, HDD'),
    Field('primaryStorageCapacity', String, 'Primary Storage Capacity',
        hint: 'Total primary storage'),
    Field('primaryIops', String, 'Primary IOPS',
        hint: 'Required IOPS'),
    Field('readWriteRatio', String, 'Read/Write Ratio',
        hint: 'Expected R/W ratio'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Database storage requirements.
  @SerializationOrder(1)
  ServerStorageRequirementsDatabase database =
      ServerStorageRequirementsDatabase();

  /// File storage requirements.
  @SerializationOrder(2)
  ServerStorageRequirementsFileStorage fileStorage =
      ServerStorageRequirementsFileStorage();

  /// Backup storage requirements.
  @SerializationOrder(3)
  ServerStorageRequirementsBackup backup = ServerStorageRequirementsBackup();

  /// Performance requirements and notes.
  @SerializationOrder(4)
  ServerStorageRequirementsPerformance performance =
      ServerStorageRequirementsPerformance();
}

/// Database storage requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'TIA-942 — data center infrastructure',
  ],
  'Captures the database storage type, capacity, and IOPS requirements.',
)
@SectionId('SSRD')
class ServerStorageRequirementsDatabase {
  @Form([
    Field('databaseStorageType', String, 'Database Storage Type',
        hint: 'Storage for databases'),
    Field('databaseStorageCapacity', String, 'Database Storage Capacity',
        hint: 'Database storage size'),
    Field('databaseIops', String, 'Database IOPS', hint: 'Database IOPS'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// File storage requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'TIA-942 — data center infrastructure',
  ],
  'Captures the file storage type, capacity, and network file system requirements.',
)
@SectionId('SSRFS')
class ServerStorageRequirementsFileStorage {
  @Form([
    Field('fileStorageType', String, 'File Storage Type',
        hint: 'NAS, SAN, object storage'),
    Field('fileStorageCapacity', String, 'File Storage Capacity',
        hint: 'File storage size'),
    Field('networkFileSystem', String, 'Network File System',
        hint: 'NFS, SMB, etc.'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Backup storage requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'TIA-942 — data center infrastructure',
  ],
  'Captures the backup storage medium, capacity, and retention requirements.',
)
@SectionId('SSRB')
class ServerStorageRequirementsBackup {
  @Form([
    Field('backupStorageType', String, 'Backup Storage Type',
        hint: 'Backup storage medium'),
    Field('backupStorageCapacity', String, 'Backup Storage Capacity',
        hint: 'Backup storage size'),
    Field('backupRetention', String, 'Backup Retention',
        hint: 'Retention period'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Performance requirements and notes.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the storage throughput and latency performance requirements.',
)
@SectionId('SSRP')
class ServerStorageRequirementsPerformance {
  @Form([
    Field('throughputRequired', String, 'Throughput Required',
        hint: 'MB/s throughput'),
    Field('latencyRequirement', String, 'Latency Requirement',
        hint: 'Maximum latency'),
    Field('notes', String, 'Notes', hint: 'Additional storage notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Load profile requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the user and load profile that sizes the server capacity plan.',
)
@SectionId('LOPRRE')
class LoadProfileRequirements {
  @Form([
    Field('peakConcurrentUsers', String, 'Peak Concurrent Users',
        hint: 'Maximum concurrent users'),
    Field('averageConcurrentUsers', String, 'Average Concurrent Users',
        hint: 'Typical concurrent users'),
    Field('totalRegisteredUsers', String, 'Total Registered Users',
        hint: 'Total user base'),
    Field('userGrowthRate', String, 'User Growth Rate',
        hint: 'Expected growth %/year'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Request volume assumptions.
  @SerializationOrder(1)
  LoadProfileRequirementsRequestLoad requestLoad =
      LoadProfileRequirementsRequestLoad();

  /// Temporal and seasonal patterns.
  @SerializationOrder(2)
  LoadProfileRequirementsPatterns patterns = LoadProfileRequirementsPatterns();

  /// Performance target metrics.
  @SerializationOrder(3)
  LoadProfileRequirementsPerformanceTargets performanceTargets =
      LoadProfileRequirementsPerformanceTargets();
}

/// Request volume assumptions.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the request-rate and payload-size assumptions that drive server load.',
)
@SectionId('LPRRL')
class LoadProfileRequirementsRequestLoad {
  @Form([
    Field('peakRequestsPerSecond', String, 'Peak Requests/Second',
        hint: 'Maximum RPS'),
    Field('averageRequestsPerSecond', String, 'Average Requests/Second',
        hint: 'Typical RPS'),
    Field('requestSizeAverage', String, 'Average Request Size',
        hint: 'Average payload size'),
    Field('responseSizeAverage', String, 'Average Response Size',
        hint: 'Average response size'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Temporal and seasonal patterns.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the temporal, seasonal, and event-driven load patterns for capacity planning.',
)
@SectionId('LPRP')
class LoadProfileRequirementsPatterns {
  @Form([
    Field('peakHours', String, 'Peak Hours', hint: 'Time of day for peak load'),
    Field('peakDays', String, 'Peak Days', hint: 'Days of week for peak load'),
    Field('seasonalPatterns', String, 'Seasonal Patterns',
        hint: 'Seasonal variations'),
    Field('eventDrivenSpikes', String, 'Event-Driven Spikes',
        hint: 'Known spike events'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Performance target metrics.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the response-time percentile targets that the server tier must meet.',
)
@SectionId('LPRPT')
class LoadProfileRequirementsPerformanceTargets {
  @Form([
    Field('responseTimeP50', String, 'Response Time P50',
        hint: '50th percentile latency'),
    Field('responseTimeP95', String, 'Response Time P95',
        hint: '95th percentile latency'),
    Field('responseTimeP99', String, 'Response Time P99',
        hint: '99th percentile latency'),
    Field('notes', String, 'Notes',
        hint: 'Additional load profile notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scaling requirements.
@StandardReferences(
  [
    'IaaS / cloud infrastructure — server provisioning',
    'Twelve-Factor App — cloud-native deployment',
  ],
  'Captures the overall scaling strategy, approach, and triggers for the server tier.',
)
@SectionId('SCRE')
class ScalingRequirements {
  @Form([
    Field('scalingStrategy', String, 'Scaling Strategy',
        hint: 'Horizontal, Vertical, Both'),
    Field('scalingApproach', String, 'Scaling Approach',
        hint: 'Manual, Auto, Scheduled'),
    Field('scalingTriggers', String, 'Scaling Triggers',
        hint: 'What triggers scaling'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Horizontal scaling configuration.
  @SerializationOrder(1)
  ScalingRequirementsHorizontal horizontal = ScalingRequirementsHorizontal();

  /// Vertical scaling configuration.
  @SerializationOrder(2)
  ScalingRequirementsVertical vertical = ScalingRequirementsVertical();

  /// Auto-scaling thresholds.
  @SerializationOrder(3)
  ScalingRequirementsAutoScaling autoScaling =
      ScalingRequirementsAutoScaling();

  /// Budget and timing constraints.
  @SerializationOrder(4)
  ScalingRequirementsConstraints constraints =
      ScalingRequirementsConstraints();
}

/// Horizontal scaling configuration.
@StandardReferences(
  [
    'IaaS / cloud infrastructure — server provisioning',
    'Twelve-Factor App — cloud-native deployment',
  ],
  'Captures the horizontal-scaling instance bounds, startup time, and session handling.',
)
@SectionId('SCREHO')
class ScalingRequirementsHorizontal {
  @Form([
    Field('minInstances', int, 'Minimum Instances',
        hint: 'Minimum server count'),
    Field('maxInstances', int, 'Maximum Instances',
        hint: 'Maximum server count'),
    Field('instanceStartupTime', String, 'Instance Startup Time',
        hint: 'Time to add capacity'),
    Field('sessionHandling', String, 'Session Handling',
        hint: 'Sticky, distributed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Vertical scaling configuration.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'IaaS / cloud infrastructure — server provisioning',
  ],
  'Captures the vertical-scaling limits for CPU and memory upgrades.',
)
@SectionId('SCREVE')
class ScalingRequirementsVertical {
  @Form([
    Field('canVerticallyScale', bool, 'Can Vertically Scale',
        hint: 'Allow CPU/RAM increases'),
    Field('maxCpuCores', int, 'Max CPU Cores',
        hint: 'Maximum CPU cores'),
    Field('maxMemoryGb', int, 'Max Memory (GB)',
        hint: 'Maximum RAM'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Auto-scaling thresholds.
@StandardReferences(
  [
    'IaaS / cloud infrastructure — server provisioning',
    'Twelve-Factor App — cloud-native deployment',
  ],
  'Captures the auto-scaling thresholds, cooldown, and scale-down policy.',
)
@SectionId('SRAS')
class ScalingRequirementsAutoScaling {
  @Form([
    Field('cpuThresholdScale', String, 'CPU Scale Threshold',
        hint: 'CPU % to trigger scale'),
    Field('memoryThresholdScale', String, 'Memory Scale Threshold',
        hint: 'Memory % to trigger scale'),
    Field('cooldownPeriod', String, 'Cooldown Period',
        hint: 'Time between scale events'),
    Field('scaleDownPolicy', String, 'Scale Down Policy',
        hint: 'How to scale down'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Budget and timing constraints.
@StandardReferences(
  [
    'IaaS / cloud infrastructure — server provisioning',
    'Twelve-Factor App — cloud-native deployment',
  ],
  'Captures the budget and timing constraints that bound scaling decisions.',
)
@SectionId('SCRECO')
class ScalingRequirementsConstraints {
  @Form([
    Field('budgetConstraint', String, 'Budget Constraint',
        hint: 'Cost limits for scaling'),
    Field('scalingWindow', String, 'Scaling Window',
        hint: 'When scaling is allowed'),
    Field('notes', String, 'Notes', hint: 'Additional scaling notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// High availability requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the overall availability target, downtime budget, and maintenance windows.',
)
@SectionId('HIAVRE')
class HighAvailabilityRequirements {
  @Form([
    Field('availabilityTarget', String, 'Availability Target',
        hint: '99.9%, 99.99%, etc.'),
    Field('downtimeBudgetMonthly', String, 'Monthly Downtime Budget',
        hint: 'Allowed downtime/month'),
    Field('plannedMaintenanceWindow', String, 'Planned Maintenance Window',
        hint: 'When maintenance allowed'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Redundancy model.
  @SerializationOrder(1)
  HighAvailabilityRequirementsRedundancy redundancy =
      HighAvailabilityRequirementsRedundancy();

  /// Failover behavior.
  @SerializationOrder(2)
  HighAvailabilityRequirementsFailover failover =
      HighAvailabilityRequirementsFailover();

  /// Load balancing behavior.
  @SerializationOrder(3)
  HighAvailabilityRequirementsLoadBalancing loadBalancing =
      HighAvailabilityRequirementsLoadBalancing();

  /// Disaster recovery alignment.
  @SerializationOrder(4)
  HighAvailabilityRequirementsDisasterRecovery disasterRecovery =
      HighAvailabilityRequirementsDisasterRecovery();
}

/// Redundancy model.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the redundancy level, scope, and geographic/active-active model for resilience.',
)
@SectionId('HARR')
class HighAvailabilityRequirementsRedundancy {
  @Form([
    Field('redundancyLevel', String, 'Redundancy Level',
        hint: 'N+1, 2N, etc.'),
    Field('redundancyScope', String, 'Redundancy Scope',
        hint: 'Server, rack, datacenter'),
    Field('geographicRedundancy', bool, 'Geographic Redundancy',
        hint: 'Multi-region deployment'),
    Field('activeActiveMode', bool, 'Active-Active Mode',
        hint: 'All sites active'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Failover behavior.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the failover type, timing, failback procedure, and health-check interval.',
)
@SectionId('HARF')
class HighAvailabilityRequirementsFailover {
  @Form([
    Field('failoverType', String, 'Failover Type',
        hint: 'Automatic, manual'),
    Field('failoverTime', String, 'Failover Time',
        hint: 'Maximum failover time'),
    Field('failbackProcedure', String, 'Failback Procedure',
        hint: 'How to restore primary'),
    Field('healthCheckInterval', String, 'Health Check Interval',
        hint: 'How often to check health'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Load balancing behavior.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the load-balancer type, algorithm, and health-check behavior for high availability.',
)
@SectionId('HARLB')
class HighAvailabilityRequirementsLoadBalancing {
  @Form([
    Field('loadBalancerType', String, 'Load Balancer Type',
        hint: 'L4, L7, DNS-based'),
    Field('loadBalancingAlgorithm', String, 'Load Balancing Algorithm',
        hint: 'Round-robin, least-conn'),
    Field('healthCheckEndpoint', String, 'Health Check Endpoint',
        hint: 'Endpoint for health checks'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Disaster recovery alignment.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Captures the disaster-recovery site and replication method that back the high-availability model.',
)
@SectionId('HARDR')
class HighAvailabilityRequirementsDisasterRecovery {
  @Form([
    Field('drSite', String, 'DR Site',
        hint: 'Disaster recovery location'),
    Field('drSyncMethod', String, 'DR Sync Method',
        hint: 'Sync or async replication'),
    Field('notes', String, 'Notes', hint: 'Additional HA notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Virtualization and containerization requirements.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native deployment',
    'IaaS / cloud infrastructure — server provisioning',
  ],
  'Captures the deployment model and virtualization/containerization platform choices.',
)
@SectionId('VIRE')
class VirtualizationRequirements {
  @Form([
    Field('deploymentModel', String, 'Deployment Model',
        hint: 'Bare metal, VM, Container'),
    Field('primaryPlatform', String, 'Primary Platform',
        hint: 'VMware, Docker, Kubernetes'),
    Field('orchestrationPlatform', String, 'Orchestration Platform',
        hint: 'Kubernetes, ECS, etc.'),
  ])
  @SerializationOrder(0)
  String? content;

  /// VM requirements.
  @SerializationOrder(1)
  VirtualizationRequirementsVm vm = VirtualizationRequirementsVm();

  /// Container requirements.
  @SerializationOrder(2)
  VirtualizationRequirementsContainer container =
      VirtualizationRequirementsContainer();

  /// Kubernetes requirements.
  @SerializationOrder(3)
  VirtualizationRequirementsKubernetes kubernetes =
      VirtualizationRequirementsKubernetes();

  /// Networking requirements.
  @SerializationOrder(4)
  VirtualizationRequirementsNetworking networking =
      VirtualizationRequirementsNetworking();
}

/// VM requirements.
@StandardReferences(
  [
    'IaaS / cloud infrastructure — server provisioning',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the virtual-machine hypervisor, image format, and template requirements.',
)
@SectionId('VIREVM')
class VirtualizationRequirementsVm {
  @Form([
    Field('hypervisorType', String, 'Hypervisor Type',
        hint: 'VMware, Hyper-V, KVM'),
    Field('vmImageFormat', String, 'VM Image Format',
        hint: 'OVA, AMI, VHD'),
    Field('vmTemplateRequired', bool, 'VM Template Required',
        hint: 'Golden image needed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Container requirements.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native deployment',
    'IaaS / cloud infrastructure — server provisioning',
  ],
  'Captures the container runtime, base image, registry, and image-scanning requirements.',
)
@SectionId('VIRECO')
class VirtualizationRequirementsContainer {
  @Form([
    Field('containerRuntime', String, 'Container Runtime',
        hint: 'Docker, containerd, CRI-O'),
    Field('baseImage', String, 'Base Image',
        hint: 'Base container image'),
    Field('registryUrl', String, 'Registry URL',
        hint: 'Container registry'),
    Field('imageScanningRequired', bool, 'Image Scanning Required',
        hint: 'Security scanning'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Kubernetes requirements.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native deployment',
    'IaaS / cloud infrastructure — server provisioning',
  ],
  'Captures the Kubernetes version, distribution, namespace strategy, and resource quotas.',
)
@SectionId('VIREKU')
class VirtualizationRequirementsKubernetes {
  @Form([
    Field('k8sVersion', String, 'Kubernetes Version',
        hint: 'Required K8s version'),
    Field('k8sDistribution', String, 'Kubernetes Distribution',
        hint: 'EKS, GKE, AKS, OpenShift'),
    Field('namespaceStrategy', String, 'Namespace Strategy',
        hint: 'Per-env, per-service'),
    Field('resourceQuotas', String, 'Resource Quotas',
        hint: 'CPU/memory limits'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Networking requirements.
@StandardReferences(
  [
    'ISO/IEC 27033 — network / infrastructure security',
    'C4 model — deployment diagrams',
  ],
  'Captures the virtualization networking layer such as service mesh and ingress control.',
)
@SectionId('VIRENE')
class VirtualizationRequirementsNetworking {
  @Form([
    Field('serviceMesh', String, 'Service Mesh',
        hint: 'Istio, Linkerd'),
    Field('ingressController', String, 'Ingress Controller',
        hint: 'NGINX, Traefik'),
    Field('notes', String, 'Notes',
        hint: 'Additional virtualization notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cloud provider requirements.
@StandardReferences(
  [
    'IaaS / cloud infrastructure — server provisioning',
    'Twelve-Factor App — cloud-native deployment',
  ],
  'Captures the cloud provider selection and multi-cloud strategy for hosting the system.',
)
@SectionId('CLPRRE')
class CloudProviderRequirements {
  @Form([
    Field('primaryProvider', String, 'Primary Cloud Provider',
        hint: 'AWS, Azure, GCP, Private'),
    Field('secondaryProvider', String, 'Secondary Provider',
        hint: 'Multi-cloud backup'),
    Field('multiCloudStrategy', String, 'Multi-Cloud Strategy',
        hint: 'Hybrid, Multi-cloud'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Account-structure requirements.
  @SerializationOrder(1)
  CloudProviderRequirementsAccounts accounts =
      CloudProviderRequirementsAccounts();

  /// Service requirements.
  @SerializationOrder(2)
  CloudProviderRequirementsServices services =
      CloudProviderRequirementsServices();

  /// Compliance requirements.
  @SerializationOrder(3)
  CloudProviderRequirementsCompliance compliance =
      CloudProviderRequirementsCompliance();

  /// Governance requirements.
  @SerializationOrder(4)
  CloudProviderRequirementsGovernance governance =
      CloudProviderRequirementsGovernance();
}

/// Account-structure requirements.
@StandardReferences(
  [
    'IaaS / cloud infrastructure — server provisioning',
    'Twelve-Factor App — cloud-native deployment',
  ],
  'Captures the cloud account structure, environment separation, and billing model.',
)
@SectionId('CPRA')
class CloudProviderRequirementsAccounts {
  @Form([
    Field('accountStructure', String, 'Account Structure',
        hint: 'Org structure'),
    Field('environmentSeparation', String, 'Environment Separation',
        hint: 'By account, VPC, etc.'),
    Field('billingModel', String, 'Billing Model',
        hint: 'Pay-as-you-go, reserved'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Service requirements.
@StandardReferences(
  [
    'IaaS / cloud infrastructure — server provisioning',
    'Twelve-Factor App — cloud-native deployment',
  ],
  'Captures the cloud provider services required for compute, storage, database, and networking.',
)
@SectionId('CPRS')
class CloudProviderRequirementsServices {
  @Form([
    Field('computeServices', String, 'Compute Services',
        hint: 'EC2, Lambda, etc.'),
    Field('storageServices', String, 'Storage Services',
        hint: 'S3, EBS, etc.'),
    Field('databaseServices', String, 'Database Services',
        hint: 'RDS, DynamoDB, etc.'),
    Field('networkingServices', String, 'Networking Services',
        hint: 'VPC, Route 53, etc.'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance requirements.
@StandardReferences(
  [
    'ISO/IEC 27033 — network / infrastructure security',
    'IaaS / cloud infrastructure — server provisioning',
  ],
  'Captures cloud compliance requirements such as data sovereignty, certifications, and encryption.',
)
@SectionId('CPRC')
class CloudProviderRequirementsCompliance {
  @Form([
    Field('dataSovereigntyRequirements', String, 'Data Sovereignty',
        hint: 'Data residency requirements'),
    Field('cloudCompliance', String, 'Cloud Compliance',
        hint: 'SOC 2, FedRAMP, etc.'),
    Field('encryptionRequirements', String, 'Encryption Requirements',
        hint: 'At-rest, in-transit'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Governance requirements.
@StandardReferences(
  [
    'IaaS / cloud infrastructure — server provisioning',
    'Twelve-Factor App — cloud-native deployment',
  ],
  'Captures cloud governance requirements such as resource tagging and cost management.',
)
@SectionId('CPRG')
class CloudProviderRequirementsGovernance {
  @Form([
    Field('taggingStrategy', String, 'Tagging Strategy',
        hint: 'Resource tagging'),
    Field('costManagement', String, 'Cost Management',
        hint: 'Budget alerts, limits'),
    Field('notes', String, 'Notes',
        hint: 'Additional cloud provider notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Server operating system requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'IaaS / cloud infrastructure — server provisioning',
  ],
  'Captures the server operating-system requirements including distribution, version, and support level.',
)
@SectionId('SEOSRE')
class ServerOsRequirements {
  @Form([
    Field('primaryOs', String, 'Primary OS',
        required: true, hint: 'Linux, Windows Server'),
    Field('osDistribution', String, 'OS Distribution',
        hint: 'Ubuntu, RHEL, CentOS, Debian'),
    Field('osVersion', String, 'OS Version',
        hint: 'Specific version'),
    Field('supportLevel', String, 'Support Level',
        hint: 'LTS, Standard'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Hardening requirements.
  @SerializationOrder(1)
  ServerOsRequirementsHardening hardening = ServerOsRequirementsHardening();

  /// Security controls.
  @SerializationOrder(2)
  ServerOsRequirementsSecurity security = ServerOsRequirementsSecurity();

  /// Monitoring setup.
  @SerializationOrder(3)
  ServerOsRequirementsMonitoring monitoring = ServerOsRequirementsMonitoring();

  /// Licensing details.
  @SerializationOrder(4)
  ServerOsRequirementsLicensing licensing = ServerOsRequirementsLicensing();
}

/// Hardening requirements.
@StandardReferences(
  [
    'ISO/IEC 27033 — network / infrastructure security',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the server operating-system hardening standard, patching cadence, and update policy.',
)
@SectionId('SORH')
class ServerOsRequirementsHardening {
  @Form([
    Field('hardeningStandard', String, 'Hardening Standard',
        hint: 'CIS, STIG benchmark'),
    Field('patchingFrequency', String, 'Patching Frequency',
        hint: 'How often patched'),
    Field('autoUpdatePolicy', String, 'Auto-Update Policy',
        hint: 'Automatic or manual'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security controls.
@StandardReferences(
  [
    'ISO/IEC 27033 — network / infrastructure security',
    'TIA-942 — data center infrastructure',
  ],
  'Captures the server operating-system security controls such as firewall, mandatory access control, and auditing.',
)
@SectionId('SORS')
class ServerOsRequirementsSecurity {
  @Form([
    Field('firewallConfiguration', String, 'Firewall Configuration',
        hint: 'iptables, firewalld'),
    Field('selinuxMode', String, 'SELinux/AppArmor Mode',
        hint: 'Enforcing, permissive'),
    Field('auditdConfiguration', String, 'Auditd Configuration',
        hint: 'Audit logging requirements'),
    Field('antivirusRequired', bool, 'Antivirus Required',
        hint: 'AV/EDR requirement'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Monitoring setup.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'ISO/IEC 27033 — network / infrastructure security',
  ],
  'Captures the server operating-system monitoring, logging, and performance-observability setup.',
)
@SectionId('SORM')
class ServerOsRequirementsMonitoring {
  @Form([
    Field('loggingConfiguration', String, 'Logging Configuration',
        hint: 'syslog, journald'),
    Field('monitoringAgent', String, 'Monitoring Agent',
        hint: 'Agent for monitoring'),
    Field('performanceMonitoring', String, 'Performance Monitoring',
        hint: 'Performance tools'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Licensing details.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'IaaS / cloud infrastructure — server provisioning',
  ],
  'Captures the operating-system licensing model and license counts for servers.',
)
@SectionId('SORL')
class ServerOsRequirementsLicensing {
  @Form([
    Field('licensingModel', String, 'Licensing Model',
        hint: 'Open source, Enterprise'),
    Field('licenseCount', String, 'License Count',
        hint: 'Number of licenses'),
    Field('notes', String, 'Notes', hint: 'Additional OS notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// =============================================================================
// 8.4.2. Client Requirements
// =============================================================================

/// 8.4.2. Client Requirements.
///
/// Minimum client requirements: browser versions, operating systems, screen
/// resolution, network bandwidth, and device capabilities.
@ContentHelp('''
Specify client device requirements including browsers, operating systems,
display specifications, and accessibility needs. Client requirements
define the user experience boundary conditions.

**Browser Requirements**:
- Supported browsers with minimum versions
- Browser feature requirements (WebGL, WebRTC, Service Workers)
- Mobile browser considerations (Safari iOS, Chrome Android)
- Progressive Web App (PWA) requirements

**Desktop Requirements**:
- Operating systems: Windows 10/11, macOS 12+, Linux distributions
- Hardware minimums: CPU, RAM, disk space
- Required software: .NET runtime, Java, etc.
- Installation and update mechanisms

**Mobile Requirements**:
- iOS minimum version and device support
- Android API level and device compatibility
- Form factors: phone, tablet, foldable
- App store requirements and restrictions

**Display Requirements**:
- Minimum screen resolution
- Responsive design breakpoints
- Touch vs. mouse/keyboard interactions
- HiDPI and retina display support

**Accessibility Requirements**:
- WCAG 2.1 compliance level (A, AA, AAA)
- Screen reader compatibility
- Keyboard navigation
- Color contrast and visual accommodations
''')
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Describes the end-user client requirements across browsers, desktop, mobile, display, network, hardware, accessibility, and security.',
)
@SectionId('CLRESE')
class ClientRequirementsSection {
  @ContentHelp('''
Provide an overview of client requirements and support strategy.

**Include**:
- Browser support matrix and testing approach
- Mobile device tier definitions
- Accessibility compliance target
- Progressive enhancement strategy
- Client update and compatibility policy

**Best Practices**:
- Test on real devices, not just emulators
- Use browser usage analytics for prioritization
- Plan for evergreen browser updates
- Document graceful degradation strategy
- Regular accessibility audits
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of client requirements strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Web browser requirements.
  @StandardReferences(
    ['WHATWG / W3C — web platform / browser standards'],
    'The web browsers the client must support.',
  )
  @SectionId('BRREEN-BROW-LST')
  @SectionIdPattern('BRREEN-BROW-xxx')
  @ContentHelp('Add one entry per supported web browser.')
  @SerializationOrder(2)
  List<BrowserRequirementEntry> browserRequirements = [];

  /// Desktop operating system requirements.
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'The desktop operating systems the client must support.',
  )
  @SectionId('DORE1-DESK-LST')
  @SectionIdPattern('DORE1-DESK-xxx')
  @ContentHelp('Add one entry per supported desktop operating system.')
  @SerializationOrder(3)
  List<DesktopOsRequirementEntry> desktopOsRequirements = [];

  /// Mobile device requirements.
  @StandardReferences(
    ['Android CDD / Apple HIG — mobile device platform requirements'],
    'The mobile platforms and devices the client must support.',
  )
  @SectionId('MDRE-MOBI-LST')
  @SectionIdPattern('MDRE-MOBI-xxx')
  @ContentHelp('Add one entry per supported mobile platform.')
  @SerializationOrder(4)
  List<MobileDeviceRequirementEntry> mobileRequirements = [];

  /// Display and screen requirements.
  @SerializationOrder(5)
  DisplayRequirements displayRequirements = DisplayRequirements();

  /// Client network requirements.
  @SerializationOrder(6)
  ClientNetworkRequirements networkRequirements = ClientNetworkRequirements();

  /// Client hardware requirements.
  @SerializationOrder(7)
  ClientHardwareRequirements hardwareRequirements = ClientHardwareRequirements();

  /// Accessibility requirements for clients.
  @SerializationOrder(8)
  ClientAccessibilityRequirements accessibilityRequirements =
      ClientAccessibilityRequirements();

  /// Progressive Web App (PWA) requirements.
  @SerializationOrder(9)
  PwaRequirements pwaRequirements = PwaRequirements();

  /// Native app requirements.
  @SerializationOrder(10)
  NativeAppRequirements nativeAppRequirements = NativeAppRequirements();

  /// Client security requirements.
  @SerializationOrder(11)
  ClientSecurityRequirements securityRequirements = ClientSecurityRequirements();
}

/// Browser requirement entry.
@StandardReferences(
  [
    'WHATWG / W3C — web platform / browser standards',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Describes a single browser requirement entry across support, features, testing, and known issues.',
)
@SectionId('BROREQENT')
class BrowserRequirementEntry {
  @Form([
    Field('browserName', String, 'Browser Name',
        required: true, hint: 'E.g., Chrome, Firefox, Safari, Edge'),
    Field('browserEngine', String, 'Browser Engine',
        hint: 'Chromium, Gecko, WebKit'),
    Field('minVersion', String, 'Minimum Version',
        required: true, hint: 'Minimum supported version'),
    Field('recommendedVersion', String, 'Recommended Version',
        hint: 'Recommended version'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Support level and user share.
  @SerializationOrder(1)
  BrowserRequirementEntrySupport support = BrowserRequirementEntrySupport();

  /// Required and optional features.
  @SerializationOrder(2)
  BrowserRequirementEntryFeatures features = BrowserRequirementEntryFeatures();

  /// Testing strategy.
  @SerializationOrder(3)
  BrowserRequirementEntryTesting testing = BrowserRequirementEntryTesting();

  /// Known issues and workarounds.
  @SerializationOrder(4)
  BrowserRequirementEntryIssues issues = BrowserRequirementEntryIssues();
}

/// Support level and user share.
@StandardReferences(
  ['WHATWG / W3C — web platform / browser standards'],
  'Captures the browser support level, priority, and expected user share for the client.',
)
@SectionId('BRES')
class BrowserRequirementEntrySupport {
  @Form([
    Field('supportLevel', String, 'Support Level',
        hint: 'Full, Partial, Best-effort'),
    Field('priority', String, 'Priority',
        hint: 'Primary, Secondary, Edge case'),
    Field('expectedUserShare', String, 'Expected User Share',
        hint: 'Percentage of users'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Required and optional features.
@StandardReferences(
  ['WHATWG / W3C — web platform / browser standards'],
  'Captures the required and optional browser platform features such as JS/CSS features, polyfills, and CSS support.',
)
@SectionId('BREF')
class BrowserRequirementEntryFeatures {
  @Form([
    Field('requiredFeatures', String, 'Required Features',
        hint: 'JS, CSS features required'),
    Field('optionalFeatures', String, 'Optional Features',
        hint: 'Enhanced features'),
    Field('polyfillsNeeded', String, 'Polyfills Needed',
        hint: 'Required polyfills'),
    Field('cssSupport', String, 'CSS Support',
        hint: 'CSS features required'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing strategy.
@StandardReferences(
  [
    'WHATWG / W3C — web platform / browser standards',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the browser testing strategy such as test platform, automation, and manual testing frequency.',
)
@SectionId('BRET')
class BrowserRequirementEntryTesting {
  @Form([
    Field('testPlatform', String, 'Test Platform',
        hint: 'BrowserStack, Sauce Labs'),
    Field('automatedTesting', bool, 'Automated Testing',
        hint: 'Include in automated tests'),
    Field('manualTestingFrequency', String, 'Manual Testing Frequency',
        hint: 'How often manually tested'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Known issues and workarounds.
@StandardReferences(
  ['WHATWG / W3C — web platform / browser standards'],
  'Captures the browser-specific known limitations and workarounds for the client.',
)
@SectionId('BREI')
class BrowserRequirementEntryIssues {
  @Form([
    Field('knownLimitations', String, 'Known Limitations',
        hint: 'Browser-specific limitations'),
    Field('workarounds', String, 'Workarounds',
        hint: 'Applied workarounds'),
    Field('notes', String, 'Notes',
        hint: 'Additional browser requirement notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Desktop operating system requirement entry.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Describes a single desktop operating-system requirement entry across support, hardware, software, and testing.',
)
@SectionId('DEOSREEN')
class DesktopOsRequirementEntry {
  @Form([
    Field('osName', String, 'Operating System',
        required: true, hint: 'E.g., Windows, macOS, Linux'),
    Field('osFamily', String, 'OS Family',
        hint: 'Windows, macOS, Unix'),
    Field('minVersion', String, 'Minimum Version',
        required: true, hint: 'Minimum supported version'),
    Field('recommendedVersion', String, 'Recommended Version',
        hint: 'Recommended version'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Support prioritization.
  @SerializationOrder(1)
  DesktopOsRequirementEntrySupport support =
      DesktopOsRequirementEntrySupport();

  /// Hardware and display requirements.
  @SerializationOrder(2)
  DesktopOsRequirementEntryRequirements requirements =
      DesktopOsRequirementEntryRequirements();

  /// Software prerequisites.
  @SerializationOrder(3)
  DesktopOsRequirementEntrySoftware software =
      DesktopOsRequirementEntrySoftware();

  /// Testing and known issues.
  @SerializationOrder(4)
  DesktopOsRequirementEntryTesting testing = DesktopOsRequirementEntryTesting();
}

/// Support prioritization.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency / resource utilization'],
  'Captures the desktop OS support prioritization such as support level, priority, and expected user share.',
)
@SectionId('DORES')
class DesktopOsRequirementEntrySupport {
  @Form([
    Field('supportLevel', String, 'Support Level',
        hint: 'Full, Partial, Best-effort'),
    Field('priority', String, 'Priority',
        hint: 'Primary, Secondary'),
    Field('expectedUserShare', String, 'Expected User Share',
        hint: 'Percentage of users'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Hardware and display requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency / resource utilization'],
  'Captures the desktop OS hardware and display requirements such as architecture, RAM, storage, and display driver.',
)
@SectionId('DORER')
class DesktopOsRequirementEntryRequirements {
  @Form([
    Field('architecture', String, 'Architecture',
        hint: 'x64, ARM64, x86'),
    Field('minRam', String, 'Minimum RAM',
        hint: 'Minimum RAM required'),
    Field('minStorage', String, 'Minimum Storage',
        hint: 'Free disk space needed'),
    Field('displayDriver', String, 'Display Driver',
        hint: 'Graphics requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Software prerequisites.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency / resource utilization'],
  'Captures the desktop OS software prerequisites such as runtime dependencies and additional required software.',
)
@SectionId('DEOSREENSO')
class DesktopOsRequirementEntrySoftware {
  @Form([
    Field('runtimeDependencies', String, 'Runtime Dependencies',
        hint: 'Required runtimes (.NET, Java)'),
    Field('additionalSoftware', String, 'Additional Software',
        hint: 'Other required software'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing and known issues.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency / resource utilization'],
  'Captures the desktop OS testing environment, automation, and known issues for the client platform.',
)
@SectionId('DORET')
class DesktopOsRequirementEntryTesting {
  @Form([
    Field('testEnvironment', String, 'Test Environment',
        hint: 'VM, physical, cloud'),
    Field('automatedTesting', bool, 'Automated Testing',
        hint: 'Include in CI/CD'),
    Field('knownIssues', String, 'Known Issues',
        hint: 'OS-specific issues'),
    Field('notes', String, 'Notes',
        hint: 'Additional desktop OS notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Mobile device requirement entry.
@StandardReferences(
  [
    'Android CDD / Apple HIG — mobile device platform requirements',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Describes a single mobile-platform requirement entry across support, device coverage, hardware, and capabilities.',
)
@SectionId('MODEREEN')
class MobileDeviceRequirementEntry {
  @Form([
    Field('platform', String, 'Platform',
        required: true, hint: 'iOS, Android, iPadOS'),
    Field('minOsVersion', String, 'Minimum OS Version',
        required: true, hint: 'Minimum OS version'),
    Field('recommendedOsVersion', String, 'Recommended OS Version',
        hint: 'Recommended OS version'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Support prioritization.
  @SerializationOrder(1)
  MobileDeviceRequirementEntrySupport support =
      MobileDeviceRequirementEntrySupport();

  /// Device coverage.
  @SerializationOrder(2)
  MobileDeviceRequirementEntryDevices devices =
      MobileDeviceRequirementEntryDevices();

  /// Hardware expectations.
  @SerializationOrder(3)
  MobileDeviceRequirementEntryHardware hardware =
      MobileDeviceRequirementEntryHardware();

  /// Capability requirements.
  @SerializationOrder(4)
  MobileDeviceRequirementEntryCapabilities capabilities =
      MobileDeviceRequirementEntryCapabilities();
}

/// Support prioritization.
@StandardReferences(
  ['Android CDD / Apple HIG — mobile device platform requirements'],
  'Captures the mobile device support prioritization such as support level, priority, and expected user share.',
)
@SectionId('MDRES')
class MobileDeviceRequirementEntrySupport {
  @Form([
    Field('supportLevel', String, 'Support Level',
        hint: 'Full, Partial, Best-effort'),
    Field('priority', String, 'Priority',
        hint: 'Primary, Secondary'),
    Field('expectedUserShare', String, 'Expected User Share',
        hint: 'Percentage of users'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Device coverage.
@StandardReferences(
  ['Android CDD / Apple HIG — mobile device platform requirements'],
  'Captures the mobile device coverage such as device types, specific named devices, and supported screen sizes.',
)
@SectionId('MDRED')
class MobileDeviceRequirementEntryDevices {
  @Form([
    Field('deviceTypes', String, 'Device Types',
        hint: 'Phone, Tablet, Foldable'),
    Field('specificDevices', String, 'Specific Devices',
        hint: 'Named devices to support'),
    Field('screenSizes', String, 'Screen Sizes',
        hint: 'Supported screen sizes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Hardware expectations.
@StandardReferences(
  [
    'Android CDD / Apple HIG — mobile device platform requirements',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the mobile device hardware expectations such as minimum RAM, storage, required sensors, and hardware acceleration.',
)
@SectionId('MDREH')
class MobileDeviceRequirementEntryHardware {
  @Form([
    Field('minRam', String, 'Minimum RAM',
        hint: 'Minimum device RAM'),
    Field('minStorage', String, 'Minimum Storage',
        hint: 'Storage for app'),
    Field('requiredSensors', String, 'Required Sensors',
        hint: 'GPS, camera, biometric'),
    Field('hardwareAcceleration', bool, 'Hardware Acceleration',
        hint: 'GPU acceleration needed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Capability requirements.
@StandardReferences(
  ['Android CDD / Apple HIG — mobile device platform requirements'],
  'Captures the mobile device capability requirements such as permissions, background execution, and push notifications.',
)
@SectionId('MDREC')
class MobileDeviceRequirementEntryCapabilities {
  @Form([
    Field('permissionsRequired', String, 'Permissions Required',
        hint: 'Required app permissions'),
    Field('backgroundExecution', String, 'Background Execution',
        hint: 'Background modes needed'),
    Field('pushNotifications', bool, 'Push Notifications',
        hint: 'Push notification support'),
    Field('notes', String, 'Notes',
        hint: 'Additional mobile device notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Display and screen requirements.
@StandardReferences(
  [
    'ISO 9241 — ergonomics of human-system interaction',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Describes the client display and screen requirements across resolution, layout, scaling, color, and multi-display support.',
)
@SectionId('DIRE')
class DisplayRequirements {
  @Form([
    Field('minResolution', String, 'Minimum Resolution',
        hint: '1024x768, 1280x720'),
    Field('recommendedResolution', String, 'Recommended Resolution',
        hint: 'Recommended screen resolution'),
    Field('maxResolution', String, 'Maximum Resolution',
        hint: 'Maximum tested resolution'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Aspect ratio and layout support.
  @SerializationOrder(1)
  DisplayRequirementsLayout layout = DisplayRequirementsLayout();

  /// DPI and scaling support.
  @SerializationOrder(2)
  DisplayRequirementsScaling scaling = DisplayRequirementsScaling();

  /// Color and contrast support.
  @SerializationOrder(3)
  DisplayRequirementsColor color = DisplayRequirementsColor();

  /// Multi-display support.
  @SerializationOrder(4)
  DisplayRequirementsMultiDisplay multiDisplay =
      DisplayRequirementsMultiDisplay();
}

/// Aspect ratio and layout support.
@StandardReferences(
  ['ISO 9241 — ergonomics of human-system interaction'],
  'Captures the client display layout support such as aspect ratios, responsive breakpoints, and fluid layout.',
)
@SectionId('DIRELA')
class DisplayRequirementsLayout {
  @Form([
    Field('supportedAspectRatios', String, 'Supported Aspect Ratios',
        hint: '16:9, 4:3, 21:9'),
    Field('responsiveBreakpoints', String, 'Responsive Breakpoints',
        hint: 'Mobile, tablet, desktop'),
    Field('fluidLayout', bool, 'Fluid Layout',
        hint: 'Supports fluid layouts'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// DPI and scaling support.
@StandardReferences(
  ['ISO 9241 — ergonomics of human-system interaction'],
  'Captures the client display DPI and scaling support such as minimum DPI, HiDPI, scaling factors, and vector graphics.',
)
@SectionId('DIRESC')
class DisplayRequirementsScaling {
  @Form([
    Field('minDpi', String, 'Minimum DPI',
        hint: 'Minimum display DPI'),
    Field('hiDpiSupport', bool, 'HiDPI Support',
        hint: 'Retina/HiDPI support'),
    Field('scalingFactors', String, 'Scaling Factors',
        hint: '100%, 125%, 150%, 200%'),
    Field('vectorGraphics', bool, 'Vector Graphics',
        hint: 'SVG/vector support'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Color and contrast support.
@StandardReferences(
  [
    'ISO 9241 — ergonomics of human-system interaction',
    'WCAG 2.2 — accessible client experience',
  ],
  'Captures the client display color and contrast support such as color depth, color space, dark mode, and high contrast.',
)
@SectionId('DIREC1')
class DisplayRequirementsColor {
  @Form([
    Field('colorDepth', String, 'Color Depth',
        hint: '24-bit, 32-bit'),
    Field('colorSpaceSupport', String, 'Color Space Support',
        hint: 'sRGB, P3, HDR'),
    Field('darkModeSupport', bool, 'Dark Mode Support',
        hint: 'Dark mode theme support'),
    Field('highContrastSupport', bool, 'High Contrast Support',
        hint: 'High contrast mode'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Multi-display support.
@StandardReferences(
  ['ISO 9241 — ergonomics of human-system interaction'],
  'Captures the client multi-display support such as multi-monitor and projector/presentation modes.',
)
@SectionId('DRMD')
class DisplayRequirementsMultiDisplay {
  @Form([
    Field('multiMonitorSupport', bool, 'Multi-Monitor Support',
        hint: 'Multiple display support'),
    Field('projectorMode', String, 'Projector/Presentation Mode',
        hint: 'Presentation display mode'),
    Field('notes', String, 'Notes',
        hint: 'Additional display notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Client network requirements.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Describes the client-side network requirements across bandwidth, latency, connection type, protocols, and proxy/firewall.',
)
@SectionId('CLNERE')
class ClientNetworkRequirements {
  @Form([
    Field('minDownloadSpeed', String, 'Minimum Download Speed',
        hint: 'Minimum download Mbps'),
    Field('recommendedDownloadSpeed', String, 'Recommended Download Speed',
        hint: 'Recommended download Mbps'),
    Field('minUploadSpeed', String, 'Minimum Upload Speed',
        hint: 'Minimum upload Mbps'),
    Field('peakBandwidthUsage', String, 'Peak Bandwidth Usage',
        hint: 'Maximum bandwidth consumed'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Latency requirements.
  @SerializationOrder(1)
  ClientNetworkRequirementsLatency latency = ClientNetworkRequirementsLatency();

  /// Connection-type requirements.
  @SerializationOrder(2)
  ClientNetworkRequirementsConnection connection =
      ClientNetworkRequirementsConnection();

  /// Protocol requirements.
  @SerializationOrder(3)
  ClientNetworkRequirementsProtocols protocols =
      ClientNetworkRequirementsProtocols();

  /// Proxy and firewall requirements.
  @SerializationOrder(4)
  ClientNetworkRequirementsProxy proxy = ClientNetworkRequirementsProxy();
}

/// Latency requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency / resource utilization'],
  'Captures the client network latency requirements such as maximum latency, recommended latency, and jitter tolerance.',
)
@SectionId('CNRL')
class ClientNetworkRequirementsLatency {
  @Form([
    Field('maxLatency', String, 'Maximum Latency',
        hint: 'Maximum acceptable latency'),
    Field('recommendedLatency', String, 'Recommended Latency',
        hint: 'Recommended latency'),
    Field('jitterTolerance', String, 'Jitter Tolerance',
        hint: 'Network jitter tolerance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Connection-type requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency / resource utilization'],
  'Captures the client connection-type requirements such as supported networks, offline capability, and low-bandwidth mode.',
)
@SectionId('CNRC')
class ClientNetworkRequirementsConnection {
  @Form([
    Field('connectionTypes', String, 'Connection Types',
        hint: 'WiFi, Ethernet, Cellular'),
    Field('offlineCapability', String, 'Offline Capability',
        hint: 'Offline mode support'),
    Field('lowBandwidthMode', String, 'Low Bandwidth Mode',
        hint: 'Degraded mode for slow connections'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Protocol requirements.
@StandardReferences(
  [
    'WHATWG / W3C — web platform / browser standards',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the client network protocol requirements such as HTTP/2, TLS version, and WebRTC support.',
)
@SectionId('CNRP')
class ClientNetworkRequirementsProtocols {
  @Form([
    Field('requiredProtocols', String, 'Required Protocols',
        hint: 'HTTP/2, WebSocket'),
    Field('tlsVersion', String, 'TLS Version',
        hint: 'Minimum TLS version'),
    Field('webRtcRequired', bool, 'WebRTC Required',
        hint: 'Real-time communication'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Proxy and firewall requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency / resource utilization'],
  'Captures the client-side proxy and firewall requirements such as proxy support and required outbound ports.',
)
@SectionId('CLNEREPR')
class ClientNetworkRequirementsProxy {
  @Form([
    Field('proxySupport', String, 'Proxy Support',
        hint: 'HTTP/SOCKS proxy support'),
    Field('firewallPorts', String, 'Firewall Ports',
        hint: 'Required outbound ports'),
    Field('notes', String, 'Notes',
        hint: 'Additional network notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Client hardware requirements.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Describes the minimum client hardware requirements across CPU, memory, storage, graphics, and peripherals.',
)
@SectionId('CLHARE')
class ClientHardwareRequirements {
  @Form([
    Field('minCpuCores', String, 'Minimum CPU Cores',
        hint: 'Minimum CPU cores'),
    Field('recommendedCpuCores', String, 'Recommended CPU Cores',
        hint: 'Recommended CPU cores'),
    Field('cpuArchitecture', String, 'CPU Architecture',
        hint: 'x64, ARM, Universal'),
    Field('minCpuSpeed', String, 'Minimum CPU Speed',
        hint: 'Minimum clock speed'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Memory requirements.
  @SerializationOrder(1)
  ClientHardwareRequirementsMemory memory = ClientHardwareRequirementsMemory();

  /// Storage requirements.
  @SerializationOrder(2)
  ClientHardwareRequirementsStorage storage =
      ClientHardwareRequirementsStorage();

  /// Graphics requirements.
  @SerializationOrder(3)
  ClientHardwareRequirementsGraphics graphics =
      ClientHardwareRequirementsGraphics();

  /// Peripheral requirements.
  @SerializationOrder(4)
  ClientHardwareRequirementsPeripherals peripherals =
      ClientHardwareRequirementsPeripherals();
}

/// Memory requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency / resource utilization'],
  'Captures the client memory requirements such as minimum RAM, recommended RAM, and app memory usage.',
)
@SectionId('CHRM')
class ClientHardwareRequirementsMemory {
  @Form([
    Field('minRam', String, 'Minimum RAM',
        hint: 'Minimum system RAM'),
    Field('recommendedRam', String, 'Recommended RAM',
        hint: 'Recommended RAM'),
    Field('appMemoryUsage', String, 'App Memory Usage',
        hint: 'Expected memory consumption'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Storage requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency / resource utilization'],
  'Captures the client storage requirements such as free space, install size, cache size, and storage type.',
)
@SectionId('CHRS')
class ClientHardwareRequirementsStorage {
  @Form([
    Field('minFreeSpace', String, 'Minimum Free Space',
        hint: 'Required free disk space'),
    Field('installSize', String, 'Installation Size',
        hint: 'App installation size'),
    Field('cacheSize', String, 'Cache Size',
        hint: 'Typical cache size'),
    Field('storageType', String, 'Storage Type',
        hint: 'SSD recommended'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Graphics requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency / resource utilization'],
  'Captures the client graphics requirements such as GPU need, hardware acceleration, and video decoding.',
)
@SectionId('CHRG')
class ClientHardwareRequirementsGraphics {
  @Form([
    Field('gpuRequired', bool, 'GPU Required',
        hint: 'Dedicated GPU needed'),
    Field('gpuAcceleration', String, 'GPU Acceleration',
        hint: 'WebGL, hardware acceleration'),
    Field('videoDecoding', String, 'Video Decoding',
        hint: 'Hardware video decode'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Peripheral requirements.
@StandardReferences(
  [
    'USB / Bluetooth — peripheral connectivity standards',
    'ISO 9241 — ergonomics of human-system interaction',
  ],
  'Captures the client peripheral requirements such as input devices and audio I/O.',
)
@SectionId('CHRP')
class ClientHardwareRequirementsPeripherals {
  @Form([
    Field('inputDevices', String, 'Input Devices',
        hint: 'Keyboard, mouse, touch'),
    Field('audioSupport', String, 'Audio Support',
        hint: 'Audio I/O requirements'),
    Field('notes', String, 'Notes',
        hint: 'Additional hardware notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Client accessibility requirements.
@StandardReferences(
  [
    'WCAG 2.2 — accessible client experience',
    'ISO 9241 — ergonomics of human-system interaction',
  ],
  'Describes the accessibility requirements the end-user client must satisfy across visual, motor, cognitive support, and conformance standards.',
)
@SectionId('CLACRE')
class ClientAccessibilityRequirements {
  @Form([
    Field('screenReaderSupport', String, 'Screen Reader Support',
        hint: 'NVDA, VoiceOver, JAWS'),
    Field('ariaCompliance', String, 'ARIA Compliance',
        hint: 'ARIA landmark/role support'),
    Field('semanticHtml', bool, 'Semantic HTML',
        hint: 'Proper semantic structure'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Visual accessibility support.
  @SerializationOrder(1)
  ClientAccessibilityRequirementsVisual visual =
      ClientAccessibilityRequirementsVisual();

  /// Motor accessibility support.
  @SerializationOrder(2)
  ClientAccessibilityRequirementsMotor motor =
      ClientAccessibilityRequirementsMotor();

  /// Cognitive accessibility support.
  @SerializationOrder(3)
  ClientAccessibilityRequirementsCognitive cognitive =
      ClientAccessibilityRequirementsCognitive();

  /// Standards and notes.
  @SerializationOrder(4)
  ClientAccessibilityRequirementsStandards standards =
      ClientAccessibilityRequirementsStandards();
}

/// Visual accessibility support.
@StandardReferences(
  [
    'WCAG 2.2 — accessible client experience',
    'ISO 9241 — ergonomics of human-system interaction',
  ],
  'Captures the visual accessibility support such as color-blind friendliness, high contrast, zoom, and font scaling in the client.',
)
@SectionId('CARV')
class ClientAccessibilityRequirementsVisual {
  @Form([
    Field('colorBlindSupport', bool, 'Color Blind Support',
        hint: 'Color-blind friendly'),
    Field('highContrastMode', bool, 'High Contrast Mode',
        hint: 'High contrast support'),
    Field('zoomSupport', String, 'Zoom Support',
        hint: 'Browser zoom support'),
    Field('fontScaling', String, 'Font Scaling',
        hint: 'Dynamic font scaling'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Motor accessibility support.
@StandardReferences(
  [
    'WCAG 2.2 — accessible client experience',
    'ISO 9241 — ergonomics of human-system interaction',
  ],
  'Captures the motor accessibility support such as keyboard navigation, focus indicators, and touch target sizing in the client.',
)
@SectionId('CARM')
class ClientAccessibilityRequirementsMotor {
  @Form([
    Field('keyboardNavigation', bool, 'Keyboard Navigation',
        hint: 'Full keyboard access'),
    Field('focusIndicators', bool, 'Focus Indicators',
        hint: 'Visible focus indicators'),
    Field('touchTargetSize', String, 'Touch Target Size',
        hint: 'Minimum touch targets'),
    Field('voiceControl', String, 'Voice Control',
        hint: 'Voice input support'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cognitive accessibility support.
@StandardReferences(
  [
    'WCAG 2.2 — accessible client experience',
    'ISO 9241 — ergonomics of human-system interaction',
  ],
  'Captures the cognitive accessibility support such as simplified mode, reading level, and reduced motion in the client.',
)
@SectionId('CARC')
class ClientAccessibilityRequirementsCognitive {
  @Form([
    Field('simplifiedMode', bool, 'Simplified Mode',
        hint: 'Reduced complexity mode'),
    Field('readingLevel', String, 'Reading Level',
        hint: 'Content reading level'),
    Field('animationControls', bool, 'Animation Controls',
        hint: 'Reduce motion option'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Standards and notes.
@StandardReferences(
  ['WCAG 2.2 — accessible client experience'],
  'Captures the accessibility conformance standards such as WCAG level and Section 508 the client targets.',
)
@SectionId('CARS')
class ClientAccessibilityRequirementsStandards {
  @Form([
    Field('wcagLevel', String, 'WCAG Conformance',
        hint: 'A, AA, or AAA'),
    Field('additionalStandards', String, 'Additional Standards',
        hint: 'Section 508, EN 301 549'),
    Field('notes', String, 'Notes',
        hint: 'Additional accessibility notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Progressive Web App (PWA) requirements.
@StandardReferences(
  [
    'WHATWG / W3C — web platform / browser standards',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Describes the Progressive Web App requirements the browser client must satisfy across manifest, icons, installation, offline, and updates.',
)
@SectionId('PWRE')
class PwaRequirements {
  @Form([
    Field('pwaEnabled', bool, 'PWA Enabled',
        hint: 'PWA functionality enabled'),
    Field('appName', String, 'App Name',
        hint: 'PWA display name'),
    Field('shortName', String, 'Short Name',
        hint: 'PWA short name'),
    Field('themeColor', String, 'Theme Color',
        hint: 'Theme color hex'),
    Field('backgroundColor', String, 'Background Color',
        hint: 'Splash background color'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Icon requirements.
  @SerializationOrder(1)
  PwaRequirementsIcons icons = PwaRequirementsIcons();

  /// Installation behavior.
  @SerializationOrder(2)
  PwaRequirementsInstallation installation = PwaRequirementsInstallation();

  /// Offline support.
  @SerializationOrder(3)
  PwaRequirementsOffline offline = PwaRequirementsOffline();

  /// Update handling.
  @SerializationOrder(4)
  PwaRequirementsUpdates updates = PwaRequirementsUpdates();
}

/// Icon requirements.
@StandardReferences(
  ['WHATWG / W3C — web platform / browser standards'],
  'Captures the PWA icon sizes, maskable icons, and splash-screen requirements in the browser client.',
)
@SectionId('PWREIC')
class PwaRequirementsIcons {
  @Form([
    Field('iconSizes', String, 'Icon Sizes',
        hint: '192x192, 512x512'),
    Field('maskableIcon', bool, 'Maskable Icon',
        hint: 'Adaptive icon support'),
    Field('splashScreen', String, 'Splash Screen',
        hint: 'Splash screen config'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Installation behavior.
@StandardReferences(
  ['WHATWG / W3C — web platform / browser standards'],
  'Captures the PWA installation prompt and standalone-mode behavior in the browser client.',
)
@SectionId('PWREIN')
class PwaRequirementsInstallation {
  @Form([
    Field('installPrompt', String, 'Install Prompt',
        hint: 'Installation prompt strategy'),
    Field('standaloneMode', bool, 'Standalone Mode',
        hint: 'Standalone display mode'),
    Field('startUrl', String, 'Start URL',
        hint: 'PWA start URL'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Offline support.
@StandardReferences(
  ['WHATWG / W3C — web platform / browser standards'],
  'Captures the PWA offline support via service workers and background sync in the browser client.',
)
@SectionId('PWREOF')
class PwaRequirementsOffline {
  @Form([
    Field('serviceWorkerStrategy', String, 'Service Worker Strategy',
        hint: 'Cache-first, network-first'),
    Field('offlinePages', String, 'Offline Pages',
        hint: 'Pages available offline'),
    Field('backgroundSync', bool, 'Background Sync',
        hint: 'Background sync support'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Update handling.
@StandardReferences(
  ['WHATWG / W3C — web platform / browser standards'],
  'Captures the PWA update and cache-versioning strategy in the browser client.',
)
@SectionId('PWREUP')
class PwaRequirementsUpdates {
  @Form([
    Field('updateStrategy', String, 'Update Strategy',
        hint: 'How updates are handled'),
    Field('cacheVersion', String, 'Cache Versioning',
        hint: 'Cache versioning approach'),
    Field('notes', String, 'Notes',
        hint: 'Additional PWA notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Native app requirements.
@StandardReferences(
  [
    'Android CDD / Apple HIG — mobile device platform requirements',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Describes the native mobile app requirements the client must satisfy across distribution, stores, SDK versions, performance, and deep-linking.',
)
@SectionId('NAAPRE')
class NativeAppRequirements {
  @Form([
    Field('appStoreDistribution', bool, 'App Store Distribution',
        hint: 'Distributed via app stores'),
    Field('enterpriseDistribution', bool, 'Enterprise Distribution',
        hint: 'MDM/enterprise deployment'),
    Field('sideloading', bool, 'Sideloading',
        hint: 'Direct installation'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Store presence requirements.
  @SerializationOrder(1)
  NativeAppRequirementsStores stores = NativeAppRequirementsStores();

  /// SDK and version requirements.
  @SerializationOrder(2)
  NativeAppRequirementsVersions versions = NativeAppRequirementsVersions();

  /// Size and performance requirements.
  @SerializationOrder(3)
  NativeAppRequirementsPerformance performance =
      NativeAppRequirementsPerformance();

  /// Deep-linking support.
  @SerializationOrder(4)
  NativeAppRequirementsLinking linking = NativeAppRequirementsLinking();
}

/// Store presence requirements.
@StandardReferences(
  ['Android CDD / Apple HIG — mobile device platform requirements'],
  'Captures the app-store presence requirements across Apple, Google, and other native distribution channels.',
)
@SectionId('NARS')
class NativeAppRequirementsStores {
  @Form([
    Field('appleAppStore', bool, 'Apple App Store',
        hint: 'iOS App Store listing'),
    Field('googlePlayStore', bool, 'Google Play Store',
        hint: 'Google Play listing'),
    Field('otherStores', String, 'Other Stores',
        hint: 'Amazon, Samsung, etc.'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// SDK and version requirements.
@StandardReferences(
  ['Android CDD / Apple HIG — mobile device platform requirements'],
  'Captures the native app minimum, target, and compile SDK version requirements for the client platform.',
)
@SectionId('NARV')
class NativeAppRequirementsVersions {
  @Form([
    Field('minSdkVersion', String, 'Minimum SDK Version',
        hint: 'Minimum SDK level'),
    Field('targetSdkVersion', String, 'Target SDK Version',
        hint: 'Target SDK level'),
    Field('compileSdkVersion', String, 'Compile SDK Version',
        hint: 'Compile SDK version'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Size and performance requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'Android CDD / Apple HIG — mobile device platform requirements',
  ],
  'Captures the native app size, startup time, and memory performance targets on the client device.',
)
@SectionId('NARP')
class NativeAppRequirementsPerformance {
  @Form([
    Field('maxAppSize', String, 'Maximum App Size',
        hint: 'Max download size'),
    Field('startupTime', String, 'Startup Time Target',
        hint: 'Cold start time target'),
    Field('memoryLimit', String, 'Memory Limit', hint: 'Max memory usage'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Deep-linking support.
@StandardReferences(
  ['Android CDD / Apple HIG — mobile device platform requirements'],
  'Captures the native app deep-linking and universal-link support on the client device.',
)
@SectionId('NARL')
class NativeAppRequirementsLinking {
  @Form([
    Field('deepLinking', bool, 'Deep Linking', hint: 'Deep link support'),
    Field('universalLinks', bool, 'Universal/App Links',
        hint: 'Universal links support'),
    Field('customScheme', String, 'Custom URL Scheme',
        hint: 'App URL scheme'),
    Field('notes', String, 'Notes', hint: 'Additional native app notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Client security requirements.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Describes the security requirements the end-user client must satisfy across storage, authentication, device, network, and code protection.',
)
@SectionId('CLSERE')
class ClientSecurityRequirements {
  @Form([
    Field('localDataEncryption', bool, 'Local Data Encryption',
        hint: 'Encrypt local storage'),
    Field('secureStorage', String, 'Secure Storage',
        hint: 'Keychain, encrypted prefs'),
    Field('cacheClearing', String, 'Cache Clearing',
        hint: 'Sensitive data clearing'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Authentication requirements.
  @SerializationOrder(1)
  ClientSecurityRequirementsAuthentication authentication =
      ClientSecurityRequirementsAuthentication();

  /// Device security controls.
  @SerializationOrder(2)
  ClientSecurityRequirementsDevice device = ClientSecurityRequirementsDevice();

  /// Network security controls.
  @SerializationOrder(3)
  ClientSecurityRequirementsNetwork network =
      ClientSecurityRequirementsNetwork();

  /// Code protection controls.
  @SerializationOrder(4)
  ClientSecurityRequirementsCodeProtection codeProtection =
      ClientSecurityRequirementsCodeProtection();
}

/// Authentication requirements.
@StandardReferences(
  [
    'Android CDD / Apple HIG — mobile device platform requirements',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the client-side authentication requirements such as biometrics, device passcode, and auto-lock.',
)
@SectionId('CSRA')
class ClientSecurityRequirementsAuthentication {
  @Form([
    Field('biometricAuth', bool, 'Biometric Authentication',
        hint: 'FaceID, TouchID, fingerprint'),
    Field('devicePasscode', bool, 'Device Passcode Required',
        hint: 'Require device passcode'),
    Field('rememberCredentials', String, 'Remember Credentials',
        hint: 'Credential storage policy'),
    Field('autoLockTimeout', String, 'Auto-Lock Timeout',
        hint: 'Session timeout'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Device security controls.
@StandardReferences(
  [
    'Android CDD / Apple HIG — mobile device platform requirements',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the device-level security controls such as jailbreak detection and certificate pinning on the client device.',
)
@SectionId('CSRD')
class ClientSecurityRequirementsDevice {
  @Form([
    Field('jailbreakDetection', bool, 'Jailbreak Detection',
        hint: 'Detect rooted devices'),
    Field('debugDetection', bool, 'Debug Detection',
        hint: 'Detect debugging'),
    Field('certificatePinning', bool, 'Certificate Pinning',
        hint: 'SSL certificate pinning'),
    Field('vpnDetection', String, 'VPN Detection',
        hint: 'VPN/proxy detection'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Network security controls.
@StandardReferences(
  [
    'WHATWG / W3C — web platform / browser standards',
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ],
  'Captures the client-side network security controls such as HTTPS enforcement and TLS versioning.',
)
@SectionId('CSRN')
class ClientSecurityRequirementsNetwork {
  @Form([
    Field('httpsOnly', bool, 'HTTPS Only',
        hint: 'Require HTTPS'),
    Field('minTlsVersion', String, 'Minimum TLS Version',
        hint: 'TLS 1.2, TLS 1.3'),
    Field('insecureConnectionBlocking', bool, 'Block Insecure Connections',
        hint: 'Block HTTP'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Code protection controls.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency / resource utilization'],
  'Captures the client-side code protection controls such as obfuscation and tamper detection.',
)
@SectionId('CSRCP')
class ClientSecurityRequirementsCodeProtection {
  @Form([
    Field('codeObfuscation', bool, 'Code Obfuscation',
        hint: 'Obfuscate app code'),
    Field('tamperDetection', bool, 'Tamper Detection',
        hint: 'Detect app tampering'),
    Field('notes', String, 'Notes',
        hint: 'Additional client security notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// =============================================================================
// 8.4.3. Network Requirements
// =============================================================================

/// 8.4.3. Network Requirements.
///
/// Network requirements: bandwidth, latency, availability, VPN/firewall rules,
/// and geographic distribution.
@ContentHelp('''
Specify network infrastructure requirements including bandwidth, latency,
availability, security, and geographic distribution. Network architecture
underpins system performance and reliability.

**Network Architecture**:
- Internal networks: VPC/VLAN structure, subnets, routing
- External connectivity: Internet, partner connections, VPN
- Network topology: hub-spoke, mesh, star
- Segmentation: DMZ, application tiers, database isolation

**Performance Requirements**:
- Bandwidth: Upload/download throughput per user/service
- Latency: Maximum acceptable latency by operation type
- Packet loss: Acceptable thresholds
- Jitter: For real-time applications (VoIP, video)

**Availability Requirements**:
- Uptime target: 99.9%, 99.95%, 99.99%
- Redundancy: Dual ISP, multiple availability zones
- Failover: Automatic failover time requirements
- Disaster recovery: Cross-region connectivity

**Security Requirements**:
- Firewall rules and network ACLs
- DDoS protection and mitigation
- Intrusion detection/prevention (IDS/IPS)
- Network monitoring and traffic analysis

**Geographic Distribution**:
- CDN requirements for static assets
- Edge computing requirements
- Data residency constraints
- Multi-region deployment topology
''')
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 27033 — network security',
    'TCP/IP — internet protocol suite',
  ],
  'Captures the network infrastructure requirements: architecture, bandwidth, latency, availability, and security.',
)
@SectionId('NRS')
class NetworkRequirementsSection {
  @ContentHelp('''
Provide an overview of network strategy and architecture.

**Include**:
- Network architecture overview
- Key performance and availability requirements
- Security perimeter design
- Geographic distribution strategy
- Cost and capacity considerations

**Best Practices**:
- Design for zero-trust networking
- Implement defense in depth
- Use Infrastructure as Code for network config
- Monitor network performance continuously
- Plan for network capacity growth
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of network infrastructure strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Internal network requirements.
  @SerializationOrder(2)
  InternalNetworkRequirements internalNetwork = InternalNetworkRequirements();

  /// External connectivity requirements.
  @SerializationOrder(3)
  ExternalNetworkRequirements externalNetwork = ExternalNetworkRequirements();

  /// Bandwidth and throughput requirements.
  @SerializationOrder(4)
  BandwidthRequirements bandwidthRequirements = BandwidthRequirements();

  /// Latency and performance requirements.
  @SerializationOrder(5)
  NetworkLatencyRequirements latencyRequirements = NetworkLatencyRequirements();

  /// Network availability requirements.
  @SerializationOrder(6)
  NetworkAvailabilityRequirements availabilityRequirements =
      NetworkAvailabilityRequirements();

  /// VPN requirements.
  @StandardReferences(
    ['IETF RFCs (DNS / TLS / IPsec) — network protocol standards'],
    'The VPN requirements the network must satisfy.',
  )
  @SectionId('VPREEN-VPNR-LST')
  @SectionIdPattern('VPREEN-VPNR-xxx')
  @ContentHelp('Add one entry per VPN requirement.')
  @SerializationOrder(7)
  List<VpnRequirementEntry> vpnRequirements = [];

  /// Firewall rules and policies.
  @SerializationOrder(8)
  FirewallRequirements firewallRequirements = FirewallRequirements();

  /// Geographic distribution and CDN.
  @SerializationOrder(9)
  GeographicDistributionRequirements geographicDistribution =
      GeographicDistributionRequirements();

  /// DNS requirements.
  @SerializationOrder(10)
  DnsRequirements dnsRequirements = DnsRequirements();

  /// Load balancing requirements.
  @SerializationOrder(11)
  NetworkLoadBalancingRequirements loadBalancing =
      NetworkLoadBalancingRequirements();

  /// Network security requirements.
  @SerializationOrder(12)
  NetworkSecurityRequirements networkSecurity = NetworkSecurityRequirements();
}

/// Internal network requirements.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'C4 model — deployment / infrastructure diagrams',
    'IEEE 802 — LAN/WLAN networking standards',
  ],
  'Internal network requirements covering topology, VPC/VLAN structure, subnets, and CIDR ranges.',
)
@SectionId('INNERE')
class InternalNetworkRequirements {
  @Form([
    Field('networkTopology', String, 'Network Topology',
        hint: 'Hub-spoke, mesh, star'),
    Field('vpcStructure', String, 'VPC Structure',
        hint: 'VPC/VLAN organization'),
    Field('subnetConfiguration', String, 'Subnet Configuration',
        hint: 'Subnet layout'),
    Field('cidrRanges', String, 'CIDR Ranges',
        hint: 'IP address ranges'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Segmentation and isolation.
  @SerializationOrder(1)
  InternalNetworkRequirementsSegmentation segmentation =
      InternalNetworkRequirementsSegmentation();

  /// Routing and service discovery.
  @SerializationOrder(2)
  InternalNetworkRequirementsRouting routing =
      InternalNetworkRequirementsRouting();

  /// Inter-service communication controls.
  @SerializationOrder(3)
  InternalNetworkRequirementsInterService interService =
      InternalNetworkRequirementsInterService();

  /// Monitoring and notes.
  @SerializationOrder(4)
  InternalNetworkRequirementsMonitoring monitoring =
      InternalNetworkRequirementsMonitoring();
}

/// Segmentation and isolation.
@StandardReferences(
  ['ISO/IEC 27033 — network security'],
  'Internal network segmentation and isolation via DMZ, security zones, and trust boundaries.',
)
@SectionId('INRS')
class InternalNetworkRequirementsSegmentation {
  @Form([
    Field('networkSegmentation', String, 'Network Segmentation',
        hint: 'DMZ, tiers, microsegmentation'),
    Field('securityZones', String, 'Security Zones',
        hint: 'Trust zones defined'),
    Field('isolationRequirements', String, 'Isolation Requirements',
        hint: 'Network isolation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Routing and service discovery.
@StandardReferences(
  [
    'TCP/IP — internet protocol suite',
    'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
  ],
  'Internal routing and service discovery covering routing protocols, service discovery, and service mesh.',
)
@SectionId('INRR')
class InternalNetworkRequirementsRouting {
  @Form([
    Field('routingProtocol', String, 'Routing Protocol',
        hint: 'BGP, OSPF, static'),
    Field('serviceDiscovery', String, 'Service Discovery',
        hint: 'DNS, Consul, etc.'),
    Field('serviceMesh', String, 'Service Mesh',
        hint: 'Istio, Linkerd if used'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Inter-service communication controls.
@StandardReferences(
  [
    'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
    'ISO/IEC 27033 — network security',
  ],
  'Inter-service communication controls including protocols, encryption in transit, and certificate management.',
)
@SectionId('INRIS')
class InternalNetworkRequirementsInterService {
  @Form([
    Field('interServiceCommunication', String, 'Inter-Service Communication',
        hint: 'REST, gRPC, messaging'),
    Field('encryptionInTransit', bool, 'Encryption in Transit',
        hint: 'mTLS, TLS required'),
    Field('certificateManagement', String, 'Certificate Management',
        hint: 'Cert-manager, PKI'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Monitoring and notes.
@StandardReferences(
  ['ISO/IEC 27033 — network security'],
  'Internal network monitoring requirements including tooling and flow logging.',
)
@SectionId('INRM')
class InternalNetworkRequirementsMonitoring {
  @Form([
    Field('networkMonitoring', String, 'Network Monitoring',
        hint: 'Network monitoring tools'),
    Field('flowLogging', bool, 'Flow Logging', hint: 'VPC flow logs'),
    Field('notes', String, 'Notes',
        hint: 'Additional internal network notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// External network requirements.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'C4 model — deployment / infrastructure diagrams',
  ],
  'External network requirements covering internet access, ISP redundancy, dedicated lines, and peering.',
)
@SectionId('EXNERE')
class ExternalNetworkRequirements {
  @Form([
    Field('internetAccess', String, 'Internet Access',
        hint: 'Direct, NAT gateway, proxy'),
    Field('ispRedundancy', String, 'ISP Redundancy',
        hint: 'Multi-ISP, single ISP'),
    Field('dedicatedLines', String, 'Dedicated Lines',
        hint: 'MPLS, leased lines'),
    Field('peeringRequirements', String, 'Peering Requirements',
        hint: 'Direct peering arrangements'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Public endpoint requirements.
  @SerializationOrder(1)
  ExternalNetworkRequirementsPublic publicEndpointsConfig =
      ExternalNetworkRequirementsPublic();

  /// Third-party connectivity.
  @SerializationOrder(2)
  ExternalNetworkRequirementsPartners partners =
      ExternalNetworkRequirementsPartners();

  /// Cloud connectivity.
  @SerializationOrder(3)
  ExternalNetworkRequirementsCloud cloud = ExternalNetworkRequirementsCloud();

  /// Security controls.
  @SerializationOrder(4)
  ExternalNetworkRequirementsSecurity security =
      ExternalNetworkRequirementsSecurity();
}

/// Public endpoint requirements.
@StandardReferences(
  [
    'TCP/IP — internet protocol suite',
    'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
  ],
  'Public endpoint requirements covering public-facing services, static IPs, IPv6, and DNS records.',
)
@SectionId('ENRP')
class ExternalNetworkRequirementsPublic {
  @Form([
    Field('publicEndpoints', String, 'Public Endpoints',
        hint: 'Public-facing services'),
    Field('staticIps', String, 'Static IP Addresses',
        hint: 'Required static IPs'),
    Field('ipv6Support', bool, 'IPv6 Support',
        hint: 'IPv6 required'),
    Field('dnscname', String, 'DNS/CNAME Requirements',
        hint: 'DNS records needed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Third-party connectivity.
@StandardReferences(
  [
    'TCP/IP — internet protocol suite',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Third-party connectivity requirements covering B2B connections, API gateways, and webhooks.',
)
@SectionId('EXNEREPA')
class ExternalNetworkRequirementsPartners {
  @Form([
    Field('partnerConnectivity', String, 'Partner Connectivity',
        hint: 'B2B connections'),
    Field('apiGateway', String, 'API Gateway',
        hint: 'External API gateway'),
    Field('webhookEndpoints', String, 'Webhook Endpoints',
        hint: 'Inbound webhooks'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cloud connectivity.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'C4 model — deployment / infrastructure diagrams',
  ],
  'Cloud connectivity requirements such as direct connect and hybrid cloud networking.',
)
@SectionId('ENRC')
class ExternalNetworkRequirementsCloud {
  @Form([
    Field('cloudConnect', String, 'Cloud Direct Connect',
        hint: 'AWS Direct Connect, Azure ExpressRoute'),
    Field('hybridCloud', String, 'Hybrid Cloud',
        hint: 'Hybrid cloud networking'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security controls.
@StandardReferences(
  ['ISO/IEC 27033 — network security'],
  'External network security controls including DDoS protection and web application firewall.',
)
@SectionId('ENRS')
class ExternalNetworkRequirementsSecurity {
  @Form([
    Field('ddosProtection', String, 'DDoS Protection',
        hint: 'DDoS mitigation'),
    Field('waf', String, 'WAF Requirements',
        hint: 'Web application firewall'),
    Field('notes', String, 'Notes',
        hint: 'Additional external network notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Bandwidth requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Bandwidth requirements covering total, peak, average, and burst capacity.',
)
@SectionId('BARE')
class BandwidthRequirements {
  @Form([
    Field('totalBandwidth', String, 'Total Bandwidth Required',
        hint: 'Total bandwidth capacity'),
    Field('peakBandwidth', String, 'Peak Bandwidth',
        hint: 'Peak bandwidth requirements'),
    Field('averageBandwidth', String, 'Average Bandwidth',
        hint: 'Average bandwidth usage'),
    Field('burstCapacity', String, 'Burst Capacity',
        hint: 'Burst handling capability'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Directional bandwidth requirements.
  @SerializationOrder(1)
  BandwidthRequirementsDirection direction = BandwidthRequirementsDirection();

  /// Per-connection bandwidth requirements.
  @SerializationOrder(2)
  BandwidthRequirementsConnection connection = BandwidthRequirementsConnection();

  /// Traffic-pattern requirements.
  @SerializationOrder(3)
  BandwidthRequirementsTraffic traffic = BandwidthRequirementsTraffic();

  /// QoS requirements.
  @SerializationOrder(4)
  BandwidthRequirementsQos qos = BandwidthRequirementsQos();
}

/// Directional bandwidth requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Directional bandwidth requirements for ingress, egress, and east-west traffic.',
)
@SectionId('BAREDI')
class BandwidthRequirementsDirection {
  @Form([
    Field('ingressBandwidth', String, 'Ingress Bandwidth',
        hint: 'Inbound bandwidth'),
    Field('egressBandwidth', String, 'Egress Bandwidth',
        hint: 'Outbound bandwidth'),
    Field('eastWestBandwidth', String, 'East-West Bandwidth',
        hint: 'Internal traffic bandwidth'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Per-connection bandwidth requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Per-connection bandwidth requirements including concurrency and connection pooling.',
)
@SectionId('BARECO')
class BandwidthRequirementsConnection {
  @Form([
    Field('perConnectionBandwidth', String, 'Per-Connection Bandwidth',
        hint: 'Bandwidth per connection'),
    Field('concurrentConnections', String, 'Concurrent Connections',
        hint: 'Max concurrent connections'),
    Field('connectionPooling', String, 'Connection Pooling',
        hint: 'Connection pool requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Traffic-pattern requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Bandwidth traffic-pattern requirements including streaming and large file transfers.',
)
@SectionId('BARETR')
class BandwidthRequirementsTraffic {
  @Form([
    Field('trafficPatterns', String, 'Traffic Patterns',
        hint: 'Typical traffic patterns'),
    Field('videoStreaming', String, 'Video/Streaming',
        hint: 'Streaming bandwidth'),
    Field('fileTransfers', String, 'File Transfers',
        hint: 'Large file transfer needs'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// QoS requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Bandwidth quality-of-service requirements and traffic prioritization rules.',
)
@SectionId('BAREQO')
class BandwidthRequirementsQos {
  @Form([
    Field('qosRequirements', String, 'QoS Requirements',
        hint: 'Quality of Service'),
    Field('trafficPrioritization', String, 'Traffic Prioritization',
        hint: 'Traffic priority rules'),
    Field('notes', String, 'Notes',
        hint: 'Additional bandwidth notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Network latency requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Network latency requirements covering maximum, target, and percentile latency budgets.',
)
@SectionId('NELARE')
class NetworkLatencyRequirements {
  @Form([
    Field('maxLatency', String, 'Maximum Latency',
        hint: 'Maximum acceptable latency'),
    Field('targetLatency', String, 'Target Latency',
        hint: 'Target p50 latency'),
    Field('p95Latency', String, 'P95 Latency',
        hint: '95th percentile target'),
    Field('p99Latency', String, 'P99 Latency',
        hint: '99th percentile target'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Segment-level latency budgets.
  @SerializationOrder(1)
  NetworkLatencyRequirementsSegments segments =
      NetworkLatencyRequirementsSegments();

  /// Geographic latency budgets.
  @SerializationOrder(2)
  NetworkLatencyRequirementsGeographic geographic =
      NetworkLatencyRequirementsGeographic();

  /// Stability tolerances.
  @SerializationOrder(3)
  NetworkLatencyRequirementsStability stability =
      NetworkLatencyRequirementsStability();

  /// Optimization strategies.
  @SerializationOrder(4)
  NetworkLatencyRequirementsOptimization optimization =
      NetworkLatencyRequirementsOptimization();
}

/// Segment-level latency budgets.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Segment-level latency budgets across client-edge, edge-origin, internal, and database hops.',
)
@SectionId('NLRS')
class NetworkLatencyRequirementsSegments {
  @Form([
    Field('clientToEdge', String, 'Client to Edge Latency',
        hint: 'Client to CDN/edge'),
    Field('edgeToOrigin', String, 'Edge to Origin Latency',
        hint: 'Edge to origin server'),
    Field('internalLatency', String, 'Internal Service Latency',
        hint: 'Service-to-service'),
    Field('databaseLatency', String, 'Database Latency',
        hint: 'DB access latency'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Geographic latency budgets.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Geographic latency budgets across regional, cross-regional, and global scopes.',
)
@SectionId('NLRG')
class NetworkLatencyRequirementsGeographic {
  @Form([
    Field('regionalLatency', String, 'Regional Latency',
        hint: 'Same region latency'),
    Field('crossRegionalLatency', String, 'Cross-Regional Latency',
        hint: 'Cross-region latency'),
    Field('globalLatency', String, 'Global Latency',
        hint: 'Worldwide latency targets'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Stability tolerances.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Network stability tolerances such as jitter, packet loss, and connection stability.',
)
@SectionId('NELAREST')
class NetworkLatencyRequirementsStability {
  @Form([
    Field('jitterTolerance', String, 'Jitter Tolerance',
        hint: 'Acceptable jitter'),
    Field('packetLoss', String, 'Packet Loss Tolerance',
        hint: 'Acceptable packet loss'),
    Field('connectionStability', String, 'Connection Stability',
        hint: 'Connection stability requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Optimization strategies.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Network latency optimization strategies and related notes.',
)
@SectionId('NLRO')
class NetworkLatencyRequirementsOptimization {
  @Form([
    Field('latencyOptimization', String, 'Latency Optimization',
        hint: 'Optimization strategies'),
    Field('notes', String, 'Notes', hint: 'Additional latency notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Network availability requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency (network throughput / latency)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Network availability requirements covering uptime targets, downtime budgets, and maintenance windows.',
)
@SectionId('NEAVRE')
class NetworkAvailabilityRequirements {
  @Form([
    Field('availabilityTarget', String, 'Availability Target',
        hint: '99.99%, 99.999%'),
    Field('monthlyDowntime', String, 'Monthly Downtime Budget',
        hint: 'Allowed downtime/month'),
    Field('maintenanceWindows', String, 'Maintenance Windows',
        hint: 'Scheduled maintenance'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Redundancy configuration.
  @SerializationOrder(1)
  NetworkAvailabilityRequirementsRedundancy redundancy =
      NetworkAvailabilityRequirementsRedundancy();

  /// Failover configuration.
  @SerializationOrder(2)
  NetworkAvailabilityRequirementsFailover failover =
      NetworkAvailabilityRequirementsFailover();

  /// Recovery objectives.
  @SerializationOrder(3)
  NetworkAvailabilityRequirementsRecovery recovery =
      NetworkAvailabilityRequirementsRecovery();

  /// Testing and notes.
  @SerializationOrder(4)
  NetworkAvailabilityRequirementsTesting testing =
      NetworkAvailabilityRequirementsTesting();
}

/// Redundancy configuration.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Network redundancy configuration across paths, ISPs, links, and devices.',
)
@SectionId('NARR')
class NetworkAvailabilityRequirementsRedundancy {
  @Form([
    Field('pathRedundancy', String, 'Path Redundancy',
        hint: 'Multiple network paths'),
    Field('ispRedundancy', String, 'ISP Redundancy',
        hint: 'Multiple ISPs'),
    Field('linkRedundancy', String, 'Link Redundancy',
        hint: 'Redundant links'),
    Field('deviceRedundancy', String, 'Device Redundancy',
        hint: 'Redundant network devices'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Failover configuration.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Network failover configuration covering mechanism, time, health checks, and rerouting.',
)
@SectionId('NARF')
class NetworkAvailabilityRequirementsFailover {
  @Form([
    Field('failoverMechanism', String, 'Failover Mechanism',
        hint: 'Automatic/manual failover'),
    Field('failoverTime', String, 'Failover Time',
        hint: 'Maximum failover time'),
    Field('healthChecks', String, 'Health Checks',
        hint: 'Network health monitoring'),
    Field('automaticRerouting', bool, 'Automatic Rerouting',
        hint: 'Auto path rerouting'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Recovery objectives.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Network recovery objectives such as RPO, RTO, and DR-site connectivity.',
)
@SectionId('NEAVRERE')
class NetworkAvailabilityRequirementsRecovery {
  @Form([
    Field('rpo', String, 'Recovery Point Objective',
        hint: 'Network state RPO'),
    Field('rto', String, 'Recovery Time Objective',
        hint: 'Network recovery RTO'),
    Field('drSite', String, 'DR Site Connectivity',
        hint: 'DR network connectivity'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing and notes.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Network availability failover testing frequency and related notes.',
)
@SectionId('NART')
class NetworkAvailabilityRequirementsTesting {
  @Form([
    Field('failoverTesting', String, 'Failover Testing',
        hint: 'Testing frequency'),
    Field('notes', String, 'Notes',
        hint: 'Additional availability notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// VPN requirement entry.
@StandardReferences(
  [
    'ISO/IEC 27033 — network security',
    'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
  ],
  'A single VPN requirement entry covering its name, type, and purpose.',
)
@SectionId('VRE')
class VpnRequirementEntry {
  @Form([
    Field('vpnName', String, 'VPN Name',
        required: true, hint: 'VPN connection name'),
    Field('vpnType', String, 'VPN Type',
        hint: 'Site-to-Site, Client, SSL'),
    Field('purpose', String, 'Purpose',
        hint: 'Purpose of this VPN'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Endpoint configuration.
  @SerializationOrder(1)
  VpnRequirementEntryEndpoints endpoints = VpnRequirementEntryEndpoints();

  /// Protocol and cryptography.
  @SerializationOrder(2)
  VpnRequirementEntryProtocol protocolDetails =
      VpnRequirementEntryProtocol();

  /// Performance expectations.
  @SerializationOrder(3)
  VpnRequirementEntryPerformance performance =
      VpnRequirementEntryPerformance();

  /// Availability and notes.
  @SerializationOrder(4)
  VpnRequirementEntryAvailability availabilityDetails =
      VpnRequirementEntryAvailability();
}

/// Endpoint configuration.
@StandardReferences(
  ['IETF RFCs (DNS / TLS / IPsec) — network protocol standards'],
  'VPN endpoint configuration covering local, remote, and reachable networks.',
)
@SectionId('VREE')
class VpnRequirementEntryEndpoints {
  @Form([
    Field('localEndpoint', String, 'Local Endpoint',
        hint: 'Local network endpoint'),
    Field('remoteEndpoint', String, 'Remote Endpoint',
        hint: 'Remote network endpoint'),
    Field('remoteNetworks', String, 'Remote Networks',
        hint: 'Networks accessible via VPN'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Protocol and cryptography.
@StandardReferences(
  [
    'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
    'ISO/IEC 27033 — network security',
  ],
  'VPN protocol and cryptography settings including protocol, encryption, and authentication.',
)
@SectionId('VREP')
class VpnRequirementEntryProtocol {
  @Form([
    Field('protocol', String, 'Protocol',
        hint: 'IPSec, OpenVPN, WireGuard'),
    Field('encryptionAlgorithm', String, 'Encryption Algorithm',
        hint: 'AES-256, ChaCha20'),
    Field('authenticationMethod', String, 'Authentication Method',
        hint: 'PSK, certificates, MFA'),
    Field('perfectForwardSecrecy', bool, 'Perfect Forward Secrecy',
        hint: 'PFS enabled'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Performance expectations.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'VPN performance expectations such as bandwidth, max connections, and split tunneling.',
)
@SectionId('VPREENPE')
class VpnRequirementEntryPerformance {
  @Form([
    Field('bandwidth', String, 'Bandwidth',
        hint: 'VPN bandwidth capacity'),
    Field('maxConnections', int, 'Max Connections',
        hint: 'Maximum concurrent connections'),
    Field('splitTunneling', bool, 'Split Tunneling',
        hint: 'Split tunnel allowed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Availability and notes.
@StandardReferences(
  ['ISO/IEC 27033 — network security'],
  'VPN availability and redundancy expectations for a single VPN requirement.',
)
@SectionId('VREA')
class VpnRequirementEntryAvailability {
  @Form([
    Field('availability', String, 'Availability',
        hint: 'Required availability'),
    Field('redundancy', String, 'Redundancy',
        hint: 'VPN redundancy'),
    Field('notes', String, 'Notes', hint: 'Additional VPN notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Firewall requirements.
@StandardReferences(
  [
    'ISO/IEC 27033 — network security',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Firewall requirements covering architecture, vendor/product, and management model.',
)
@SectionId('FIRE')
class FirewallRequirements {
  @Form([
    Field('firewallArchitecture', String, 'Firewall Architecture',
        hint: 'Perimeter, distributed, cloud'),
    Field('firewallVendor', String, 'Firewall Vendor/Product',
        hint: 'Firewall product used'),
    Field('managementModel', String, 'Management Model',
        hint: 'Centralized, distributed'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Rule definitions.
  @SerializationOrder(1)
  FirewallRequirementsRules rules = FirewallRequirementsRules();

  /// Port requirements.
  @SerializationOrder(2)
  FirewallRequirementsPorts ports = FirewallRequirementsPorts();

  /// Advanced inspection features.
  @SerializationOrder(3)
  FirewallRequirementsAdvanced advanced = FirewallRequirementsAdvanced();

  /// Logging and alerts.
  @SerializationOrder(4)
  FirewallRequirementsLogging logging = FirewallRequirementsLogging();
}

/// Rule definitions.
@StandardReferences(
  ['ISO/IEC 27033 — network security'],
  'Firewall rule definitions covering default policy and inbound/outbound/internal rules.',
)
@SectionId('FIRERU')
class FirewallRequirementsRules {
  @Form([
    Field('defaultPolicy', String, 'Default Policy',
        hint: 'Deny-all, allow-all'),
    Field('inboundRules', String, 'Inbound Rules Summary',
        hint: 'Summary of inbound rules'),
    Field('outboundRules', String, 'Outbound Rules Summary',
        hint: 'Summary of outbound rules'),
    Field('internalRules', String, 'Internal Rules Summary',
        hint: 'Inter-zone rules'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Port requirements.
@StandardReferences(
  [
    'ISO/IEC 27033 — network security',
    'TCP/IP — internet protocol suite',
  ],
  'Firewall port requirements covering required, blocked, and dynamic port ranges.',
)
@SectionId('FIREPO')
class FirewallRequirementsPorts {
  @Form([
    Field('requiredPorts', String, 'Required Ports',
        hint: 'Ports that must be open'),
    Field('blockedPorts', String, 'Blocked Ports',
        hint: 'Explicitly blocked ports'),
    Field('portRanges', String, 'Port Ranges',
        hint: 'Dynamic port ranges'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Advanced inspection features.
@StandardReferences(
  ['ISO/IEC 27033 — network security'],
  'Advanced firewall inspection features such as IDS/IPS, deep packet inspection, and threat intelligence.',
)
@SectionId('FIREAD')
class FirewallRequirementsAdvanced {
  @Form([
    Field('intrusionDetection', bool, 'Intrusion Detection',
        hint: 'IDS/IPS enabled'),
    Field('deepPacketInspection', bool, 'Deep Packet Inspection',
        hint: 'DPI enabled'),
    Field('applicationAwareness', bool, 'Application Awareness',
        hint: 'Layer 7 inspection'),
    Field('threatIntelligence', String, 'Threat Intelligence',
        hint: 'Threat feed integration'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Logging and alerts.
@StandardReferences(
  ['ISO/IEC 27033 — network security'],
  'Firewall logging and alerting requirements including log retention.',
)
@SectionId('FIRELO')
class FirewallRequirementsLogging {
  @Form([
    Field('loggingRequirements', String, 'Logging Requirements',
        hint: 'Firewall log retention'),
    Field('alerting', String, 'Alerting',
        hint: 'Firewall alerting'),
    Field('notes', String, 'Notes',
        hint: 'Additional firewall notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Geographic distribution requirements.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'C4 model — deployment / infrastructure diagrams',
  ],
  'Geographic distribution requirements covering regions, edge locations, and data residency.',
)
@SectionId('GEDIRE')
class GeographicDistributionRequirements {
  @Form([
    Field('primaryRegion', String, 'Primary Region',
        hint: 'Primary deployment region'),
    Field('secondaryRegions', String, 'Secondary Regions',
        hint: 'Secondary/backup regions'),
    Field('edgeLocations', String, 'Edge Locations',
        hint: 'CDN edge locations'),
    Field('regionalCompliance', String, 'Regional Compliance',
        hint: 'Data residency requirements'),
  ])
  @SerializationOrder(0)
  String? content;

  /// CDN requirements.
  @SerializationOrder(1)
  GeographicDistributionRequirementsCdn cdn =
      GeographicDistributionRequirementsCdn();

  /// Traffic routing requirements.
  @SerializationOrder(2)
  GeographicDistributionRequirementsRouting routing =
      GeographicDistributionRequirementsRouting();

  /// Anycast and global load balancing.
  @SerializationOrder(3)
  GeographicDistributionRequirementsAnycast anycast =
      GeographicDistributionRequirementsAnycast();

  /// Performance considerations.
  @SerializationOrder(4)
  GeographicDistributionRequirementsPerformance performance =
      GeographicDistributionRequirementsPerformance();
}

/// CDN requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Content delivery network requirements including provider, cached content, and TTL.',
)
@SectionId('GDRC')
class GeographicDistributionRequirementsCdn {
  @Form([
    Field('cdnRequired', bool, 'CDN Required',
        hint: 'Content delivery network'),
    Field('cdnProvider', String, 'CDN Provider',
        hint: 'CloudFront, Cloudflare, etc.'),
    Field('cachedContent', String, 'Cached Content',
        hint: 'What to cache at edge'),
    Field('cacheTtl', String, 'Cache TTL', hint: 'Cache expiration'),
    Field('cacheInvalidation', String, 'Cache Invalidation',
        hint: 'Invalidation strategy'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Traffic routing requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Geographic traffic routing strategy, failover routing, and traffic steering.',
)
@SectionId('GDRR')
class GeographicDistributionRequirementsRouting {
  @Form([
    Field('routingStrategy', String, 'Routing Strategy',
        hint: 'Latency, geo, weighted'),
    Field('failoverRouting', String, 'Failover Routing',
        hint: 'Geographic failover'),
    Field('trafficSteering', String, 'Traffic Steering',
        hint: 'How traffic is directed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Anycast and global load balancing.
@StandardReferences(
  [
    'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
    'TCP/IP — internet protocol suite',
  ],
  'Anycast addressing and global server load balancing requirements.',
)
@SectionId('GDRA')
class GeographicDistributionRequirementsAnycast {
  @Form([
    Field('anycastIp', bool, 'Anycast IP', hint: 'Anycast addressing'),
    Field('globalLoadBalancing', String, 'Global Load Balancing',
        hint: 'GSLB requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Performance considerations.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Geographic distribution performance considerations such as edge caching.',
)
@SectionId('GDRP')
class GeographicDistributionRequirementsPerformance {
  @Form([
    Field('edgeCaching', String, 'Edge Caching',
        hint: 'Edge cache strategy'),
    Field('notes', String, 'Notes',
        hint: 'Additional geographic distribution notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// DNS requirements.
@StandardReferences(
  [
    'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
    'TCP/IP — internet protocol suite',
  ],
  'DNS requirements covering provider, hosting model, and DNSSEC.',
)
@SectionId('DNRE')
class DnsRequirements {
  @Form([
    Field('dnsProvider', String, 'DNS Provider',
        hint: 'Route 53, Cloudflare, etc.'),
    Field('dnsHosting', String, 'DNS Hosting',
        hint: 'Managed, self-hosted'),
    Field('dnsSecEnabled', bool, 'DNSSEC Enabled',
        hint: 'DNS security extensions'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Zone requirements.
  @SerializationOrder(1)
  DnsRequirementsZones zones = DnsRequirementsZones();

  /// Record requirements.
  @SerializationOrder(2)
  DnsRequirementsRecords records = DnsRequirementsRecords();

  /// Availability requirements.
  @SerializationOrder(3)
  DnsRequirementsAvailability availability = DnsRequirementsAvailability();

  /// Health-check settings.
  @SerializationOrder(4)
  DnsRequirementsHealthChecks healthChecks = DnsRequirementsHealthChecks();
}

/// Zone requirements.
@StandardReferences(
  ['IETF RFCs (DNS / TLS / IPsec) — network protocol standards'],
  'DNS zone requirements including public, private, and split-horizon zones.',
)
@SectionId('DNREZO')
class DnsRequirementsZones {
  @Form([
    Field('publicZones', String, 'Public Zones',
        hint: 'Public DNS zones'),
    Field('privateZones', String, 'Private Zones',
        hint: 'Private DNS zones'),
    Field('splitHorizon', bool, 'Split Horizon DNS',
        hint: 'Internal/external split'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Record requirements.
@StandardReferences(
  ['IETF RFCs (DNS / TLS / IPsec) — network protocol standards'],
  'DNS record requirements covering record types, TTL policy, and dynamic DNS.',
)
@SectionId('DNRERE')
class DnsRequirementsRecords {
  @Form([
    Field('recordTypes', String, 'Record Types',
        hint: 'A, CNAME, TXT, etc.'),
    Field('ttlPolicy', String, 'TTL Policy',
        hint: 'Default TTL settings'),
    Field('dynamicDns', bool, 'Dynamic DNS',
        hint: 'Dynamic DNS updates'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Availability requirements.
@StandardReferences(
  ['IETF RFCs (DNS / TLS / IPsec) — network protocol standards'],
  'DNS availability requirements such as redundancy, resolution SLA, and failover.',
)
@SectionId('DNREAV')
class DnsRequirementsAvailability {
  @Form([
    Field('dnsRedundancy', String, 'DNS Redundancy',
        hint: 'Secondary DNS'),
    Field('resolutionSla', String, 'Resolution SLA',
        hint: 'DNS query SLA'),
    Field('failoverDns', String, 'Failover DNS',
        hint: 'DNS-based failover'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Health-check settings.
@StandardReferences(
  ['IETF RFCs (DNS / TLS / IPsec) — network protocol standards'],
  'DNS health-check settings including endpoints, checks, and failover actions.',
)
@SectionId('DRHC')
class DnsRequirementsHealthChecks {
  @Form([
    Field('healthChecks', bool, 'Health Checks',
        hint: 'DNS health checking'),
    Field('healthCheckEndpoints', String, 'Health Check Endpoints',
        hint: 'Endpoints to check'),
    Field('failoverAction', String, 'Failover Action',
        hint: 'Action on failure'),
    Field('notes', String, 'Notes',
        hint: 'Additional DNS notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Network load balancing requirements.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency (network throughput / latency)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ],
  'Network load balancing requirements covering load balancer type, product, and deployment model.',
)
@SectionId('NLBR')
class NetworkLoadBalancingRequirements {
  @Form([
    Field('loadBalancerType', String, 'Load Balancer Type',
        hint: 'L4, L7, DNS-based'),
    Field('loadBalancerProduct', String, 'Load Balancer Product',
        hint: 'ALB, NLB, HAProxy, etc.'),
    Field('deploymentModel', String, 'Deployment Model',
        hint: 'Cloud, on-premises, hybrid'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Routing strategy.
  @SerializationOrder(1)
  NetworkLoadBalancingRequirementsRouting routing =
      NetworkLoadBalancingRequirementsRouting();

  /// Health-check behavior.
  @SerializationOrder(2)
  NetworkLoadBalancingRequirementsHealthChecks healthChecks =
      NetworkLoadBalancingRequirementsHealthChecks();

  /// TLS settings.
  @SerializationOrder(3)
  NetworkLoadBalancingRequirementsTls tls =
      NetworkLoadBalancingRequirementsTls();

  /// Availability settings.
  @SerializationOrder(4)
  NetworkLoadBalancingRequirementsAvailability availability =
      NetworkLoadBalancingRequirementsAvailability();
}

/// Routing strategy.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Load balancer routing strategy such as algorithm, session persistence, and weighted routing.',
)
@SectionId('NLBRR')
class NetworkLoadBalancingRequirementsRouting {
  @Form([
    Field('loadBalancingAlgorithm', String, 'Load Balancing Algorithm',
        hint: 'Round-robin, least-conn'),
    Field('sessionPersistence', String, 'Session Persistence',
        hint: 'Sticky sessions'),
    Field('weightedRouting', bool, 'Weighted Routing',
        hint: 'Weighted distribution'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Health-check behavior.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Load balancer health-check behavior including protocol, path, interval, and thresholds.',
)
@SectionId('NLBRHC')
class NetworkLoadBalancingRequirementsHealthChecks {
  @Form([
    Field('healthCheckProtocol', String, 'Health Check Protocol',
        hint: 'HTTP, TCP, HTTPS'),
    Field('healthCheckPath', String, 'Health Check Path',
        hint: 'Health endpoint path'),
    Field('healthCheckInterval', String, 'Health Check Interval',
        hint: 'Check frequency'),
    Field('unhealthyThreshold', int, 'Unhealthy Threshold',
        hint: 'Failures before unhealthy'),
    Field('healthyThreshold', int, 'Healthy Threshold',
        hint: 'Successes before healthy'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// TLS settings.
@StandardReferences(
  ['IETF RFCs (DNS / TLS / IPsec) — network protocol standards'],
  'Load balancer TLS settings covering SSL termination, certificates, and HTTP/2 support.',
)
@SectionId('NLBRT')
class NetworkLoadBalancingRequirementsTls {
  @Form([
    Field('sslTermination', String, 'SSL Termination',
        hint: 'At LB, at backend'),
    Field('sslCertificate', String, 'SSL Certificate',
        hint: 'Certificate management'),
    Field('http2Support', bool, 'HTTP/2 Support',
        hint: 'HTTP/2 enabled'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Availability settings.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Load balancer high-availability settings such as redundancy and cross-zone balancing.',
)
@SectionId('NLBRA')
class NetworkLoadBalancingRequirementsAvailability {
  @Form([
    Field('lbRedundancy', String, 'LB Redundancy',
        hint: 'Load balancer HA'),
    Field('crossZoneBalancing', bool, 'Cross-Zone Balancing',
        hint: 'Cross-AZ distribution'),
    Field('notes', String, 'Notes',
        hint: 'Additional load balancing notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Network security requirements.
@StandardReferences(
  [
    'ISO/IEC 27033 — network security',
    'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
  ],
  'Network security requirements including encryption in transit, TLS versions, and certificate authorities.',
)
@SectionId('NESERE')
class NetworkSecurityRequirements {
  @Form([
    Field('encryptionInTransit', String, 'Encryption in Transit',
        hint: 'TLS requirements'),
    Field('minTlsVersion', String, 'Minimum TLS Version',
        hint: 'TLS 1.2, TLS 1.3'),
    Field('cipherSuites', String, 'Cipher Suites',
        hint: 'Allowed cipher suites'),
    Field('certificateAuthority', String, 'Certificate Authority',
        hint: 'CA for certificates'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Access-control settings.
  @SerializationOrder(1)
  NetworkSecurityRequirementsAccess access = NetworkSecurityRequirementsAccess();

  /// Monitoring controls.
  @SerializationOrder(2)
  NetworkSecurityRequirementsMonitoring monitoring =
      NetworkSecurityRequirementsMonitoring();

  /// DDoS protection controls.
  @SerializationOrder(3)
  NetworkSecurityRequirementsDdos ddos = NetworkSecurityRequirementsDdos();

  /// Compliance settings.
  @SerializationOrder(4)
  NetworkSecurityRequirementsCompliance compliance =
      NetworkSecurityRequirementsCompliance();
}

/// Access-control settings.
@StandardReferences(
  ['ISO/IEC 27033 — network security'],
  'Network access controls: ACLs, security groups, and IP allow/deny lists.',
)
@SectionId('NSRA')
class NetworkSecurityRequirementsAccess {
  @Form([
    Field('networkAcls', String, 'Network ACLs',
        hint: 'Network access control lists'),
    Field('securityGroups', String, 'Security Groups',
        hint: 'SG strategy'),
    Field('ipWhitelisting', String, 'IP Whitelisting',
        hint: 'Allowed IP ranges'),
    Field('ipBlacklisting', String, 'IP Blacklisting',
        hint: 'Blocked IP ranges'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Monitoring controls.
@StandardReferences(
  ['ISO/IEC 27033 — network security'],
  'Network intrusion detection, traffic analysis, and anomaly detection controls.',
)
@SectionId('NSRM')
class NetworkSecurityRequirementsMonitoring {
  @Form([
    Field('networkIdp', String, 'Network IDS/IPS',
        hint: 'Intrusion detection/prevention'),
    Field('trafficAnalysis', String, 'Traffic Analysis',
        hint: 'Deep traffic analysis'),
    Field('anomalyDetection', bool, 'Anomaly Detection',
        hint: 'Anomaly-based detection'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// DDoS protection controls.
@StandardReferences(
  ['ISO/IEC 27033 — network security'],
  'DDoS mitigation, rate limiting, and geo-blocking controls for the network.',
)
@SectionId('NSRD')
class NetworkSecurityRequirementsDdos {
  @Form([
    Field('ddosProtection', String, 'DDoS Protection',
        hint: 'DDoS mitigation'),
    Field('rateLimiting', String, 'Rate Limiting',
        hint: 'Rate limit policies'),
    Field('geoBlocking', String, 'Geo-Blocking',
        hint: 'Geographic restrictions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance settings.
@StandardReferences(
  ['ISO/IEC 27033 — network security'],
  'Network security compliance requirements such as PCI-DSS and audit logging.',
)
@SectionId('NSRC')
class NetworkSecurityRequirementsCompliance {
  @Form([
    Field('pciDssCompliance', String, 'PCI-DSS Network Compliance',
        hint: 'PCI network requirements'),
    Field('networkAuditLogs', String, 'Network Audit Logs',
        hint: 'Audit logging'),
    Field('notes', String, 'Notes',
        hint: 'Additional network security notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 8.5. Operations Requirements.
@DetailedIn(D06ArchitectureTechnologySpecification)
@SecondLevelSectionId(D06ArchitectureTechnologySpecification, 'ATS-OPE')
@ContentHelp('''
Define operational requirements for running and maintaining the system
in production. Operations excellence directly impacts system availability,
user experience, and team efficiency.

**Subsections**:
- **Backup and Recovery**: Backup frequency, retention, RPO/RTO, disaster
  recovery, backup verification
- **Deployment Strategy**: Deployment model, CI/CD pipeline, release
  strategy, rollback, configuration management
- **Monitoring and Alerting**: Release/DevOps deployment-pipeline
  observability — build/deploy health, pipeline alerts, release gates,
  rollback triggers
- **Maintenance Windows**: Scheduled maintenance, emergency procedures,
  change management, user communication

**Ownership boundary**: This section owns *release/DevOps* concerns. The
*runtime* operational monitoring (health checks, runtime metrics, SLA/SLO
tracking, dashboards, on-call, incident management) is owned by SBP.8.7
`SystemOperationAndMonitoring` (runtime SRE) — reference it, do not
restate it here.

**DevOps/SRE Principles**:
- Automation over manual processes
- Immutable infrastructure
- Everything as code (IaC, GitOps)
- Blameless postmortems
- Continuous improvement

**Operational Metrics**:
- MTTR (Mean Time To Recovery)
- MTBF (Mean Time Between Failures)
- Change failure rate
- Deployment frequency
- Lead time for changes

**Reference**: Google SRE book, DORA metrics, ITIL practices.
''')
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'ISO/IEC 20000 — IT service management system',
    'Google SRE — site reliability engineering',
  ],
  'Captures the operational requirements for running and maintaining the system in production.',
)
@SectionId('OPRE')
class OperationsRequirements {
  @ContentHelp('''
Provide an overview of operational philosophy and key requirements.

**Include**:
- Operations team structure and responsibilities
- Key operational metrics and targets
- Automation maturity and goals
- On-call and incident management approach
- Runbook and documentation strategy

**Best Practices**:
- Implement SLOs and error budgets
- Automate toil reduction
- Practice chaos engineering
- Regular disaster recovery testing
- Continuous operational improvement
''')
  @SerializationOrder(0)
  String? content;

  /// 8.5.1. Backup And Recovery.
  @SerializationOrder(1)
  BackupAndRecoverySection backupAndRecovery = BackupAndRecoverySection();

  /// 8.5.2. Deployment Strategy.
  @SerializationOrder(2)
  DeploymentStrategySection deploymentStrategy = DeploymentStrategySection();

  /// 8.5.3. Monitoring And Alerting.
  @SerializationOrder(3)
  MonitoringAndAlertingSection monitoringAndAlerting =
      MonitoringAndAlertingSection();

  /// 8.5.4. Maintenance Windows.
  @SerializationOrder(4)
  MaintenanceWindowsSection maintenanceWindows = MaintenanceWindowsSection();
}

// =============================================================================
// 8.5.1. Backup and Recovery
// =============================================================================

/// 8.5.1. Backup and Recovery.
///
/// Backup frequency, retention period, recovery point objective (RPO),
/// recovery time objective (RTO), and backup verification procedures.
@ContentHelp('''
Specify backup, recovery, and disaster recovery requirements. Data
protection is critical for business continuity and compliance.

**Backup Strategy**:
- **Full Backups**: Complete data copy, longer duration, periodic
- **Incremental**: Changes since last backup, faster, continuous
- **Differential**: Changes since last full, balance of both
- **Snapshot**: Point-in-time copy, instant, storage overhead

**RPO and RTO Definitions**:
- **RPO (Recovery Point Objective)**: Maximum acceptable data loss
  (e.g., 1 hour RPO = backups every hour)
- **RTO (Recovery Time Objective)**: Maximum acceptable downtime
  (e.g., 4 hour RTO = must restore within 4 hours)

**Backup Requirements by Data Type**:
- Database: Transaction logs, consistent snapshots
- File storage: Object versioning, cross-region replication
- Configuration: Version control, secrets backup
- Application state: Stateful service backups

**Disaster Recovery Tiers**:
- **Tier 1**: Active-active, instant failover, highest cost
- **Tier 2**: Hot standby, minutes to failover
- **Tier 3**: Warm standby, hours to failover
- **Tier 4**: Cold standby, days to recover

**Backup Verification**:
- Regular restore testing
- Backup integrity validation
- Cross-region restore drills
- Documented recovery procedures
''')
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ISO 22301 — business continuity management',
  ],
  'Describes the overall backup, recovery, and disaster recovery strategy for the system.',
)
@SectionId('BARS')
class BackupAndRecoverySection {
  @ContentHelp('''
Provide an overview of backup and recovery strategy.

**Include**:
- Backup architecture and technologies
- RPO/RTO targets by system/data type
- Disaster recovery strategy and tier
- Testing and verification schedule
- Compliance requirements for data retention

**Best Practices**:
- Automate backup verification
- Test restores regularly (quarterly minimum)
- Document step-by-step recovery procedures
- Cross-train team on recovery operations
- Review and update DR plan annually
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of backup and recovery strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Data classification for backup purposes.
  @SerializationOrder(2)
  BackupDataClassification dataClassification = BackupDataClassification();

  /// Backup policies by data type.
  @StandardReferences(
    ['ISO/IEC 27031 — ICT business continuity / disaster recovery'],
    'The backup policies the system applies.',
  )
  @SectionId('BAPOEN-BACK-LST')
  @SectionIdPattern('BAPOEN-BACK-xxx')
  @ContentHelp('Add one entry per backup policy.')
  @SerializationOrder(3)
  List<BackupPolicyEntry> backupPolicies = [];

  /// RPO and RTO requirements.
  @SerializationOrder(4)
  RpoRtoRequirements rpoRtoRequirements = RpoRtoRequirements();

  /// Backup infrastructure requirements.
  @SerializationOrder(5)
  BackupInfrastructure infrastructure = BackupInfrastructure();

  /// Recovery procedures.
  @SerializationOrder(6)
  RecoveryProcedures recoveryProcedures = RecoveryProcedures();

  /// Disaster recovery requirements.
  @SerializationOrder(7)
  DisasterRecoveryRequirements disasterRecovery = DisasterRecoveryRequirements();

  /// Backup verification and testing.
  @SerializationOrder(8)
  BackupVerification verification = BackupVerification();

  /// Compliance and audit requirements.
  @SerializationOrder(9)
  BackupCompliance compliance = BackupCompliance();
}

/// Data classification for backup purposes.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Classifies data by criticality to drive backup priority and protection levels.',
)
@SectionId('BADACL')
class BackupDataClassification {
  @Form([
    Field('criticalData', String, 'Critical Data',
        hint: 'Data requiring highest protection'),
    Field('highPriorityData', String, 'High Priority Data',
        hint: 'Important business data'),
    Field('mediumPriorityData', String, 'Medium Priority Data',
        hint: 'Standard operational data'),
    Field('lowPriorityData', String, 'Low Priority Data',
        hint: 'Non-essential data'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Included data categories.
  @SerializationOrder(1)
  BackupDataClassificationCategories categories =
    BackupDataClassificationCategories();

  /// Exclusions and regeneration rules.
  @SerializationOrder(2)
  BackupDataClassificationExclusions exclusions =
    BackupDataClassificationExclusions();
}

/// Included data categories for backup planning.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Lists the data categories, such as databases, files, and configuration, that are backed up.',
)
@SectionId('BDCC')
class BackupDataClassificationCategories {
  @Form([
  Field('databaseData', String, 'Database Data',
    hint: 'Which databases to back up'),
  Field('fileStorage', String, 'File Storage',
    hint: 'File systems to back up'),
  Field('configurationData', String, 'Configuration Data',
    hint: 'System configurations'),
  Field('logData', String, 'Log Data',
    hint: 'Logs to archive/backup'),
  Field('applicationState', String, 'Application State',
    hint: 'Stateful application data'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Exclusions and regeneration rules for backup planning.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Identifies data excluded from backup and how ephemeral or cache data is regenerated.',
)
@SectionId('BDCE')
class BackupDataClassificationExclusions {
  @Form([
  Field('excludedData', String, 'Excluded Data',
    hint: 'Data not requiring backup'),
  Field('temporaryData', String, 'Temporary Data',
    hint: 'Ephemeral data handling'),
  Field('cacheData', String, 'Cache Data',
    hint: 'Cache regeneration strategy'),
  Field('notes', String, 'Notes',
    hint: 'Additional classification notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Backup policy entry.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Defines a single backup policy covering type, schedule, retention, and storage for a data scope.',
)
@SectionId('BPE')
class BackupPolicyEntry {
  @Form([
    Field('policyName', String, 'Policy Name',
        required: true, hint: 'Policy identifier'),
    Field('dataScope', String, 'Data Scope',
        hint: 'What this policy covers'),
    Field('priority', String, 'Priority',
        hint: 'Critical, High, Medium, Low'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Backup type configuration.
  @SerializationOrder(1)
  BackupPolicyEntryType backupType = BackupPolicyEntryType();

  /// Schedule settings.
  @SerializationOrder(2)
  BackupPolicyEntrySchedule schedule = BackupPolicyEntrySchedule();

  /// Retention policies.
  @SerializationOrder(3)
  BackupPolicyEntryRetention retention = BackupPolicyEntryRetention();

  /// Storage configuration.
  @SerializationOrder(4)
  BackupPolicyEntryStorage storage = BackupPolicyEntryStorage();
}

/// Backup type configuration.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Defines the backup type and the frequency of full, incremental, and differential backups.',
)
@SectionId('BPET')
class BackupPolicyEntryType {
  @Form([
    Field('backupType', String, 'Backup Type',
        hint: 'Full, Incremental, Differential'),
    Field('fullBackupFrequency', String, 'Full Backup Frequency',
        hint: 'Daily, Weekly, Monthly'),
    Field('incrementalFrequency', String, 'Incremental Frequency',
        hint: 'Hourly, Every 6 hours'),
    Field('differentialFrequency', String, 'Differential Frequency',
        hint: 'If using differential'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Schedule settings for backup policy.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Defines the backup window, maximum duration, and timezone for scheduled backups.',
)
@SectionId('BPES')
class BackupPolicyEntrySchedule {
  @Form([
    Field('backupWindow', String, 'Backup Window',
        hint: 'When backups run'),
    Field('maxDuration', String, 'Max Duration',
        hint: 'Maximum backup duration'),
    Field('timezone', String, 'Timezone',
        hint: 'Backup schedule timezone'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Retention policies for backup.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Defines how long daily, weekly, monthly, and yearly backups are retained.',
)
@SectionId('BPER')
class BackupPolicyEntryRetention {
  @Form([
    Field('retentionPeriod', String, 'Retention Period',
        hint: 'How long to keep backups'),
    Field('dailyRetention', String, 'Daily Retention',
        hint: 'Daily backup retention'),
    Field('weeklyRetention', String, 'Weekly Retention',
        hint: 'Weekly backup retention'),
    Field('monthlyRetention', String, 'Monthly Retention',
        hint: 'Monthly backup retention'),
    Field('yearlyRetention', String, 'Yearly Retention',
        hint: 'Annual backup retention'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Storage configuration for backup policy.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Describes where backups are stored, plus off-site replication, encryption, and compression.',
)
@SectionId('BAPOENST')
class BackupPolicyEntryStorage {
  @Form([
    Field('storageLocation', String, 'Storage Location',
        hint: 'Where backups are stored'),
    Field('offSiteReplication', bool, 'Off-Site Replication',
        hint: 'Replicate to off-site'),
    Field('encryptionRequired', bool, 'Encryption Required',
        hint: 'Encrypt backups'),
    Field('compressionEnabled', bool, 'Compression Enabled',
        hint: 'Compress backups'),
    Field('verificationRequired', bool, 'Verification Required',
        hint: 'Verify backup integrity'),
    Field('notes', String, 'Notes',
        hint: 'Additional policy notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// RPO and RTO requirements.
@StandardReferences(
  [
    'ISO 22301 — business continuity management',
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
  ],
  'Captures the overall recovery point and recovery time objectives for the system.',
)
@SectionId('RPRTRE')
class RpoRtoRequirements {
  @Form([
    Field('overallRpo', String, 'Overall RPO',
        hint: 'Maximum acceptable data loss'),
    Field('overallRto', String, 'Overall RTO',
        hint: 'Maximum acceptable downtime'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Tier-based targets.
  @SerializationOrder(1)
  RpoRtoRequirementsByTier byTier = RpoRtoRequirementsByTier();

  /// System-specific recovery targets.
  @SerializationOrder(2)
  RpoRtoRequirementsSystems systems = RpoRtoRequirementsSystems();

  /// Degraded-mode guidance.
  @SerializationOrder(3)
  RpoRtoRequirementsDegraded degraded = RpoRtoRequirementsDegraded();
}

/// Tier-based targets.
@StandardReferences(
  [
    'ISO 22301 — business continuity management',
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
  ],
  'Defines RPO and RTO targets per data-criticality tier.',
)
@SectionId('RRRBT')
class RpoRtoRequirementsByTier {
  @Form([
    Field('criticalRpo', String, 'Critical Data RPO',
        hint: 'RPO for critical data'),
    Field('criticalRto', String, 'Critical Data RTO',
        hint: 'RTO for critical systems'),
    Field('highRpo', String, 'High Priority RPO',
        hint: 'RPO for high priority data'),
    Field('highRto', String, 'High Priority RTO',
        hint: 'RTO for high priority systems'),
    Field('mediumRpo', String, 'Medium Priority RPO',
        hint: 'RPO for medium priority'),
    Field('mediumRto', String, 'Medium Priority RTO',
        hint: 'RTO for medium priority'),
    Field('lowRpo', String, 'Low Priority RPO',
        hint: 'RPO for low priority'),
    Field('lowRto', String, 'Low Priority RTO',
        hint: 'RTO for low priority'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// System-specific recovery targets.
@StandardReferences(
  [
    'ISO 22301 — business continuity management',
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
  ],
  'Defines per-system RPO and RTO targets for databases and applications.',
)
@SectionId('RRRS')
class RpoRtoRequirementsSystems {
  @Form([
    Field('databaseRpo', String, 'Database RPO',
        hint: 'Database-specific RPO'),
    Field('databaseRto', String, 'Database RTO',
        hint: 'Database recovery time'),
    Field('applicationRpo', String, 'Application RPO',
        hint: 'Application state RPO'),
    Field('applicationRto', String, 'Application RTO',
        hint: 'Application recovery time'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Degraded-mode guidance.
@StandardReferences(
  [
    'ISO 22301 — business continuity management',
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
  ],
  'Describes whether partial restoration and minimal functionality are acceptable during recovery.',
)
@SectionId('RRRD')
class RpoRtoRequirementsDegraded {
  @Form([
    Field('degradedOperationAllowed', bool, 'Degraded Operation Allowed',
        hint: 'Allow partial restoration'),
    Field('minimalFunctionality', String, 'Minimal Functionality',
        hint: 'Minimum required functions'),
    Field('notes', String, 'Notes',
        hint: 'Additional RPO/RTO notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Backup infrastructure requirements.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Captures the primary backup storage, type, and capacity required by the system.',
)
@SectionId('BAIN')
class BackupInfrastructure {
  @Form([
    Field('primaryStorage', String, 'Primary Backup Storage',
        hint: 'Primary storage system'),
    Field('storageType', String, 'Storage Type',
        hint: 'Object, block, tape'),
    Field('storageCapacity', String, 'Storage Capacity',
        hint: 'Required capacity'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Performance and secondary storage.
  @SerializationOrder(1)
  BackupInfrastructureStorage storage = BackupInfrastructureStorage();

  /// Backup software configuration.
  @SerializationOrder(2)
  BackupInfrastructureSoftware software = BackupInfrastructureSoftware();

  /// Network requirements.
  @SerializationOrder(3)
  BackupInfrastructureNetwork network = BackupInfrastructureNetwork();

  /// Security controls.
  @SerializationOrder(4)
  BackupInfrastructureSecurity security = BackupInfrastructureSecurity();
}

/// Performance and secondary storage.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Describes secondary storage, geographic separation, and cross-region replication for backups.',
)
@SectionId('BAINST')
class BackupInfrastructureStorage {
  @Form([
    Field('storagePerformance', String, 'Storage Performance',
        hint: 'IOPS, throughput'),
    Field('secondaryStorage', String, 'Secondary Storage',
        hint: 'Secondary storage location'),
    Field('geographicSeparation', String, 'Geographic Separation',
        hint: 'Distance from primary'),
    Field('cloudBackupProvider', String, 'Cloud Backup Provider',
        hint: 'AWS S3, Azure Blob, GCS'),
    Field('crossRegionReplication', bool, 'Cross-Region Replication',
        hint: 'Replicate across regions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Backup software configuration.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Describes the backup software, agent model, and deduplication configuration.',
)
@SectionId('BAINSO')
class BackupInfrastructureSoftware {
  @Form([
    Field('backupSoftware', String, 'Backup Software',
        hint: 'Backup solution used'),
    Field('agentBased', bool, 'Agent-Based',
        hint: 'Requires backup agents'),
    Field('agentlessBackup', bool, 'Agentless Backup',
        hint: 'Snapshot-based backup'),
    Field('deduplication', bool, 'Deduplication',
        hint: 'Enable deduplication'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Network requirements.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Describes the dedicated network, bandwidth, and in-transit encryption for backup traffic.',
)
@SectionId('BAINNE')
class BackupInfrastructureNetwork {
  @Form([
    Field('backupNetwork', String, 'Backup Network',
        hint: 'Dedicated backup network'),
    Field('bandwidthRequired', String, 'Bandwidth Required',
        hint: 'Network bandwidth'),
    Field('encryptionInTransit', bool, 'Encryption in Transit',
        hint: 'Encrypt backup traffic'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security controls.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes access control, encryption, key management, and immutability for backups.',
)
@SectionId('BAINSE')
class BackupInfrastructureSecurity {
  @Form([
    Field('accessControl', String, 'Access Control',
        hint: 'Who can access backups'),
    Field('encryptionAlgorithm', String, 'Encryption Algorithm',
        hint: 'AES-256 etc.'),
    Field('keyManagement', String, 'Key Management',
        hint: 'Encryption key handling'),
    Field('immutableBackups', bool, 'Immutable Backups',
        hint: 'WORM compliance'),
    Field('notes', String, 'Notes',
        hint: 'Additional infrastructure notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Recovery procedures.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Describes the granular, volume, system, and bare-metal recovery procedures.',
)
@SectionId('RP')
class RecoveryProcedures {
  @Form([
    Field('granularRecovery', String, 'Granular Recovery',
        hint: 'File/item-level recovery'),
    Field('volumeRecovery', String, 'Volume Recovery',
        hint: 'Volume-level recovery'),
    Field('systemRecovery', String, 'Full System Recovery',
        hint: 'Complete system restore'),
    Field('bareMetalRecovery', bool, 'Bare Metal Recovery',
        hint: 'Hardware replacement'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Database recovery behavior.
  @SerializationOrder(1)
  RecoveryProceduresDatabase database = RecoveryProceduresDatabase();

  /// Application recovery behavior.
  @SerializationOrder(2)
  RecoveryProceduresApplication application = RecoveryProceduresApplication();

  /// Recovery automation.
  @SerializationOrder(3)
  RecoveryProceduresAutomation automation = RecoveryProceduresAutomation();

  /// Validation after recovery.
  @SerializationOrder(4)
  RecoveryProceduresValidation validation = RecoveryProceduresValidation();
}

/// Database recovery behavior.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Describes database restore, point-in-time, and transaction-log recovery behavior.',
)
@SectionId('REPRDA')
class RecoveryProceduresDatabase {
  @Form([
    Field('databaseRecovery', String, 'Database Recovery',
        hint: 'Database restore process'),
    Field('pointInTimeRecovery', bool, 'Point-in-Time Recovery',
        hint: 'Restore to specific time'),
    Field('transactionLogRecovery', bool, 'Transaction Log Recovery',
        hint: 'Log-based recovery'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Application recovery behavior.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Describes how application, configuration, and state are restored during recovery.',
)
@SectionId('REPRAP')
class RecoveryProceduresApplication {
  @Form([
    Field('applicationRecovery', String, 'Application Recovery',
        hint: 'App restoration process'),
    Field('configurationRecovery', String, 'Configuration Recovery',
        hint: 'Config restoration'),
    Field('stateRecovery', String, 'State Recovery',
        hint: 'Session/state restoration'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Recovery automation.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'Google SRE — site reliability engineering',
  ],
  'Describes automated recovery, recovery scripts, and where runbooks are stored.',
)
@SectionId('REPRAU')
class RecoveryProceduresAutomation {
  @Form([
    Field('automatedRecovery', bool, 'Automated Recovery',
        hint: 'Auto-failover enabled'),
    Field('recoveryScripts', String, 'Recovery Scripts',
        hint: 'Scripted recovery'),
    Field('runbookLocation', String, 'Runbook Location',
        hint: 'Where runbooks are stored'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Validation after recovery.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'Google SRE — site reliability engineering',
  ],
  'Describes the sanity and service checks that confirm data integrity after a restore.',
)
@SectionId('REPRVA')
class RecoveryProceduresValidation {
  @Form([
    Field('postRecoveryValidation', String, 'Post-Recovery Validation',
        hint: 'Validation procedures'),
    Field('sanityChecks', String, 'Sanity Checks',
        hint: 'Data integrity checks'),
    Field('serviceValidation', String, 'Service Validation',
        hint: 'Service health verification'),
    Field('notes', String, 'Notes',
        hint: 'Additional recovery notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Disaster recovery requirements.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ISO 22301 — business continuity management',
  ],
  'Captures the overall disaster recovery strategy, site, and provider for the system.',
)
@SectionId('DIRERE')
class DisasterRecoveryRequirements {
  @Form([
    Field('drStrategy', String, 'DR Strategy',
        hint: 'Hot, Warm, Cold standby'),
    Field('drSite', String, 'DR Site Location',
        hint: 'DR site location'),
    Field('drProvider', String, 'DR Provider',
        hint: 'DR service provider'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Failover execution.
  @SerializationOrder(1)
  DisasterRecoveryRequirementsFailover failover =
      DisasterRecoveryRequirementsFailover();

  /// Failback procedure.
  @SerializationOrder(2)
  DisasterRecoveryRequirementsFailback failback =
      DisasterRecoveryRequirementsFailback();

  /// Replication requirements.
  @SerializationOrder(3)
  DisasterRecoveryRequirementsReplication replication =
      DisasterRecoveryRequirementsReplication();

  /// Continuity and coordination.
  @SerializationOrder(4)
  DisasterRecoveryRequirementsContinuity continuity =
      DisasterRecoveryRequirementsContinuity();
}

/// Failover execution.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ISO 22301 — business continuity management',
  ],
  'Defines the failover type, trigger threshold, and duration for switching to the DR site.',
)
@SectionId('DRRF')
class DisasterRecoveryRequirementsFailover {
  @Form([
    Field('failoverType', String, 'Failover Type',
        hint: 'Automatic, Manual, Semi-auto'),
    Field('failoverThreshold', String, 'Failover Threshold',
        hint: 'When to trigger failover'),
    Field('failoverDuration', String, 'Failover Duration',
        hint: 'Time to complete failover'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Failback procedure.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ISO 22301 — business continuity management',
  ],
  'Describes returning from the DR site to primary and re-synchronizing data after failback.',
)
@SectionId('DIREREFA')
class DisasterRecoveryRequirementsFailback {
  @Form([
    Field('failbackProcedure', String, 'Failback Procedure',
        hint: 'Return to primary'),
    Field('failbackValidation', String, 'Failback Validation',
        hint: 'Validating failback'),
    Field('dataSync', String, 'Data Synchronization',
        hint: 'Syncing after failback'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Replication requirements.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ISO 22301 — business continuity management',
  ],
  'Specifies the replication method, acceptable lag, and bandwidth for the DR site.',
)
@SectionId('DRRR')
class DisasterRecoveryRequirementsReplication {
  @Form([
    Field('replicationMethod', String, 'Replication Method',
        hint: 'Sync, Async replication'),
    Field('replicationLag', String, 'Replication Lag',
        hint: 'Acceptable lag'),
    Field('replicationBandwidth', String, 'Replication Bandwidth',
        hint: 'Bandwidth for DR'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Continuity and coordination.
@StandardReferences(
  [
    'ISO 22301 — business continuity management',
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
  ],
  'Links disaster recovery to the business continuity plan, communication, and escalation.',
)
@SectionId('DRRC')
class DisasterRecoveryRequirementsContinuity {
  @Form([
    Field('businessContinuityPlan', String, 'Business Continuity Plan',
        hint: 'BCP reference'),
    Field('communicationPlan', String, 'Communication Plan',
        hint: 'Stakeholder notification'),
    Field('escalationPath', String, 'Escalation Path',
        hint: 'DR escalation'),
    Field('drTeam', String, 'DR Team',
        hint: 'DR response team'),
    Field('notes', String, 'Notes',
        hint: 'Additional DR notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Backup verification and testing.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Describes how backup integrity is verified and recoverability is regularly tested.',
)
@SectionId('BAVE')
class BackupVerification {
  @Form([
    Field('verificationFrequency', String, 'Verification Frequency',
        hint: 'How often to verify'),
    Field('verificationMethod', String, 'Verification Method',
        hint: 'Checksum, test restore'),
    Field('integrityChecks', bool, 'Integrity Checks',
        hint: 'Automated integrity checks'),
    Field('alertOnFailure', bool, 'Alert on Failure',
        hint: 'Notify on verification failure'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Recovery testing.
  @SerializationOrder(1)
  BackupVerificationRecovery recovery = BackupVerificationRecovery();

  /// Test environment constraints.
  @SerializationOrder(2)
  BackupVerificationEnvironment environment = BackupVerificationEnvironment();

  /// Documentation and follow-up.
  @SerializationOrder(3)
  BackupVerificationDocumentation documentation =
      BackupVerificationDocumentation();
}

/// Recovery testing.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ISO 22301 — business continuity management',
  ],
  'Defines the schedule and scope of recovery tests and disaster-recovery drills.',
)
@SectionId('BAVERE')
class BackupVerificationRecovery {
  @Form([
    Field('recoveryTestFrequency', String, 'Recovery Test Frequency',
        hint: 'How often to test recovery'),
    Field('fullRecoveryTest', String, 'Full Recovery Test',
        hint: 'Complete restore test'),
    Field('partialRecoveryTest', String, 'Partial Recovery Test',
        hint: 'Selective restore test'),
    Field('drTest', String, 'DR Test',
        hint: 'Disaster recovery drill'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Test environment constraints.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'Google SRE — site reliability engineering',
  ],
  'Defines the isolated environment and data handling used for recovery testing.',
)
@SectionId('BAVEEN')
class BackupVerificationEnvironment {
  @Form([
    Field('testEnvironment', String, 'Test Environment',
        hint: 'Where tests run'),
    Field('testDataHandling', String, 'Test Data Handling',
        hint: 'Handling test data'),
    Field('productionIsolation', bool, 'Production Isolation',
        hint: 'Isolated from production'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation and follow-up.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ITIL 4 — IT service management',
  ],
  'Records how verification test results are documented, signed off, and remediated.',
)
@SectionId('BAVEDO')
class BackupVerificationDocumentation {
  @Form([
    Field('testDocumentation', String, 'Test Documentation',
        hint: 'Test result documentation'),
    Field('testSignoff', String, 'Test Sign-off',
        hint: 'Who approves tests'),
    Field('deficiencyRemediation', String, 'Deficiency Remediation',
        hint: 'Addressing test failures'),
    Field('notes', String, 'Notes',
        hint: 'Additional verification notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Backup compliance requirements.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Captures regulatory, retention, and data-residency compliance requirements for backups.',
)
@SectionId('BACO')
class BackupCompliance {
  @Form([
    Field('regulatoryRequirements', String, 'Regulatory Requirements',
        hint: 'GDPR, HIPAA, SOX etc.'),
    Field('retentionCompliance', String, 'Retention Compliance',
        hint: 'Legal retention requirements'),
    Field('dataResidency', String, 'Data Residency',
        hint: 'Where backups can be stored'),
    Field('crossBorderTransfer', bool, 'Cross-Border Transfer',
        hint: 'International data transfer'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Audit controls.
  @SerializationOrder(1)
  BackupComplianceAudit audit = BackupComplianceAudit();

  /// Reporting obligations.
  @SerializationOrder(2)
  BackupComplianceReporting reporting = BackupComplianceReporting();

  /// Legal hold support.
  @SerializationOrder(3)
  BackupComplianceLegalHold legalHold = BackupComplianceLegalHold();
}

/// Audit controls.
@StandardReferences(
  [
    'ISO/IEC 20000 — IT service management system',
    'ITIL 4 — IT service management',
  ],
  'Describes audit trails, access logging, and change management for backup operations.',
)
@SectionId('BACOAU')
class BackupComplianceAudit {
  @Form([
    Field('auditTrail', bool, 'Audit Trail',
        hint: 'Backup operation logging'),
    Field('accessLogging', bool, 'Access Logging',
        hint: 'Log backup access'),
    Field('changeManagement', String, 'Change Management',
        hint: 'Backup policy changes'),
    Field('auditFrequency', String, 'Audit Frequency',
        hint: 'How often audited'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reporting obligations.
@StandardReferences(
  [
    'ISO/IEC 20000 — IT service management system',
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
  ],
  'Defines the compliance reporting produced from backup operations and who receives it.',
)
@SectionId('BACOR1')
class BackupComplianceReporting {
  @Form([
    Field('complianceReporting', String, 'Compliance Reporting',
        hint: 'Required reports'),
    Field('reportFrequency', String, 'Report Frequency',
        hint: 'How often reported'),
    Field('reportRecipients', String, 'Report Recipients',
        hint: 'Who receives reports'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Legal hold support.
@StandardReferences(
  [
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes legal hold and eDiscovery support so backups can be preserved for litigation.',
)
@SectionId('BCLH')
class BackupComplianceLegalHold {
  @Form([
    Field('legalHoldCapability', bool, 'Legal Hold Capability',
        hint: 'Support legal holds'),
    Field('legalHoldProcess', String, 'Legal Hold Process',
        hint: 'How legal holds work'),
    Field('eDiscovery', String, 'eDiscovery Support',
        hint: 'Supporting eDiscovery'),
    Field('notes', String, 'Notes',
        hint: 'Additional compliance notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// =============================================================================
// 8.5.2. Deployment Strategy
// =============================================================================

/// 8.5.2. Deployment Strategy.
///
/// Deployment model (containerized, VM-based, serverless), deployment pipeline,
/// rollback strategy, and canary/blue-green deployment requirements.
@ContentHelp('''
Specify deployment model, CI/CD pipeline, release strategy, and rollback
procedures. Reliable deployments enable fast iteration and reduce risk.

**Deployment Models**:
- **Containerized**: Docker, Kubernetes orchestration
- **VM-Based**: Traditional server deployment, AMI/image-based
- **Serverless**: Function deployment, managed scaling
- **Hybrid**: Mix of models for different components

**CI/CD Pipeline Stages**:
1. **Build**: Compile, lint, unit tests
2. **Test**: Integration tests, security scans
3. **Package**: Container image, artifact creation
4. **Deploy to Staging**: Automated deployment, smoke tests
5. **QA/Acceptance**: Manual or automated acceptance
6. **Deploy to Production**: Gated deployment, monitoring

**Release Strategies**:
- **Rolling**: Gradual instance replacement
- **Blue-Green**: Two identical environments, instant switch
- **Canary**: Small percentage rollout, gradual increase
- **Feature Flags**: Runtime feature toggling

**Rollback Strategy**:
- Automatic rollback on health check failure
- Manual rollback procedures and triggers
- Database migration rollback plan
- Configuration rollback

**Infrastructure as Code**:
- Terraform, Pulumi, CloudFormation, ARM templates
- GitOps workflow with ArgoCD, Flux
- Environment promotion pipeline
''')
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'Google SRE — site reliability engineering',
    'DORA metrics — DevOps performance',
  ],
  'Describes the overall deployment strategy for releasing the system, including pipeline, release strategy, and rollback.',
)
@SectionId('DSS')
class DeploymentStrategySection {
  @ContentHelp('''
Provide an overview of deployment strategy and pipeline.

**Include**:
- Deployment model and orchestration
- CI/CD pipeline overview
- Release strategy selection and rationale
- Rollback procedures and triggers
- Deployment metrics and goals

**Best Practices**:
- Deploy frequently in small batches
- Automate everything, minimize manual steps
- Implement comprehensive deployment testing
- Monitor deployments with automated rollback
- Document deployment runbooks
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of deployment strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Deployment model requirements.
  @SerializationOrder(2)
  DeploymentModelRequirements deploymentModel = DeploymentModelRequirements();

  /// Environment strategy.
  @SerializationOrder(3)
  EnvironmentStrategy environments = EnvironmentStrategy();

  /// CI/CD pipeline requirements.
  @SerializationOrder(4)
  CiCdPipelineRequirements cicdPipeline = CiCdPipelineRequirements();

  /// Release strategy.
  @SerializationOrder(5)
  ReleaseStrategy releaseStrategy = ReleaseStrategy();

  /// Rollback strategy.
  @SerializationOrder(6)
  RollbackStrategy rollbackStrategy = RollbackStrategy();

  /// Configuration management.
  @SerializationOrder(7)
  ConfigurationManagement configurationManagement = ConfigurationManagement();

  /// Infrastructure as Code requirements.
  @SerializationOrder(8)
  InfrastructureAsCode infrastructureAsCode = InfrastructureAsCode();

  /// Deployment security requirements.
  @SerializationOrder(9)
  DeploymentSecurity deploymentSecurity = DeploymentSecurity();
}

/// Deployment model requirements.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native ops',
    'CI/CD — continuous delivery pipelines',
  ],
  'Describes the deployment model — containerized, VM-based, or serverless — and its orchestration platform.',
)
@SectionId('DEMORE')
class DeploymentModelRequirements {
  @Form([
    Field('deploymentModel', String, 'Deployment Model',
        hint: 'Containerized, VM-based, Serverless, Hybrid'),
    Field('containerRuntime', String, 'Container Runtime',
        hint: 'Docker, containerd, CRI-O'),
    Field('orchestrationPlatform', String, 'Orchestration Platform',
        hint: 'Kubernetes, ECS, Nomad'),
    Field('serverlessProvider', String, 'Serverless Provider',
        hint: 'AWS Lambda, Azure Functions, Cloud Run'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Container image policies.
  @SerializationOrder(1)
  DeploymentModelRequirementsContainer container =
      DeploymentModelRequirementsContainer();

  /// Resource allocation.
  @SerializationOrder(2)
  DeploymentModelRequirementsResources resources =
      DeploymentModelRequirementsResources();

  /// Networking configuration.
  @SerializationOrder(3)
  DeploymentModelRequirementsNetworking networking =
      DeploymentModelRequirementsNetworking();

  /// Storage configuration.
  @SerializationOrder(4)
  DeploymentModelRequirementsStorage storage =
      DeploymentModelRequirementsStorage();
}

/// Container image policies.
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'ISO/IEC 27001 — information security controls',
  ],
  'Defines container image policies: registry, security scanning on push, tagging strategy, and approved base images.',
)
@SectionId('DMRC')
class DeploymentModelRequirementsContainer {
  @Form([
    Field('containerRegistry', String, 'Container Registry',
        hint: 'ECR, ACR, GCR, Docker Hub'),
    Field('imageScanningRequired', bool, 'Image Scanning Required',
        hint: 'Security scanning on push'),
    Field('imageTaggingStrategy', String, 'Image Tagging Strategy',
        hint: 'Semantic versioning, git SHA'),
    Field('baseImagePolicy', String, 'Base Image Policy',
        hint: 'Approved base images'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Resource allocation.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'Twelve-Factor App — cloud-native ops',
  ],
  'Defines CPU/memory resource requirements, scaling configuration, and replica counts for deployed workloads.',
)
@SectionId('DMRR')
class DeploymentModelRequirementsResources {
  @Form([
    Field('resourceRequirements', String, 'Resource Requirements',
        hint: 'CPU, memory specifications'),
    Field('scalingConfiguration', String, 'Scaling Configuration',
        hint: 'HPA, VPA, cluster autoscaler'),
    Field('replicaCount', String, 'Replica Count',
        hint: 'Default and min/max replicas'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Networking configuration.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native ops',
    'Google SRE — site reliability engineering',
  ],
  'Defines the deployment networking: service discovery, ingress configuration, and load balancing.',
)
@SectionId('DMRN')
class DeploymentModelRequirementsNetworking {
  @Form([
    Field('serviceDiscovery', String, 'Service Discovery',
        hint: 'DNS, service mesh'),
    Field('ingressConfiguration', String, 'Ingress Configuration',
        hint: 'Ingress controller, routes'),
    Field('loadBalancing', String, 'Load Balancing',
        hint: 'ALB, NLB, internal LB'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Storage configuration.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native ops',
    'Google SRE — site reliability engineering',
  ],
  'Defines persistent-storage requirements and storage classes for deployed workloads.',
)
@SectionId('DMRS')
class DeploymentModelRequirementsStorage {
  @Form([
    Field('persistentStorage', String, 'Persistent Storage',
        hint: 'PVC, EBS, EFS requirements'),
    Field('storageClass', String, 'Storage Class',
        hint: 'SSD, HDD, performance tier'),
    Field('notes', String, 'Notes',
        hint: 'Additional deployment model notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Environment strategy.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native ops',
    'CI/CD — continuous delivery pipelines',
  ],
  'Describes the environment tiers, their parity with production, and their isolation.',
)
@SectionId('ENST')
class EnvironmentStrategy {
  @Form([
    Field('environmentTiers', String, 'Environment Tiers',
        hint: 'Dev, Test, Staging, Prod'),
    Field('environmentParity', String, 'Environment Parity',
        hint: 'How similar envs are to prod'),
    Field('environmentIsolation', String, 'Environment Isolation',
        hint: 'Network, account, cluster isolation'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Development environment setup.
  @SerializationOrder(1)
  EnvironmentStrategyDevelopment development = EnvironmentStrategyDevelopment();

  /// Test environment setup.
  @SerializationOrder(2)
  EnvironmentStrategyTesting testing = EnvironmentStrategyTesting();

  /// Staging configuration.
  @SerializationOrder(3)
  EnvironmentStrategyStaging staging = EnvironmentStrategyStaging();

  /// Production configuration.
  @SerializationOrder(4)
  EnvironmentStrategyProduction production = EnvironmentStrategyProduction();

  /// Ephemeral environment strategy.
  @SerializationOrder(5)
  EnvironmentStrategyEphemeral ephemeral = EnvironmentStrategyEphemeral();
}

/// Development environment setup.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native ops',
    'CI/CD — continuous delivery pipelines',
  ],
  'Defines the development and local environment setup and the strategy for development data.',
)
@SectionId('ENSTDE')
class EnvironmentStrategyDevelopment {
  @Form([
    Field('devEnvironment', String, 'Development Environment',
        hint: 'Dev environment setup'),
    Field('localDevelopment', String, 'Local Development',
        hint: 'Local dev environment'),
    Field('devDataStrategy', String, 'Dev Data Strategy',
        hint: 'Synthetic, anonymized, subset'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Test environment setup.
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'Twelve-Factor App — cloud-native ops',
  ],
  'Defines the test, integration, and performance environments used to validate changes before release.',
)
@SectionId('ENSTTE')
class EnvironmentStrategyTesting {
  @Form([
    Field('testEnvironment', String, 'Test Environment',
        hint: 'Test/QA environment'),
    Field('integrationEnvironment', String, 'Integration Environment',
        hint: 'Integration testing env'),
    Field('performanceEnvironment', String, 'Performance Environment',
        hint: 'Performance testing env'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Staging configuration.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native ops',
    'CI/CD — continuous delivery pipelines',
  ],
  'Defines the pre-production staging environment, its parity with production, and how its data is refreshed.',
)
@SectionId('ENSTST')
class EnvironmentStrategyStaging {
  @Form([
    Field('stagingEnvironment', String, 'Staging Environment',
        hint: 'Pre-production staging'),
    Field('stagingProdParity', bool, 'Staging-Prod Parity',
        hint: 'Staging mirrors production'),
    Field('stagingDataRefresh', String, 'Staging Data Refresh',
        hint: 'How staging data is refreshed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Production configuration.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'Twelve-Factor App — cloud-native ops',
  ],
  'Defines the production environment configuration, including multi-region and active-active deployment topology.',
)
@SectionId('ENSTPR')
class EnvironmentStrategyProduction {
  @Form([
    Field('productionEnvironment', String, 'Production Environment',
        hint: 'Production deployment'),
    Field('multiRegion', bool, 'Multi-Region',
        hint: 'Multi-region deployment'),
    Field('activeActive', bool, 'Active-Active',
        hint: 'Active-active configuration'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Ephemeral environment strategy.
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'Twelve-Factor App — cloud-native ops',
  ],
  'Defines ephemeral per-PR or per-feature environments and their auto-cleanup lifecycle.',
)
@SectionId('ENSTEP')
class EnvironmentStrategyEphemeral {
  @Form([
    Field('ephemeralEnvironments', bool, 'Ephemeral Environments',
        hint: 'Per-PR/feature environments'),
    Field('environmentLifecycle', String, 'Environment Lifecycle',
        hint: 'Auto-cleanup, retention'),
    Field('notes', String, 'Notes',
        hint: 'Additional environment notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// CI/CD pipeline requirements.
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'DORA metrics — DevOps performance',
  ],
  'Describes the CI/CD pipeline platform and pipeline-as-code approach that automates build, test, and deployment.',
)
@SectionId('CCPR')
class CiCdPipelineRequirements {
  @Form([
    Field('cicdPlatform', String, 'CI/CD Platform',
        hint: 'GitHub Actions, GitLab CI, Jenkins'),
    Field('pipelineAsCode', bool, 'Pipeline as Code',
        hint: 'Pipeline definition in repo'),
    Field('pipelineLocation', String, 'Pipeline Location',
        hint: 'Where pipeline files are stored'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Build stage settings.
  @SerializationOrder(1)
  CiCdPipelineRequirementsBuild build = CiCdPipelineRequirementsBuild();

  /// Quality gate settings.
  @SerializationOrder(2)
  CiCdPipelineRequirementsQuality quality = CiCdPipelineRequirementsQuality();

  /// Deployment stage settings.
  @SerializationOrder(3)
  CiCdPipelineRequirementsDeployment deployment =
      CiCdPipelineRequirementsDeployment();

  /// Notification and escalation settings.
  @SerializationOrder(4)
  CiCdPipelineRequirementsNotifications notifications =
      CiCdPipelineRequirementsNotifications();
}

/// Build stage settings.
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'DORA metrics — DevOps performance',
  ],
  'Defines the build stage: triggers, compile/test/lint/scan steps, dependency caching, and produced artifacts.',
)
@SectionId('CCPRB')
class CiCdPipelineRequirementsBuild {
  @Form([
    Field('buildTriggers', String, 'Build Triggers',
        hint: 'Push, PR, tag, schedule'),
    Field('buildSteps', String, 'Build Steps',
        hint: 'Compile, test, lint, scan'),
    Field('buildCaching', String, 'Build Caching',
        hint: 'Dependency caching strategy'),
    Field('buildArtifacts', String, 'Build Artifacts',
        hint: 'What artifacts are produced'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Quality gate settings.
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'ISO/IEC 27001 — information security controls',
  ],
  'Defines pipeline quality gates: code-quality checks, test-coverage thresholds, security scans, and manual approval gates.',
)
@SectionId('CCPRQ')
class CiCdPipelineRequirementsQuality {
  @Form([
    Field('codeQualityGates', String, 'Code Quality Gates',
        hint: 'Linting, static analysis'),
    Field('testCoverageThreshold', String, 'Test Coverage Threshold',
        hint: 'Minimum coverage required'),
    Field('securityScanRequired', bool, 'Security Scan Required',
        hint: 'SAST, SCA in pipeline'),
    Field('approvalRequired', bool, 'Approval Required',
        hint: 'Manual approval gates'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Deployment stage settings.
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'DORA metrics — DevOps performance',
  ],
  'Defines the ordered deployment stages, auto-deploy behavior per environment, and the production deployment gate.',
)
@SectionId('CCPRD')
class CiCdPipelineRequirementsDeployment {
  @Form([
    Field('deploymentStages', String, 'Deployment Stages',
        hint: 'Ordered deployment stages'),
    Field('autoDeployDev', bool, 'Auto-Deploy to Dev',
        hint: 'Auto-deploy on merge'),
    Field('autoDeployStaging', bool, 'Auto-Deploy to Staging',
        hint: 'Auto-deploy to staging'),
    Field('productionGate', String, 'Production Gate',
        hint: 'Prod deployment gate'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Notification and escalation settings.
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'Google SRE — site reliability engineering',
  ],
  'Defines pipeline notifications and the escalation path when a build or deployment fails.',
)
@SectionId('CCPRN')
class CiCdPipelineRequirementsNotifications {
  @Form([
    Field('pipelineNotifications', String, 'Pipeline Notifications',
        hint: 'Slack, email, Teams alerts'),
    Field('failureEscalation', String, 'Failure Escalation',
        hint: 'Build failure response'),
    Field('notes', String, 'Notes',
        hint: 'Additional CI/CD notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Release strategy.
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'DORA metrics — DevOps performance',
  ],
  'Describes the release methodology, frequency, and schedule for delivering new versions to production.',
)
@SectionId('REST')
class ReleaseStrategy {
  @Form([
    Field('releaseMethodology', String, 'Release Methodology',
        hint: 'Blue-green, Canary, Rolling, A/B'),
    Field('releaseFrequency', String, 'Release Frequency',
        hint: 'Daily, Weekly, Bi-weekly'),
    Field('releaseSchedule', String, 'Release Schedule',
        hint: 'When releases occur'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Blue-green deployment configuration.
  @SerializationOrder(1)
  ReleaseStrategyBlueGreen blueGreen = ReleaseStrategyBlueGreen();

  /// Canary deployment configuration.
  @SerializationOrder(2)
  ReleaseStrategyCanary canary = ReleaseStrategyCanary();

  /// Feature flags configuration.
  @SerializationOrder(3)
  ReleaseStrategyFeatureFlags featureFlags = ReleaseStrategyFeatureFlags();

  /// Release management.
  @SerializationOrder(4)
  ReleaseStrategyManagement management = ReleaseStrategyManagement();
}

/// Blue-green deployment configuration.
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'Google SRE — site reliability engineering',
  ],
  'Defines blue-green deployment: traffic switching, warmup period, and retention of the old (green) version for fast switch-back.',
)
@SectionId('RSBG')
class ReleaseStrategyBlueGreen {
  @Form([
    Field('releaseWindow', String, 'Release Window',
        hint: 'Allowed deployment times'),
    Field('blueGreenEnabled', bool, 'Blue-Green Enabled',
        hint: 'Uses blue-green deployment'),
    Field('trafficSwitching', String, 'Traffic Switching',
        hint: 'How traffic is switched'),
    Field('warmupPeriod', String, 'Warmup Period',
        hint: 'New version warmup time'),
    Field('greenRetention', String, 'Green Retention',
        hint: 'How long to keep old version'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Canary deployment configuration.
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'Google SRE — site reliability engineering',
  ],
  'Defines canary deployment: initial traffic percentage, ramp-up steps, health metrics, and auto-rollback criteria.',
)
@SectionId('RESTCA')
class ReleaseStrategyCanary {
  @Form([
    Field('canaryEnabled', bool, 'Canary Enabled',
        hint: 'Uses canary deployment'),
    Field('canaryPercentage', String, 'Canary Percentage',
        hint: 'Initial canary traffic %'),
    Field('canaryRampUpSteps', String, 'Canary Ramp-Up Steps',
        hint: 'Percentage ramp-up steps'),
    Field('canaryMetrics', String, 'Canary Metrics',
        hint: 'Metrics for canary health'),
    Field('canaryDuration', String, 'Canary Duration',
        hint: 'Time at each step'),
    Field('autoRollbackCriteria', String, 'Auto-Rollback Criteria',
        hint: 'When to auto-rollback canary'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Feature flags configuration.
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'Twelve-Factor App — cloud-native ops',
  ],
  'Defines feature-flag usage for decoupling deploy from release, including provider and flag-management strategy.',
)
@SectionId('RSFF')
class ReleaseStrategyFeatureFlags {
  @Form([
    Field('featureFlagsEnabled', bool, 'Feature Flags Enabled',
        hint: 'Uses feature flags'),
    Field('featureFlagProvider', String, 'Feature Flag Provider',
        hint: 'LaunchDarkly, Flagsmith, custom'),
    Field('flagStrategy', String, 'Flag Strategy',
        hint: 'How flags are managed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Release management configuration.
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'CI/CD — continuous delivery pipelines',
  ],
  'Defines release management practices: release notes, changelog generation, and release approval.',
)
@SectionId('RESTMA')
class ReleaseStrategyManagement {
  @Form([
    Field('releaseNotes', String, 'Release Notes',
        hint: 'Release notes process'),
    Field('changelogGeneration', String, 'Changelog Generation',
        hint: 'Auto or manual changelog'),
    Field('releaseApproval', String, 'Release Approval',
        hint: 'Who approves releases'),
    Field('notes', String, 'Notes',
        hint: 'Additional release notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Rollback strategy.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'CI/CD — continuous delivery pipelines',
  ],
  'Describes the overall rollback strategy for reverting a failed deployment safely.',
)
@SectionId('ROST')
class RollbackStrategy {
  @Form([
    Field('rollbackMethod', String, 'Rollback Method',
        hint: 'Redeploy, traffic switch, restore'),
    Field('autoRollbackEnabled', bool, 'Auto-Rollback Enabled',
        hint: 'Automatic rollback on failure'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Trigger and timing conditions.
  @SerializationOrder(1)
  RollbackStrategyTriggers triggers = RollbackStrategyTriggers();

  /// Health-based rollback thresholds.
  @SerializationOrder(2)
  RollbackStrategyHealth health = RollbackStrategyHealth();

  /// Rollback target and artifact retention.
  @SerializationOrder(3)
  RollbackStrategyTargets targets = RollbackStrategyTargets();

  /// Data rollback safeguards.
  @SerializationOrder(4)
  RollbackStrategyData data = RollbackStrategyData();

  /// Manual procedure and follow-up.
  @SerializationOrder(5)
  RollbackStrategyOperations operations = RollbackStrategyOperations();
}

/// Trigger and timing conditions.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'DORA metrics — DevOps performance',
  ],
  'Defines what triggers a rollback and the target time to complete it (time-to-restore).',
)
@SectionId('ROSTTR')
class RollbackStrategyTriggers {
  @Form([
    Field('rollbackTriggers', String, 'Rollback Triggers',
        hint: 'What triggers rollback'),
    Field('rollbackTimeTarget', String, 'Rollback Time Target',
        hint: 'Max time to complete rollback'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Health-based rollback thresholds.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'DORA metrics — DevOps performance',
  ],
  'Defines health signal thresholds — error rate, latency, and health-check failures — that trigger an automatic rollback.',
)
@SectionId('ROSTHE')
class RollbackStrategyHealth {
  @Form([
    Field('healthCheckFailures', String, 'Health Check Failures',
        hint: 'Failures before rollback'),
    Field('errorRateThreshold', String, 'Error Rate Threshold',
        hint: 'Error rate triggering rollback'),
    Field('latencyThreshold', String, 'Latency Threshold',
        hint: 'Latency triggering rollback'),
    Field('customMetricThresholds', String, 'Custom Metric Thresholds',
        hint: 'Business metrics for rollback'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Rollback target and artifact retention.
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'Google SRE — site reliability engineering',
  ],
  'Defines which version a rollback targets and how many prior artifacts are retained for rollback.',
)
@SectionId('ROSTTA')
class RollbackStrategyTargets {
  @Form([
    Field('rollbackTarget', String, 'Rollback Target',
        hint: 'Previous version, specific version'),
    Field('versionRetention', String, 'Version Retention',
        hint: 'How many versions kept'),
    Field('artifactStorage', String, 'Artifact Storage',
        hint: 'Where rollback artifacts stored'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data rollback safeguards.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'CI/CD — continuous delivery pipelines',
  ],
  'Defines safeguards for rolling back data and database migrations while preserving backward compatibility.',
)
@SectionId('ROSTDA')
class RollbackStrategyData {
  @Form([
    Field('dataRollbackStrategy', String, 'Data Rollback Strategy',
        hint: 'How to handle data on rollback'),
    Field('migrationRollback', String, 'Migration Rollback',
        hint: 'Database migration rollback'),
    Field('backwardCompatibility', String, 'Backward Compatibility',
        hint: 'Data format compatibility'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Manual procedure and follow-up.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'ITIL 4 — IT service management',
  ],
  'Defines the manual rollback procedure, validation of a successful rollback, and post-rollback follow-up actions.',
)
@SectionId('ROSTOP')
class RollbackStrategyOperations {
  @Form([
    Field('manualRollbackProcedure', String, 'Manual Rollback Procedure',
        hint: 'Steps for manual rollback'),
    Field('rollbackValidation', String, 'Rollback Validation',
        hint: 'Validating successful rollback'),
    Field('postRollbackActions', String, 'Post-Rollback Actions',
        hint: 'Actions after rollback'),
    Field('notes', String, 'Notes',
        hint: 'Additional rollback notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Configuration management.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native ops',
    'ISO/IEC 27001 — information security controls',
  ],
  'Describes how application configuration and secrets are stored, versioned, and audited across environments.',
)
@SectionId('CM')
class ConfigurationManagement {
  @Form([
    Field('configStorage', String, 'Configuration Storage',
        hint: 'ConfigMaps, SSM, Consul'),
    Field('secretsManagement', String, 'Secrets Management',
        hint: 'Vault, AWS Secrets, Azure KV'),
    Field('configVersioning', bool, 'Config Versioning',
        hint: 'Version controlled config'),
    Field('configAudit', bool, 'Config Audit',
        hint: 'Audit config changes'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Environment-configuration rules.
  @SerializationOrder(1)
  ConfigurationManagementEnvironment environment =
      ConfigurationManagementEnvironment();

  /// Configuration injection rules.
  @SerializationOrder(2)
  ConfigurationManagementInjection injection =
      ConfigurationManagementInjection();

  /// Feature-configuration rules.
  @SerializationOrder(3)
  ConfigurationManagementFeatures features =
      ConfigurationManagementFeatures();

  /// Security controls.
  @SerializationOrder(4)
  ConfigurationManagementSecurity security =
      ConfigurationManagementSecurity();
}

/// Environment-configuration rules.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native ops',
    'CI/CD — continuous delivery pipelines',
  ],
  'Defines how configuration differs per environment through inheritance and override patterns, with validation.',
)
@SectionId('COMAEN')
class ConfigurationManagementEnvironment {
  @Form([
    Field('envSpecificConfig', String, 'Environment-Specific Config',
        hint: 'How env config differs'),
    Field('configInheritance', String, 'Config Inheritance',
        hint: 'Base + override pattern'),
    Field('configValidation', String, 'Config Validation',
        hint: 'Config validation process'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Configuration injection rules.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native ops',
    'Google SRE — site reliability engineering',
  ],
  'Defines how configuration is injected into running apps and how they reload it dynamically at runtime.',
)
@SectionId('COMAIN')
class ConfigurationManagementInjection {
  @Form([
    Field('configInjectionMethod', String, 'Config Injection Method',
        hint: 'Env vars, mounted files'),
    Field('dynamicConfig', bool, 'Dynamic Config',
        hint: 'Runtime config updates'),
    Field('configReload', String, 'Config Reload',
        hint: 'How apps reload config'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Feature-configuration rules.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native ops',
    'CI/CD — continuous delivery pipelines',
  ],
  'Defines feature-toggle, experiment, and per-tenant configuration rules that vary runtime behavior.',
)
@SectionId('COMAFE')
class ConfigurationManagementFeatures {
  @Form([
    Field('featureToggles', String, 'Feature Toggles',
        hint: 'Feature toggle management'),
    Field('experimentsConfig', String, 'Experiments Config',
        hint: 'A/B test configuration'),
    Field('tenantConfig', String, 'Tenant Configuration',
        hint: 'Per-tenant configuration'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security controls.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security controls',
    'Twelve-Factor App — cloud-native ops',
  ],
  'Defines security controls over configuration, including secret rotation and access control for who may manage config.',
)
@SectionId('COMASE')
class ConfigurationManagementSecurity {
  @Form([
    Field('secretRotation', String, 'Secret Rotation',
        hint: 'Secret rotation policy'),
    Field('accessControl', String, 'Access Control',
        hint: 'Who can manage config'),
    Field('notes', String, 'Notes',
        hint: 'Additional config notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Infrastructure as Code requirements.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native ops',
    'CI/CD — continuous delivery pipelines',
  ],
  'Describes the Infrastructure-as-Code tooling, repository, and reusable-module strategy for provisioning environments.',
)
@SectionId('INASCO')
class InfrastructureAsCode {
  @Form([
    Field('iacTool', String, 'IaC Tool',
        hint: 'Terraform, Pulumi, CloudFormation'),
    Field('iacRepository', String, 'IaC Repository',
        hint: 'Where IaC code lives'),
    Field('iacModules', String, 'IaC Modules',
        hint: 'Reusable modules strategy'),
    Field('iacRegistry', String, 'IaC Registry',
        hint: 'Private module registry'),
  ])
  @SerializationOrder(0)
  String? content;

  /// State management.
  @SerializationOrder(1)
  InfrastructureAsCodeState state = InfrastructureAsCodeState();

  /// Execution governance.
  @SerializationOrder(2)
  InfrastructureAsCodeExecution execution = InfrastructureAsCodeExecution();

  /// Drift detection settings.
  @SerializationOrder(3)
  InfrastructureAsCodeDrift drift = InfrastructureAsCodeDrift();

  /// Security and policy controls.
  @SerializationOrder(4)
  InfrastructureAsCodeSecurity security = InfrastructureAsCodeSecurity();
}

/// State management.
@StandardReferences(
  [
    'Twelve-Factor App — cloud-native ops',
    'Google SRE — site reliability engineering',
  ],
  'Defines how infrastructure state is stored, locked against concurrent changes, and separated per environment.',
)
@SectionId('IACS')
class InfrastructureAsCodeState {
  @Form([
    Field('stateStorage', String, 'State Storage',
        hint: 'S3, GCS, Azure Blob'),
    Field('stateLocking', bool, 'State Locking',
        hint: 'Prevent concurrent changes'),
    Field('stateEnvironmentSeparation', String, 'State Separation',
        hint: 'Per-environment state files'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Execution governance.
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'CI/CD — continuous delivery pipelines',
  ],
  'Governs how infrastructure plans are reviewed, approved, and applied through the CI/CD pipeline.',
)
@SectionId('IACE')
class InfrastructureAsCodeExecution {
  @Form([
    Field('planReview', String, 'Plan Review',
        hint: 'Who reviews IaC plans'),
    Field('applyApproval', String, 'Apply Approval',
        hint: 'Approval for applying changes'),
    Field('pipelineIntegration', String, 'Pipeline Integration',
        hint: 'IaC in CI/CD pipeline'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Drift detection settings.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'Twelve-Factor App — cloud-native ops',
  ],
  'Defines how manual drift from the desired infrastructure state is detected, remediated, and reconciled on a schedule.',
)
@SectionId('IACD')
class InfrastructureAsCodeDrift {
  @Form([
    Field('driftDetection', bool, 'Drift Detection',
        hint: 'Detect manual changes'),
    Field('driftRemediation', String, 'Drift Remediation',
        hint: 'How to handle drift'),
    Field('reconciliationSchedule', String, 'Reconciliation Schedule',
        hint: 'When to check for drift'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security and policy controls.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security controls',
    'Twelve-Factor App — cloud-native ops',
  ],
  'Defines security and policy-as-code controls for infrastructure code, including sensitive-value handling and compliance checks.',
)
@SectionId('INASCOSE')
class InfrastructureAsCodeSecurity {
  @Form([
    Field('sensitiveValueHandling', String, 'Sensitive Value Handling',
        hint: 'Handling secrets in IaC'),
    Field('policyAsCode', String, 'Policy as Code',
        hint: 'OPA, Sentinel policies'),
    Field('complianceChecks', String, 'Compliance Checks',
        hint: 'Compliance validation'),
    Field('notes', String, 'Notes',
        hint: 'Additional IaC notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Deployment security requirements.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security controls',
    'CI/CD — continuous delivery pipelines',
  ],
  'Describes the security requirements applied to the deployment pipeline and its runtime.',
)
@SectionId('DESE')
class DeploymentSecurity {
  @Form([
    Field('pipelineSecrets', String, 'Pipeline Secrets',
        hint: 'How secrets are injected'),
    Field('serviceAccounts', String, 'Service Accounts',
        hint: 'Deployment service accounts'),
    Field('roleBindings', String, 'Role Bindings',
        hint: 'Kubernetes RBAC'),
    Field('leastPrivilege', bool, 'Least Privilege',
        hint: 'Minimum required permissions'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Supply-chain security.
  @SerializationOrder(1)
  DeploymentSecuritySupplyChain supplyChain = DeploymentSecuritySupplyChain();

  /// Runtime security.
  @SerializationOrder(2)
  DeploymentSecurityRuntime runtime = DeploymentSecurityRuntime();

  /// Access control and audit.
  @SerializationOrder(3)
  DeploymentSecurityAccess access = DeploymentSecurityAccess();
}

/// Supply-chain security.
@StandardReferences(
  [
    'CI/CD — continuous delivery pipelines',
    'ISO/IEC 27001 — information security controls',
  ],
  'Covers supply-chain integrity for the delivery pipeline: signed artifacts, image signatures, SBOM generation, and provenance attestation.',
)
@SectionId('DSSC')
class DeploymentSecuritySupplyChain {
  @Form([
    Field('signedArtifacts', bool, 'Signed Artifacts',
        hint: 'Artifact signing required'),
    Field('imageSignature', String, 'Image Signature',
        hint: 'Cosign, Notary'),
    Field('sbomGeneration', bool, 'SBOM Generation',
        hint: 'Software bill of materials'),
    Field('supplyChainAttestation', String, 'Supply Chain Attestation',
        hint: 'Provenance verification'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Runtime security.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security controls',
    'Google SRE — site reliability engineering',
  ],
  'Defines runtime security hardening for deployed workloads such as pod security policies, network policies, and immutable containers.',
)
@SectionId('DESERU')
class DeploymentSecurityRuntime {
  @Form([
    Field('podSecurityPolicy', String, 'Pod Security Policy',
        hint: 'PSP/PSA configuration'),
    Field('networkPolicies', String, 'Network Policies',
        hint: 'Network segmentation'),
    Field('seccompProfile', String, 'Seccomp Profile',
        hint: 'Syscall restrictions'),
    Field('readOnlyRootFilesystem', bool, 'Read-Only Root Filesystem',
        hint: 'Immutable containers'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access control and audit.
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'ISO/IEC 27001 — information security controls',
  ],
  'Governs who may approve deployments, break-glass emergency access, and audit logging of all deployments.',
)
@SectionId('DESEAC')
class DeploymentSecurityAccess {
  @Form([
    Field('deploymentApprovers', String, 'Deployment Approvers',
        hint: 'Who can approve deployments'),
    Field('emergencyAccess', String, 'Emergency Access',
        hint: 'Break-glass procedures'),
    Field('auditLogging', bool, 'Audit Logging',
        hint: 'Log all deployments'),
    Field('notes', String, 'Notes',
        hint: 'Additional deployment security notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// =============================================================================
// 8.5.3. Monitoring and Alerting
// =============================================================================

/// 8.5.3. Monitoring and Alerting.
///
/// Monitoring requirements: metrics to collect, alert thresholds, dashboard
/// requirements, on-call procedures, and escalation paths.
@ContentHelp('''
Specify monitoring, alerting, logging, and observability requirements.
Effective monitoring enables rapid issue detection and resolution.

**Three Pillars of Observability**:
- **Metrics**: Quantitative measurements (latency, throughput, errors)
- **Logs**: Discrete events with context
- **Traces**: Request flow across services

**Monitoring Infrastructure**:
- Metrics: Prometheus, Datadog, CloudWatch, New Relic
- Logging: ELK Stack, Splunk, CloudWatch Logs, Loki
- Tracing: Jaeger, Zipkin, AWS X-Ray, Honeycomb
- APM: Datadog APM, New Relic APM, Dynatrace

**Key Metrics**:
- **SLIs (Service Level Indicators)**: Latency, availability, error rate
- **SLOs (Service Level Objectives)**: Targets for SLIs
- **Error Budgets**: Acceptable error margin
- **Golden Signals**: Latency, traffic, errors, saturation

**Alerting Requirements**:
- Alert severity levels and response times
- Notification channels (PagerDuty, Slack, email)
- Alert routing and escalation
- Alert fatigue prevention

**Dashboards and Visualization**:
- Operational dashboards for on-call
- Business metrics dashboards
- Real-time vs. historical views
- SLO tracking dashboards

**Incident Management**:
- On-call rotation and coverage
- Incident response procedures
- Postmortem process
- Runbook integration
''')
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'Prometheus / Grafana — metrics & alerting',
    'Google SRE — site reliability engineering',
  ],
  'Describes the monitoring, alerting, logging, and observability requirements for the system.',
)
@SectionId('MAAS')
class MonitoringAndAlertingSection {
  @ContentHelp('''
Provide an overview of monitoring and observability strategy.

**Include**:
- Monitoring architecture and tools
- Key SLIs and SLOs
- Alerting philosophy and coverage
- On-call structure and escalation
- Dashboard and visualization approach

**Best Practices**:
- Monitor user-facing metrics (SLIs)
- Set meaningful alert thresholds
- Implement structured logging
- Create actionable runbooks for alerts
- Regular monitoring coverage reviews
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of monitoring strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Monitoring infrastructure requirements.
  @SerializationOrder(2)
  MonitoringInfrastructure infrastructure = MonitoringInfrastructure();

  /// Metrics collection requirements.
  @SerializationOrder(3)
  MetricsCollectionRequirements metricsCollection =
      MetricsCollectionRequirements();

  /// Application performance monitoring.
  @SerializationOrder(4)
  ApplicationPerformanceMonitoring apm = ApplicationPerformanceMonitoring();

  /// Log management requirements.
  @SerializationOrder(5)
  LogManagementRequirements logManagement = LogManagementRequirements();

  /// Alerting requirements.
  @SerializationOrder(6)
  AlertingRequirements alerting = AlertingRequirements();

  /// Alert definitions.
  @StandardReferences(
    ['Prometheus / Grafana — metrics & alerting'],
    'The alert definitions the system applies.',
  )
  @SectionId('ALDEEN-ALER-LST')
  @SectionIdPattern('ALDEEN-ALER-xxx')
  @ContentHelp('Add one entry per alert definition.')
  @SerializationOrder(7)
  List<AlertDefinitionEntry> alertDefinitions = [];

  /// Dashboard requirements.
  @SerializationOrder(8)
  DashboardRequirements dashboards = DashboardRequirements();

  /// On-call procedures.
  @SerializationOrder(9)
  OnCallProcedures onCallProcedures = OnCallProcedures();

  /// Incident management.
  @SerializationOrder(10)
  IncidentManagementRequirements incidentManagement =
      IncidentManagementRequirements();

  /// SLA monitoring.
  @SerializationOrder(11)
  SlaMonitoringRequirements slaMonitoring = SlaMonitoringRequirements();
}

/// Monitoring infrastructure requirements.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'OpenTelemetry — observability / metrics / tracing',
  ],
  'Describes the monitoring infrastructure platform and its metrics, logging, and tracing backends.',
)
@SectionId('MOIN')
class MonitoringInfrastructure {
  @Form([
    Field('monitoringPlatform', String, 'Monitoring Platform',
        hint: 'Datadog, Prometheus, CloudWatch'),
    Field('metricsBackend', String, 'Metrics Backend',
        hint: 'Prometheus, InfluxDB, Graphite'),
    Field('loggingBackend', String, 'Logging Backend',
        hint: 'ELK, Splunk, CloudWatch Logs'),
    Field('tracingBackend', String, 'Tracing Backend',
        hint: 'Jaeger, Zipkin, X-Ray'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Deployment model.
  @SerializationOrder(1)
  MonitoringInfrastructureDeployment deployment =
    MonitoringInfrastructureDeployment();

  /// Collection model.
  @SerializationOrder(2)
  MonitoringInfrastructureCollection collection =
    MonitoringInfrastructureCollection();

  /// Access and privacy controls.
  @SerializationOrder(3)
  MonitoringInfrastructureAccess access = MonitoringInfrastructureAccess();
}

/// Deployment model.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'OpenTelemetry — observability / metrics / tracing',
  ],
  'Describes the monitoring deployment model including hosting, data retention, and HA.',
)
@SectionId('MOINDE')
class MonitoringInfrastructureDeployment {
  @Form([
  Field('monitoringDeployment', String, 'Monitoring Deployment',
    hint: 'SaaS, self-hosted, hybrid'),
  Field('dataRetention', String, 'Data Retention',
    hint: 'Metrics/logs retention period'),
  Field('storageRequirements', String, 'Storage Requirements',
    hint: 'Estimated storage needs'),
  Field('highAvailability', bool, 'High Availability',
    hint: 'Monitoring HA required'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Collection model.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'Prometheus / Grafana — metrics & alerting',
  ],
  'Describes the metrics collection model including frequency and agent-based versus agentless collection.',
)
@SectionId('MOINCO')
class MonitoringInfrastructureCollection {
  @Form([
  Field('collectionFrequency', String, 'Collection Frequency',
    hint: 'Metrics scrape interval'),
  Field('agentBased', bool, 'Agent-Based Collection',
    hint: 'Requires monitoring agents'),
  Field('agentlessCollection', bool, 'Agentless Collection',
    hint: 'Push-based metrics'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access and privacy controls.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes access control, data privacy, and multi-tenant isolation for monitoring.',
)
@SectionId('MOINAC')
class MonitoringInfrastructureAccess {
  @Form([
  Field('accessControl', String, 'Access Control',
    hint: 'Who can access monitoring'),
  Field('dataPrivacy', String, 'Data Privacy',
    hint: 'Sensitive data handling'),
  Field('multiTenant', bool, 'Multi-Tenant',
    hint: 'Tenant isolation in monitoring'),
  Field('notes', String, 'Notes',
    hint: 'Additional infrastructure notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Metrics collection requirements.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'Prometheus / Grafana — metrics & alerting',
  ],
  'Describes metrics collection requirements for CPU, memory, disk, and network.',
)
@SectionId('MECORE')
class MetricsCollectionRequirements {
  @Form([
    Field('cpuMetrics', bool, 'CPU Metrics',
        hint: 'CPU utilization, load'),
    Field('memoryMetrics', bool, 'Memory Metrics',
        hint: 'Memory usage, swap'),
    Field('diskMetrics', bool, 'Disk Metrics',
        hint: 'Disk I/O, space'),
    Field('networkMetrics', bool, 'Network Metrics',
        hint: 'Network I/O, connections'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Container and cluster metrics.
  @SerializationOrder(1)
  MetricsCollectionRequirementsContainer container =
      MetricsCollectionRequirementsContainer();

  /// Application metrics.
  @SerializationOrder(2)
  MetricsCollectionRequirementsApplication application =
      MetricsCollectionRequirementsApplication();

  /// Business metrics.
  @SerializationOrder(3)
  MetricsCollectionRequirementsBusiness business =
      MetricsCollectionRequirementsBusiness();

  /// Custom metrics settings.
  @SerializationOrder(4)
  MetricsCollectionRequirementsCustom custom =
      MetricsCollectionRequirementsCustom();
}

/// Container and cluster metrics.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'Prometheus / Grafana — metrics & alerting',
  ],
  'Describes container, pod, node, and cluster-level metrics to collect.',
)
@SectionId('MCRC')
class MetricsCollectionRequirementsContainer {
  @Form([
    Field('containerMetrics', bool, 'Container Metrics',
        hint: 'Container resource usage'),
    Field('podMetrics', bool, 'Pod Metrics',
        hint: 'Pod status, restarts'),
    Field('nodeMetrics', bool, 'Node Metrics',
        hint: 'Kubernetes node metrics'),
    Field('clusterMetrics', bool, 'Cluster Metrics',
        hint: 'Cluster-level metrics'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Application metrics.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'Google SRE — site reliability engineering',
  ],
  'Describes application metrics such as request rate, error rate, and saturation.',
)
@SectionId('MCRA')
class MetricsCollectionRequirementsApplication {
  @Form([
    Field('requestMetrics', bool, 'Request Metrics',
        hint: 'Request rate, latency'),
    Field('errorMetrics', bool, 'Error Metrics',
        hint: 'Error rates, types'),
    Field('saturationMetrics', bool, 'Saturation Metrics',
        hint: 'Queue depth, utilization'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Business metrics.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'DORA metrics — DevOps performance',
  ],
  'Describes business metrics such as KPIs, user activity, and transaction volume.',
)
@SectionId('MCRB')
class MetricsCollectionRequirementsBusiness {
  @Form([
    Field('businessMetrics', String, 'Business Metrics',
        hint: 'Custom business KPIs'),
    Field('userMetrics', String, 'User Metrics',
        hint: 'Active users, sessions'),
    Field('transactionMetrics', String, 'Transaction Metrics',
        hint: 'Transaction volume, value'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Custom metrics settings.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'Prometheus / Grafana — metrics & alerting',
  ],
  'Describes custom application-specific metrics and their naming conventions.',
)
@SectionId('MECORECU')
class MetricsCollectionRequirementsCustom {
  @Form([
    Field('customMetricsRequired', bool, 'Custom Metrics Required',
        hint: 'Application-specific metrics'),
    Field('metricNamingConvention', String, 'Metric Naming Convention',
        hint: 'Naming standard for metrics'),
    Field('notes', String, 'Notes',
        hint: 'Additional metrics notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Application performance monitoring.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'Prometheus / Grafana — metrics & alerting',
  ],
  'Describes the application performance monitoring platform, instrumentation, and sampling.',
)
@SectionId('APPEMO')
class ApplicationPerformanceMonitoring {
  @Form([
    Field('apmPlatform', String, 'APM Platform',
        hint: 'Datadog APM, New Relic, Dynatrace'),
    Field('instrumentationMethod', String, 'Instrumentation Method',
        hint: 'Auto, manual, hybrid'),
    Field('samplingRate', String, 'Sampling Rate',
        hint: 'Trace sampling percentage'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Tracing settings.
  @SerializationOrder(1)
  ApplicationPerformanceMonitoringTracing tracing =
      ApplicationPerformanceMonitoringTracing();

  /// Profiling settings.
  @SerializationOrder(2)
  ApplicationPerformanceMonitoringProfiling profiling =
      ApplicationPerformanceMonitoringProfiling();

  /// Error tracking settings.
  @SerializationOrder(3)
  ApplicationPerformanceMonitoringErrors errors =
      ApplicationPerformanceMonitoringErrors();

  /// User and synthetic monitoring settings.
  @SerializationOrder(4)
  ApplicationPerformanceMonitoringUserSignals userSignals =
      ApplicationPerformanceMonitoringUserSignals();
}

/// Tracing settings.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'Prometheus / Grafana — metrics & alerting',
  ],
  'Describes distributed tracing settings including trace context, span collection, and retention.',
)
@SectionId('APMT')
class ApplicationPerformanceMonitoringTracing {
  @Form([
    Field('distributedTracing', bool, 'Distributed Tracing',
        hint: 'End-to-end tracing'),
    Field('traceContext', String, 'Trace Context',
        hint: 'W3C, B3, custom'),
    Field('spanCollection', String, 'Span Collection',
        hint: 'What spans to collect'),
    Field('traceRetention', String, 'Trace Retention',
        hint: 'Trace data retention'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Profiling settings.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'Google SRE — site reliability engineering',
  ],
  'Describes continuous CPU and memory profiling settings and acceptable overhead.',
)
@SectionId('APMP')
class ApplicationPerformanceMonitoringProfiling {
  @Form([
    Field('continuousProfiling', bool, 'Continuous Profiling',
        hint: 'Production profiling'),
    Field('cpuProfiling', bool, 'CPU Profiling',
        hint: 'CPU profile collection'),
    Field('memoryProfiling', bool, 'Memory Profiling',
        hint: 'Memory profile collection'),
    Field('profilingOverhead', String, 'Profiling Overhead',
        hint: 'Acceptable overhead'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Error tracking settings.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'Prometheus / Grafana — metrics & alerting',
  ],
  'Describes error tracking settings such as grouping, source mapping, and error context.',
)
@SectionId('APME')
class ApplicationPerformanceMonitoringErrors {
  @Form([
    Field('errorTracking', bool, 'Error Tracking',
        hint: 'Exception collection'),
    Field('errorGrouping', String, 'Error Grouping',
        hint: 'How errors are grouped'),
    Field('sourceMapping', bool, 'Source Mapping',
        hint: 'Stack trace mapping'),
    Field('errorContext', String, 'Error Context',
        hint: 'Context data with errors'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// User and synthetic monitoring settings.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'Google SRE — site reliability engineering',
  ],
  'Describes real-user monitoring and synthetic monitoring settings.',
)
@SectionId('APMUS')
class ApplicationPerformanceMonitoringUserSignals {
  @Form([
    Field('realUserMonitoring', bool, 'Real User Monitoring',
        hint: 'Client-side monitoring'),
    Field('syntheticMonitoring', bool, 'Synthetic Monitoring',
        hint: 'Synthetic transactions'),
    Field('notes', String, 'Notes',
        hint: 'Additional APM notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Log management requirements.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes log management requirements: sources, format, levels, and required fields.',
)
@SectionId('LOMARE')
class LogManagementRequirements {
  @Form([
    Field('logSources', String, 'Log Sources',
        hint: 'Application, system, container'),
    Field('logFormat', String, 'Log Format',
        hint: 'JSON, structured, unstructured'),
    Field('logLevels', String, 'Log Levels',
        hint: 'Debug, Info, Warn, Error'),
    Field('logFields', String, 'Required Log Fields',
        hint: 'timestamp, correlation_id'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Collection method.
  @SerializationOrder(1)
  LogManagementRequirementsCollection collection =
      LogManagementRequirementsCollection();

  /// Storage settings.
  @SerializationOrder(2)
  LogManagementRequirementsStorage storage =
      LogManagementRequirementsStorage();

  /// Search and analysis.
  @SerializationOrder(3)
  LogManagementRequirementsAnalysis analysis =
      LogManagementRequirementsAnalysis();

  /// Compliance settings.
  @SerializationOrder(4)
  LogManagementRequirementsCompliance compliance =
      LogManagementRequirementsCompliance();
}

/// Collection method.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'Prometheus / Grafana — metrics & alerting',
  ],
  'Describes the log collection method, shipping pipeline, and buffering strategy.',
)
@SectionId('LMRC')
class LogManagementRequirementsCollection {
  @Form([
    Field('collectionMethod', String, 'Collection Method',
        hint: 'Sidecar, agent, stdout'),
    Field('logShipping', String, 'Log Shipping',
        hint: 'Fluentd, Filebeat, Vector'),
    Field('bufferingStrategy', String, 'Buffering Strategy',
        hint: 'Memory, disk buffering'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Storage settings.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes log storage settings including retention, cold storage, and compression.',
)
@SectionId('LMRS')
class LogManagementRequirementsStorage {
  @Form([
    Field('logRetention', String, 'Log Retention',
        hint: 'Retention period by type'),
    Field('coldStorage', String, 'Cold Storage',
        hint: 'Archive strategy'),
    Field('compressionEnabled', bool, 'Compression Enabled',
        hint: 'Log compression'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Search and analysis.
@StandardReferences(
  [
    'OpenTelemetry — observability / metrics / tracing',
    'Prometheus / Grafana — metrics & alerting',
  ],
  'Describes log search, analytics, and anomaly detection capabilities.',
)
@SectionId('LMRA')
class LogManagementRequirementsAnalysis {
  @Form([
    Field('fullTextSearch', bool, 'Full-Text Search',
        hint: 'Log search capability'),
    Field('logAnalytics', String, 'Log Analytics',
        hint: 'Analysis capabilities'),
    Field('anomalyDetection', bool, 'Anomaly Detection',
        hint: 'ML-based detection'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance settings.
@StandardReferences(
  [
    'ISO/IEC 20000 — IT service management system',
    'OpenTelemetry — observability / metrics / tracing',
  ],
  'Describes logging compliance controls such as PII handling, audit logs, and immutability.',
)
@SectionId('LOMARECO')
class LogManagementRequirementsCompliance {
  @Form([
    Field('piiHandling', String, 'PII Handling',
        hint: 'Sensitive data masking'),
    Field('auditLogs', bool, 'Audit Logs',
        hint: 'Separate audit logging'),
    Field('logImmutability', bool, 'Log Immutability',
        hint: 'Tamper-proof logs'),
    Field('notes', String, 'Notes',
        hint: 'Additional logging notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Alerting requirements.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'ITIL 4 — IT service management',
  ],
  'Describes alerting requirements including channels, routing, and response automation.',
)
@SectionId('ALRE')
class AlertingRequirements {
  @Form([
    Field('alertChannels', String, 'Alert Channels',
        hint: 'Email, Slack, PagerDuty'),
    Field('primaryChannel', String, 'Primary Channel',
        hint: 'Primary alert channel'),
    Field('secondaryChannel', String, 'Secondary Channel',
        hint: 'Fallback channel'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Routing rules.
  @SerializationOrder(1)
  AlertingRequirementsRouting routing = AlertingRequirementsRouting();

  /// De-duplication behavior.
  @SerializationOrder(2)
  AlertingRequirementsDeduplication deduplication =
      AlertingRequirementsDeduplication();

  /// Suppression rules.
  @SerializationOrder(3)
  AlertingRequirementsSuppression suppression =
      AlertingRequirementsSuppression();

  /// Response automation.
  @SerializationOrder(4)
  AlertingRequirementsResponse response = AlertingRequirementsResponse();
}

/// Routing rules.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'ITIL 4 — IT service management',
  ],
  'Describes how alerts are routed by team, service, and severity.',
)
@SectionId('ALRERO')
class AlertingRequirementsRouting {
  @Form([
    Field('routingRules', String, 'Routing Rules',
        hint: 'How alerts are routed'),
    Field('teamRouting', String, 'Team Routing',
        hint: 'Team-based routing'),
    Field('serviceRouting', String, 'Service Routing',
        hint: 'Service-based routing'),
    Field('severityRouting', String, 'Severity Routing',
        hint: 'Severity-based routing'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// De-duplication behavior.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'Google SRE — site reliability engineering',
  ],
  'Describes alert de-duplication, grouping, and flapping detection to reduce noise.',
)
@SectionId('ALREDE')
class AlertingRequirementsDeduplication {
  @Form([
    Field('alertDeduplication', String, 'Alert De-duplication',
        hint: 'De-dup strategy'),
    Field('alertGrouping', String, 'Alert Grouping',
        hint: 'Related alert grouping'),
    Field('flappingDetection', bool, 'Flapping Detection',
        hint: 'Detect flapping alerts'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Suppression rules.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'ITIL 4 — IT service management',
  ],
  'Describes alert suppression via maintenance windows, dependency-based rules, and manual overrides.',
)
@SectionId('ALRESU')
class AlertingRequirementsSuppression {
  @Form([
    Field('maintenanceWindows', String, 'Maintenance Windows',
        hint: 'Scheduled suppression'),
    Field('dependencyAlerts', String, 'Dependency Alerts',
        hint: 'Dependency-based suppression'),
    Field('manualSuppression', bool, 'Manual Suppression',
        hint: 'Allow manual suppression'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Response automation.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'Google SRE — site reliability engineering',
  ],
  'Describes alert response automation such as auto-remediation, runbook links, and acknowledgment.',
)
@SectionId('ALRERE')
class AlertingRequirementsResponse {
  @Form([
    Field('autoRemediation', bool, 'Auto-Remediation',
        hint: 'Automatic remediation'),
    Field('runbookLinks', bool, 'Runbook Links',
        hint: 'Link alerts to runbooks'),
    Field('acknowledgeRequired', bool, 'Acknowledge Required',
        hint: 'Require acknowledgment'),
    Field('notes', String, 'Notes',
        hint: 'Additional alerting notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Alert definition entry.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'OpenTelemetry — observability / metrics / tracing',
  ],
  'Describes a single alert definition including its name, severity, and priority.',
)
@SectionId('ALEDEFENT')
class AlertDefinitionEntry {
  @Form([
    Field('alertName', String, 'Alert Name',
        required: true, hint: 'Alert identifier'),
    Field('alertDescription', String, 'Alert Description',
        hint: 'What this alert means'),
    Field('severity', String, 'Severity',
        hint: 'Critical, Warning, Info'),
    Field('priority', String, 'Priority',
        hint: 'P1, P2, P3, P4, P5'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Trigger conditions.
  @SerializationOrder(1)
  AlertDefinitionEntryCondition condition = AlertDefinitionEntryCondition();

  /// Recovery conditions.
  @SerializationOrder(2)
  AlertDefinitionEntryRecovery recovery = AlertDefinitionEntryRecovery();

  /// Notification details.
  @SerializationOrder(3)
  AlertDefinitionEntryNotification notification =
      AlertDefinitionEntryNotification();
}

/// Trigger conditions.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'OpenTelemetry — observability / metrics / tracing',
  ],
  'Describes alert trigger conditions: metric, comparison, threshold, and evaluation window.',
)
@SectionId('ADEC')
class AlertDefinitionEntryCondition {
  @Form([
    Field('metricName', String, 'Metric Name',
        hint: 'Metric to monitor'),
    Field('condition', String, 'Condition',
        hint: '>, <, ==, etc.'),
    Field('threshold', String, 'Threshold',
        hint: 'Alert threshold value'),
    Field('duration', String, 'Duration',
        hint: 'How long before alerting'),
    Field('evaluationPeriod', String, 'Evaluation Period',
        hint: 'Evaluation window'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Recovery conditions.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'OpenTelemetry — observability / metrics / tracing',
  ],
  'Describes recovery thresholds, recovery duration, and auto-resolve behavior for alerts.',
)
@SectionId('ADER')
class AlertDefinitionEntryRecovery {
  @Form([
    Field('recoveryThreshold', String, 'Recovery Threshold',
        hint: 'When alert resolves'),
    Field('recoveryDuration', String, 'Recovery Duration',
        hint: 'Time before resolving'),
    Field('autoResolve', bool, 'Auto-Resolve',
        hint: 'Auto-resolve enabled'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Notification details.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'ITIL 4 — IT service management',
  ],
  'Describes alert notification channel, escalation policy, and runbook linkage.',
)
@SectionId('ADEN')
class AlertDefinitionEntryNotification {
  @Form([
    Field('notificationChannel', String, 'Notification Channel',
        hint: 'Where to send alert'),
    Field('escalationPolicy', String, 'Escalation Policy',
        hint: 'Escalation if not acked'),
    Field('runbookUrl', String, 'Runbook URL',
        hint: 'Link to runbook'),
    Field('notes', String, 'Notes',
        hint: 'Additional alert notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dashboard requirements.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'OpenTelemetry — observability / metrics / tracing',
  ],
  'Describes the dashboard platform, dashboards-as-code approach, and storage location.',
)
@SectionId('DARE')
class DashboardRequirements {
  @Form([
    Field('dashboardPlatform', String, 'Dashboard Platform',
        hint: 'Grafana, Datadog, custom'),
    Field('dashboardAsCode', bool, 'Dashboards as Code',
        hint: 'Version-controlled dashboards'),
    Field('dashboardLocation', String, 'Dashboard Location',
        hint: 'Where dashboards are stored'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Standard dashboards.
  @SerializationOrder(1)
  DashboardRequirementsStandard standard = DashboardRequirementsStandard();

  /// Access controls.
  @SerializationOrder(2)
  DashboardRequirementsAccess access = DashboardRequirementsAccess();

  /// Feature requirements.
  @SerializationOrder(3)
  DashboardRequirementsFeatures features = DashboardRequirementsFeatures();

  /// Mobile support and notes.
  @SerializationOrder(4)
  DashboardRequirementsMobile mobile = DashboardRequirementsMobile();
}

/// Standard dashboards.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'OpenTelemetry — observability / metrics / tracing',
  ],
  'Describes the standard set of dashboards for system, service, infrastructure, and business views.',
)
@SectionId('DAREST')
class DashboardRequirementsStandard {
  @Form([
    Field('systemOverview', bool, 'System Overview Dashboard',
        hint: 'High-level system health'),
    Field('serviceDashboards', bool, 'Service Dashboards',
        hint: 'Per-service dashboards'),
    Field('infrastructureDashboard', bool, 'Infrastructure Dashboard',
        hint: 'Infra-level dashboard'),
    Field('businessDashboard', bool, 'Business Dashboard',
        hint: 'Business metrics dashboard'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access controls.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'ITIL 4 — IT service management',
  ],
  'Describes access controls for public, internal, and edit permissions on dashboards.',
)
@SectionId('DAREAC')
class DashboardRequirementsAccess {
  @Form([
    Field('publicDashboards', String, 'Public Dashboards',
        hint: 'Status page dashboards'),
    Field('internalDashboards', String, 'Internal Dashboards',
        hint: 'Internal-only dashboards'),
    Field('accessControl', String, 'Dashboard Access Control',
        hint: 'Who can view/edit'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Feature requirements.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'OpenTelemetry — observability / metrics / tracing',
  ],
  'Describes dashboard features such as drill-down, annotations, templating, and alert integration.',
)
@SectionId('DAREFE')
class DashboardRequirementsFeatures {
  @Form([
    Field('drillDown', bool, 'Drill-Down Capability',
        hint: 'Navigate to details'),
    Field('annotations', bool, 'Annotations',
        hint: 'Deployment markers'),
    Field('templating', bool, 'Templating',
        hint: 'Variable-based filtering'),
    Field('alertIntegration', bool, 'Alert Integration',
        hint: 'Show alerts on dashboard'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Mobile support and notes.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'OpenTelemetry — observability / metrics / tracing',
  ],
  'Describes mobile access to dashboards and additional dashboard notes.',
)
@SectionId('DAREMO')
class DashboardRequirementsMobile {
  @Form([
    Field('mobileAccess', bool, 'Mobile Access',
        hint: 'Mobile-friendly dashboards'),
    Field('notes', String, 'Notes',
        hint: 'Additional dashboard notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// On-call procedures.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'ITIL 4 — IT service management',
    'Google SRE — site reliability engineering',
  ],
  'Describes on-call tooling, rotation, coverage, and escalation procedures.',
)
@SectionId('ONCAPR')
class OnCallProcedures {
  @Form([
    Field('onCallTool', String, 'On-Call Tool',
        hint: 'PagerDuty, OpsGenie, VictorOps'),
    Field('rotationSchedule', String, 'Rotation Schedule',
        hint: 'Weekly, daily rotation'),
    Field('coverageHours', String, 'Coverage Hours',
        hint: '24/7, business hours'),
    Field('primarySecondary', bool, 'Primary/Secondary',
        hint: 'Primary and backup on-call'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Team coverage.
  @SerializationOrder(1)
  OnCallProceduresTeams teams = OnCallProceduresTeams();

  /// Response SLAs.
  @SerializationOrder(2)
  OnCallProceduresSlas slas = OnCallProceduresSlas();

  /// Escalation rules.
  @SerializationOrder(3)
  OnCallProceduresEscalation escalation = OnCallProceduresEscalation();

  /// Documentation requirements.
  @SerializationOrder(4)
  OnCallProceduresDocumentation documentation =
      OnCallProceduresDocumentation();
}

/// Team coverage.
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'Google SRE — site reliability engineering',
  ],
  'Describes which teams participate in on-call and how escalation flows between them.',
)
@SectionId('OCPT')
class OnCallProceduresTeams {
  @Form([
    Field('onCallTeams', String, 'On-Call Teams',
        hint: 'Which teams participate'),
    Field('crossTeamEscalation', String, 'Cross-Team Escalation',
        hint: 'Escalation between teams'),
    Field('managementEscalation', String, 'Management Escalation',
        hint: 'When to involve management'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Response SLAs.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'ITIL 4 — IT service management',
  ],
  'Describes on-call response SLAs for acknowledgment, response, and resolution.',
)
@SectionId('OCPS')
class OnCallProceduresSlas {
  @Form([
    Field('ackSla', String, 'Acknowledgment SLA',
        hint: 'Time to acknowledge'),
    Field('responseSla', String, 'Response SLA',
        hint: 'Time to start response'),
    Field('resolutionSla', String, 'Resolution SLA',
        hint: 'Time to resolve'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Escalation rules.
@StandardReferences(
  [
    'Prometheus / Grafana — metrics & alerting',
    'ITIL 4 — IT service management',
  ],
  'Describes on-call escalation timeouts, escalation path, and executive escalation.',
)
@SectionId('OCPE')
class OnCallProceduresEscalation {
  @Form([
    Field('escalationTimeout', String, 'Escalation Timeout',
        hint: 'When to escalate'),
    Field('escalationPath', String, 'Escalation Path',
        hint: 'Escalation chain'),
    Field('executiveEscalation', String, 'Executive Escalation',
        hint: 'When to involve executives'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation requirements.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'ITIL 4 — IT service management',
  ],
  'Describes on-call documentation such as runbooks, incident and communication templates.',
)
@SectionId('OCPD')
class OnCallProceduresDocumentation {
  @Form([
    Field('runbooks', String, 'Runbooks',
        hint: 'Where runbooks are stored'),
    Field('incidentTemplates', String, 'Incident Templates',
        hint: 'Incident response templates'),
    Field('communicationTemplates', String, 'Communication Templates',
        hint: 'Stakeholder comm templates'),
    Field('notes', String, 'Notes',
        hint: 'Additional on-call notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Incident management requirements.
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'ISO/IEC 20000 — IT service management system',
    'Google SRE — site reliability engineering',
  ],
  'Describes the incident management process, severity definitions, and commander role.',
)
@SectionId('INMARE')
class IncidentManagementRequirements {
  @Form([
    Field('incidentProcess', String, 'Incident Process',
        hint: 'Incident management process'),
    Field('severityDefinitions', String, 'Severity Definitions',
        hint: 'SEV1, SEV2, SEV3 definitions'),
    Field('incidentCommander', String, 'Incident Commander',
        hint: 'IC role and selection'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Communication requirements.
  @SerializationOrder(1)
  IncidentManagementRequirementsCommunication communication =
      IncidentManagementRequirementsCommunication();

  /// War room setup.
  @SerializationOrder(2)
  IncidentManagementRequirementsWarRoom warRoom =
      IncidentManagementRequirementsWarRoom();

  /// Post-incident expectations.
  @SerializationOrder(3)
  IncidentManagementRequirementsPostIncident postIncident =
      IncidentManagementRequirementsPostIncident();

  /// Metrics and notes.
  @SerializationOrder(4)
  IncidentManagementRequirementsMetrics metrics =
      IncidentManagementRequirementsMetrics();
}

/// Communication requirements.
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes internal, external, and status-page communication during incidents.',
)
@SectionId('IMRC')
class IncidentManagementRequirementsCommunication {
  @Form([
    Field('internalComms', String, 'Internal Communications',
        hint: 'Internal status updates'),
    Field('externalComms', String, 'External Communications',
        hint: 'Customer communication'),
    Field('statusPageUpdates', String, 'Status Page Updates',
        hint: 'Status page process'),
    Field('stakeholderNotification', String, 'Stakeholder Notification',
        hint: 'Who gets notified'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// War room setup.
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'Google SRE — site reliability engineering',
  ],
  'Describes the incident war room, bridge call, and chat channel setup.',
)
@SectionId('IMRWR')
class IncidentManagementRequirementsWarRoom {
  @Form([
    Field('warRoomSetup', String, 'War Room Setup',
        hint: 'Incident war room'),
    Field('bridgeCall', String, 'Bridge Call',
        hint: 'Conference bridge'),
    Field('chatChannel', String, 'Chat Channel',
        hint: 'Incident chat channel'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Post-incident expectations.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'ITIL 4 — IT service management',
  ],
  'Describes post-incident expectations including blameless post-mortems and action item tracking.',
)
@SectionId('IMRPI')
class IncidentManagementRequirementsPostIncident {
  @Form([
    Field('postMortemRequired', bool, 'Post-Mortem Required',
        hint: 'Require post-mortems'),
    Field('postMortemTimeline', String, 'Post-Mortem Timeline',
        hint: 'When post-mortem due'),
    Field('blamelessCulture', bool, 'Blameless Culture',
        hint: 'Blameless post-mortems'),
    Field('actionItemTracking', String, 'Action Item Tracking',
        hint: 'Track remediation items'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Metrics and notes.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'DORA metrics — DevOps performance',
  ],
  'Describes incident metrics such as MTTR and MTBF targets.',
)
@SectionId('IMRM')
class IncidentManagementRequirementsMetrics {
  @Form([
    Field('mttr', String, 'MTTR Target',
        hint: 'Mean time to repair target'),
    Field('mtbf', String, 'MTBF Target',
        hint: 'Mean time between failures'),
    Field('notes', String, 'Notes',
        hint: 'Additional incident notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// SLA monitoring requirements.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'ITIL 4 — IT service management',
  ],
  'Describes SLA monitoring for availability, performance, and error rate targets.',
)
@SectionId('SLMORE')
class SlaMonitoringRequirements {
  @Form([
    Field('availabilitySla', String, 'Availability SLA',
        hint: '99.9%, 99.99%'),
    Field('performanceSla', String, 'Performance SLA',
        hint: 'Latency SLA'),
    Field('errorRateSla', String, 'Error Rate SLA',
        hint: 'Maximum error rate'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Monitoring mechanics.
  @SerializationOrder(1)
  SlaMonitoringRequirementsMonitoring monitoring =
      SlaMonitoringRequirementsMonitoring();

  /// Error-budget policy.
  @SerializationOrder(2)
  SlaMonitoringRequirementsErrorBudget errorBudget =
      SlaMonitoringRequirementsErrorBudget();

  /// Customer-specific SLA rules.
  @SerializationOrder(3)
  SlaMonitoringRequirementsCustomer customer =
      SlaMonitoringRequirementsCustomer();

  /// Reporting and review.
  @SerializationOrder(4)
  SlaMonitoringRequirementsReporting reporting =
      SlaMonitoringRequirementsReporting();
}

/// Monitoring mechanics.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'Prometheus / Grafana — metrics & alerting',
  ],
  'Describes how SLAs are tracked, reported, and how breaches and burn rate are alerted.',
)
@SectionId('SLMOREMO')
class SlaMonitoringRequirementsMonitoring {
  @Form([
    Field('slaTracking', String, 'SLA Tracking',
        hint: 'How SLAs are tracked'),
    Field('slaReporting', String, 'SLA Reporting',
        hint: 'SLA report frequency'),
    Field('slaBreachAlerts', bool, 'SLA Breach Alerts',
        hint: 'Alert on SLA breach'),
    Field('slaBurnRate', bool, 'SLA Burn Rate',
        hint: 'Track error budget burn'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Error-budget policy.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'DORA metrics — DevOps performance',
  ],
  'Describes the error-budget policy, exhaustion action, and reset period.',
)
@SectionId('SMREB')
class SlaMonitoringRequirementsErrorBudget {
  @Form([
    Field('errorBudgetPolicy', String, 'Error Budget Policy',
        hint: 'Error budget handling'),
    Field('budgetExhaustionAction', String, 'Budget Exhaustion Action',
        hint: 'Action when budget spent'),
    Field('budgetResetPeriod', String, 'Budget Reset Period',
        hint: 'Monthly, quarterly reset'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Customer-specific SLA rules.
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes customer-specific SLA tiers, exclusions, and credit policy.',
)
@SectionId('SLMORECU')
class SlaMonitoringRequirementsCustomer {
  @Form([
    Field('customerSlaTiers', String, 'Customer SLA Tiers',
        hint: 'Different SLA tiers'),
    Field('slaExclusions', String, 'SLA Exclusions',
        hint: 'What is excluded'),
    Field('slaCredits', String, 'SLA Credits',
        hint: 'Credit policy for misses'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reporting and review.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'ITIL 4 — IT service management',
  ],
  'Describes SLA reporting recipients, review cadence, and related notes.',
)
@SectionId('SLMORERE')
class SlaMonitoringRequirementsReporting {
  @Form([
    Field('slaReportRecipients', String, 'SLA Report Recipients',
        hint: 'Who receives reports'),
    Field('slaReviewMeetings', String, 'SLA Review Meetings',
        hint: 'SLA review cadence'),
    Field('notes', String, 'Notes', hint: 'Additional SLA notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// =============================================================================
// 8.5.4. Maintenance Windows
// =============================================================================

/// 8.5.4. Maintenance Windows.
///
/// Maintenance window requirements: frequency, duration, notification period,
/// and impact on users.
@ContentHelp('''
Specify maintenance window requirements including scheduling, duration,
communication, and change management. Planned maintenance minimizes
disruption while enabling necessary system updates.

**Maintenance Categories**:
- **Routine**: Regular patching, updates, housekeeping
- **Scheduled**: Planned changes requiring downtime
- **Emergency**: Unplanned urgent changes (security patches)
- **Zero-Downtime**: Changes without user impact

**Maintenance Window Scheduling**:
- Preferred days and times (low-traffic periods)
- Maximum frequency (weekly, monthly, quarterly)
- Maximum duration limits
- Blackout periods (year-end, high-traffic events)

**User Communication**:
- Notification lead time (24h, 72h, 1 week)
- Communication channels (email, in-app, status page)
- Status page updates during maintenance
- Post-maintenance notification

**Change Management**:
- Change approval process
- Risk assessment for changes
- Rollback criteria and procedures
- Post-change validation

**Zero-Downtime Strategies**:
- Blue-green deployment
- Rolling updates
- Database migration strategies
- Feature flags for gradual rollout
''')
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes the maintenance window requirements for the system, including scheduling, communication, and change management.',
)
@SectionId('MWS')
class MaintenanceWindowsSection {
  @ContentHelp('''
Provide an overview of maintenance strategy and policies.

**Include**:
- Maintenance window schedule and policy
- Communication and notification plan
- Change management process
- Zero-downtime goals and approach
- Emergency maintenance procedures

**Best Practices**:
- Minimize maintenance windows through automation
- Test changes in staging first
- Have rollback plan for every change
- Communicate early and often
- Track maintenance metrics and trends
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of maintenance strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Scheduled maintenance policies.
  @SerializationOrder(2)
  ScheduledMaintenancePolicy scheduledMaintenance =
      ScheduledMaintenancePolicy();

  /// Maintenance window definitions.
  @StandardReferences(
    ['ITIL 4 — change management'],
    'The maintenance windows the system schedules.',
  )
  @SectionId('MAWIEN-MAIN-LST')
  @SectionIdPattern('MAWIEN-MAIN-xxx')
  @ContentHelp('Add one entry per maintenance window.')
  @SerializationOrder(3)
  List<MaintenanceWindowEntry> maintenanceWindows = [];

  /// Emergency maintenance procedures.
  @SerializationOrder(4)
  EmergencyMaintenanceProcedures emergencyMaintenance =
      EmergencyMaintenanceProcedures();

  /// Change management for maintenance.
  @SerializationOrder(5)
  MaintenanceChangeManagement changeManagement =
      MaintenanceChangeManagement();

  /// User impact and communication.
  @SerializationOrder(6)
  MaintenanceUserImpact userImpact = MaintenanceUserImpact();

  /// Post-maintenance validation.
  @SerializationOrder(7)
  PostMaintenanceValidation postMaintenance = PostMaintenanceValidation();
}

/// Scheduled maintenance policy.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Defines the overall policy governing scheduled maintenance, including its scheduling, duration, notice, and approval.',
)
@SectionId('SCMAPO')
class ScheduledMaintenancePolicy {
  @Form([
    Field('maintenancePolicy', String, 'Maintenance Policy',
        hint: 'Overall maintenance approach'),
    Field('zeroDowntimeGoal', bool, 'Zero-Downtime Goal',
        hint: 'Strive for zero downtime'),
    Field('maintenanceAgreement', String, 'Maintenance Agreement',
        hint: 'SLA for maintenance windows'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Scheduling preferences.
  @SerializationOrder(1)
  ScheduledMaintenancePolicyScheduling scheduling =
      ScheduledMaintenancePolicyScheduling();

  /// Duration constraints.
  @SerializationOrder(2)
  ScheduledMaintenancePolicyDuration duration =
      ScheduledMaintenancePolicyDuration();

  /// Notice requirements.
  @SerializationOrder(3)
  ScheduledMaintenancePolicyNotice notice = ScheduledMaintenancePolicyNotice();

  /// Approval requirements.
  @SerializationOrder(4)
  ScheduledMaintenancePolicyApproval approval =
      ScheduledMaintenancePolicyApproval();
}

/// Scheduling preferences.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Defines the preferred days, times, frequency, and blackout periods for scheduled maintenance.',
)
@SectionId('SMPS')
class ScheduledMaintenancePolicyScheduling {
  @Form([
    Field('preferredDay', String, 'Preferred Day',
        hint: 'Preferred day of week'),
    Field('preferredTime', String, 'Preferred Time',
        hint: 'Preferred start time'),
    Field('timezone', String, 'Timezone',
        hint: 'Maintenance timezone'),
    Field('maxFrequency', String, 'Maximum Frequency',
        hint: 'Max maintenance per month'),
    Field('blackoutPeriods', String, 'Blackout Periods',
        hint: 'When maintenance is forbidden'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Duration constraints.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Defines the maximum and typical duration constraints for scheduled maintenance windows.',
)
@SectionId('SMPD')
class ScheduledMaintenancePolicyDuration {
  @Form([
    Field('maxDuration', String, 'Maximum Duration',
        hint: 'Max window duration'),
    Field('typicalDuration', String, 'Typical Duration',
        hint: 'Typical window length'),
    Field('extensionPolicy', String, 'Extension Policy',
        hint: 'How to extend if needed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Notice requirements.
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Defines the advance notice periods and channels for scheduled maintenance.',
)
@SectionId('SMPN')
class ScheduledMaintenancePolicyNotice {
  @Form([
    Field('standardNotice', String, 'Standard Notice Period',
        hint: 'Days advance notice'),
    Field('minimumNotice', String, 'Minimum Notice Period',
        hint: 'Minimum advance notice'),
    Field('noticeChannels', String, 'Notice Channels',
        hint: 'How users are notified'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Approval requirements.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Defines who must approve scheduled maintenance and the approval requirements.',
)
@SectionId('SMPA')
class ScheduledMaintenancePolicyApproval {
  @Form([
    Field('approvalRequired', bool, 'Approval Required',
        hint: 'Requires approval'),
    Field('approvalAuthority', String, 'Approval Authority',
        hint: 'Who approves maintenance'),
    Field('notes', String, 'Notes',
        hint: 'Additional policy notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Maintenance window entry.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Defines a single scheduled maintenance window with its schedule, scope, impact, and rollback.',
)
@SectionId('MWE')
class MaintenanceWindowEntry {
  @Form([
    Field('windowName', String, 'Window Name',
        required: true, hint: 'Maintenance window name'),
    Field('windowType', String, 'Window Type',
        hint: 'Routine, Patch, Upgrade, Migration'),
    Field('priority', String, 'Priority',
        hint: 'Critical, Standard, Low'),
    Field('description', String, 'Description',
        hint: 'What maintenance is performed'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Schedule details.
  @SerializationOrder(1)
  MaintenanceWindowEntrySchedule schedule = MaintenanceWindowEntrySchedule();

  /// Scope details.
  @SerializationOrder(2)
  MaintenanceWindowEntryScope scope = MaintenanceWindowEntryScope();

  /// Impact details.
  @SerializationOrder(3)
  MaintenanceWindowEntryImpact impact = MaintenanceWindowEntryImpact();

  /// Rollback details.
  @SerializationOrder(4)
  MaintenanceWindowEntryRollback rollback = MaintenanceWindowEntryRollback();
}

/// Schedule details.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes the frequency, timing, and duration of a maintenance window.',
)
@SectionId('MWES')
class MaintenanceWindowEntrySchedule {
  @Form([
    Field('frequency', String, 'Frequency',
        hint: 'Weekly, Monthly, Quarterly'),
    Field('dayOfWeek', String, 'Day of Week',
        hint: 'When this window occurs'),
    Field('startTime', String, 'Start Time',
        hint: 'Window start time'),
    Field('endTime', String, 'End Time',
        hint: 'Window end time'),
    Field('duration', String, 'Duration',
        hint: 'Expected duration'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scope details.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes the systems, services, and regions in scope for a maintenance window.',
)
@SectionId('MAWIENSC')
class MaintenanceWindowEntryScope {
  @Form([
    Field('affectedSystems', String, 'Affected Systems',
        hint: 'Which systems are affected'),
    Field('affectedServices', String, 'Affected Services',
        hint: 'Which services impacted'),
    Field('affectedRegions', String, 'Affected Regions',
        hint: 'Geographic scope'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Impact details.
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes the user and service impact of a maintenance window.',
)
@SectionId('MWEI')
class MaintenanceWindowEntryImpact {
  @Form([
    Field('userImpact', String, 'User Impact',
        hint: 'How users are affected'),
    Field('serviceAvailability', String, 'Service Availability',
        hint: 'Fully down, degraded, partial'),
    Field('dataAvailability', String, 'Data Availability',
        hint: 'Data access during window'),
    Field('workarounds', String, 'Workarounds',
        hint: 'Workarounds during maintenance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Rollback details.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'ITIL 4 — change management',
  ],
  'Describes the rollback plan and decision point for a maintenance window.',
)
@SectionId('MWER')
class MaintenanceWindowEntryRollback {
  @Form([
    Field('rollbackPlan', String, 'Rollback Plan',
        hint: 'How to roll back if needed'),
    Field('rollbackDecisionPoint', String, 'Rollback Decision Point',
        hint: 'When to decide on rollback'),
    Field('notes', String, 'Notes',
        hint: 'Additional window notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Emergency maintenance procedures.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
  ],
  'Defines the procedures for unplanned emergency maintenance such as urgent security patches.',
)
@SectionId('EMMAPR')
class EmergencyMaintenanceProcedures {
  @Form([
    Field('emergencyTriggers', String, 'Emergency Triggers',
        hint: 'What triggers emergency maintenance'),
    Field('securityPatchPolicy', String, 'Security Patch Policy',
        hint: 'Critical security patch handling'),
    Field('severityThresholds', String, 'Severity Thresholds',
        hint: 'What severity warrants emergency'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Approval and documentation workflow.
  @SerializationOrder(1)
  EmergencyMaintenanceProceduresGovernance governance =
    EmergencyMaintenanceProceduresGovernance();

  /// Notification and stakeholder handling.
  @SerializationOrder(2)
  EmergencyMaintenanceProceduresCommunication communication =
    EmergencyMaintenanceProceduresCommunication();

  /// Execution and follow-up details.
  @SerializationOrder(3)
  EmergencyMaintenanceProceduresExecution execution =
    EmergencyMaintenanceProceduresExecution();
}

/// Approval and documentation workflow for emergency maintenance.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Defines the approval and documentation workflow for emergency maintenance work.',
)
@SectionId('EMPG')
class EmergencyMaintenanceProceduresGovernance {
  @Form([
  Field('emergencyApproval', String, 'Emergency Approval',
    hint: 'Who approves emergency work'),
  Field('delegationOfAuthority', String, 'Delegation of Authority',
    hint: 'Backup approvers'),
  Field('documentationRequired', String, 'Documentation Required',
    hint: 'Post-hoc documentation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Notification and stakeholder handling for emergency maintenance.
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes how stakeholders are notified when emergency maintenance is required.',
)
@SectionId('EMPC')
class EmergencyMaintenanceProceduresCommunication {
  @Form([
  Field('emergencyNotice', String, 'Emergency Notice',
    hint: 'Minimum notice for emergency'),
  Field('notificationChannels', String, 'Notification Channels',
    hint: 'Emergency notification channels'),
  Field('stakeholderEscalation', String, 'Stakeholder Escalation',
    hint: 'How stakeholders are informed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Execution and follow-up details for emergency maintenance.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'ITIL 4 — change management',
  ],
  'Describes how emergency maintenance is executed and reviewed afterward.',
)
@SectionId('EMPE')
class EmergencyMaintenanceProceduresExecution {
  @Form([
  Field('teamAssembly', String, 'Team Assembly',
    hint: 'How response team assembles'),
  Field('maxEmergencyDuration', String, 'Max Emergency Duration',
    hint: 'Maximum emergency window'),
  Field('postEmergencyReview', bool, 'Post-Emergency Review',
    hint: 'Mandatory review after'),
  Field('notes', String, 'Notes',
    hint: 'Additional emergency notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Change management for maintenance.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Defines the change management process governing maintenance changes.',
)
@SectionId('MACHMA')
class MaintenanceChangeManagement {
  @Form([
    // Change process
    Field('changeProcess', String, 'Change Process',
        hint: 'ITIL, custom change process'),
    Field('changeCategories', String, 'Change Categories',
        hint: 'Standard, Normal, Emergency'),
    Field('changeBoard', String, 'Change Advisory Board',
        hint: 'CAB composition'),
  ])
  @SerializationOrder(0)
  String? content;

  /// CAB cadence and documentation prerequisites.
  @SerializationOrder(1)
  MaintenanceChangeManagementGovernance governance =
    MaintenanceChangeManagementGovernance();

  /// Required assessments and rollback planning.
  @SerializationOrder(2)
  MaintenanceChangeManagementDocumentation documentation =
    MaintenanceChangeManagementDocumentation();

  /// Testing and sign-off requirements.
  @SerializationOrder(3)
  MaintenanceChangeManagementTesting testing =
    MaintenanceChangeManagementTesting();

  /// Logging and audit trail expectations.
  @SerializationOrder(4)
  MaintenanceChangeManagementAudit audit = MaintenanceChangeManagementAudit();
}

/// CAB cadence and documentation prerequisites.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Defines the change advisory board cadence and governance prerequisites for maintenance changes.',
)
@SectionId('MCMG')
class MaintenanceChangeManagementGovernance {
  @Form([
  Field('changeBoardSchedule', String, 'CAB Schedule',
    hint: 'When CAB meets'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Required assessments and rollback planning.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Defines the impact/risk assessments and rollback plans required to document a maintenance change.',
)
@SectionId('MCMD')
class MaintenanceChangeManagementDocumentation {
  @Form([
  Field('changeRequestRequired', bool, 'Change Request Required',
    hint: 'CR needed for maintenance'),
  Field('impactAssessment', bool, 'Impact Assessment Required',
    hint: 'Assess impact before change'),
  Field('riskAssessment', bool, 'Risk Assessment Required',
    hint: 'Assess risk before change'),
  Field('rollbackPlanRequired', bool, 'Rollback Plan Required',
    hint: 'Rollback plan mandatory'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing and sign-off requirements.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Defines the testing and sign-off required before a maintenance change proceeds.',
)
@SectionId('MCMT')
class MaintenanceChangeManagementTesting {
  @Form([
  Field('preProdTesting', bool, 'Pre-Production Testing',
    hint: 'Test in staging first'),
  Field('testPlanRequired', bool, 'Test Plan Required',
    hint: 'Test plan mandatory'),
  Field('signOffRequired', bool, 'Sign-Off Required',
    hint: 'Post-test sign-off'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Logging and audit trail expectations.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Defines the change logging and audit trail kept for maintenance changes.',
)
@SectionId('MCMA')
class MaintenanceChangeManagementAudit {
  @Form([
  Field('changeLogging', bool, 'Change Logging',
    hint: 'Log all changes'),
  Field('changeHistory', String, 'Change History',
    hint: 'Where changes are tracked'),
  Field('notes', String, 'Notes',
    hint: 'Additional change management notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// User impact and communication.
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes how maintenance affects users and how it is communicated to them.',
)
@SectionId('MAUSIM')
class MaintenanceUserImpact {
  @Form([
    Field('advanceNotification', String, 'Advance Notification',
        hint: 'How users are notified in advance'),
    Field('inAppNotification', bool, 'In-App Notification',
        hint: 'Banner or popup in app'),
    Field('emailNotification', bool, 'Email Notification',
        hint: 'Email users before maintenance'),
    Field('statusPageUpdate', bool, 'Status Page Update',
        hint: 'Update status page'),
    Field('socialMediaNotice', bool, 'Social Media Notice',
        hint: 'Post on social media'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Communication during maintenance.
  @SerializationOrder(1)
  MaintenanceUserImpactDuring during = MaintenanceUserImpactDuring();

  /// Graceful-degradation strategy.
  @SerializationOrder(2)
  MaintenanceUserImpactGracefulDegradation gracefulDegradation =
      MaintenanceUserImpactGracefulDegradation();

  /// Post-maintenance communication.
  @SerializationOrder(3)
  MaintenanceUserImpactPost post = MaintenanceUserImpactPost();
}

/// Communication during maintenance.
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes what users are shown and told while maintenance is in progress.',
)
@SectionId('MUID')
class MaintenanceUserImpactDuring {
  @Form([
    Field('maintenancePage', String, 'Maintenance Page',
        hint: 'What user sees during downtime'),
    Field('maintenanceMessage', String, 'Maintenance Message',
        hint: 'Default maintenance text'),
    Field('estimatedCompletion', bool, 'Estimated Completion',
        hint: 'Show estimated completion'),
    Field('progressUpdates', bool, 'Progress Updates',
        hint: 'Periodic progress updates'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Graceful-degradation strategy.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
  ],
  'Defines how partial service is preserved during maintenance to reduce user impact.',
)
@SectionId('MUIGD')
class MaintenanceUserImpactGracefulDegradation {
  @Form([
    Field('gracefulDegradation', String, 'Graceful Degradation',
        hint: 'Partial service availability'),
    Field('readOnlyMode', bool, 'Read-Only Mode',
        hint: 'Allow read-only access'),
    Field('queuedOperations', bool, 'Queued Operations',
        hint: 'Queue writes during maintenance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Post-maintenance communication.
@StandardReferences(
  [
    'ITIL 4 — IT service management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Describes how completion of maintenance is communicated to users afterward.',
)
@SectionId('MUIP')
class MaintenanceUserImpactPost {
  @Form([
    Field('completionNotice', bool, 'Completion Notice',
        hint: 'Notify when complete'),
    Field('changelogPublished', bool, 'Changelog Published',
        hint: 'Publish changes made'),
    Field('feedbackCollection', bool, 'Feedback Collection',
        hint: 'Collect user feedback'),
    Field('notes', String, 'Notes',
        hint: 'Additional user impact notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Post-maintenance validation.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'ITIL 4 — change management',
  ],
  'Defines the validation performed after maintenance to confirm the system is fully functional.',
)
@SectionId('POMAVA')
class PostMaintenanceValidation {
  @Form([
    Field('smokeTests', bool, 'Smoke Tests',
        hint: 'Run smoke tests after'),
    Field('functionalTests', bool, 'Functional Tests',
        hint: 'Run functional test suite'),
    Field('performanceTests', bool, 'Performance Tests',
        hint: 'Run performance checks'),
    Field('healthChecks', bool, 'Health Checks',
        hint: 'Verify all health checks'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Monitoring requirements after maintenance.
  @SerializationOrder(1)
  PostMaintenanceValidationMonitoring monitoring =
    PostMaintenanceValidationMonitoring();

  /// Sign-off and reporting expectations.
  @SerializationOrder(2)
  PostMaintenanceValidationClosure closure =
    PostMaintenanceValidationClosure();
}

/// Monitoring requirements after maintenance.
@StandardReferences(
  [
    'Google SRE — site reliability engineering',
    'ITIL 4 — change management',
  ],
  'Describes the heightened monitoring required after a maintenance window to confirm system health.',
)
@SectionId('PMVM')
class PostMaintenanceValidationMonitoring {
  @Form([
  Field('enhancedMonitoring', String, 'Enhanced Monitoring',
    hint: 'Heightened monitoring period'),
  Field('monitoringDuration', String, 'Monitoring Duration',
    hint: 'How long to watch after'),
  Field('keyMetrics', String, 'Key Metrics',
    hint: 'Metrics to watch closely'),
  Field('baselineComparison', bool, 'Baseline Comparison',
    hint: 'Compare to pre-maintenance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Sign-off and reporting expectations.
@StandardReferences(
  [
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ],
  'Captures the sign-off and reporting expectations that close out a maintenance window.',
)
@SectionId('PMVC')
class PostMaintenanceValidationClosure {
  @Form([
  Field('validateSignoff', String, 'Validation Sign-Off',
    hint: 'Who signs off validation'),
  Field('maintenanceReport', bool, 'Maintenance Report',
    hint: 'Generate maintenance report'),
  Field('lessonsLearned', bool, 'Lessons Learned',
    hint: 'Document lessons learned'),
  Field('notes', String, 'Notes',
    hint: 'Additional validation notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 8.6. Communication Requirements.
@StandardReferences(
  [
    'IETF RFC 9110 — HTTP semantics',
    'IETF RFC 8446 — TLS 1.3',
    'ISO/IEC 7498 — OSI reference model',
  ],
  'Defines the network communication requirements: protocols, transport security, API conventions, and external connectivity.',
)
@DetailedIn(D06ArchitectureTechnologySpecification)
@SecondLevelSectionId(D06ArchitectureTechnologySpecification, 'ATS-COM')
@ContentHelp('''
Define network communication requirements including protocols, security,
and external connectivity. Communication architecture affects performance,
security, and integration capabilities.

**Subsections**:
- **Protocols and Standards**: Communication protocols, TLS/SSL, API
  versioning, certificate management, data formats
- **External Connectivity**: Partner integrations, cloud services, third-
  party APIs, service mesh, API gateway

**Communication Patterns**:
- **Synchronous**: HTTP/REST, gRPC, GraphQL (request-response)
- **Asynchronous**: Message queues, event streaming (fire-and-forget)
- **Real-time**: WebSocket, Server-Sent Events, WebRTC
- **Batch**: File transfer, scheduled data exchange

**Security Considerations**:
- Transport security (TLS 1.2/1.3, certificate pinning)
- API authentication (API keys, OAuth, mTLS)
- Data encryption in transit and at rest
- Rate limiting and throttling

**Integration Standards**:
- API design guidelines (REST, OpenAPI, AsyncAPI)
- Data format standards (JSON, Protocol Buffers, Avro)
- Error handling and response formats
- Idempotency and retry handling
''')
@SectionId('COMREQ')
class CommunicationRequirements {
  @ContentHelp('''
Provide an overview of communication architecture and strategy.

**Include**:
- Primary communication patterns
- Security requirements overview
- External integration landscape
- API design principles
- Performance requirements

**Best Practices**:
- Design for failure (circuit breakers, retries)
- Use asynchronous where possible
- Implement proper error handling
- Version APIs for backward compatibility
- Monitor communication health
''')
  @SerializationOrder(0)
  String? content;

  /// 8.6.1. Protocols and Standards.
  @SerializationOrder(1)
  ProtocolsAndStandardsSection protocolsAndStandards =
      ProtocolsAndStandardsSection();

  /// 8.6.2. External Connectivity.
  @SerializationOrder(2)
  ExternalConnectivitySection externalConnectivity =
      ExternalConnectivitySection();
}

/// 8.6.1. Protocols and Standards.
@ContentHelp('''
Specify communication protocols, security standards, and API conventions.
Standardized protocols ensure interoperability and security.

**Network Protocols**:
- **Application Layer**: HTTP/1.1, HTTP/2, HTTP/3 (QUIC), gRPC, WebSocket
- **Transport**: TCP, UDP, QUIC
- **Security**: TLS 1.2/1.3, DTLS, SSH

**API Protocols**:
- **REST**: Resource-based, HTTP verbs, JSON/XML
- **GraphQL**: Query language, single endpoint, flexible queries
- **gRPC**: Binary protocol, Protocol Buffers, streaming support
- **WebSocket**: Full-duplex, real-time, persistent connection

**TLS/SSL Requirements**:
- Minimum TLS version (TLS 1.2 or 1.3)
- Cipher suites (AEAD, perfect forward secrecy)
- Certificate requirements (CA-signed, validity period)
- Certificate pinning considerations

**Certificate Management**:
- Certificate lifecycle (issuance, renewal, revocation)
- Automated certificate management (cert-manager, Let's Encrypt)
- Certificate monitoring and alerting
- Key rotation procedures

**API Versioning Strategy**:
- URL versioning (/v1/, /v2/)
- Header versioning (Accept-Version)
- Content negotiation (media type)
- Deprecation and sunset policies
''')
@StandardReferences(
  [
    'IETF RFC 9110 — HTTP semantics',
    'IETF RFC 8446 — TLS 1.3',
    'ISO/IEC 7498 — OSI reference model',
  ],
  'Specifies the communication protocols, security standards, and API conventions the system uses.',
)
@SectionId('PASS')
class ProtocolsAndStandardsSection {
  @ContentHelp('''
Provide an overview of protocol and standards approach.

**Include**:
- Primary protocols and selection rationale
- TLS/security configuration
- Certificate management strategy
- API versioning approach
- Data format standards

**Best Practices**:
- Use TLS 1.3 where supported
- Automate certificate renewal
- Implement proper API versioning from start
- Document protocol requirements clearly
- Monitor protocol compliance
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of communication protocols and standards.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Protocol catalog — contains 0+× Protocol.
  @StandardReferences(
    ['IETF RFC 9110 — HTTP semantics'],
    'The communication protocols the system supports.',
  )
  @SectionId('PREN-PROT-LST')
  @SectionIdPattern('PREN-PROT-xxx')
  @ContentHelp('Add one entry per protocol.')
  @SerializationOrder(2)
  List<ProtocolEntry> protocols = [];

  /// TLS/SSL requirements.
  @SerializationOrder(3)
  TlsRequirements tlsRequirements = TlsRequirements();

  /// Certificate management.
  @SerializationOrder(4)
  CertificateManagement certificateManagement = CertificateManagement();

  /// API versioning strategy.
  @SerializationOrder(5)
  ApiVersioningStrategy apiVersioning = ApiVersioningStrategy();

  /// Message format standards.
  @SerializationOrder(6)
  MessageFormatStandards messageFormats = MessageFormatStandards();

  /// Rate limiting and throttling.
  @SerializationOrder(7)
  RateLimitingPolicy rateLimiting = RateLimitingPolicy();

  /// Protocol compliance requirements.
  @SerializationOrder(8)
  ProtocolComplianceRequirements compliance = ProtocolComplianceRequirements();
}

/// A protocol or standard entry (form).
@StandardReferences(
  [
    'IETF RFC 9110 — HTTP semantics',
    'ISO/IEC 7498 — OSI reference model',
  ],
  'Describes a single communication protocol entry with its version and transport layer.',
)
@SectionId('PE')
class ProtocolEntry {
  @Form([
    Field('protocolName', String, 'Protocol Name',
        required: true, hint: 'HTTP/2, WebSocket, gRPC, MQTT, AMQP'),
    Field('protocolType', String, 'Protocol Type',
        hint: 'Request-response, streaming, pub-sub, event-driven'),
    Field('protocolVersion', String, 'Protocol Version',
        hint: 'HTTP/2, MQTT 5.0, gRPC 1.x'),
    Field('transportLayer', String, 'Transport Layer',
        hint: 'TCP, UDP, QUIC'),
    Field('directionality', String, 'Directionality',
        hint: 'Client-to-server, bidirectional, server-push'),
    Field('notes', String, 'Notes',
        hint: 'Additional protocol notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Authentication and serialization.
@StandardReferences(
  [
    'OAuth 2.0 / IETF RFC 6749 — authorization framework',
    'JSON / IETF RFC 8259 — data interchange format',
  ],
  'Defines the protocol authentication method, authorization scheme, and message serialization.',
)
@SectionId('PRAUSE')
class ProtocolAuthSerialization {
  @Form([
    Field('authenticationMethod', String, 'Authentication Method',
        hint: 'API key, OAuth 2.0, mTLS, JWT'),
    Field('authorizationScheme', String, 'Authorization Scheme',
        hint: 'Bearer token, Basic, custom'),
    Field('messageFormat', String, 'Message Format',
        hint: 'JSON, Protocol Buffers, XML, Avro'),
    Field('encoding', String, 'Encoding',
        hint: 'UTF-8, Base64, binary'),
    Field('compressionSupport', String, 'Compression Support',
        hint: 'gzip, brotli, none'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Performance settings.
@StandardReferences(
  [
    'IETF RFC 9110 — HTTP semantics',
    'ISO/IEC 7498 — OSI reference model',
  ],
  'Defines protocol performance settings such as message size, pooling, and timeouts.',
)
@SectionId('PRPE')
class ProtocolPerformance {
  @Form([
    Field('maxMessageSize', String, 'Max Message Size',
        hint: 'Maximum payload size'),
    Field('connectionPooling', bool, 'Connection Pooling',
        hint: 'Connection reuse strategy'),
    Field('keepAliveInterval', String, 'Keep-Alive Interval',
        hint: 'Heartbeat/keep-alive timing'),
    Field('connectionTimeout', String, 'Connection Timeout',
        hint: 'Connection establishment timeout'),
    Field('requestTimeout', String, 'Request Timeout',
        hint: 'Individual request timeout'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reliability and delivery.
@StandardReferences(
  [
    'IETF RFC 9110 — HTTP semantics',
    'ISO/IEC 7498 — OSI reference model',
  ],
  'Defines retry policy, idempotency, and delivery guarantees for the protocol.',
)
@SectionId('PRRE')
class ProtocolReliability {
  @Form([
    Field('retryPolicy', String, 'Retry Policy',
        hint: 'Exponential backoff, fixed interval'),
    Field('idempotencySupport', bool, 'Idempotency Support',
        hint: 'Support for idempotent operations'),
    Field('deliveryGuarantee', String, 'Delivery Guarantee',
        hint: 'At-most-once, at-least-once, exactly-once'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Usage and notes.
@StandardReferences(
  [
    'IETF RFC 9110 — HTTP semantics',
  ],
  'Describes which components use the protocol and its directionality.',
)
@SectionId('PRUS')
class ProtocolUsage {
  @Form([
    Field('usedBy', String, 'Used By',
        hint: 'Components or services using this protocol'),
    Field('directionality', String, 'Directionality',
        hint: 'Client-to-server, bidirectional, server-push'),
    Field('notes', String, 'Notes',
        hint: 'Additional protocol notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// TLS/SSL requirements.
@StandardReferences(
  [
    'IETF RFC 8446 — TLS 1.3',
    'IETF RFC 5280 — X.509 PKI certificates',
  ],
  'Defines the minimum, preferred, and disabled TLS versions for transport security.',
)
@SectionId('TLRE')
class TlsRequirements {
  @Form([
    Field('minimumTlsVersion', String, 'Minimum TLS Version',
        required: true, hint: 'TLS 1.2, TLS 1.3'),
    Field('preferredTlsVersion', String, 'Preferred TLS Version',
        hint: 'TLS 1.3'),
    Field('disabledProtocols', String, 'Disabled Protocols',
        hint: 'SSLv3, TLS 1.0, TLS 1.1'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Cipher suite policy.
  @SerializationOrder(1)
  TlsRequirementsCipherSuites cipherSuites = TlsRequirementsCipherSuites();

  /// Certificate validation rules.
  @SerializationOrder(2)
  TlsRequirementsCertificateValidation certificateValidation =
      TlsRequirementsCertificateValidation();

  /// Termination and internal encryption.
  @SerializationOrder(3)
  TlsRequirementsTermination termination = TlsRequirementsTermination();

  /// Compliance and HSTS settings.
  @SerializationOrder(4)
  TlsRequirementsCompliance compliance = TlsRequirementsCompliance();
}

/// Cipher suite policy.
@StandardReferences(
  [
    'IETF RFC 8446 — TLS 1.3',
  ],
  'Defines allowed and disabled cipher suites and key-exchange algorithms.',
)
@SectionId('TRCS')
class TlsRequirementsCipherSuites {
  @Form([
    Field('allowedCipherSuites', String, 'Allowed Cipher Suites',
        hint: 'AES-256-GCM, ChaCha20-Poly1305'),
    Field('disabledCipherSuites', String, 'Disabled Cipher Suites',
        hint: 'RC4, DES, 3DES, MD5-based'),
    Field('keyExchangeAlgorithms', String, 'Key Exchange Algorithms',
        hint: 'ECDHE, DHE, X25519'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Certificate validation rules.
@StandardReferences(
  [
    'IETF RFC 5280 — X.509 PKI certificates',
    'IETF RFC 8446 — TLS 1.3',
  ],
  'Defines certificate pinning, OCSP stapling, and mutual-TLS validation rules.',
)
@SectionId('TRCV')
class TlsRequirementsCertificateValidation {
  @Form([
    Field('certificatePinning', bool, 'Certificate Pinning',
        hint: 'Enable HPKP or app-level pinning'),
    Field('ocspStapling', bool, 'OCSP Stapling',
        hint: 'Online certificate status protocol'),
    Field('mutualTls', bool, 'Mutual TLS (mTLS)',
        hint: 'Client certificate authentication'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Termination and internal encryption.
@StandardReferences(
  [
    'IETF RFC 8446 — TLS 1.3',
  ],
  'Defines where TLS is terminated and whether internal service-to-service traffic is encrypted.',
)
@SectionId('TLRETE')
class TlsRequirementsTermination {
  @Form([
    Field('tlsTermination', String, 'TLS Termination',
        hint: 'Load balancer, reverse proxy, application'),
    Field('internalTls', bool, 'Internal TLS',
        hint: 'Encrypt service-to-service traffic'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance and HSTS settings.
@StandardReferences(
  [
    'IETF RFC 8446 — TLS 1.3',
    'IETF RFC 9110 — HTTP semantics',
  ],
  'Defines TLS compliance targets and HSTS enforcement settings.',
)
@SectionId('TLRECO')
class TlsRequirementsCompliance {
  @Form([
    Field('sslLabsTargetGrade', String, 'SSL Labs Target Grade',
        hint: 'A+, A, B minimum rating'),
    Field('hstsEnabled', bool, 'HSTS Enabled',
        hint: 'HTTP Strict Transport Security'),
    Field('hstsMaxAge', String, 'HSTS Max-Age',
        hint: 'HSTS header max-age value'),
    Field('hstsIncludeSubdomains', bool, 'HSTS Include Subdomains',
        hint: 'Apply HSTS to all subdomains'),
    Field('notes', String, 'Notes', hint: 'Additional TLS requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Certificate management.
@StandardReferences(
  [
    'IETF RFC 5280 — X.509 PKI certificates',
    'IETF RFC 8446 — TLS 1.3',
  ],
  'Defines the certificate authority, type, and overall certificate management approach.',
)
@SectionId('CEMA')
class CertificateManagement {
  @Form([
    Field('certificateAuthority', String, 'Certificate Authority',
        hint: 'Public CA, private PKI, Let\'s Encrypt'),
    Field('certificateType', String, 'Certificate Type',
        hint: 'DV, OV, EV, Wildcard'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Key specifications.
  @SerializationOrder(1)
  CertificateManagementKeys keys = CertificateManagementKeys();

  /// Lifecycle management.
  @SerializationOrder(2)
  CertificateManagementLifecycle lifecycle = CertificateManagementLifecycle();

  /// Storage and access controls.
  @SerializationOrder(3)
  CertificateManagementStorage storage = CertificateManagementStorage();

  /// Monitoring rules.
  @SerializationOrder(4)
  CertificateManagementMonitoring monitoring =
      CertificateManagementMonitoring();
}

/// Key specifications.
@StandardReferences(
  [
    'IETF RFC 5280 — X.509 PKI certificates',
  ],
  'Defines the key algorithm, length, and signature algorithm for certificates.',
)
@SectionId('CEMAKE')
class CertificateManagementKeys {
  @Form([
    Field('keyAlgorithm', String, 'Key Algorithm',
        hint: 'RSA, ECDSA, Ed25519'),
    Field('keyLength', String, 'Key Length',
        hint: 'RSA 2048/4096, ECDSA P-256/P-384'),
    Field('signatureAlgorithm', String, 'Signature Algorithm',
        hint: 'SHA-256, SHA-384'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Lifecycle management.
@StandardReferences(
  [
    'IETF RFC 5280 — X.509 PKI certificates',
  ],
  'Defines certificate validity, renewal, rotation, and revocation lifecycle.',
)
@SectionId('CEMALI')
class CertificateManagementLifecycle {
  @Form([
    Field('validityPeriod', String, 'Validity Period',
        hint: 'Certificate lifetime (e.g. 90 days, 1 year)'),
    Field('renewalWindow', String, 'Renewal Window',
        hint: 'Days before expiry to renew'),
    Field('automaticRenewal', bool, 'Automatic Renewal',
        hint: 'Auto-renew via ACME/cert-manager'),
    Field('rotationPolicy', String, 'Rotation Policy',
        hint: 'Scheduled rotation cadence'),
    Field('revocationProcess', String, 'Revocation Process',
        hint: 'CRL, OCSP procedures'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Storage and access controls.
@StandardReferences(
  [
    'IETF RFC 5280 — X.509 PKI certificates',
  ],
  'Defines how certificates and private keys are stored, protected, and access-controlled.',
)
@SectionId('CEMAST')
class CertificateManagementStorage {
  @Form([
    Field('storageMethod', String, 'Storage Method',
        hint: 'HSM, vault, Kubernetes secrets'),
    Field('privateKeyProtection', String, 'Private Key Protection',
        hint: 'Hardware-backed, encrypted at rest'),
    Field('accessControl', String, 'Access Control',
        hint: 'Who can access certificates/keys'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Monitoring rules.
@StandardReferences(
  [
    'IETF RFC 5280 — X.509 PKI certificates',
  ],
  'Defines certificate expiry monitoring and alert thresholds.',
)
@SectionId('CEMAMO')
class CertificateManagementMonitoring {
  @Form([
    Field('expiryMonitoring', bool, 'Expiry Monitoring',
        hint: 'Automated certificate expiry alerts'),
    Field('expiryAlertThreshold', String, 'Expiry Alert Threshold',
        hint: 'Days before expiry to alert (e.g. 30, 14, 7)'),
    Field('notes', String, 'Notes',
        hint: 'Additional certificate management notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// API versioning strategy.
@StandardReferences(
  [
    'SemVer — semantic versioning',
    'OpenAPI Specification — REST API description',
  ],
  'Defines the overall API versioning scheme, format, and current version.',
)
@SectionId('APVEST')
class ApiVersioningStrategy {
  @Form([
    // Scheme
    Field('versioningScheme', String, 'Versioning Scheme',
        required: true, hint: 'URL path, header, query parameter'),
    Field('versionFormat', String, 'Version Format',
        hint: 'v1, v2.0, semver, date-based'),
    Field('currentVersion', String, 'Current Version',
        hint: 'Current active API version'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Supported versions and deprecation commitments.
  @SerializationOrder(1)
  ApiVersioningStrategySupport support = ApiVersioningStrategySupport();

  /// Compatibility guarantees and migration expectations.
  @SerializationOrder(2)
  ApiVersioningStrategyCompatibility compatibility =
    ApiVersioningStrategyCompatibility();

  /// Documentation and client generation practices.
  @SerializationOrder(3)
  ApiVersioningStrategyDocumentation documentation =
    ApiVersioningStrategyDocumentation();
}

/// Supported versions and deprecation commitments.
@StandardReferences(
  [
    'SemVer — semantic versioning',
    'IETF RFC 9110 — HTTP semantics',
  ],
  'Defines supported API versions and their deprecation and sunset commitments.',
)
@SectionId('AVSS')
class ApiVersioningStrategySupport {
  @Form([
  Field('supportedVersions', String, 'Supported Versions',
    hint: 'List of all currently supported versions'),
  Field('deprecationPolicy', String, 'Deprecation Policy',
    hint: 'Sunset timeline, notice period'),
  Field('deprecationNoticeMethod', String, 'Deprecation Notice Method',
    hint: 'HTTP Sunset header, changelog, email'),
  Field('minimumSupportPeriod', String, 'Minimum Support Period',
    hint: 'Minimum time a version stays supported'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compatibility guarantees and migration expectations.
@StandardReferences(
  [
    'SemVer — semantic versioning',
    'OpenAPI Specification — REST API description',
  ],
  'Defines backward-compatibility guarantees, breaking-change policy, and migration guidance.',
)
@SectionId('AVSC')
class ApiVersioningStrategyCompatibility {
  @Form([
  Field('backwardCompatibility', String, 'Backward Compatibility',
    hint: 'Guaranteed compatibility rules'),
  Field('breakingChangePolicy', String, 'Breaking Change Policy',
    hint: 'When and how breaking changes are allowed'),
  Field('migrationGuidance', bool, 'Migration Guidance',
    hint: 'Provide migration guides between versions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Documentation and client generation practices.
@StandardReferences(
  [
    'OpenAPI Specification — REST API description',
    'AsyncAPI — event-driven API description',
  ],
  'Defines API documentation formats and client SDK generation practices.',
)
@SectionId('AVSD')
class ApiVersioningStrategyDocumentation {
  @Form([
  Field('apiDocumentationFormat', String, 'API Documentation Format',
    hint: 'OpenAPI/Swagger, AsyncAPI, GraphQL SDL'),
  Field('changelogFormat', String, 'Changelog Format',
    hint: 'Keep a Changelog, custom'),
  Field('clientSdkGeneration', bool, 'Client SDK Generation',
    hint: 'Auto-generate client libraries'),
  Field('notes', String, 'Notes',
    hint: 'Additional versioning notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Message format standards.
@StandardReferences(
  [
    'JSON / IETF RFC 8259 — data interchange format',
    'Protocol Buffers — binary serialization',
  ],
  'Defines the message serialization formats the system uses on the wire.',
)
@SectionId('MEFOST')
class MessageFormatStandards {
  @Form([
    Field('primaryFormat', String, 'Primary Format',
        required: true, hint: 'JSON, Protocol Buffers, XML'),
    Field('secondaryFormats', String, 'Secondary Formats',
        hint: 'Additional supported formats'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Schema standards.
  @SerializationOrder(1)
  MessageFormatStandardsSchema schema = MessageFormatStandardsSchema();

  /// Field conventions.
  @SerializationOrder(2)
  MessageFormatStandardsConventions conventions =
      MessageFormatStandardsConventions();

  /// Pagination and error envelopes.
  @SerializationOrder(3)
  MessageFormatStandardsResponses responses =
      MessageFormatStandardsResponses();

  /// Compression and negotiation.
  @SerializationOrder(4)
  MessageFormatStandardsTransport transport =
      MessageFormatStandardsTransport();
}

/// Schema standards.
@StandardReferences(
  [
    'JSON / IETF RFC 8259 — data interchange format',
    'Protocol Buffers — binary serialization',
  ],
  'Defines schema definition, registry, evolution, and validation standards.',
)
@SectionId('MFSS')
class MessageFormatStandardsSchema {
  @Form([
    Field('schemaDefinition', String, 'Schema Definition',
        hint: 'JSON Schema, Protobuf definitions, XSD'),
    Field('schemaRegistry', String, 'Schema Registry',
        hint: 'Confluent, Apicurio, custom'),
    Field('schemaEvolution', String, 'Schema Evolution',
        hint: 'Forward, backward, full compatibility'),
    Field('schemaValidation', String, 'Schema Validation',
        hint: 'Request/response validation strategy'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Field conventions.
@StandardReferences(
  [
    'JSON / IETF RFC 8259 — data interchange format',
  ],
  'Defines field-level conventions for dates, encoding, nulls, enums, and naming.',
)
@SectionId('MFSC')
class MessageFormatStandardsConventions {
  @Form([
    Field('dateTimeFormat', String, 'Date/Time Format',
        hint: 'ISO 8601, Unix timestamp'),
    Field('characterEncoding', String, 'Character Encoding',
        hint: 'UTF-8, ASCII'),
    Field('nullHandling', String, 'Null Handling',
        hint: 'Omit, explicit null, empty string'),
    Field('enumRepresentation', String, 'Enum Representation',
        hint: 'String, integer, UPPER_CASE'),
    Field('namingConvention', String, 'Naming Convention',
        hint: 'camelCase, snake_case for field names'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Pagination and error envelopes.
@StandardReferences(
  [
    'JSON / IETF RFC 8259 — data interchange format',
    'IETF RFC 9110 — HTTP semantics',
  ],
  'Defines pagination formats and standardized error and response envelopes.',
)
@SectionId('MFSR')
class MessageFormatStandardsResponses {
  @Form([
    Field('paginationFormat', String, 'Pagination Format',
        hint: 'Cursor, offset, page-number'),
    Field('errorResponseFormat', String, 'Error Response Format',
        hint: 'RFC 7807 Problem Details, custom envelope'),
    Field('envelopeFormat', String, 'Envelope Format',
        hint: 'Flat, wrapped with metadata'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compression and negotiation.
@StandardReferences(
  [
    'IETF RFC 9110 — HTTP semantics',
    'JSON / IETF RFC 8259 — data interchange format',
  ],
  'Defines message compression algorithms and content negotiation behavior.',
)
@SectionId('MFST')
class MessageFormatStandardsTransport {
  @Form([
    Field('compressionAlgorithm', String, 'Compression Algorithm',
        hint: 'gzip, brotli, zstd, none'),
    Field('contentNegotiation', bool, 'Content Negotiation',
        hint: 'Support Accept/Content-Type headers'),
    Field('notes', String, 'Notes',
        hint: 'Additional message format notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Rate limiting and throttling.
@StandardReferences(
  [
    'IETF RFC 9110 — HTTP semantics',
  ],
  'Defines the rate limiting and throttling policy for API traffic.',
)
@SectionId('RALIPO')
class RateLimitingPolicy {
  @Form([
    Field('rateLimitingStrategy', String, 'Rate Limiting Strategy',
        required: true, hint: 'Token bucket, sliding window, fixed window'),
    Field('rateLimitScope', String, 'Rate Limit Scope',
        hint: 'Global, per-client, per-endpoint, per-tenant'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Rate-limit ceilings and burst handling.
  @SerializationOrder(1)
  RateLimitingPolicyLimits limits = RateLimitingPolicyLimits();

  /// Runtime response behavior when limits are exceeded.
  @SerializationOrder(2)
  RateLimitingPolicyBehavior behavior = RateLimitingPolicyBehavior();

  /// Quota management and exceptions.
  @SerializationOrder(3)
  RateLimitingPolicyQuotas quotas = RateLimitingPolicyQuotas();
}

/// Rate-limit ceilings and burst handling.
@StandardReferences(
  [
    'IETF RFC 9110 — HTTP semantics',
  ],
  'Defines rate-limit ceilings, per-scope limits, and burst allowances.',
)
@SectionId('RLPL')
class RateLimitingPolicyLimits {
  @Form([
  Field('globalRateLimit', String, 'Global Rate Limit',
    hint: 'Requests per second/minute overall'),
  Field('perClientLimit', String, 'Per-Client Limit',
    hint: 'Rate limit per API key/client'),
  Field('perEndpointLimit', String, 'Per-Endpoint Limit',
    hint: 'Rate limit per API endpoint'),
  Field('burstAllowance', String, 'Burst Allowance',
    hint: 'Short burst above steady-state limit'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Runtime response behavior when limits are exceeded.
@StandardReferences(
  [
    'IETF RFC 9110 — HTTP semantics',
  ],
  'Defines runtime throttling behavior and rate-limit response headers when limits are exceeded.',
)
@SectionId('RLPB')
class RateLimitingPolicyBehavior {
  @Form([
  Field('throttlingBehavior', String, 'Throttling Behavior',
    hint: 'HTTP 429, queue, graceful degrade'),
  Field('retryAfterHeader', bool, 'Retry-After Header',
    hint: 'Include Retry-After in 429 responses'),
  Field('rateLimitHeaders', bool, 'Rate Limit Headers',
    hint: 'X-RateLimit-* response headers'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Quota management and exceptions.
@StandardReferences(
  [
    'IETF RFC 9110 — HTTP semantics',
  ],
  'Defines quota management, reset cadence, and exemptions from rate limits.',
)
@SectionId('RLPQ')
class RateLimitingPolicyQuotas {
  @Form([
  Field('quotaManagement', String, 'Quota Management',
    hint: 'Daily/monthly quotas per subscription tier'),
  Field('quotaResetPolicy', String, 'Quota Reset Policy',
    hint: 'Calendar-based, rolling window'),
  Field('exemptions', String, 'Exemptions',
    hint: 'Services or clients exempt from limits'),
  Field('notes', String, 'Notes',
    hint: 'Additional rate limiting notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Protocol compliance requirements.
@StandardReferences(
  [
    'IETF RFC 9110 — HTTP semantics',
    'OAuth 2.0 / IETF RFC 6749 — authorization framework',
  ],
  'Defines protocol-level compliance requirements such as CORS, CSP, and security headers.',
)
@SectionId('PRCORE')
class ProtocolComplianceRequirements {
  @Form([
    Field('corsPolicy', String, 'CORS Policy',
        hint: 'Allowed origins, methods, headers'),
    Field('contentSecurityPolicy', String, 'Content Security Policy',
        hint: 'CSP header directives'),
    Field('httpSecurityHeaders', String, 'HTTP Security Headers',
        hint: 'X-Frame-Options, X-Content-Type-Options'),
    Field('cookiePolicy', String, 'Cookie Policy',
        hint: 'SameSite, Secure, HttpOnly attributes'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Caching requirements.
  @SerializationOrder(1)
  ProtocolComplianceRequirementsCaching caching =
    ProtocolComplianceRequirementsCaching();

  /// Request logging and trace propagation rules.
  @SerializationOrder(2)
  ProtocolComplianceRequirementsObservability observability =
    ProtocolComplianceRequirementsObservability();

  /// Webhook, event, and health endpoint standards.
  @SerializationOrder(3)
  ProtocolComplianceRequirementsEvents events =
    ProtocolComplianceRequirementsEvents();
}

/// Caching requirements.
@StandardReferences(
  [
    'IETF RFC 9110 — HTTP semantics',
  ],
  'Defines HTTP caching and CDN integration requirements.',
)
@SectionId('PCRC')
class ProtocolComplianceRequirementsCaching {
  @Form([
  Field('cachingPolicy', String, 'Caching Policy',
    hint: 'Cache-Control, ETag, If-Modified-Since'),
  Field('cdnIntegration', String, 'CDN Integration',
    hint: 'CDN caching strategy and invalidation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Request logging and trace propagation rules.
@StandardReferences(
  [
    'IETF RFC 9110 — HTTP semantics',
  ],
  'Defines request logging and distributed trace-context propagation rules.',
)
@SectionId('PCRO')
class ProtocolComplianceRequirementsObservability {
  @Form([
  Field('requestLogging', String, 'Request Logging',
    hint: 'Request/response logging, PII redaction'),
  Field('distributedTracing', String, 'Distributed Tracing',
    hint: 'Correlation IDs, W3C Trace Context, OpenTelemetry'),
  Field('tracePropagation', String, 'Trace Propagation',
    hint: 'Header format for trace context propagation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Webhook, event, and health endpoint standards.
@StandardReferences(
  [
    'AsyncAPI — event-driven API description',
    'IETF RFC 9110 — HTTP semantics',
  ],
  'Defines standards for webhooks, event streams, and health-check endpoints.',
)
@SectionId('PCRE')
class ProtocolComplianceRequirementsEvents {
  @Form([
  Field('webhookStandards', String, 'Webhook Standards',
    hint: 'Signature verification, retry policy'),
  Field('eventStreamStandards', String, 'Event Stream Standards',
    hint: 'SSE, CloudEvents format'),
  Field('healthEndpointStandard', String, 'Health Endpoint Standard',
    hint: '/health, /ready, /live conventions'),
  Field('notes', String, 'Notes',
    hint: 'Additional compliance notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 8.6.2. External Connectivity.
@ContentHelp('''
Specify requirements for external connectivity including partner
integrations, cloud services, and third-party APIs. External connections
require careful security and reliability considerations.

**Partner Integrations**:
- B2B connections (EDI, API, file exchange)
- Partner onboarding process
- SLA and support agreements
- Data exchange formats and protocols
- Security requirements (VPN, mTLS, IP whitelisting)

**Cloud Service Integrations**:
- Cloud provider services (storage, messaging, ML)
- Multi-cloud considerations
- Vendor lock-in mitigation
- Cost management and optimization

**Third-Party API Integrations**:
- API consumption patterns and rate limits
- Authentication and credential management
- Error handling and fallback strategies
- Dependency health monitoring
- Vendor reliability and SLAs

**Service Mesh and API Gateway**:
- Traffic management (routing, load balancing)
- Security (authentication, authorization)
- Observability (tracing, logging, metrics)
- Rate limiting and throttling

**Resilience Patterns**:
- Circuit breaker implementation
- Retry with exponential backoff
- Bulkhead isolation
- Graceful degradation
''')
@StandardReferences(
  [
    'OpenAPI Specification — REST API description',
    'OAuth 2.0 / IETF RFC 6749 — authorization framework',
    'Enterprise Integration Patterns — messaging & integration',
  ],
  'Describes the external connectivity the system integrates with, including partners, cloud services, and third-party APIs.',
)
@SectionId('ECS')
class ExternalConnectivitySection {
  @ContentHelp('''
Provide an overview of external connectivity landscape.

**Include**:
- Key partner and integration landscape
- Cloud service dependencies
- Critical third-party APIs
- Gateway and mesh architecture
- Resilience strategy

**Best Practices**:
- Abstract external dependencies with adapters
- Implement comprehensive error handling
- Monitor external dependency health
- Have fallback strategies for critical integrations
- Regular vendor review and risk assessment
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of external connectivity requirements.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// External partner connections — contains 0+× ExternalPartnerConnection.
  @StandardReferences(
    ['Enterprise Integration Patterns — messaging & integration'],
    'The external partner connections the system integrates with.',
  )
  @SectionId('EPCE-PART-LST')
  @SectionIdPattern('EPCE-PART-xxx')
  @ContentHelp('Add one entry per external partner connection.')
  @SerializationOrder(2)
  List<ExternalPartnerConnectionEntry> partnerConnections = [];

  /// Cloud service integrations.
  @SerializationOrder(3)
  CloudServiceIntegrations cloudServices = CloudServiceIntegrations();

  /// Third-party API integrations.
  @SerializationOrder(4)
  ThirdPartyApiIntegrations thirdPartyApis = ThirdPartyApiIntegrations();

  /// Network security and access control.
  @SerializationOrder(5)
  NetworkSecurityPolicy networkSecurity = NetworkSecurityPolicy();

  /// Service mesh and API gateway.
  @SerializationOrder(6)
  ServiceMeshAndGateway serviceMeshAndGateway = ServiceMeshAndGateway();

  /// Connectivity resilience requirements.
  @SerializationOrder(7)
  ConnectivityResilience resilience = ConnectivityResilience();
}

/// An external partner connection entry (form).
@StandardReferences(
  [
    'Enterprise Integration Patterns — messaging & integration',
    'OAuth 2.0 / IETF RFC 6749 — authorization framework',
    'OpenAPI Specification — REST API description',
  ],
  'Describes a single external partner integration the system connects to.',
)
@SectionId('EXPACOEN')
class ExternalPartnerConnectionEntry {
  @Form([
    Field('partnerName', String, 'Partner Name',
        required: true, hint: 'Name of the external partner or system'),
    Field('partnerType', String, 'Partner Type',
        hint: 'Vendor, customer, regulatory body, payment provider'),
    Field('connectionPurpose', String, 'Connection Purpose',
        hint: 'Business purpose of this integration'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Protocol and endpoint.
  @SerializationOrder(1)
  ExternalPartnerProtocol protocol = ExternalPartnerProtocol();

  /// Authentication settings.
  @SerializationOrder(2)
  ExternalPartnerAuthentication authentication =
      ExternalPartnerAuthentication();

  /// Network configuration.
  @SerializationOrder(3)
  ExternalPartnerNetwork network = ExternalPartnerNetwork();

  /// Reliability and SLA.
  @SerializationOrder(4)
  ExternalPartnerReliability reliability = ExternalPartnerReliability();

  /// Data handling.
  @SerializationOrder(5)
  ExternalPartnerDataHandling dataHandling =
      ExternalPartnerDataHandling();

  /// Operations and contacts.
  @StandardReferences(
    ['Enterprise Integration Patterns — messaging & integration'],
    'The operational contacts and procedures for the partner connection.',
  )
  @SectionId('EXPAOP-OPER-LST')
  @SectionIdPattern('EXPAOP-OPER-xxx')
  @ContentHelp('Add one entry per operational contact.')
  @SerializationOrder(6)
  List<ExternalPartnerOperations> operations = [];
}

/// Protocol and endpoint.
@StandardReferences(
  [
    'OpenAPI Specification — REST API description',
    'IETF RFC 9110 — HTTP semantics',
  ],
  'Describes the protocol, endpoint, and data format for the partner connection.',
)
@SectionId('EXPAPR')
class ExternalPartnerProtocol {
  @Form([
    Field('protocol', String, 'Protocol',
        hint: 'REST, SOAP, SFTP, AS2, EDI'),
    Field('endpointUrl', String, 'Endpoint URL',
        hint: 'Base URL or hostname'),
    Field('dataDirection', String, 'Data Direction',
        hint: 'Inbound, outbound, bidirectional'),
    Field('dataFormat', String, 'Data Format',
        hint: 'JSON, XML, CSV, EDI X12, EDIFACT'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Authentication settings.
@StandardReferences(
  [
    'OAuth 2.0 / IETF RFC 6749 — authorization framework',
    'ISO/IEC 27001 — information security controls',
  ],
  'Specifies the authentication method and credential management for the partner connection.',
)
@SectionId('EXPAAU')
class ExternalPartnerAuthentication {
  @Form([
    Field('authenticationMethod', String, 'Authentication Method',
        hint: 'API key, OAuth 2.0, client certificate, SAML'),
    Field('credentialStorage', String, 'Credential Storage',
        hint: 'Vault, secrets manager, environment variable'),
    Field('credentialRotation', String, 'Credential Rotation',
        hint: 'Rotation frequency and process'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Network configuration.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security controls',
  ],
  'Describes network routing, IP whitelisting, and firewall rules for the partner connection.',
)
@SectionId('EXPANE')
class ExternalPartnerNetwork {
  @Form([
    Field('networkRoute', String, 'Network Route',
        hint: 'Public internet, VPN, private link, dedicated line'),
    Field('ipWhitelisting', bool, 'IP Whitelisting',
        hint: 'Restrict by IP address'),
    Field('whitelistedIps', String, 'Whitelisted IPs',
        hint: 'Allowed IP ranges'),
    Field('firewallRules', String, 'Firewall Rules',
        hint: 'Required firewall rule changes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reliability and SLA.
@StandardReferences(
  [
    'Circuit Breaker / Resilience patterns — fault tolerance',
    'Enterprise Integration Patterns — messaging & integration',
  ],
  'Captures SLA, latency, timeout, and retry expectations for the partner connection.',
)
@SectionId('EXPARE')
class ExternalPartnerReliability {
  @Form([
    Field('sla', String, 'SLA',
        hint: 'Partner system availability SLA'),
    Field('expectedLatency', String, 'Expected Latency',
        hint: 'Round-trip time expectations'),
    Field('expectedThroughput', String, 'Expected Throughput',
        hint: 'Requests per second or data volume'),
    Field('timeoutPolicy', String, 'Timeout Policy',
        hint: 'Connection and read timeout'),
    Field('retryStrategy', String, 'Retry Strategy',
        hint: 'Retry count, backoff policy'),
    Field('circuitBreakerEnabled', bool, 'Circuit Breaker',
        hint: 'Circuit breaker for partner failures'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data handling.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security controls',
    'IETF RFC 8446 — TLS 1.3',
  ],
  'Specifies data classification, encryption, and retention for partner data exchange.',
)
@SectionId('EPDH')
class ExternalPartnerDataHandling {
  @Form([
    Field('dataClassification', String, 'Data Classification',
        hint: 'Confidentiality level of exchanged data'),
    Field('encryptionRequirements', String, 'Encryption Requirements',
        hint: 'Encryption in transit and at rest'),
    Field('dataRetention', String, 'Data Retention',
        hint: 'Retention of exchanged data'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Operations and contacts.
@StandardReferences(
  [
    'Enterprise Integration Patterns — messaging & integration',
  ],
  'Captures operational contacts and escalation processes for the partner integration.',
)
@SectionId('EXPAOP')
class ExternalPartnerOperations {
  @Form([
    Field('contactPerson', String, 'Contact Person',
        hint: 'Technical contact at partner'),
    Field('escalationProcess', String, 'Escalation Process',
        hint: 'Issue escalation path'),
    Field('maintenanceNotification', String, 'Maintenance Notification',
        hint: 'How partner communicates downtimes'),
    Field('notes', String, 'Notes',
        hint: 'Additional connection notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cloud service integrations.
@StandardReferences(
  [
    'OpenAPI Specification — REST API description',
    'ISO/IEC 27001 — information security controls',
  ],
  'Describes the cloud provider services the system integrates with.',
)
@SectionId('CLSEIN')
class CloudServiceIntegrations {
  @Form([
    Field('primaryCloudProvider', String, 'Primary Cloud Provider',
        hint: 'AWS, Azure, GCP, multi-cloud'),
    Field('secondaryProviders', String, 'Secondary Providers',
        hint: 'Additional cloud providers'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Managed services catalog.
  @SerializationOrder(1)
  CloudServiceIntegrationsServices services =
      CloudServiceIntegrationsServices();

  /// Network connectivity.
  @SerializationOrder(2)
  CloudServiceIntegrationsNetworking networking =
      CloudServiceIntegrationsNetworking();

  /// Compliance and notes.
  @SerializationOrder(3)
  CloudServiceIntegrationsCompliance compliance =
      CloudServiceIntegrationsCompliance();
}

/// Managed services catalog.
@StandardReferences(
  [
    'OpenAPI Specification — REST API description',
    'ISO/IEC 27001 — information security controls',
  ],
  'Catalogs the managed cloud services the system depends on, such as storage and identity.',
)
@SectionId('CSIS')
class CloudServiceIntegrationsServices {
  @Form([
    Field('managedServices', String, 'Managed Services',
        hint: 'Databases, queues, caches, storage'),
    Field('identityProvider', String, 'Identity Provider',
        hint: 'Cognito, Azure AD, Auth0, Keycloak'),
    Field('emailService', String, 'Email Service',
        hint: 'SES, SendGrid, Mailgun'),
    Field('notificationService', String, 'Notification Service',
        hint: 'Push notifications, SMS gateway'),
    Field('storageService', String, 'Storage Service',
        hint: 'S3, Blob Storage, GCS'),
    Field('cdnService', String, 'CDN Service',
        hint: 'CloudFront, Azure CDN, Cloudflare'),
    Field('searchService', String, 'Search Service',
        hint: 'Elasticsearch, OpenSearch, Algolia'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Network connectivity.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security controls',
  ],
  'Describes VPC peering, private endpoints, and transit routing for cloud connectivity.',
)
@SectionId('CSIN')
class CloudServiceIntegrationsNetworking {
  @Form([
    Field('vpcPeering', String, 'VPC Peering',
        hint: 'VPC/VNet peering requirements'),
    Field('privateEndpoints', String, 'Private Endpoints',
        hint: 'Private link, service endpoints'),
    Field('transitGateway', String, 'Transit Gateway',
        hint: 'Cross-VPC or cross-region routing'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance and notes.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security controls',
  ],
  'Specifies data residency and compliance certifications for cloud service integrations.',
)
@SectionId('CSIC')
class CloudServiceIntegrationsCompliance {
  @Form([
    Field('dataResidency', String, 'Data Residency',
        hint: 'Region restrictions for data storage'),
    Field('complianceCertifications', String, 'Compliance Certifications',
        hint: 'SOC 2, ISO 27001, HIPAA'),
    Field('notes', String, 'Notes',
        hint: 'Additional cloud integration notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Third-party API integrations.
@StandardReferences(
  [
    'OpenAPI Specification — REST API description',
    'OAuth 2.0 / IETF RFC 6749 — authorization framework',
    'Enterprise Integration Patterns — messaging & integration',
  ],
  'Describes third-party API integrations the system consumes, including payment providers.',
)
@SectionId('TPAI')
class ThirdPartyApiIntegrations {
  @Form([
    Field('paymentGateways', String, 'Payment Gateways',
        hint: 'Stripe, PayPal, Adyen'),
    Field('paymentCompliance', String, 'Payment Compliance',
        hint: 'PCI DSS level, tokenization'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Analytics and monitoring providers.
  @SerializationOrder(1)
  ThirdPartyApiIntegrationsAnalytics analytics =
      ThirdPartyApiIntegrationsAnalytics();

  /// Communication providers.
  @SerializationOrder(2)
  ThirdPartyApiIntegrationsCommunication communication =
      ThirdPartyApiIntegrationsCommunication();

  /// Mapping and location providers.
  @SerializationOrder(3)
  ThirdPartyApiIntegrationsLocation location =
      ThirdPartyApiIntegrationsLocation();

  /// Document and media providers.
  @SerializationOrder(4)
  ThirdPartyApiIntegrationsMedia media = ThirdPartyApiIntegrationsMedia();

  /// AI and translation providers.
  @SerializationOrder(5)
  ThirdPartyApiIntegrationsAi ai = ThirdPartyApiIntegrationsAi();

  /// Compliance and fallback controls.
  @SerializationOrder(6)
  ThirdPartyApiIntegrationsOperations operations =
      ThirdPartyApiIntegrationsOperations();
}

/// Analytics and monitoring providers.
@StandardReferences(
  [
    'OpenAPI Specification — REST API description',
    'OAuth 2.0 / IETF RFC 6749 — authorization framework',
  ],
  'Describes third-party analytics and error-tracking service providers the system consumes.',
)
@SectionId('TPAIA')
class ThirdPartyApiIntegrationsAnalytics {
  @Form([
    Field('analyticsServices', String, 'Analytics Services',
        hint: 'Google Analytics, Mixpanel, Amplitude'),
    Field('errorTrackingServices', String, 'Error Tracking Services',
        hint: 'Sentry, Bugsnag, Datadog APM'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Communication providers.
@StandardReferences(
  [
    'OpenAPI Specification — REST API description',
    'Webhooks — HTTP callback delivery',
  ],
  'Describes third-party SMS, chat, and video conferencing communication providers.',
)
@SectionId('TPAIC')
class ThirdPartyApiIntegrationsCommunication {
  @Form([
    Field('smsProviders', String, 'SMS Providers',
        hint: 'Twilio, MessageBird, Vonage'),
    Field('chatIntegrations', String, 'Chat Integrations',
        hint: 'Slack, Teams, Telegram bots'),
    Field('videoConferencing', String, 'Video Conferencing',
        hint: 'Zoom, Teams, Jitsi APIs'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Mapping and location providers.
@StandardReferences(
  [
    'OpenAPI Specification — REST API description',
    'OAuth 2.0 / IETF RFC 6749 — authorization framework',
  ],
  'Describes third-party mapping and geocoding service providers the system consumes.',
)
@SectionId('TPAIL')
class ThirdPartyApiIntegrationsLocation {
  @Form([
    Field('mappingServices', String, 'Mapping Services',
        hint: 'Google Maps, Mapbox, HERE'),
    Field('geocodingServices', String, 'Geocoding Services',
        hint: 'Address validation and geocoding'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Document and media providers.
@StandardReferences(
  [
    'OpenAPI Specification — REST API description',
    'OAuth 2.0 / IETF RFC 6749 — authorization framework',
  ],
  'Describes third-party document generation, media processing, and OCR providers.',
)
@SectionId('TPAIM')
class ThirdPartyApiIntegrationsMedia {
  @Form([
    Field('documentGeneration', String, 'Document Generation',
        hint: 'PDF generation, document signing'),
    Field('mediaProcessing', String, 'Media Processing',
        hint: 'Image resizing, video transcoding'),
    Field('ocrServices', String, 'OCR Services',
        hint: 'Document scanning and text extraction'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// AI and translation providers.
@StandardReferences(
  [
    'OpenAPI Specification — REST API description',
    'OAuth 2.0 / IETF RFC 6749 — authorization framework',
  ],
  'Describes third-party AI/ML and translation service providers the system consumes.',
)
@SectionId('THPAAPINAI')
class ThirdPartyApiIntegrationsAi {
  @Form([
    Field('aiServices', String, 'AI/ML Services',
        hint: 'OpenAI, Claude, Bedrock, Vertex AI'),
    Field('translationServices', String, 'Translation Services',
        hint: 'Google Translate, DeepL'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance and fallback controls.
@StandardReferences(
  [
    'Circuit Breaker / Resilience patterns — fault tolerance',
    'OAuth 2.0 / IETF RFC 6749 — authorization framework',
  ],
  'Defines API key management, usage monitoring, and fallback strategy for third-party APIs.',
)
@SectionId('TPAIO')
class ThirdPartyApiIntegrationsOperations {
  @Form([
    Field('apiKeyManagement', String, 'API Key Management',
        hint: 'Storage, rotation, access control'),
    Field('usageMonitoring', String, 'Usage Monitoring',
        hint: 'Cost tracking per API'),
    Field('fallbackStrategy', String, 'Fallback Strategy',
        hint: 'Alternative when primary is unavailable'),
    Field('notes', String, 'Notes',
        hint: 'Additional third-party integration notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Network security and access control.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security controls',
    'API Gateway pattern — edge routing & policy enforcement',
  ],
  'Defines network security policy and access control for external connectivity.',
)
@SectionId('NESEPO')
class NetworkSecurityPolicy {
  @Form([
    Field('firewallType', String, 'Firewall Type',
        hint: 'WAF, network firewall, host-based'),
    Field('wafProvider', String, 'WAF Provider',
        hint: 'AWS WAF, Cloudflare, Azure Front Door'),
    Field('defaultDenyPolicy', bool, 'Default Deny Policy',
        hint: 'Deny all except explicit allow'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Firewall rule details.
  @SerializationOrder(1)
  NetworkSecurityPolicyFirewall firewall = NetworkSecurityPolicyFirewall();

  /// IP management controls.
  @SerializationOrder(2)
  NetworkSecurityPolicyIpManagement ipManagement =
      NetworkSecurityPolicyIpManagement();

  /// VPN configuration.
  @SerializationOrder(3)
  NetworkSecurityPolicyVpn vpn = NetworkSecurityPolicyVpn();

  /// DDoS protections.
  @SerializationOrder(4)
  NetworkSecurityPolicyDdos ddos = NetworkSecurityPolicyDdos();

  /// DNS controls and notes.
  @SerializationOrder(5)
  NetworkSecurityPolicyDns dns = NetworkSecurityPolicyDns();
}

/// Firewall rule details.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security controls',
  ],
  'Specifies ingress and egress firewall rules governing external traffic.',
)
@SectionId('NSPF')
class NetworkSecurityPolicyFirewall {
  @Form([
    Field('ingressRules', String, 'Ingress Rules',
        hint: 'Allowed inbound traffic rules'),
    Field('egressRules', String, 'Egress Rules',
        hint: 'Allowed outbound traffic rules'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// IP management controls.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security controls',
  ],
  'Defines IP allow-listing, deny-listing, and geo-blocking access controls.',
)
@SectionId('NSPIM')
class NetworkSecurityPolicyIpManagement {
  @Form([
    Field('staticIpRequired', bool, 'Static IP Required',
        hint: 'Fixed outbound IP addresses'),
    Field('ipAllowListing', String, 'IP Allow-Listing',
        hint: 'Inbound IP restrictions'),
    Field('ipDenyListing', String, 'IP Deny-Listing',
        hint: 'Blocked IP ranges'),
    Field('geoBlocking', String, 'Geo-Blocking',
        hint: 'Country or region-based access control'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// VPN configuration.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security controls',
    'IETF RFC 8446 — TLS 1.3',
  ],
  'Specifies VPN type, topology, and availability for secure external connectivity.',
)
@SectionId('NSPV')
class NetworkSecurityPolicyVpn {
  @Form([
    Field('vpnRequired', bool, 'VPN Required',
        hint: 'Site-to-site or client VPN'),
    Field('vpnType', String, 'VPN Type',
        hint: 'IPSec, WireGuard, OpenVPN, AWS Client VPN'),
    Field('vpnTopology', String, 'VPN Topology',
        hint: 'Hub-spoke, mesh, point-to-point'),
    Field('vpnHighAvailability', bool, 'VPN High Availability',
        hint: 'Redundant VPN tunnels'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// DDoS protections.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security controls',
    'API Gateway pattern — edge routing & policy enforcement',
  ],
  'Describes DDoS protection and edge rate limiting for external connectivity.',
)
@SectionId('NSPD')
class NetworkSecurityPolicyDdos {
  @Form([
    Field('ddosProtection', String, 'DDoS Protection',
        hint: 'AWS Shield, Cloudflare, Azure DDoS'),
    Field('rateLimitingAtEdge', String, 'Rate Limiting at Edge',
        hint: 'Edge-level request throttling'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// DNS controls and notes.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security controls',
  ],
  'Specifies DNS provider, DNSSEC, and private DNS controls for connectivity.',
)
@SectionId('NESEPODN')
class NetworkSecurityPolicyDns {
  @Form([
    Field('dnsProvider', String, 'DNS Provider',
        hint: 'Route 53, Cloudflare DNS, Azure DNS'),
    Field('dnssecEnabled', bool, 'DNSSEC Enabled',
        hint: 'DNS Security Extensions'),
    Field('privateDns', String, 'Private DNS',
        hint: 'Internal DNS zones'),
    Field('notes', String, 'Notes',
        hint: 'Additional network security notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Service mesh and API gateway.
@StandardReferences(
  [
    'API Gateway pattern — edge routing & policy enforcement',
    'Service Mesh (Istio / Envoy) — service-to-service traffic management',
    'OAuth 2.0 / IETF RFC 6749 — authorization framework',
  ],
  'Defines the API gateway and service mesh used for edge routing and traffic management.',
)
@SectionId('SMAG')
class ServiceMeshAndGateway {
  @Form([
    Field('apiGateway', String, 'API Gateway',
        hint: 'Kong, AWS API Gateway, Apigee, Azure APIM'),
    Field('gatewayFeatures', String, 'Gateway Features',
        hint: 'Auth, throttling, transformation, caching'),
    Field('gatewayHighAvailability', bool, 'Gateway High Availability',
        hint: 'Multi-region or multi-zone gateway'),
    Field('apiKeyManagement', String, 'API Key Management',
        hint: 'Developer portal, key provisioning'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Service mesh configuration.
  @SerializationOrder(1)
  ServiceMeshAndGatewayMesh mesh = ServiceMeshAndGatewayMesh();

  /// Load balancing and termination rules.
  @SerializationOrder(2)
  ServiceMeshAndGatewayLoadBalancing loadBalancing =
    ServiceMeshAndGatewayLoadBalancing();
}

/// Service mesh configuration.
@StandardReferences(
  [
    'Service Mesh (Istio / Envoy) — service-to-service traffic management',
    'IETF RFC 8446 — TLS 1.3',
  ],
  'Describes the service mesh, sidecar proxy, traffic policy, and mTLS configuration.',
)
@SectionId('SMAGM')
class ServiceMeshAndGatewayMesh {
  @Form([
  Field('serviceMesh', String, 'Service Mesh',
    hint: 'Istio, Linkerd, Consul Connect'),
  Field('sidecarProxy', String, 'Sidecar Proxy',
    hint: 'Envoy, HAProxy, custom'),
  Field('trafficPolicy', String, 'Traffic Policy',
    hint: 'Retries, timeouts, circuit breaking'),
  Field('mtlsEnabled', bool, 'mTLS Enabled',
    hint: 'Mutual TLS for internal traffic'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Load balancing and termination rules.
@StandardReferences(
  [
    'Service Mesh (Istio / Envoy) — service-to-service traffic management',
    'IETF RFC 8446 — TLS 1.3',
  ],
  'Specifies load balancing algorithms and SSL termination rules for traffic distribution.',
)
@SectionId('SMAGLB')
class ServiceMeshAndGatewayLoadBalancing {
  @Form([
  Field('loadBalancerType', String, 'Load Balancer Type',
    hint: 'Application LB, Network LB, internal'),
  Field('loadBalancingAlgorithm', String, 'Load Balancing Algorithm',
    hint: 'Round-robin, least-connections, weighted'),
  Field('healthCheckEndpoint', String, 'Health Check Endpoint',
    hint: 'LB health check path and interval'),
  Field('sslTermination', String, 'SSL Termination',
    hint: 'At load balancer, gateway, or application'),
  Field('notes', String, 'Notes',
    hint: 'Additional gateway/mesh notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Connectivity resilience requirements.
@StandardReferences(
  [
    'Circuit Breaker / Resilience patterns — fault tolerance',
    'Enterprise Integration Patterns — messaging & integration',
  ],
  'Captures failover, redundancy, and resilience requirements for external connectivity.',
)
@SectionId('CONRES')
class ConnectivityResilience {
  @Form([
    Field('failoverStrategy', String, 'Failover Strategy',
        hint: 'Active-passive, active-active, DNS failover'),
    Field('redundantConnections', bool, 'Redundant Connections',
        hint: 'Multiple ISP or network paths'),
    Field('geographicRedundancy', String, 'Geographic Redundancy',
        hint: 'Multi-region connectivity'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Circuit breaking and isolation strategy.
  @SerializationOrder(1)
  ConnectivityResilienceProtection protection =
    ConnectivityResilienceProtection();

  /// Offline and reconnection behavior.
  @SerializationOrder(2)
  ConnectivityResilienceOffline offline = ConnectivityResilienceOffline();

  /// Monitoring and alerting expectations.
  @SerializationOrder(3)
  ConnectivityResilienceOperations operations =
    ConnectivityResilienceOperations();
}

/// Circuit breaking and isolation strategy.
@StandardReferences(
  [
    'Circuit Breaker / Resilience patterns — fault tolerance',
  ],
  'Defines circuit breaking, bulkhead isolation, and fallback behavior for downstream failures.',
)
@SectionId('COREP1')
class ConnectivityResilienceProtection {
  @Form([
  Field('circuitBreakerPattern', String, 'Circuit Breaker Pattern',
    hint: 'Threshold, timeout, half-open criteria'),
  Field('bulkheadIsolation', String, 'Bulkhead Isolation',
    hint: 'Connection pool isolation per downstream'),
  Field('fallbackBehavior', String, 'Fallback Behavior',
    hint: 'Cached response, degraded mode, error page'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Offline and reconnection behavior.
@StandardReferences(
  [
    'Circuit Breaker / Resilience patterns — fault tolerance',
    'Enterprise Integration Patterns — messaging & integration',
  ],
  'Describes offline capability and reconnection behavior when connectivity is lost.',
)
@SectionId('COREOF')
class ConnectivityResilienceOffline {
  @Form([
  Field('offlineCapability', String, 'Offline Capability',
    hint: 'Client-side caching and sync strategy'),
  Field('reconnectionStrategy', String, 'Reconnection Strategy',
    hint: 'Automatic reconnect with backoff'),
  Field('queuedOperations', bool, 'Queued Operations',
    hint: 'Queue requests when connectivity lost'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Monitoring and alerting expectations.
@StandardReferences(
  [
    'Circuit Breaker / Resilience patterns — fault tolerance',
    'ISO/IEC 27001 — information security controls',
  ],
  'Defines monitoring and alerting expectations for external connectivity health.',
)
@SectionId('COREOP')
class ConnectivityResilienceOperations {
  @Form([
  Field('connectivityMonitoring', String, 'Connectivity Monitoring',
    hint: 'Uptime monitoring, latency checks'),
  Field('connectivityAlerts', String, 'Connectivity Alerts',
    hint: 'Alert on degradation or outage'),
  Field('notes', String, 'Notes',
    hint: 'Additional resilience notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 8.7. System Operation and Monitoring.
@StandardReferences(
  [
    'Google SRE — site reliability engineering practices',
    'ISO/IEC 20000 — IT service management system',
    'ITIL 4 — service operation and monitoring',
  ],
  'Defines runtime system operation and monitoring: administration, maintenance, health checks, alerting, metrics, dashboards, SLA/SLO tracking, and capacity planning.',
)
@DetailedIn(D06ArchitectureTechnologySpecification)
@SecondLevelSectionId(D06ArchitectureTechnologySpecification, 'ATS-SYS')
@ContentHelp('''
Define system operation, monitoring, and capacity planning requirements.
Day-to-day operations ensure the system runs reliably and efficiently.

**Subsections**:
- **System Operation**: Administration, maintenance procedures, user
  provisioning, configuration management
- **Monitoring**: Health checks, runtime alerting, metrics, dashboards,
  SLA/SLO tracking, on-call, incident management
- **Capacity Planning**: Growth projections, scaling triggers, resource
  baselines, capacity reviews

**Ownership boundary**: This section is the single owner of *runtime*
operational monitoring (runtime SRE). Release/DevOps deployment-pipeline
observability is owned by SBP.8.5 `OperationsRequirements`.

**Operational Excellence**:
- Runbook-driven operations
- Automation-first approach
- Self-healing capabilities
- Proactive problem detection
- Continuous improvement

**Key Operational Concerns**:
- System availability and uptime
- Performance and response times
- Resource utilization efficiency
- Security posture maintenance
- Compliance adherence

**Reference**: AWS Well-Architected Operational Excellence pillar,
Google SRE practices, Azure operational best practices.
''')
@SectionId('SOAM')
class SystemOperationAndMonitoring {
  @ContentHelp('''
Provide an overview of operational approach and responsibilities.

**Include**:
- Operational model (dedicated ops, DevOps, SRE)
- Key operational metrics and targets
- Automation and tooling strategy
- Team structure and responsibilities
- Continuous improvement process

**Best Practices**:
- Document everything in runbooks
- Automate repetitive tasks
- Implement comprehensive monitoring
- Practice incident response
- Regular operational reviews
''')
  @SerializationOrder(0)
  String? content;

  /// 8.7.1. System Operation.
  @SerializationOrder(1)
  SystemOperation systemOperation = SystemOperation();

  /// 8.7.2. Monitoring.
  @SerializationOrder(2)
  Monitoring monitoring = Monitoring();

  /// 8.7.3. Capacity Planning.
  @SerializationOrder(3)
  CapacityPlanningSection capacityPlanning = CapacityPlanningSection();
}

/// 8.7.1. System Operation.
@ContentHelp('''
Specify day-to-day system operation requirements including administration,
maintenance, and user management. Efficient operations reduce toil and
improve system reliability.

**Administration Areas**:
- System configuration management
- User provisioning and access control
- Service lifecycle management
- Log management and retention
- Secret and credential management

**Maintenance Procedures**:
- Routine maintenance tasks
- Patch management process
- Database maintenance (vacuuming, indexing)
- Storage management and cleanup
- Certificate and key rotation

**Operational Automation**:
- Infrastructure as Code
- Configuration management (Ansible, Chef, Puppet)
- Scheduled jobs and batch processing
- Auto-remediation and self-healing
- Chatops and operational bots

**Documentation Requirements**:
- Runbooks for common operations
- Troubleshooting guides
- Architecture documentation
- Change management records
- Incident postmortems
''')
@StandardReferences(
  [
    'Google SRE — eliminating toil and operational procedures',
    'AWS Well-Architected — operational excellence (runbooks, playbooks)',
  ],
  'System operation covers the day-to-day administration, maintenance, and user management the running system requires.',
)
@SectionId('SO')
class SystemOperation {
  @ContentHelp('''
Provide an overview of system operation approach.

**Include**:
- Key administrative functions
- Maintenance procedures summary
- Automation coverage and goals
- Documentation standards
- Operational team interfaces

**Best Practices**:
- Automate everything possible
- Create self-service capabilities
- Document procedures in runbooks
- Review and update procedures regularly
- Track operational metrics
''')
  @SerializationOrder(0)
  String? content;

  /// 8.7.1.1. Administration Requirements.
  @SerializationOrder(1)
  AdministrationRequirementsSection administrationRequirements =
      AdministrationRequirementsSection();

  /// Maintenance Procedures.
  @StandardReferences(
    ['ITIL 4 — change enablement and maintenance windows'],
    'The catalog of scheduled maintenance procedures the system requires.',
  )
  @SectionId('MAINT-MAIN-LST')
  @SectionIdPattern('MAINT-MAIN-xxx')
  @ContentHelp('Add one entry per maintenance procedure.')
  @SerializationOrder(2)
  List<MaintenanceProcedureEntry> maintenanceProcedures = [];
}

/// 8.7.1.1. Administration Requirements.
@ContentHelp('''
Specify system administration requirements including admin interfaces,
configuration management, and user provisioning. Good administration
tools reduce operational burden and error rates.

**Admin Interface Requirements**:
- Admin portal/dashboard functionality
- Role-based access for admin functions
- Audit logging of all admin actions
- Bulk operations and batch processing
- Search and reporting capabilities

**Configuration Management**:
- Centralized configuration store (Consul, etcd, Parameter Store)
- Environment-specific configurations
- Feature flags and toggles
- Dynamic configuration refresh
- Configuration versioning and rollback

**User Provisioning**:
- User lifecycle management (create, update, disable, delete)
- Role and permission assignment
- SCIM or directory synchronization
- Service account management
- Access review and certification

**Secrets Management**:
- Secrets storage (Vault, AWS Secrets Manager)
- Secret rotation automation
- Encryption key management
- Service-to-service credentials
- Developer access to secrets

**Batch Operations**:
- Batch user imports/exports
- Bulk data operations
- Scheduled maintenance scripts
- Report generation
''')
@StandardReferences(
  [
    'CIS Controls — secure configuration and administration',
    'ISO/IEC 27001 — operations security (A.12)',
  ],
  'Administration requirements define the admin interfaces, configuration management, and user provisioning the system needs.',
)
@SectionId('ARS')
class AdministrationRequirementsSection {
  @ContentHelp('''
Provide an overview of administration requirements.

**Include**:
- Admin interface scope and features
- Configuration management approach
- User provisioning workflow
- Secrets management strategy
- Admin team access model

**Best Practices**:
- Implement least-privilege admin access
- Audit all administrative actions
- Automate common admin tasks
- Provide self-service where safe
- Regular admin access reviews
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of administration requirements.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Admin interface requirements.
  @SerializationOrder(2)
  AdminInterfaceRequirements adminInterface = AdminInterfaceRequirements();

  /// Configuration management.
  @SerializationOrder(3)
  SystemConfigurationManagement configurationManagement =
      SystemConfigurationManagement();

  /// User provisioning and management tools.
  @SerializationOrder(4)
  UserProvisioningTools userProvisioning = UserProvisioningTools();

  /// Batch job management.
  @SerializationOrder(5)
  BatchJobManagement batchJobs = BatchJobManagement();

  /// Environment management.
  @SerializationOrder(6)
  AdminEnvironmentManagement environmentManagement =
      AdminEnvironmentManagement();

  /// System diagnostic tools.
  @SerializationOrder(7)
  SystemDiagnosticTools diagnosticTools = SystemDiagnosticTools();
}

/// Admin interface requirements.
@StandardReferences(
  [
    'CIS Controls — secure configuration and administration',
    'AWS Well-Architected — operational excellence (runbooks, playbooks)',
  ],
  'Admin interface requirements describe the portal through which operators manage the system.',
)
@SectionId('ADINRE')
class AdminInterfaceRequirements {
  @Form([
    Field('adminPortalType', String, 'Admin Portal Type',
        required: true, hint: 'Web dashboard, CLI, API, mobile'),
    Field('adminPortalUrl', String, 'Admin Portal URL',
        hint: 'Dedicated admin subdomain or path'),
    Field('accessRestriction', String, 'Access Restriction',
        hint: 'VPN-only, IP-restricted, MFA-required'),
    Field('authenticationMethod', String, 'Authentication Method',
        hint: 'SSO, LDAP, local credentials'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Dashboard widget requirements.
  @SerializationOrder(1)
  AdminInterfaceRequirementsDashboard dashboard =
      AdminInterfaceRequirementsDashboard();

  /// Data management tooling.
  @SerializationOrder(2)
  AdminInterfaceRequirementsData data = AdminInterfaceRequirementsData();

  /// Operational controls.
  @SerializationOrder(3)
  AdminInterfaceRequirementsOperations operations =
      AdminInterfaceRequirementsOperations();
}

/// Dashboard widget requirements.
@StandardReferences(
  [
    'AWS Well-Architected — operational excellence (runbooks, playbooks)',
    'Google SRE — eliminating toil and operational procedures',
  ],
  'Dashboard widget requirements define the at-a-glance status widgets on the admin landing page.',
)
@SectionId('AIRD')
class AdminInterfaceRequirementsDashboard {
  @Form([
    Field('dashboardOverview', String, 'Dashboard Overview',
        hint: 'Key metrics displayed on landing page'),
    Field('systemHealthWidget', bool, 'System Health Widget',
        hint: 'Real-time system status indicator'),
    Field('activeUsersWidget', bool, 'Active Users Widget',
        hint: 'Current active user count'),
    Field('alertsSummaryWidget', bool, 'Alerts Summary Widget',
        hint: 'Recent alerts and warnings'),
    Field('resourceUsageWidget', bool, 'Resource Usage Widget',
        hint: 'CPU, memory, storage gauges'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data management tooling.
@StandardReferences(
  [
    'CIS Controls — secure configuration and administration',
    'ISO/IEC 27001 — operations security (A.12)',
  ],
  'Data management tooling provides import, export, search, and audit-log viewing for administrators.',
)
@SectionId('ADINREDA')
class AdminInterfaceRequirementsData {
  @Form([
    Field('dataExport', String, 'Data Export',
        hint: 'Export formats (CSV, JSON, PDF)'),
    Field('dataImport', String, 'Data Import',
        hint: 'Bulk import capabilities'),
    Field('searchAndFiltering', String, 'Search and Filtering',
        hint: 'Global search, advanced filters'),
    Field('auditLogViewer', bool, 'Audit Log Viewer',
        hint: 'View admin action audit trail'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Operational controls.
@StandardReferences(
  [
    'AWS Well-Architected — operational excellence (runbooks, playbooks)',
    'Google SRE — eliminating toil and operational procedures',
  ],
  'Operational controls let administrators toggle maintenance mode, feature flags, and caches.',
)
@SectionId('AIRO')
class AdminInterfaceRequirementsOperations {
  @Form([
    Field('maintenanceModeToggle', bool, 'Maintenance Mode Toggle',
        hint: 'Enable/disable maintenance mode'),
    Field('featureFlagManagement', bool, 'Feature Flag Management',
        hint: 'Toggle feature flags from admin'),
    Field('cacheManagement', bool, 'Cache Management',
        hint: 'Clear or invalidate caches'),
    Field('notes', String, 'Notes',
        hint: 'Additional admin interface notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// System configuration management.
@StandardReferences(
  [
    'ITIL 4 — service configuration management practice',
    'ISO/IEC 20000 — configuration and change management',
  ],
  'System configuration management specifies how the system stores and controls its configuration.',
)
@SectionId('SYCOMA')
class SystemConfigurationManagement {
  @Form([
    // Configuration sources
    Field('configurationSource', String, 'Configuration Source',
        required: true, hint: 'Environment variables, config files, vault'),
    Field('configurationFormat', String, 'Configuration Format',
        hint: 'YAML, JSON, TOML, properties'),
    Field('centralConfigService', String, 'Central Config Service',
        hint: 'Consul, Spring Cloud Config, AWS AppConfig'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Dynamic configuration and rollback behavior.
  @SerializationOrder(1)
  SystemConfigurationManagementDynamic dynamic =
    SystemConfigurationManagementDynamic();

  /// Environment overrides and secrets handling.
  @SerializationOrder(2)
  SystemConfigurationManagementEnvironment environment =
    SystemConfigurationManagementEnvironment();

  /// Validation, diffing, and audit controls.
  @SerializationOrder(3)
  SystemConfigurationManagementGovernance governance =
    SystemConfigurationManagementGovernance();
}

/// Dynamic configuration and rollback behavior.
@StandardReferences(
  [
    'ISO/IEC 20000 — configuration and change management',
    'ITIL 4 — change enablement and maintenance windows',
  ],
  'Dynamic configuration and rollback behavior describe how config changes are applied live and reverted.',
)
@SectionId('SCMD')
class SystemConfigurationManagementDynamic {
  @Form([
  Field('dynamicConfiguration', bool, 'Dynamic Configuration',
    hint: 'Change config without restart'),
  Field('hotReloadSupport', bool, 'Hot Reload Support',
    hint: 'Apply config changes live'),
  Field('configVersioning', bool, 'Config Versioning',
    hint: 'Track configuration history'),
  Field('configRollback', bool, 'Config Rollback',
    hint: 'Revert to previous configuration'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Environment overrides and secrets handling.
@StandardReferences(
  [
    'CIS Controls — secure configuration and administration',
    'ISO/IEC 27001 — operations security (A.12)',
  ],
  'Environment overrides and secrets handling govern per-environment configuration and credential storage.',
)
@SectionId('SCME')
class SystemConfigurationManagementEnvironment {
  @Form([
  Field('environmentOverrides', String, 'Environment Overrides',
    hint: 'Per-environment config layering'),
  Field('secretsManagement', String, 'Secrets Management',
    hint: 'Vault, AWS Secrets Manager, Azure Key Vault'),
  Field('secretRotation', bool, 'Secret Rotation',
    hint: 'Automated secret rotation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Validation, diffing, and audit controls.
@StandardReferences(
  [
    'ISO/IEC 20000 — configuration and change management',
    'ITIL 4 — service configuration management practice',
  ],
  'Validation, diffing, and audit controls ensure configuration changes are checked and traceable.',
)
@SectionId('SCMG')
class SystemConfigurationManagementGovernance {
  @Form([
  Field('configValidation', String, 'Config Validation',
    hint: 'Schema validation before deploy'),
  Field('configDiffing', bool, 'Config Diffing',
    hint: 'Compare configurations across envs'),
  Field('configAuditTrail', bool, 'Config Audit Trail',
    hint: 'Log who changed what and when'),
  Field('notes', String, 'Notes',
    hint: 'Additional configuration management notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// User provisioning and management tools.
@StandardReferences(
  [
    'CIS Controls — secure configuration and administration',
    'ISO/IEC 27001 — operations security (A.12)',
  ],
  'User provisioning and management tools cover how user accounts are created and managed across their lifecycle.',
)
@SectionId('USPRTO')
class UserProvisioningTools {
  @Form([
    Field('provisioningMethod', String, 'Provisioning Method',
        required: true, hint: 'Manual, SCIM, LDAP sync, JIT provisioning'),
    Field('bulkProvisioning', bool, 'Bulk Provisioning',
        hint: 'Import users via CSV/file upload'),
    Field('selfServiceRegistration', bool, 'Self-Service Registration',
        hint: 'Users can create own accounts'),
    Field('invitationWorkflow', bool, 'Invitation Workflow',
        hint: 'Invite users via email'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Account lifecycle management.
  @SerializationOrder(1)
  UserProvisioningToolsLifecycle lifecycle = UserProvisioningToolsLifecycle();

  /// Role management and reviews.
  @SerializationOrder(2)
  UserProvisioningToolsRoleManagement roleManagement =
      UserProvisioningToolsRoleManagement();

  /// Directory integration settings.
  @SerializationOrder(3)
  UserProvisioningToolsDirectoryIntegration directoryIntegration =
      UserProvisioningToolsDirectoryIntegration();
}

/// Account lifecycle management.
@StandardReferences(
  [
    'CIS Controls — secure configuration and administration',
    'ISO/IEC 27001 — operations security (A.12)',
  ],
  'Account lifecycle management defines how user accounts are activated, suspended, and offboarded.',
)
@SectionId('UPTL')
class UserProvisioningToolsLifecycle {
  @Form([
    Field('accountActivation', String, 'Account Activation',
        hint: 'Email verification, admin approval'),
    Field('accountDeactivation', String, 'Account Deactivation',
        hint: 'Soft delete, hard delete, disable'),
    Field('accountSuspension', bool, 'Account Suspension',
        hint: 'Temporary account suspension'),
    Field('inactivityPolicy', String, 'Inactivity Policy',
        hint: 'Auto-disable after N days of inactivity'),
    Field('offboardingProcess', String, 'Offboarding Process',
        hint: 'Data transfer, access revocation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Role management and reviews.
@StandardReferences(
  [
    'CIS Controls — secure configuration and administration',
    'ISO/IEC 27001 — operations security (A.12)',
  ],
  'Role management and reviews control how roles are assigned and periodically recertified.',
)
@SectionId('UPTRM')
class UserProvisioningToolsRoleManagement {
  @Form([
    Field('roleAssignment', String, 'Role Assignment',
        hint: 'Manual, rule-based, request-approval'),
    Field('delegatedAdministration', bool, 'Delegated Administration',
        hint: 'Department admins manage own users'),
    Field('accessReviewProcess', String, 'Access Review Process',
        hint: 'Periodic access recertification'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Directory integration settings.
@StandardReferences(
  [
    'CIS Controls — secure configuration and administration',
    'ISO/IEC 27001 — operations security (A.12)',
  ],
  'Directory integration settings govern how user accounts synchronize with an external directory.',
)
@SectionId('UPTDI')
class UserProvisioningToolsDirectoryIntegration {
  @Form([
    Field('directoryIntegration', String, 'Directory Integration',
        hint: 'Active Directory, Azure AD, LDAP'),
    Field('syncFrequency', String, 'Sync Frequency',
        hint: 'Real-time, hourly, daily'),
    Field('conflictResolution', String, 'Conflict Resolution',
        hint: 'Source of truth for conflicts'),
    Field('notes', String, 'Notes',
        hint: 'Additional user provisioning notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Batch job management.
@StandardReferences(
  [
    'Google SRE — eliminating toil and operational procedures',
    'AWS Well-Architected — operational excellence (runbooks, playbooks)',
  ],
  'Batch job management specifies how scheduled and background jobs are defined and operated.',
)
@SectionId('BAJOMA')
class BatchJobManagement {
  @Form([
    Field('schedulingEngine', String, 'Scheduling Engine',
        required: true, hint: 'Cron, Quartz, cloud scheduler, Airflow'),
    Field('scheduleDefinition', String, 'Schedule Definition',
        hint: 'Cron expression, calendar-based, event-driven'),
    Field('timeZoneHandling', String, 'Time Zone Handling',
        hint: 'UTC, local, configurable per job'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Supported job categories.
  @SerializationOrder(1)
  BatchJobManagementJobTypes jobTypes = BatchJobManagementJobTypes();

  /// Execution controls.
  @SerializationOrder(2)
  BatchJobManagementExecution execution = BatchJobManagementExecution();

  /// Monitoring and manual controls.
  @SerializationOrder(3)
  BatchJobManagementMonitoring monitoring = BatchJobManagementMonitoring();
}

/// Supported job categories.
@StandardReferences(
  [
    'Google SRE — eliminating toil and operational procedures',
    'ITIL 4 — change enablement and maintenance windows',
  ],
  'Supported job categories catalog the kinds of scheduled work the system performs.',
)
@SectionId('BJMJT')
class BatchJobManagementJobTypes {
  @Form([
    Field('dataProcessingJobs', String, 'Data Processing Jobs',
        hint: 'ETL, aggregation, cleanup'),
    Field('reportGenerationJobs', String, 'Report Generation Jobs',
        hint: 'Scheduled report creation'),
    Field('notificationJobs', String, 'Notification Jobs',
        hint: 'Digest emails, reminder notifications'),
    Field('maintenanceJobs', String, 'Maintenance Jobs',
        hint: 'Database cleanup, log rotation, temp file purge'),
    Field('integrationSyncJobs', String, 'Integration Sync Jobs',
        hint: 'External system synchronization'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Execution controls.
@StandardReferences(
  [
    'Google SRE — eliminating toil and operational procedures',
    'AWS Well-Architected — operational excellence (runbooks, playbooks)',
  ],
  'Execution controls define how batch jobs run, retry, and enforce timeouts.',
)
@SectionId('BJME')
class BatchJobManagementExecution {
  @Form([
    Field('concurrencyControl', String, 'Concurrency Control',
        hint: 'Max parallel jobs, queue depth'),
    Field('priorityLevels', String, 'Priority Levels',
        hint: 'Job priority classification'),
    Field('retryPolicy', String, 'Retry Policy',
        hint: 'Retry count, backoff, dead-letter'),
    Field('idempotency', bool, 'Idempotency',
        hint: 'Safe to re-run on failure'),
    Field('timeout', String, 'Timeout',
        hint: 'Maximum job execution time'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Monitoring and manual controls.
@StandardReferences(
  [
    'AWS Well-Architected — operational excellence (runbooks, playbooks)',
    'Google SRE — eliminating toil and operational procedures',
  ],
  'Monitoring and manual controls track batch job health and allow operators to intervene.',
)
@SectionId('BJMM')
class BatchJobManagementMonitoring {
  @Form([
    Field('jobDashboard', bool, 'Job Dashboard',
        hint: 'Visual job status overview'),
    Field('executionHistory', bool, 'Execution History',
        hint: 'Job run history and logs'),
    Field('failureAlerts', String, 'Failure Alerts',
        hint: 'Notification on job failure'),
    Field('slaMonitoring', String, 'SLA Monitoring',
        hint: 'Alert if job exceeds expected duration'),
    Field('manualTrigger', bool, 'Manual Trigger',
        hint: 'Admin can trigger jobs on demand'),
    Field('notes', String, 'Notes',
        hint: 'Additional batch job notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Administration environment management.
@StandardReferences(
  [
    'ITIL 4 — service configuration management practice',
    'AWS Well-Architected — operational excellence (runbooks, playbooks)',
  ],
  'Administration environment management governs how environments are provisioned, seeded, and accessed.',
)
@SectionId('ADENMA')
class AdminEnvironmentManagement {
  @Form([
    // Environments
    Field('environmentCatalog', String, 'Environment Catalog',
        hint: 'List of managed environments'),
    Field('environmentProvisioning', String, 'Environment Provisioning',
        hint: 'Automated, on-demand, scheduled'),
    Field('environmentCloning', bool, 'Environment Cloning',
        hint: 'Clone environment for testing'),

    // Data management
    Field('dataSeeding', String, 'Data Seeding',
        hint: 'Seed data for non-production envs'),
    Field('dataAnonymization', bool, 'Data Anonymization',
        hint: 'Anonymize production data for dev/test'),
    Field('dataSyncBetweenEnvs', String, 'Data Sync Between Envs',
        hint: 'Selective data promotion'),

    // Access
    Field('environmentAccessControl', String, 'Environment Access Control',
        hint: 'Who can access which environment'),
    Field('productionAccessPolicy', String, 'Production Access Policy',
        hint: 'Break-glass, approval workflow'),
    Field('environmentVariableManagement', String, 'Env Variable Management',
        hint: 'Per-env variable sets'),
    Field('notes', String, 'Notes',
        hint: 'Additional environment management notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// System diagnostic tools.
@StandardReferences(
  [
    'AWS Well-Architected — operational excellence (runbooks, playbooks)',
    'Google SRE — eliminating toil and operational procedures',
  ],
  'System diagnostic tools give operators the means to inspect and troubleshoot the running system.',
)
@SectionId('SYDITO')
class SystemDiagnosticTools {
  @Form([
    Field('remoteDebugging', bool, 'Remote Debugging',
        hint: 'Attach debugger to running service'),
    Field('profiling', String, 'Profiling',
        hint: 'CPU, memory, I/O profiling tools'),
    Field('threadDumpCapability', bool, 'Thread Dump Capability',
        hint: 'Capture thread/goroutine dumps'),
    Field('heapDumpCapability', bool, 'Heap Dump Capability',
        hint: 'Capture memory heap dumps'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Trace and dependency inspection tools.
  @SerializationOrder(1)
  SystemDiagnosticToolsTracing tracing = SystemDiagnosticToolsTracing();

  /// Log analysis capabilities.
  @SerializationOrder(2)
  SystemDiagnosticToolsLogs logs = SystemDiagnosticToolsLogs();

  /// Self-service diagnostic entry points.
  @SerializationOrder(3)
  SystemDiagnosticToolsSelfService selfService =
    SystemDiagnosticToolsSelfService();
}

/// Trace and dependency inspection tools.
@StandardReferences(
  [
    'AWS Well-Architected — operational excellence (runbooks, playbooks)',
    'Google SRE — eliminating toil and operational procedures',
  ],
  'Trace and dependency inspection tools reveal how requests flow across services.',
)
@SectionId('SDTT')
class SystemDiagnosticToolsTracing {
  @Form([
  Field('requestTracing', String, 'Request Tracing',
    hint: 'End-to-end request trace viewer'),
  Field('slowQueryAnalysis', bool, 'Slow Query Analysis',
    hint: 'Identify slow database queries'),
  Field('dependencyMapping', bool, 'Dependency Mapping',
    hint: 'Visualize service dependencies'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Log analysis capabilities.
@StandardReferences(
  [
    'ISO/IEC 27001 — operations security (A.12)',
    'AWS Well-Architected — operational excellence (runbooks, playbooks)',
  ],
  'Log analysis capabilities let operators search and correlate log data during diagnosis.',
)
@SectionId('SDTL')
class SystemDiagnosticToolsLogs {
  @Form([
  Field('logAggregation', String, 'Log Aggregation',
    hint: 'ELK, Loki, CloudWatch Logs'),
  Field('logSearchCapability', String, 'Log Search',
    hint: 'Full-text search across logs'),
  Field('correlatedLogView', bool, 'Correlated Log View',
    hint: 'View logs across services by trace ID'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Self-service diagnostic entry points.
@StandardReferences(
  [
    'AWS Well-Architected — operational excellence (runbooks, playbooks)',
    'Google SRE — eliminating toil and operational procedures',
  ],
  'Self-service diagnostic entry points let operators inspect the system without escalation.',
)
@SectionId('SDTSS')
class SystemDiagnosticToolsSelfService {
  @Form([
  Field('adminDiagnosticEndpoints', String, 'Diagnostic Endpoints',
    hint: '/info, /env, /metrics endpoints'),
  Field('databaseQueryConsole', bool, 'Database Query Console',
    hint: 'Read-only query interface for admins'),
  Field('notes', String, 'Notes',
    hint: 'Additional diagnostic tool notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 8.7.2. Monitoring.
///
/// Comprehensive monitoring specification covering health checks, alerting,
/// observability, dashboards, and SLA/SLO tracking.
@StandardReferences(
  [
    'Google SRE — monitoring and alerting (the four golden signals)',
    'OpenTelemetry — observability signals',
    'ITIL 4 — monitoring and event management practice',
  ],
  'The overall monitoring approach spanning health, alerting, and observability.',
)
@SectionId('MONITO')
class Monitoring {
  // ─────────────────────────────────────────────────────────────────────────
  // Monitoring Overview
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    // Strategy
    Field('monitoringStrategy', String, 'Monitoring Strategy',
        hint: 'Proactive, reactive, hybrid approach'),
    Field('observabilityMaturity', String, 'Observability Maturity',
        hint: 'Current maturity level (L1-L4)'),
    Field('monitoringScope', String, 'Monitoring Scope',
        hint: 'Infrastructure, application, business metrics'),
    // Tools
    Field('primaryMonitoringPlatform', String, 'Primary Monitoring Platform',
        hint: 'Datadog, New Relic, Prometheus, CloudWatch'),
    Field('metricsStore', String, 'Metrics Store',
        hint: 'InfluxDB, Prometheus, CloudWatch Metrics'),
    Field('tracingPlatform', String, 'Tracing Platform',
        hint: 'Jaeger, Zipkin, AWS X-Ray, Datadog APM'),
    Field('loggingPlatform', String, 'Logging Platform',
        hint: 'ELK Stack, Loki, CloudWatch Logs'),
    // Coverage
    Field('coverageRequirement', String, 'Coverage Requirement',
        hint: 'Which services must be monitored'),
    Field('dataRetention', String, 'Data Retention',
        hint: 'Metrics: 15d, traces: 7d, logs: 30d'),
    Field('costBudget', String, 'Cost Budget',
        hint: 'Monthly monitoring cost budget'),
  ])
  @SerializationOrder(0)
  String? monitoringOverview;

  /// Monitoring strategy narrative.
  @ContentHelp('Executive summary of monitoring philosophy, tool '
      'selection rationale, and observability goals.')
  @SerializationOrder(1)
  TextSection overviewNarrative = TextSection();

  /// 8.7.2.1. Health Checks and Diagnostics.
  @SerializationOrder(2)
  HealthChecksAndDiagnosticsSection healthChecksAndDiagnostics =
      HealthChecksAndDiagnosticsSection();

  /// 8.7.2.2. Alerting Configuration.
  @SerializationOrder(3)
  AlertingConfiguration alertingConfiguration = AlertingConfiguration();

  /// 8.7.2.3. Metrics and Observability.
  @SerializationOrder(4)
  MetricsAndObservability metricsAndObservability = MetricsAndObservability();

  /// 8.7.2.4. Monitoring Dashboards.
  @SerializationOrder(5)
  MonitoringDashboards dashboards = MonitoringDashboards();

  /// 8.7.2.5. SLA and SLO Monitoring.
  @SerializationOrder(6)
  SlaAndSloMonitoring slaAndSloMonitoring = SlaAndSloMonitoring();
}

// ---------------------------------------------------------------------------
// 8.7.2.2 Alerting Configuration
// ---------------------------------------------------------------------------

/// 8.7.2.2. Alerting Configuration.
///
/// Comprehensive alerting rules, notification channels, and escalation
/// policies.
@StandardReferences(
  [
    'Google SRE — monitoring and alerting (the four golden signals)',
    'Prometheus — Alertmanager (routing, grouping, silencing)',
    'Google SRE — being on-call and incident response',
  ],
  'The full alerting configuration covering rules, channels, and escalation.',
)
@SectionId('ALCO')
class AlertingConfiguration {
  // ─────────────────────────────────────────────────────────────────────────
  // Alerting Overview
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    // Philosophy
    Field('alertingPhilosophy', String, 'Alerting Philosophy',
        hint: 'Page on symptoms, not causes; reduce noise'),
    Field('alertSeverityLevels', String, 'Alert Severity Levels',
        hint: 'Critical, Warning, Info'),
    Field('onCallModel', String, 'On-Call Model',
        hint: 'Follow-the-sun, regional, single team'),
    // Response expectations
    Field('criticalResponseTime', String, 'Critical Response Time',
        hint: 'Max time to acknowledge critical alerts'),
    Field('warningResponseTime', String, 'Warning Response Time',
        hint: 'Max time to acknowledge warnings'),
    Field('infoResponseTime', String, 'Info Response Time',
        hint: 'Expected review time for info alerts'),
    // Alert hygiene
    Field('alertReviewCadence', String, 'Alert Review Cadence',
        hint: 'How often alert rules are reviewed'),
    Field('noisyAlertPolicy', String, 'Noisy Alert Policy',
        hint: 'Process for tuning noisy alerts'),
    Field('staleAlertCleanup', String, 'Stale Alert Cleanup',
        hint: 'Removing outdated alert rules'),
  ])
  @SerializationOrder(0)
  String? alertingOverview;

  /// Alerting overview narrative.
  @SerializationOrder(1)
  TextSection overviewNarrative = TextSection();

  /// Notification channels.
  @SerializationOrder(2)
  AlertNotificationChannels notificationChannels = AlertNotificationChannels();

  /// Alert rules catalog.
  @StandardReferences(
    ['Prometheus — Alertmanager (routing, grouping, silencing)'],
    'The catalog of alert rules the system evaluates.',
  )
  @SectionId('ALRUEN-ALER-LST')
  @SectionIdPattern('ALRUEN-ALER-xxx')
  @ContentHelp('Add one entry per alert rule.')
  @SerializationOrder(3)
  List<AlertRuleEntry> alertRules = [];

  /// Escalation policies.
  @SerializationOrder(4)
  AlertEscalationPolicies escalationPolicies = AlertEscalationPolicies();

  /// Alert suppression and maintenance windows.
  @StandardReferences(
    ['Prometheus — Alertmanager (routing, grouping, silencing)'],
    'The catalog of alert suppression and maintenance window rules.',
  )
  @SectionId('ALSURU-SUPP-LST')
  @SectionIdPattern('ALSURU-SUPP-xxx')
  @ContentHelp('Add one entry per suppression or maintenance window.')
  @SerializationOrder(5)
  List<AlertSuppressionRules> suppressionRules = [];

  /// On-call schedule.
  @SerializationOrder(6)
  OnCallScheduleConfig onCallSchedule = OnCallScheduleConfig();
}

/// Alert notification channels.
@StandardReferences(
  [
    'Prometheus — Alertmanager (routing, grouping, silencing)',
    'Google SRE — being on-call and incident response',
  ],
  'The channels through which alerts reach responders.',
)
@SectionId('ALNOCH')
class AlertNotificationChannels {
  @Form([
    // Primary channels
    Field('pagingService', String, 'Paging Service',
        hint: 'PagerDuty, Opsgenie, VictorOps'),
    Field('slackIntegration', String, 'Slack Integration',
        hint: 'Channel for alerts (#alerts, #incidents)'),
    Field('teamsIntegration', String, 'Teams Integration',
        hint: 'Microsoft Teams channel integration'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Secondary and escalation delivery methods.
  @SerializationOrder(1)
  AlertNotificationChannelsDelivery delivery =
    AlertNotificationChannelsDelivery();

  /// Severity-based channel routing.
  @SerializationOrder(2)
  AlertNotificationChannelsRouting routing =
    AlertNotificationChannelsRouting();

  /// Message templates, enrichment, and grouping rules.
  @SerializationOrder(3)
  AlertNotificationChannelsFormatting formatting =
    AlertNotificationChannelsFormatting();
}

/// Secondary and escalation delivery methods.
@StandardReferences(
  [
    'PagerDuty / on-call — escalation policy design',
    'Google SRE — being on-call and incident response',
  ],
  'The secondary email, SMS, and voice delivery methods for alerts.',
)
@SectionId('ANCD')
class AlertNotificationChannelsDelivery {
  @Form([
  Field('emailNotification', String, 'Email Notification',
    hint: 'Email distribution lists for alerts'),
  Field('smsNotification', String, 'SMS Notification',
    hint: 'SMS/text for critical alerts'),
  Field('phoneCallEscalation', String, 'Phone Call Escalation',
    hint: 'Voice call for unacknowledged criticals'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Severity-based channel routing.
@StandardReferences(
  [
    'Prometheus — Alertmanager (routing, grouping, silencing)',
    'ITIL 4 — monitoring and event management practice',
  ],
  'How alerts route to channels based on their severity level.',
)
@SectionId('ANCR')
class AlertNotificationChannelsRouting {
  @Form([
  Field('criticalAlertChannels', String, 'Critical Alert Channels',
    hint: 'Where critical alerts are sent'),
  Field('warningAlertChannels', String, 'Warning Alert Channels',
    hint: 'Where warning alerts are sent'),
  Field('infoAlertChannels', String, 'Info Alert Channels',
    hint: 'Where info alerts are sent'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Message templates, enrichment, and grouping rules.
@StandardReferences(
  [
    'Prometheus — Alertmanager (routing, grouping, silencing)',
    'Google SRE — monitoring and alerting (the four golden signals)',
  ],
  'How alert messages are formatted, enriched, deduplicated, and grouped.',
)
@SectionId('ANCF')
class AlertNotificationChannelsFormatting {
  @Form([
  Field('alertMessageFormat', String, 'Alert Message Format',
    hint: 'Template for alert notification content'),
  Field('enrichmentData', String, 'Enrichment Data',
    hint: 'Runbook links, dashboard links, context'),
  Field('deduplication', String, 'Deduplication',
    hint: 'How duplicate alerts are suppressed'),
  Field('groupingRules', String, 'Grouping Rules',
    hint: 'How related alerts are grouped'),
  Field('notes', String, 'Notes', hint: 'Additional formatting notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// An alert rule entry.
@StandardReferences(
  [
    'Google SRE — monitoring and alerting (the four golden signals)',
    'Prometheus — Alertmanager (routing, grouping, silencing)',
  ],
  'A single alert rule defining when and how the system pages responders.',
)
@SectionId('ALERULENT')
class AlertRuleEntry {
  @Form([
    Field('alertId', String, 'Alert ID', required: true,
        hint: 'Unique identifier for this alert rule'),
    Field('alertName', String, 'Alert Name', required: true,
        hint: 'Human-readable name for this alert'),
    Field('alertDescription', String, 'Alert Description',
        hint: 'What this alert detects and why it matters'),
    Field('severity', String, 'Severity',
        hint: 'Critical, Warning, Info'),
    Field('category', String, 'Category',
        hint: 'Infrastructure, Application, Business, Security'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Trigger conditions.
  @SerializationOrder(1)
  AlertRuleEntryTrigger trigger = AlertRuleEntryTrigger();

  /// Response actions.
  @SerializationOrder(2)
  AlertRuleEntryResponse response = AlertRuleEntryResponse();

  /// Ownership details.
  @SerializationOrder(3)
  AlertRuleEntryOwnership ownership = AlertRuleEntryOwnership();
}

/// Trigger conditions.
@StandardReferences(
  [
    'Google SRE — monitoring and alerting (the four golden signals)',
    'Prometheus — Alertmanager (routing, grouping, silencing)',
  ],
  'The metric, threshold, and window conditions that trigger this alert.',
)
@SectionId('ARET')
class AlertRuleEntryTrigger {
  @Form([
    Field('metricOrCondition', String, 'Metric/Condition',
        hint: 'What triggers this alert'),
    Field('threshold', String, 'Threshold',
        hint: 'Threshold value(s) for triggering'),
    Field('evaluationWindow', String, 'Evaluation Window',
        hint: 'Time window for condition evaluation'),
    Field('requiredOccurrences', String, 'Required Occurrences',
        hint: 'N of M before alerting'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Response actions.
@StandardReferences(
  [
    'Google SRE — being on-call and incident response',
    'Prometheus — Alertmanager (routing, grouping, silencing)',
  ],
  'The notification, runbook, and remediation actions taken when the alert fires.',
)
@SectionId('ARER')
class AlertRuleEntryResponse {
  @Form([
    Field('notificationChannels', String, 'Notification Channels',
        hint: 'Where alert is sent'),
    Field('runbookLink', String, 'Runbook Link',
        hint: 'Link to troubleshooting runbook'),
    Field('escalationPolicy', String, 'Escalation Policy',
        hint: 'Which escalation policy applies'),
    Field('autoRemediation', String, 'Auto-Remediation',
        hint: 'Automatic remediation action if any'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Ownership details.
@StandardReferences(
  [
    'Google SRE — being on-call and incident response',
    'ITIL 4 — monitoring and event management practice',
  ],
  'Which team and contact own responses to this alert rule.',
)
@SectionId('AREO')
class AlertRuleEntryOwnership {
  @Form([
    Field('ownerTeam', String, 'Owner Team',
        hint: 'Team that owns this alert rule'),
    Field('primaryContact', String, 'Primary Contact',
        hint: 'Primary contact for this alert'),
    Field('notes', String, 'Notes', hint: 'Additional ownership notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Alert escalation policies.
@StandardReferences(
  [
    'PagerDuty / on-call — escalation policy design',
    'Google SRE — being on-call and incident response',
  ],
  'How unacknowledged alerts escalate through responder levels.',
)
@SectionId('ALESPO')
class AlertEscalationPolicies {
  @Form([
    // Escalation levels
    Field('level1Responder', String, 'Level 1 Responder',
        hint: 'Primary on-call, response time'),
    Field('level2Responder', String, 'Level 2 Responder',
        hint: 'Escalation if L1 no response'),
    Field('level3Responder', String, 'Level 3 Responder',
        hint: 'Senior engineer/architect escalation'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Management escalation path and timing thresholds.
  @SerializationOrder(1)
  AlertEscalationPoliciesTiming timing = AlertEscalationPoliciesTiming();

  /// Escalation control behavior.
  @SerializationOrder(2)
  AlertEscalationPoliciesBehavior behavior =
    AlertEscalationPoliciesBehavior();

  /// Schedule-specific policy variants.
  @SerializationOrder(3)
  AlertEscalationPoliciesSchedules schedules =
    AlertEscalationPoliciesSchedules();
}

/// Management escalation path and timing thresholds.
@StandardReferences(
  [
    'PagerDuty / on-call — escalation policy design',
    'ISO/IEC 20000 — incident and service request management',
  ],
  'The timing thresholds that govern when alerts escalate between levels.',
)
@SectionId('AEPT')
class AlertEscalationPoliciesTiming {
  @Form([
  Field('managementEscalation', String, 'Management Escalation',
    hint: 'When to escalate to management'),
  Field('level1ToLevel2Time', String, 'L1 to L2 Time',
    hint: 'Time before escalating to L2'),
  Field('level2ToLevel3Time', String, 'L2 to L3 Time',
    hint: 'Time before escalating to L3'),
  Field('level3ToManagementTime', String, 'L3 to Management Time',
    hint: 'Time before management notification'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Escalation control behavior.
@StandardReferences(
  [
    'PagerDuty / on-call — escalation policy design',
    'ITIL 4 — monitoring and event management practice',
  ],
  'How acknowledgment and resolution control the escalation flow.',
)
@SectionId('AEPB')
class AlertEscalationPoliciesBehavior {
  @Form([
  Field('acknowledgeStopsEscalation', bool, 'Acknowledge Stops Escalation',
    hint: 'Whether acknowledgment pauses escalation'),
  Field('resolveStopsEscalation', bool, 'Resolve Stops Escalation',
    hint: 'Whether resolution cancels escalation'),
  Field('repeatNotification', String, 'Repeat Notification',
    hint: 'Re-notify if unresolved after N minutes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Schedule-specific policy variants.
@StandardReferences(
  [
    'PagerDuty / on-call — escalation policy design',
    'Google SRE — being on-call and incident response',
  ],
  'How escalation policies differ across business hours and off hours.',
)
@SectionId('AEPS')
class AlertEscalationPoliciesSchedules {
  @Form([
  Field('businessHoursPolicy', String, 'Business Hours Policy',
    hint: 'Escalation during business hours'),
  Field('afterHoursPolicy', String, 'After-Hours Policy',
    hint: 'Escalation outside business hours'),
  Field('weekendHolidayPolicy', String, 'Weekend/Holiday Policy',
    hint: 'Escalation on weekends/holidays'),
  Field('notes', String, 'Notes', hint: 'Additional escalation schedule notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Alert suppression and maintenance windows.
@StandardReferences(
  [
    'Prometheus — Alertmanager (routing, grouping, silencing)',
    'Google SRE — monitoring and alerting (the four golden signals)',
  ],
  'How alerts are silenced or inhibited during maintenance windows.',
)
@SectionId('ALSURU')
class AlertSuppressionRules {
  @Form([
    // Maintenance windows
    Field('scheduledMaintenanceWindows', String, 'Scheduled Maintenance Windows',
        hint: 'Recurring maintenance window times'),
    Field('adHocMaintenanceProcess', String, 'Ad-Hoc Maintenance Process',
        hint: 'How to create one-time maintenance windows'),
    Field('maintenanceNotification', String, 'Maintenance Notification',
        hint: 'How stakeholders are informed'),
    // Suppression rules
    Field('dependentAlertSuppression', bool, 'Dependent Alert Suppression',
        hint: 'Suppress downstream alerts'),
    Field('flappingDetection', bool, 'Flapping Detection',
        hint: 'Detect and suppress flapping alerts'),
    Field('silenceRules', String, 'Silence Rules',
        hint: 'Temporary silence for known issues'),
    Field('inhibitRules', String, 'Inhibit Rules',
        hint: 'Rules to inhibit lower-severity alerts'),
    // Audit
    Field('suppressionAuditLog', bool, 'Suppression Audit Log',
        hint: 'Log all suppression/silence actions'),
    Field('suppressionReview', String, 'Suppression Review',
        hint: 'Periodic review of active suppressions'),
    Field('notes', String, 'Notes', hint: 'Additional suppression notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// On-call schedule configuration.
@StandardReferences(
  [
    'Google SRE — being on-call and incident response',
    'PagerDuty / on-call — escalation policy design',
  ],
  'How on-call rotations and duties are configured for the team.',
)
@SectionId('OCSC')
class OnCallScheduleConfig {
  @Form([
    Field('rotationSchedule', String, 'Rotation Schedule',
        hint: 'Weekly, bi-weekly, custom rotation'),
    Field('scheduleTimezone', String, 'Schedule Timezone',
        hint: 'UTC, local, follow-the-sun'),
    Field('primaryOnCallDuties', String, 'Primary On-Call Duties',
        hint: 'Responsibilities during on-call'),
    Field('secondaryOnCallDuties', String, 'Secondary On-Call Duties',
        hint: 'Backup on-call responsibilities'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Override and coverage handling.
  @SerializationOrder(1)
  OnCallScheduleConfigCoverage coverage = OnCallScheduleConfigCoverage();

  /// Compensation and tooling support.
  @SerializationOrder(2)
  OnCallScheduleConfigOperations operations =
    OnCallScheduleConfigOperations();
}

/// Override and coverage handling.
@StandardReferences(
  [
    'PagerDuty / on-call — escalation policy design',
    'Google SRE — being on-call and incident response',
  ],
  'How on-call shift overrides and holiday coverage are managed.',
)
@SectionId('OCSCC')
class OnCallScheduleConfigCoverage {
  @Form([
  Field('scheduleOverrideProcess', String, 'Schedule Override Process',
    hint: 'How to swap on-call shifts'),
  Field('holidayCoverage', String, 'Holiday Coverage',
    hint: 'Coverage during holidays'),
  Field('vacationCoverage', String, 'Vacation Coverage',
    hint: 'How vacation affects on-call'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compensation and tooling support.
@StandardReferences(
  [
    'PagerDuty / on-call — escalation policy design',
    'Google SRE — being on-call and incident response',
  ],
  'How on-call compensation and scheduling tooling are handled.',
)
@SectionId('OCSCO')
class OnCallScheduleConfigOperations {
  @Form([
  Field('onCallCompensation', String, 'On-Call Compensation',
    hint: 'Comp for being on-call'),
  Field('incidentResponseCompensation', String, 'Incident Response Compensation',
    hint: 'Additional comp for incidents'),
  Field('scheduleManagementTool', String, 'Schedule Management Tool',
    hint: 'PagerDuty, Opsgenie schedule'),
  Field('handoffProcess', String, 'Handoff Process',
    hint: 'On-call handoff procedure'),
  Field('notes', String, 'Notes', hint: 'Additional on-call operations notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 8.7.2.3 Metrics and Observability
// ---------------------------------------------------------------------------

/// 8.7.2.3. Metrics and Observability.
///
/// Comprehensive metrics collection, distributed tracing, and observability
/// requirements.
@StandardReferences(
  [
    'OpenTelemetry — metrics, traces, and logs',
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
    'The Twelve-Factor App — logs as event streams',
  ],
  'The overall metrics, tracing, and observability strategy for the system.',
)
@SectionId('MEANOB')
class MetricsAndObservability {
  // ─────────────────────────────────────────────────────────────────────────
  // Metrics Overview
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    // Pillars
    Field('metricsEnabled', bool, 'Metrics Enabled',
        hint: 'Whether metrics collection is enabled'),
    Field('logsEnabled', bool, 'Logs Enabled',
        hint: 'Whether log collection is enabled'),
    Field('tracesEnabled', bool, 'Traces Enabled',
        hint: 'Whether distributed tracing is enabled'),
    Field('profilesEnabled', bool, 'Profiles Enabled',
        hint: 'Continuous profiling'),
    // Standards
    Field('metricsFormat', String, 'Metrics Format',
        hint: 'Prometheus, OpenMetrics, StatsD'),
    Field('logsFormat', String, 'Logs Format',
        hint: 'Structured JSON, syslog'),
    Field('tracingStandard', String, 'Tracing Standard',
        hint: 'OpenTelemetry, OpenTracing, W3C Trace Context'),
    // Collection
    Field('collectionMethod', String, 'Collection Method',
        hint: 'Pull (Prometheus), push (agent), sidecar'),
    Field('scrapeInterval', String, 'Scrape Interval',
        hint: 'Metrics collection frequency'),
    Field('samplingRate', String, 'Sampling Rate',
        hint: 'Trace sampling percentage'),
  ])
  @SerializationOrder(0)
  String? metricsOverview;

  /// Observability overview narrative.
  @SerializationOrder(1)
  TextSection overviewNarrative = TextSection();

  /// Application metrics specification.
  @SerializationOrder(2)
  ApplicationMetricsSpec applicationMetrics = ApplicationMetricsSpec();

  /// Infrastructure metrics specification.
  @SerializationOrder(3)
  InfrastructureMetricsSpec infrastructureMetrics = InfrastructureMetricsSpec();

  /// Business metrics specification.
  @SerializationOrder(4)
  BusinessMetricsSpec businessMetrics = BusinessMetricsSpec();

  /// Distributed tracing specification.
  @SerializationOrder(5)
  DistributedTracingSpec distributedTracing = DistributedTracingSpec();

  /// Custom metrics catalog.
  @StandardReferences(
    ['Prometheus — metric types and exposition format'],
    'The catalog of custom application metrics the system emits.',
  )
  @SectionId('CUMEEN-CUST-LST')
  @SectionIdPattern('CUMEEN-CUST-xxx')
  @ContentHelp('Add one entry per custom metric.')
  @SerializationOrder(6)
  List<CustomMetricEntry> customMetrics = [];
}

/// Application metrics specification.
@StandardReferences(
  [
    'RED method — rate, errors, duration (service metrics)',
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
  ],
  'Metrics that describe application request rate, errors, and duration.',
)
@SectionId('APMESP')
class ApplicationMetricsSpec {
  @Form([
    Field('requestRate', bool, 'Request Rate',
        hint: 'Requests per second'),
    Field('errorRate', bool, 'Error Rate',
        hint: 'Error percentage'),
    Field('requestDuration', bool, 'Request Duration',
        hint: 'Latency histograms (p50, p95, p99)'),
  ])
  @SerializationOrder(0)
  String? content;

  /// USE metrics.
  @SerializationOrder(1)
  ApplicationMetricsSpecResources resources =
      ApplicationMetricsSpecResources();

  /// Application-specific metrics.
  @SerializationOrder(2)
  ApplicationMetricsSpecApplication application =
      ApplicationMetricsSpecApplication();

  /// Labeling guidance.
  @SerializationOrder(3)
  ApplicationMetricsSpecLabels labels = ApplicationMetricsSpecLabels();
}

/// USE metrics.
@StandardReferences(
  [
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
    'RED method — rate, errors, duration (service metrics)',
  ],
  'Utilization, saturation, and error metrics for service resources.',
)
@SectionId('AMSR')
class ApplicationMetricsSpecResources {
  @Form([
    Field('resourceUtilization', bool, 'Resource Utilization',
        hint: 'CPU, memory per service'),
    Field('resourceSaturation', bool, 'Resource Saturation',
        hint: 'Queue depths, connection pool usage'),
    Field('resourceErrors', bool, 'Resource Errors',
        hint: 'Timeouts, failures'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Application-specific metrics.
@StandardReferences(
  [
    'RED method — rate, errors, duration (service metrics)',
    'Prometheus — metric types and exposition format',
  ],
  'Application-level metrics for caches, databases, clients, and message queues.',
)
@SectionId('AMSA')
class ApplicationMetricsSpecApplication {
  @Form([
    Field('cacheMetrics', bool, 'Cache Metrics',
        hint: 'Hit rate, miss rate, evictions'),
    Field('databaseMetrics', bool, 'Database Metrics',
        hint: 'Query count, latency, connection count'),
    Field('httpClientMetrics', bool, 'HTTP Client Metrics',
        hint: 'Outbound request metrics'),
    Field('grpcMetrics', bool, 'gRPC Metrics',
        hint: 'gRPC-specific metrics'),
    Field('messageQueueMetrics', bool, 'Message Queue Metrics',
        hint: 'Publish/consume rates, lag'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Labeling guidance.
@StandardReferences(
  [
    'Prometheus — metric types and exposition format',
    'OpenTelemetry — metrics, traces, and logs',
  ],
  'Guidance on standard and custom labels applied to metrics and their cardinality.',
)
@SectionId('AMSL')
class ApplicationMetricsSpecLabels {
  @Form([
    Field('standardLabels', String, 'Standard Labels',
        hint: 'service, environment, version, instance'),
    Field('customLabels', String, 'Custom Labels',
        hint: 'Business-specific labels'),
    Field('labelCardinality', String, 'Label Cardinality',
        hint: 'Max cardinality guidelines'),
    Field('notes', String, 'Notes',
        hint: 'Additional labeling notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Infrastructure metrics specification.
@StandardReferences(
  [
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
    'Prometheus — metric types and exposition format',
  ],
  'Metrics for compute, memory, disk, and network infrastructure resources.',
)
@SectionId('INMESP')
class InfrastructureMetricsSpec {
  @Form([
    // Compute
    Field('cpuMetrics', bool, 'CPU Metrics',
        hint: 'User, system, iowait, idle'),
    Field('memoryMetrics', bool, 'Memory Metrics',
        hint: 'Used, available, cached, buffered'),
    Field('diskMetrics', bool, 'Disk Metrics',
        hint: 'Usage, IOPS, throughput, latency'),
    Field('networkMetrics', bool, 'Network Metrics',
        hint: 'Bytes in/out, packets, errors'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Container and orchestration metrics.
  @SerializationOrder(1)
  InfrastructureMetricsSpecKubernetes kubernetes =
    InfrastructureMetricsSpecKubernetes();

  /// Cloud-managed services and edge metrics.
  @SerializationOrder(2)
  InfrastructureMetricsSpecCloud cloud = InfrastructureMetricsSpecCloud();

  /// Cost attribution and notes.
  @SerializationOrder(3)
  InfrastructureMetricsSpecCost cost = InfrastructureMetricsSpecCost();
}

/// Container and orchestration metrics.
@StandardReferences(
  [
    'Prometheus — metric types and exposition format',
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
  ],
  'Metrics for containers, pods, nodes, and deployments in the orchestrator.',
)
@SectionId('IMSK')
class InfrastructureMetricsSpecKubernetes {
  @Form([
  Field('containerMetrics', bool, 'Container Metrics',
    hint: 'Container CPU, memory, restarts'),
  Field('podMetrics', bool, 'Pod Metrics',
    hint: 'Pod status, readiness, age'),
  Field('nodeMetrics', bool, 'Node Metrics',
    hint: 'Node capacity, allocatable, conditions'),
  Field('deploymentMetrics', bool, 'Deployment Metrics',
    hint: 'Replica count, rollout status'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cloud-managed services and edge metrics.
@StandardReferences(
  [
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
    'Prometheus — metric types and exposition format',
  ],
  'Metrics from cloud provider managed services and edge infrastructure.',
)
@SectionId('IMSC')
class InfrastructureMetricsSpecCloud {
  @Form([
  Field('cloudProviderMetrics', bool, 'Cloud Provider Metrics',
    hint: 'Native cloud metrics integration'),
  Field('managedServiceMetrics', bool, 'Managed Service Metrics',
    hint: 'RDS, ElastiCache, SQS metrics'),
  Field('loadBalancerMetrics', bool, 'Load Balancer Metrics',
    hint: 'Connection count, healthy hosts'),
  Field('cdnMetrics', bool, 'CDN Metrics',
    hint: 'Cache hit ratio, bandwidth, latency'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cost attribution and notes.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency',
    'Prometheus — metric types and exposition format',
  ],
  'How infrastructure cost is attributed and tracked as a metric.',
)
@SectionId('INMESPCO')
class InfrastructureMetricsSpecCost {
  @Form([
  Field('costMetrics', bool, 'Cost Metrics',
    hint: 'Resource cost attribution'),
  Field('notes', String, 'Notes',
    hint: 'Additional cost attribution notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Business metrics specification.
@StandardReferences(
  [
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
    'ISO/IEC 25010 — performance efficiency',
  ],
  'Metrics that measure business outcomes such as user activity and revenue.',
)
@SectionId('BUMESP')
class BusinessMetricsSpec {
  @Form([
    // User activity
    Field('activeUsers', bool, 'Active Users',
        hint: 'DAU, WAU, MAU'),
    Field('sessionMetrics', bool, 'Session Metrics',
        hint: 'Session count, duration, depth'),
    Field('userJourneyMetrics', bool, 'User Journey Metrics',
        hint: 'Funnel completion, drop-off'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Transaction and revenue metrics.
  @SerializationOrder(1)
  BusinessMetricsSpecTransactions transactions =
    BusinessMetricsSpecTransactions();

  /// Feature adoption and engagement metrics.
  @SerializationOrder(2)
  BusinessMetricsSpecFeatureUsage featureUsage =
    BusinessMetricsSpecFeatureUsage();

  /// KPI and customer outcome metrics.
  @SerializationOrder(3)
  BusinessMetricsSpecKpis kpis = BusinessMetricsSpecKpis();

  /// Real-time dashboard and notes.
  @SerializationOrder(4)
  BusinessMetricsSpecOperations operations = BusinessMetricsSpecOperations();
}

/// Transaction and revenue metrics.
@StandardReferences(
  [
    'RED method — rate, errors, duration (service metrics)',
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
  ],
  'Volume, value, and success rates of business transactions.',
)
@SectionId('BMST')
class BusinessMetricsSpecTransactions {
  @Form([
  Field('transactionVolume', bool, 'Transaction Volume',
    hint: 'Orders, payments, conversions'),
  Field('transactionValue', bool, 'Transaction Value',
    hint: 'Revenue, GMV, average order value'),
  Field('transactionSuccess', bool, 'Transaction Success',
    hint: 'Success/failure rates'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Feature adoption and engagement metrics.
@StandardReferences(
  [
    'RED method — rate, errors, duration (service metrics)',
    'ISO/IEC 25010 — performance efficiency',
  ],
  'How widely and deeply product features are adopted and used.',
)
@SectionId('BMSFU')
class BusinessMetricsSpecFeatureUsage {
  @Form([
  Field('featureAdoption', bool, 'Feature Adoption',
    hint: 'Feature usage rates'),
  Field('featureEngagement', bool, 'Feature Engagement',
    hint: 'Depth of feature usage'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// KPI and customer outcome metrics.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency',
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
  ],
  'Key performance indicators that track customer outcomes and satisfaction.',
)
@SectionId('BMSK')
class BusinessMetricsSpecKpis {
  @Form([
  Field('conversionRate', bool, 'Conversion Rate',
    hint: 'Percentage of users who convert'),
  Field('churnRate', bool, 'Churn Rate',
    hint: 'Percentage of customers lost over time'),
  Field('customerSatisfaction', bool, 'Customer Satisfaction',
    hint: 'NPS, CSAT from feedback'),
  Field('slaCompliance', bool, 'SLA Compliance',
    hint: 'SLA adherence metrics'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Real-time dashboard and notes.
@StandardReferences(
  [
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
    'RED method — rate, errors, duration (service metrics)',
  ],
  'Real-time operational dashboards that surface live business metrics.',
)
@SectionId('BMSO')
class BusinessMetricsSpecOperations {
  @Form([
  Field('realTimeBusinessDashboard', bool, 'Real-Time Business Dashboard',
    hint: 'Live business metrics display'),
  Field('notes', String, 'Notes',
    hint: 'Additional business operations notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Distributed tracing specification.
@StandardReferences(
  [
    'W3C Trace Context — distributed trace propagation',
    'OpenTelemetry — metrics, traces, and logs',
  ],
  'How requests are traced end to end across distributed services.',
)
@SectionId('DITRSP')
class DistributedTracingSpec {
  @Form([
    Field('tracingBackend', String, 'Tracing Backend',
        hint: 'Jaeger, Zipkin, Tempo, X-Ray'),
    Field('tracingProtocol', String, 'Tracing Protocol',
        hint: 'OTLP, Jaeger Thrift, Zipkin JSON'),
    Field('traceIdFormat', String, 'Trace ID Format',
        hint: 'W3C Trace Context, B3, custom'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Sampling strategy.
  @SerializationOrder(1)
  DistributedTracingSpecSampling sampling = DistributedTracingSpecSampling();

  /// Span metadata.
  @SerializationOrder(2)
  DistributedTracingSpecSpans spans = DistributedTracingSpecSpans();

  /// Correlation and retention.
  @SerializationOrder(3)
  DistributedTracingSpecOperations operations =
    DistributedTracingSpecOperations();
}

/// Sampling strategy.
@StandardReferences(
  [
    'OpenTelemetry — metrics, traces, and logs',
    'W3C Trace Context — distributed trace propagation',
  ],
  'How the volume of collected traces is reduced through head and tail sampling.',
)
@SectionId('DTSS')
class DistributedTracingSpecSampling {
  @Form([
  Field('headSamplingRate', String, 'Head Sampling Rate',
    hint: 'Percentage of traces sampled at start'),
  Field('tailSamplingRules', String, 'Tail Sampling Rules',
    hint: 'Rules for sampling after trace completes'),
  Field('errorSampling', String, 'Error Sampling',
    hint: 'Always sample error traces'),
  Field('latencySampling', String, 'Latency Sampling',
    hint: 'Sample slow traces'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Span metadata.
@StandardReferences(
  [
    'OpenTelemetry — metrics, traces, and logs',
    'W3C Trace Context — distributed trace propagation',
  ],
  'The attributes and naming conventions applied to trace spans.',
)
@SectionId('DITRSPSP')
class DistributedTracingSpecSpans {
  @Form([
  Field('defaultSpanAttributes', String, 'Default Span Attributes',
    hint: 'Attributes added to all spans'),
  Field('spanNameConvention', String, 'Span Name Convention',
    hint: 'Naming convention for spans'),
  Field('resourceAttributes', String, 'Resource Attributes',
    hint: 'Service name, version, environment'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Correlation and retention.
@StandardReferences(
  [
    'W3C Trace Context — distributed trace propagation',
    'OpenTelemetry — metrics, traces, and logs',
  ],
  'How traces are correlated with logs and metrics and how long they are kept.',
)
@SectionId('DTSO')
class DistributedTracingSpecOperations {
  @Form([
  Field('logTraceCorrelation', bool, 'Log-Trace Correlation',
    hint: 'Inject trace ID into logs'),
  Field('metricsTraceCorrelation', bool, 'Metrics-Trace Correlation',
    hint: 'Link metrics to exemplar traces'),
  Field('baggagePropagation', String, 'Baggage Propagation',
    hint: 'Custom context propagated across services'),
  Field('traceRetention', String, 'Trace Retention',
    hint: 'How long traces are stored'),
  Field('notes', String, 'Notes',
    hint: 'Additional tracing correlation notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A custom metric entry.
@StandardReferences(
  [
    'Prometheus — metric types and exposition format',
    'OpenTelemetry — metrics, traces, and logs',
  ],
  'A single custom application metric with its type, unit, and labels.',
)
@SectionId('CUSMETENT')
class CustomMetricEntry {
  @Form([
    Field('metricName', String, 'Metric Name', required: true,
        hint: 'Full metric name (e.g., app_orders_total)'),
    Field('metricType', String, 'Metric Type',
        hint: 'Counter, gauge, histogram, summary'),
    Field('metricDescription', String, 'Metric Description',
        hint: 'What this metric measures'),
    Field('unit', String, 'Unit',
        hint: 'seconds, bytes, requests, count'),
    Field('labels', String, 'Labels',
        hint: 'Labels attached to this metric'),
    Field('source', String, 'Source',
        hint: 'Where this metric is emitted'),
    Field('alertOnMetric', bool, 'Alert On Metric',
        hint: 'Whether alerts are based on this metric'),
    Field('dashboardInclusion', String, 'Dashboard Inclusion',
        hint: 'Which dashboards include this metric'),
    Field('notes', String, 'Notes',
        hint: 'Additional notes for this custom metric'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 8.7.2.4 Monitoring Dashboards
// ---------------------------------------------------------------------------

/// 8.7.2.4. Monitoring Dashboards.
///
/// Operational dashboards for system monitoring.
@StandardReferences(
  [
    'Google SRE — monitoring and dashboards (the four golden signals)',
    'Grafana — dashboard and panel design',
  ],
  'Operational dashboards used to visualize and monitor the health of the system.',
)
@SectionId('MODA')
class MonitoringDashboards {
  @Form([
    // Platform
    Field('dashboardPlatform', String, 'Dashboard Platform',
        hint: 'Grafana, Datadog, CloudWatch, custom'),
    Field('dashboardAccessControl', String, 'Dashboard Access Control',
        hint: 'Who can view, edit dashboards'),
    Field('dashboardVersioning', bool, 'Dashboard Versioning',
        hint: 'Version control for dashboards'),
    // Standards
    Field('dashboardNamingConvention', String, 'Dashboard Naming Convention',
        hint: 'Naming standards for dashboards'),
    Field('standardLayout', String, 'Standard Layout',
        hint: 'Common layout patterns'),
    Field('colorCodingStandards', String, 'Color Coding Standards',
        hint: 'Red=bad, green=good conventions'),
    // Categories
    Field('executiveDashboards', bool, 'Executive Dashboards',
        hint: 'High-level business KPIs'),
    Field('operationalDashboards', bool, 'Operational Dashboards',
        hint: 'Real-time ops dashboards'),
    Field('serviceDashboards', bool, 'Service Dashboards',
        hint: 'Per-service detail dashboards'),
    Field('infrastructureDashboards', bool, 'Infrastructure Dashboards',
        hint: 'Infra-level dashboards'),
  ])
  @SerializationOrder(0)
  String? dashboardOverview;

  /// Dashboard overview narrative.
  @SerializationOrder(1)
  TextSection overviewNarrative = TextSection();

  /// Dashboard catalog.
  @StandardReferences(
    ['Grafana — dashboard and panel design'],
    'The catalog of monitoring dashboards the system provides.',
  )
  @SectionId('DAEN-DASH-LST')
  @SectionIdPattern('DAEN-DASH-xxx')
  @ContentHelp('Add one entry per dashboard.')
  @SerializationOrder(2)
  List<DashboardEntry> dashboards = [];

  /// Dashboard template specifications.
  @StandardReferences(
    ['Grafana — dashboard and panel design'],
    'The catalog of reusable dashboard templates the system provides.',
  )
  @SectionId('DATE-DASH-LST')
  @SectionIdPattern('DATE-DASH-xxx')
  @ContentHelp('Add one entry per dashboard template.')
  @SerializationOrder(3)
  List<DashboardTemplates> dashboardTemplates = [];
}

/// A dashboard entry.
@StandardReferences(
  [
    'Grafana — dashboard and panel design',
    'Google SRE — monitoring and dashboards (the four golden signals)',
  ],
  'A single monitoring dashboard entry describing its identity, category and audience.',
)
@SectionId('DASENT')
class DashboardEntry {
  @Form([
    Field('dashboardId', String, 'Dashboard ID', required: true, hint: 'Unique dashboard identifier'),
    Field('dashboardName', String, 'Dashboard Name', required: true, hint: 'Human-readable dashboard name'),
    Field('dashboardCategory', String, 'Dashboard Category',
        hint: 'Executive, operational, service, infrastructure'),
    Field('targetAudience', String, 'Target Audience',
        hint: 'Who uses this dashboard'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Refresh and data composition details.
  @SerializationOrder(1)
  DashboardEntryConfiguration configuration = DashboardEntryConfiguration();

  /// Alert ownership and notes.
  @SerializationOrder(2)
  DashboardEntryOperations operations = DashboardEntryOperations();
}

/// Refresh and data composition details.
@StandardReferences(
  [
    'Grafana — dashboard and panel design',
    'OpenTelemetry — observability signals',
  ],
  'Refresh cadence, time range and data source configuration for a monitoring dashboard.',
)
@SectionId('DAENCO')
class DashboardEntryConfiguration {
  @Form([
    Field('refreshInterval', String, 'Refresh Interval', hint: 'How often the dashboard refreshes'),
    Field('timeRangeDefault', String, 'Time Range Default',
        hint: 'Default time window'),
    Field('keyPanels', String, 'Key Panels',
        hint: 'Main visualizations on dashboard'),
    Field('dataSource', String, 'Data Source',
        hint: 'Data source for dashboard'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Alert ownership and notes.
@StandardReferences(
  [
    'Google SRE — monitoring and dashboards (the four golden signals)',
    'ISO/IEC 20000 — service reporting',
  ],
  'Ownership, alert integration and operational notes for a monitoring dashboard.',
)
@SectionId('DAENOP')
class DashboardEntryOperations {
  @Form([
    Field('alertIntegration', String, 'Alert Integration',
        hint: 'Alerts displayed on dashboard'),
    Field('ownerTeam', String, 'Owner Team', hint: 'Team that owns this dashboard'),
    Field('notes', String, 'Notes', hint: 'Additional operational notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dashboard templates specification.
@StandardReferences(
  [
    'Grafana — dashboard and panel design',
    'AWS Well-Architected — operational excellence (observability)',
  ],
  'Reusable dashboard templates that standardize layouts across services and infrastructure.',
)
@SectionId('DATE')
class DashboardTemplates {
  @Form([
    // Service template
    Field('serviceTemplateLayout', String, 'Service Template Layout',
        hint: 'Standard panels for service dashboards'),
    Field('serviceTemplateVariables', String, 'Service Template Variables',
        hint: 'Configurable variables'),
    // Infrastructure template
    Field('infraTemplateLayout', String, 'Infra Template Layout',
        hint: 'Standard panels for infra dashboards'),
    // K8s template
    Field('k8sTemplateLayout', String, 'K8s Template Layout',
        hint: 'Kubernetes-specific dashboard layout'),
    // Database template
    Field('databaseTemplateLayout', String, 'Database Template Layout',
        hint: 'Database monitoring panels'),
    // Custom templates
    Field('customTemplateProcess', String, 'Custom Template Process',
        hint: 'How to create new templates'),
    Field('templateVersioning', String, 'Template Versioning',
        hint: 'How templates are versioned'),
    Field('notes', String, 'Notes', hint: 'Additional template notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 8.7.2.5 SLA and SLO Monitoring
// ---------------------------------------------------------------------------

/// 8.7.2.5. SLA and SLO Monitoring.
///
/// Service Level Agreement and Service Level Objective tracking.
@StandardReferences(
  [
    'Google SRE — service level objectives (SLOs and SLIs)',
    'ISO/IEC 20000 — service level management',
    'ITIL 4 — service level management practice',
  ],
  'Tracks service level agreements and objectives together with their reporting.',
)
@SectionId('SASM')
class SlaAndSloMonitoring {
  @Form([
    // SLI/SLO framework
    Field('sloFramework', String, 'SLO Framework',
        hint: 'Google SRE, custom'),
    Field('errorBudgetPolicy', String, 'Error Budget Policy',
        hint: 'How error budget is managed'),
    Field('errorBudgetExhaustionPolicy', String, 'Error Budget Exhaustion Policy',
        hint: 'Actions when budget exhausted'),
    // Reporting
    Field('slaReportingCadence', String, 'SLA Reporting Cadence',
        hint: 'Weekly, monthly SLA reports'),
    Field('slaReportingAudience', String, 'SLA Reporting Audience',
        hint: 'Who receives SLA reports'),
    Field('slaBreachProcess', String, 'SLA Breach Process',
        hint: 'Process when SLA is breached'),
    // External SLAs
    Field('customerFacingSLAs', bool, 'Customer-Facing SLAs',
        hint: 'SLAs published to customers'),
    Field('slaCredits', String, 'SLA Credits',
        hint: 'Credit/refund policy for breaches'),
    Field('slaExclusions', String, 'SLA Exclusions',
        hint: 'Maintenance windows, force majeure'),
  ])
  @SerializationOrder(0)
  String? slaOverview;

  /// SLA/SLO overview narrative.
  @SerializationOrder(1)
  TextSection overviewNarrative = TextSection();

  /// Service Level Indicators.
  @SerializationOrder(2)
  ServiceLevelIndicators slis = ServiceLevelIndicators();

  /// SLO catalog.
  @StandardReferences(
    ['Google SRE — service level objectives (SLOs and SLIs)'],
    'The catalog of service level objectives the system commits to.',
  )
  @SectionId('SLEN-SLOS-LST')
  @SectionIdPattern('SLEN-SLOS-xxx')
  @ContentHelp('Add one entry per SLO.')
  @SerializationOrder(3)
  List<SloEntry> slos = [];

  /// Error budget tracking.
  @SerializationOrder(4)
  ErrorBudgetTracking errorBudget = ErrorBudgetTracking();
}

/// Service Level Indicators.
@StandardReferences(
  [
    'Google SRE — service level objectives (SLOs and SLIs)',
    'Google SRE — site reliability engineering practices',
  ],
  'The measurable service level indicators that drive the service level objectives.',
)
@SectionId('SELEIN')
class ServiceLevelIndicators {
  @Form([
    Field('availabilitySli', String, 'Availability SLI',
        hint: 'How availability is measured'),
    Field('availabilityExclusions', String, 'Availability Exclusions',
        hint: 'What is excluded from availability'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Latency and throughput indicators.
  @SerializationOrder(1)
  ServiceLevelIndicatorsPerformance performance =
    ServiceLevelIndicatorsPerformance();

  /// Error, correctness, and freshness indicators.
  @SerializationOrder(2)
  ServiceLevelIndicatorsQuality quality = ServiceLevelIndicatorsQuality();

  /// Measurement method and location.
  @SerializationOrder(3)
  ServiceLevelIndicatorsMeasurement measurement =
    ServiceLevelIndicatorsMeasurement();
}

/// Latency and throughput indicators.
@StandardReferences(
  [
    'Google SRE — service level objectives (SLOs and SLIs)',
    'ISO/IEC 25010 — reliability (availability, maturity)',
  ],
  'Service level indicators covering latency and throughput.',
)
@SectionId('SLIP')
class ServiceLevelIndicatorsPerformance {
  @Form([
  Field('latencySli', String, 'Latency SLI',
    hint: 'How latency is measured (p50, p95, p99)'),
  Field('latencyThresholds', String, 'Latency Thresholds',
    hint: 'Good latency vs bad latency'),
  Field('throughputSli', String, 'Throughput SLI',
    hint: 'How throughput is measured'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Error, correctness, and freshness indicators.
@StandardReferences(
  [
    'Google SRE — service level objectives (SLOs and SLIs)',
    'ISO/IEC 25010 — reliability (availability, maturity)',
  ],
  'Service level indicators covering error rate, correctness, and data freshness.',
)
@SectionId('SLIQ')
class ServiceLevelIndicatorsQuality {
  @Form([
  Field('errorRateSli', String, 'Error Rate SLI',
    hint: 'How errors are counted'),
  Field('errorCategories', String, 'Error Categories',
    hint: 'Which errors count against SLI'),
  Field('correctnessSli', String, 'Correctness SLI',
    hint: 'Data correctness measurement'),
  Field('freshnessSli', String, 'Freshness SLI',
    hint: 'Data freshness measurement'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Measurement method and location.
@StandardReferences(
  [
    'Google SRE — service level objectives (SLOs and SLIs)',
    'Google SRE — site reliability engineering practices',
  ],
  'Describes how and where service level indicators are measured.',
)
@SectionId('SLIM')
class ServiceLevelIndicatorsMeasurement {
  @Form([
  Field('measurementMethod', String, 'Measurement Method',
    hint: 'Synthetic, real user, logs'),
  Field('measurementLocation', String, 'Measurement Location',
    hint: 'Server-side, client-side, edge'),
  Field('notes', String, 'Notes', hint: 'Free-form measurement notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// An SLO entry.
@StandardReferences(
  [
    'Google SRE — service level objectives (SLOs and SLIs)',
  ],
  'A single service level objective the system commits to meeting.',
)
@SectionId('SE')
class SloEntry {
  @Form([
    Field('sloId', String, 'SLO ID', required: true, hint: 'Unique SLO identifier'),
    Field('sloName', String, 'SLO Name', required: true, hint: 'Human-readable SLO name'),
    Field('sloDescription', String, 'SLO Description', hint: 'What this SLO covers'),
    Field('serviceName', String, 'Service Name', hint: 'Service the SLO applies to'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Objective target and budget definition.
  @SerializationOrder(1)
  SloEntryTarget target = SloEntryTarget();

  /// Alerting and ownership rules.
  @SerializationOrder(2)
  SloEntryOperations operations = SloEntryOperations();
}

/// Objective target and budget definition.
@StandardReferences(
  [
    'Google SRE — service level objectives (SLOs and SLIs)',
    'Google SRE — error budgets',
  ],
  'Defines the target and derived error budget for a single service level objective.',
)
@SectionId('SLENTA')
class SloEntryTarget {
  @Form([
    Field('sliType', String, 'SLI Type',
        hint: 'Availability, latency, error rate'),
    Field('sloTarget', String, 'SLO Target',
        hint: 'e.g., 99.9%, p99 < 200ms'),
    Field('sloWindow', String, 'SLO Window',
        hint: 'Rolling 28-day, calendar month'),
    Field('errorBudget', String, 'Error Budget',
        hint: 'Derived error budget'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Alerting and ownership rules.
@StandardReferences(
  [
    'Google SRE — service level objectives (SLOs and SLIs)',
    'ITIL 4 — service level management practice',
  ],
  'Alerting thresholds and ownership assigned to a single service level objective.',
)
@SectionId('SLENOP')
class SloEntryOperations {
  @Form([
    Field('alertThreshold', String, 'Alert Threshold',
        hint: 'When to alert on burn rate'),
    Field('burnRateAlert', String, 'Burn Rate Alert',
        hint: 'Fast-burn, slow-burn alerts'),
    Field('ownerTeam', String, 'Owner Team', hint: 'Team owning this SLO'),
    Field('notes', String, 'Notes', hint: 'Free-form operational notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Error budget tracking.
@StandardReferences(
  [
    'Google SRE — error budgets',
    'Google SRE — service level objectives (SLOs and SLIs)',
  ],
  'Tracks the error budget derived from the service level objectives.',
)
@SectionId('ERBUTR')
class ErrorBudgetTracking {
  @Form([
    // Budget calculation
    Field('budgetCalculationMethod', String, 'Budget Calculation Method',
        hint: 'How error budget is calculated'),
    Field('budgetWindow', String, 'Budget Window',
        hint: 'Rolling or calendar window'),
    Field('budgetResetPolicy', String, 'Budget Reset Policy',
        hint: 'When budget resets'),
    // Monitoring
    Field('budgetBurnRateDashboard', bool, 'Budget Burn Rate Dashboard',
        hint: 'Dashboard showing burn rate'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Burn-rate monitoring thresholds.
  @SerializationOrder(1)
  ErrorBudgetTrackingMonitoring monitoring = ErrorBudgetTrackingMonitoring();

  /// Recovery policy and attribution rules.
  @SerializationOrder(2)
  ErrorBudgetTrackingGovernance governance = ErrorBudgetTrackingGovernance();
}

/// Burn-rate monitoring thresholds.
@StandardReferences(
  [
    'Google SRE — error budgets',
    'Google SRE — service level objectives (SLOs and SLIs)',
  ],
  'Thresholds that watch how quickly the error budget burns down.',
)
@SectionId('EBTM')
class ErrorBudgetTrackingMonitoring {
  @Form([
  Field('budgetAlertThresholds', String, 'Budget Alert Thresholds',
    hint: 'Warn at 50%, critical at 80%'),
  Field('burnRateTimePeriods', String, 'Burn Rate Time Periods',
    hint: '1h, 6h, 24h, 7d burn rates'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Recovery policy and attribution rules.
@StandardReferences(
  [
    'Google SRE — error budgets',
    'ITIL 4 — service level management practice',
  ],
  'Recovery and attribution rules applied when the error budget is spent.',
)
@SectionId('EBTG')
class ErrorBudgetTrackingGovernance {
  @Form([
  Field('budgetExhaustionActions', String, 'Budget Exhaustion Actions',
    hint: 'Feature freeze, deployment freeze'),
  Field('budgetRecoveryProcess', String, 'Budget Recovery Process',
    hint: 'Steps to recover budget'),
  Field('budgetReviewMeeting', String, 'Budget Review Meeting',
    hint: 'Regular error budget review'),
  Field('budgetAttribution', String, 'Budget Attribution',
    hint: 'Attribute budget spend to incidents'),
  Field('notes', String, 'Notes', hint: 'Free-form governance notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 8.7.2.1. Health Checks and Diagnostics.
@StandardReferences(
  [
    'Kubernetes — liveness, readiness, and startup probes',
    'Google SRE — health checking and monitoring',
    'AWS Well-Architected — reliability pillar (health checks)',
  ],
  'Defines the health check, diagnostics, troubleshooting, and self-healing requirements that enable rapid problem detection and automated remediation.',
)
@ContentHelp('''
Specify health check, diagnostics, and troubleshooting requirements.
Health checks enable rapid problem detection and automated remediation.

**Health Check Types**:
- **Liveness**: Is the process alive? (restart if not)
- **Readiness**: Is the service ready for traffic? (remove from LB if not)
- **Startup**: Is the service still starting? (give more time)
- **Deep Health**: Are all dependencies healthy?

**Health Check Endpoints**:
- Standard endpoints (/health, /ready, /live)
- Response format (JSON with details)
- Performance requirements (fast, non-blocking)
- Authentication considerations

**Diagnostics Capabilities**:
- Real-time log access
- Distributed tracing
- Request/response capture (debug mode)
- Performance profiling
- Memory and CPU analysis

**Troubleshooting Tools**:
- Log search and filtering
- Trace correlation
- Error aggregation and analysis
- Dependency graph visualization
- Runbook integration

**Self-Healing**:
- Automatic restart on failure
- Circuit breaker activation
- Traffic rerouting
- Resource scaling
- Alerting and escalation
''')
@SectionId('HCADS')
class HealthChecksAndDiagnosticsSection {
  @ContentHelp('''
Provide an overview of health check and diagnostics strategy.

**Include**:
- Health check architecture
- Diagnostics capabilities
- Troubleshooting workflow
- Self-healing mechanisms
- Integration with monitoring

**Best Practices**:
- Implement all three probe types
- Keep health checks fast and reliable
- Include dependency health in deep checks
- Correlate logs and traces
- Document troubleshooting procedures
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of health check and diagnostic strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Health check endpoint requirements.
  @SerializationOrder(2)
  HealthCheckEndpoints healthEndpoints = HealthCheckEndpoints();

  /// Application diagnostics.
  @SerializationOrder(3)
  ApplicationDiagnostics applicationDiagnostics = ApplicationDiagnostics();

  /// Log aggregation and analysis.
  @SerializationOrder(4)
  LogAggregationRequirements logAggregation = LogAggregationRequirements();

  /// Troubleshooting capabilities.
  @SerializationOrder(5)
  TroubleshootingCapabilities troubleshooting = TroubleshootingCapabilities();

  /// Dependency health monitoring.
  @SerializationOrder(6)
  DependencyHealthMonitoring dependencyHealth = DependencyHealthMonitoring();
}

/// Health check endpoint requirements.
@StandardReferences(
  [
    'Kubernetes — liveness, readiness, and startup probes',
    'Google SRE — health checking and monitoring',
    'The Twelve-Factor App — disposability (fast startup, graceful shutdown)',
  ],
  'Defines the liveness, readiness, startup, and deep-health endpoints the system exposes so orchestrators can probe its state.',
)
@SectionId('HECHEN')
class HealthCheckEndpoints {
  @Form([
    Field('livenessEndpoint', String, 'Liveness Endpoint',
        required: true, hint: '/health/live — is the process running'),
    Field('readinessEndpoint', String, 'Readiness Endpoint',
        required: true, hint: '/health/ready — can it serve traffic'),
    Field('startupEndpoint', String, 'Startup Endpoint',
        hint: '/health/startup — has initialization completed'),
    Field('deepHealthEndpoint', String, 'Deep Health Endpoint',
        hint: '/health/deep — checks all dependencies'),
    Field('healthCheckProtocol', String, 'Protocol',
        hint: 'HTTP, gRPC, TCP'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Response configuration.
  @SerializationOrder(1)
  HealthCheckEndpointsConfiguration configuration =
      HealthCheckEndpointsConfiguration();

  /// Timing thresholds.
  @SerializationOrder(2)
  HealthCheckEndpointsTiming timing = HealthCheckEndpointsTiming();

  /// Response content settings.
  @SerializationOrder(3)
  HealthCheckEndpointsContent contentSettings =
      HealthCheckEndpointsContent();
}

/// Response configuration.
@StandardReferences(
  [
    'Kubernetes — liveness, readiness, and startup probes',
    'Google SRE — health checking and monitoring',
  ],
  'Specifies the health check port, response format, and success/failure status codes returned by the endpoints.',
)
@SectionId('HCEC')
class HealthCheckEndpointsConfiguration {
  @Form([
    Field('healthCheckPort', int, 'Port',
        hint: 'Dedicated health check port'),
    Field('responseFormat', String, 'Response Format',
        hint: 'JSON, plain text, RFC Health Check format'),
    Field('successStatusCode', int, 'Success Status Code',
        hint: 'HTTP 200 for healthy'),
    Field('failureStatusCode', int, 'Failure Status Code',
        hint: 'HTTP 503 for unhealthy'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Timing thresholds.
@StandardReferences(
  [
    'Kubernetes — liveness, readiness, and startup probes',
    'Google SRE — health checking and monitoring',
  ],
  'Defines the check interval, timeout, and failure/success thresholds that govern how probes decide a service is healthy or unhealthy.',
)
@SectionId('HCET')
class HealthCheckEndpointsTiming {
  @Form([
    Field('checkInterval', String, 'Check Interval',
        hint: 'How often health is checked (e.g. 10s, 30s)'),
    Field('checkTimeout', String, 'Check Timeout',
        hint: 'Max time for a health check response'),
    Field('failureThreshold', int, 'Failure Threshold',
        hint: 'Consecutive failures before unhealthy'),
    Field('successThreshold', int, 'Success Threshold',
        hint: 'Consecutive successes to become healthy'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Response content settings.
@StandardReferences(
  [
    'Kubernetes — liveness, readiness, and startup probes',
    'Google SRE — health checking and monitoring',
  ],
  'Specifies what detail a health check response includes such as component status, version, uptime, and redaction of sensitive data.',
)
@SectionId('HECHENCO')
class HealthCheckEndpointsContent {
  @Form([
    Field('includeComponentStatus', bool, 'Include Component Status',
        hint: 'Show status of individual components'),
    Field('includeVersion', bool, 'Include Version',
        hint: 'Include app version in response'),
    Field('includeUptime', bool, 'Include Uptime',
        hint: 'Include process uptime'),
    Field('includeMetrics', bool, 'Include Metrics',
        hint: 'Include basic metrics in response'),
    Field('sensitiveDataRedaction', bool, 'Sensitive Data Redaction',
        hint: 'Redact secrets from health output'),
    Field('notes', String, 'Notes',
        hint: 'Additional health endpoint notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Application diagnostics.
@StandardReferences(
  [
    'OpenTelemetry — observability signals',
    'Google SRE — health checking and monitoring',
  ],
  'Defines the diagnostic endpoints (info, metrics, environment) and runtime introspection the application exposes for troubleshooting.',
)
@SectionId('APDI')
class ApplicationDiagnostics {
  @Form([
    // Runtime information
    Field('infoEndpoint', String, 'Info Endpoint',
        hint: '/info — build version, git commit, environment'),
    Field('metricsEndpoint', String, 'Metrics Endpoint',
        hint: '/metrics — Prometheus, OpenMetrics format'),
    Field('environmentEndpoint', String, 'Environment Endpoint',
        hint: '/env — configuration (redacted)'),
  ])
  @SerializationOrder(0)
  String? content;

  /// On-demand profiling and slow-request tracing.
  @SerializationOrder(1)
  ApplicationDiagnosticsPerformance performance =
    ApplicationDiagnosticsPerformance();

  /// Runtime queue and pool inspection.
  @SerializationOrder(2)
  ApplicationDiagnosticsRuntime runtime = ApplicationDiagnosticsRuntime();

  /// Feature and resilience status indicators.
  @SerializationOrder(3)
  ApplicationDiagnosticsFeatureStatus featureStatus =
    ApplicationDiagnosticsFeatureStatus();
}

/// On-demand profiling and slow-request tracing.
@StandardReferences(
  [
    'OpenTelemetry — observability signals',
    'Google SRE — site reliability engineering practices',
  ],
  'Specifies on-demand CPU and memory profiling and per-request tracing used to diagnose slow or resource-heavy requests.',
)
@SectionId('APDIPE')
class ApplicationDiagnosticsPerformance {
  @Form([
  Field('cpuProfiling', bool, 'CPU Profiling',
    hint: 'On-demand CPU profiling'),
  Field('memoryProfiling', bool, 'Memory Profiling',
    hint: 'Heap analysis and leak detection'),
  Field('requestTracing', bool, 'Request Tracing',
    hint: 'Per-request timing breakdown'),
  Field('slowRequestDetection', String, 'Slow Request Detection',
    hint: 'Threshold and alerting for slow requests'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Runtime queue and pool inspection.
@StandardReferences(
  [
    'OpenTelemetry — observability signals',
    'Google SRE — health checking and monitoring',
  ],
  'Provides runtime inspection of connection pools, thread pools, and queue depth for diagnosing resource contention.',
)
@SectionId('APDIRU')
class ApplicationDiagnosticsRuntime {
  @Form([
  Field('connectionPoolStatus', bool, 'Connection Pool Status',
    hint: 'Database and HTTP pool monitoring'),
  Field('threadPoolStatus', bool, 'Thread Pool Status',
    hint: 'Worker thread/isolate pool status'),
  Field('queueDepthMonitoring', bool, 'Queue Depth Monitoring',
    hint: 'Message queue backlog tracking'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Feature and resilience status indicators.
@StandardReferences(
  [
    'OpenTelemetry — observability signals',
    'Google SRE — health checking and monitoring',
  ],
  'Exposes feature-flag, circuit-breaker, and cache-hit-ratio status indicators for runtime resilience visibility.',
)
@SectionId('ADFS')
class ApplicationDiagnosticsFeatureStatus {
  @Form([
  Field('featureFlagStatus', bool, 'Feature Flag Status',
    hint: 'Active feature flags visibility'),
  Field('circuitBreakerStatus', bool, 'Circuit Breaker Status',
    hint: 'State of circuit breakers'),
  Field('cacheHitRatio', bool, 'Cache Hit Ratio',
    hint: 'Cache effectiveness monitoring'),
  Field('notes', String, 'Notes',
    hint: 'Additional diagnostics notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Log aggregation and analysis requirements.
@StandardReferences(
  [
    'OpenTelemetry — observability signals',
    'Google SRE — health checking and monitoring',
  ],
  'Defines the log aggregation platform, format, levels, and analysis requirements for centralized logging.',
)
@SectionId('LOAGRE')
class LogAggregationRequirements {
  @Form([
    Field('logPlatform', String, 'Log Platform',
        required: true, hint: 'ELK Stack, Loki/Grafana, CloudWatch, Datadog'),
    Field('logFormat', String, 'Log Format',
        hint: 'Structured JSON, plain text, syslog'),
    Field('logLevels', String, 'Log Levels',
        hint: 'TRACE, DEBUG, INFO, WARN, ERROR, FATAL'),
    Field('defaultLogLevel', String, 'Default Log Level',
        hint: 'Production default level (e.g. INFO)'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Dynamic configuration and collection settings.
  @SerializationOrder(1)
  LogAggregationRequirementsCollection collection =
      LogAggregationRequirementsCollection();

  /// Retention and archival settings.
  @SerializationOrder(2)
  LogAggregationRequirementsRetention retention =
      LogAggregationRequirementsRetention();

  /// Search and analysis capabilities.
  @SerializationOrder(3)
  LogAggregationRequirementsAnalysis analysis =
      LogAggregationRequirementsAnalysis();
}

/// Dynamic configuration and collection settings.
@StandardReferences(
  [
    'OpenTelemetry — observability signals',
    'The Twelve-Factor App — disposability (fast startup, graceful shutdown)',
  ],
  'Specifies dynamic log-level changes and the collection, shipping, buffering, and sampling settings for log ingestion.',
)
@SectionId('LARC')
class LogAggregationRequirementsCollection {
  @Form([
    Field('dynamicLogLevelChange', bool, 'Dynamic Log Level Change',
        hint: 'Change log level without restart'),
    Field('logCollectionMethod', String, 'Log Collection Method',
        hint: 'Sidecar, agent, direct push, stdout'),
    Field('logShippingProtocol', String, 'Log Shipping Protocol',
        hint: 'Fluentd, Logstash, OTLP'),
    Field('logBuffering', String, 'Log Buffering',
        hint: 'Buffer size, flush interval'),
    Field('logSampling', String, 'Log Sampling',
        hint: 'Sample rate for high-volume logs'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Retention and archival settings.
@StandardReferences(
  [
    'ISO/IEC 20000 — service availability management',
    'OpenTelemetry — observability signals',
  ],
  'Defines log retention periods, archival policy, and regulatory-compliance retention for aggregated logs.',
)
@SectionId('LARR')
class LogAggregationRequirementsRetention {
  @Form([
    Field('retentionPeriod', String, 'Retention Period',
        hint: 'Hot: 7d, warm: 30d, cold: 1y'),
    Field('archivalPolicy', String, 'Archival Policy',
        hint: 'S3 Glacier, cold storage'),
    Field('complianceRetention', String, 'Compliance Retention',
        hint: 'Regulatory retention requirements'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Search and analysis capabilities.
@StandardReferences(
  [
    'OpenTelemetry — observability signals',
    'Google SRE — health checking and monitoring',
  ],
  'Specifies log search, trace-correlation, saved queries, and log-based alerting used to analyze aggregated logs.',
)
@SectionId('LARA')
class LogAggregationRequirementsAnalysis {
  @Form([
    Field('fullTextSearch', bool, 'Full-Text Search',
        hint: 'Search across all log streams'),
    Field('correlationByTraceId', bool, 'Correlation by Trace ID',
        hint: 'Cross-service log correlation'),
    Field('savedQueries', bool, 'Saved Queries',
        hint: 'Reusable log search queries'),
    Field('logBasedAlerts', bool, 'Log-Based Alerts',
        hint: 'Alert on log patterns or frequencies'),
    Field('piiRedaction', bool, 'PII Redaction',
        hint: 'Automatic PII masking in logs'),
    Field('notes', String, 'Notes',
        hint: 'Additional log aggregation notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Troubleshooting capabilities.
@StandardReferences(
  [
    'Google SRE — site reliability engineering practices',
    'OpenTelemetry — observability signals',
  ],
  'Defines the debugging, diagnostic-dump, and request-replay capabilities used to troubleshoot the running system.',
)
@SectionId('TRCA')
class TroubleshootingCapabilities {
  @Form([
    Field('debugMode', String, 'Debug Mode',
        hint: 'How to enable verbose diagnostics'),
    Field('diagnosticDump', bool, 'Diagnostic Dump',
        hint: 'Generate full diagnostic report on demand'),
    Field('replayCapability', bool, 'Replay Capability',
        hint: 'Replay failed requests for analysis'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Runbook and remediation support.
  @SerializationOrder(1)
  TroubleshootingCapabilitiesRunbooks runbooks =
    TroubleshootingCapabilitiesRunbooks();

  /// Break-glass and diagnostic access controls.
  @SerializationOrder(2)
  TroubleshootingCapabilitiesAccess access =
    TroubleshootingCapabilitiesAccess();

  /// Incident communication and retrospective support.
  @SerializationOrder(3)
  TroubleshootingCapabilitiesCommunication communication =
    TroubleshootingCapabilitiesCommunication();
}

/// Runbook and remediation support.
@StandardReferences(
  [
    'Google SRE — site reliability engineering practices',
    'AWS Well-Architected — reliability pillar (health checks)',
  ],
  'Defines runbook integration and automated remediation that link alerts to known-issue fixes and correlated incident timelines.',
)
@SectionId('TRCARU')
class TroubleshootingCapabilitiesRunbooks {
  @Form([
  Field('runbookIntegration', bool, 'Runbook Integration',
    hint: 'Link alerts to troubleshooting runbooks'),
  Field('automatedRemediation', String, 'Automated Remediation',
    hint: 'Auto-fix for known issues (restart, scale)'),
  Field('incidentTimeline', bool, 'Incident Timeline',
    hint: 'Correlated event timeline for incidents'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Break-glass and diagnostic access controls.
@StandardReferences(
  [
    'Google SRE — site reliability engineering practices',
    'ISO/IEC 20000 — service availability management',
  ],
  'Specifies audited break-glass access and diagnostic tooling used to investigate incidents in production.',
)
@SectionId('TRCAAC')
class TroubleshootingCapabilitiesAccess {
  @Form([
  Field('productionShellAccess', String, 'Production Shell Access',
    hint: 'Break-glass SSH/exec with audit'),
  Field('databaseReadAccess', String, 'Database Read Access',
    hint: 'Read-only query for production DB'),
  Field('networkDiagnostics', bool, 'Network Diagnostics',
    hint: 'Ping, traceroute, DNS lookup tools'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Incident communication and retrospective support.
@StandardReferences(
  [
    'Google SRE — site reliability engineering practices',
    'ISO/IEC 20000 — service availability management',
  ],
  'Defines incident communication tooling and the blameless-postmortem process that supports retrospective analysis.',
)
@SectionId('TRCACO')
class TroubleshootingCapabilitiesCommunication {
  @Form([
  Field('statusPageIntegration', String, 'Status Page Integration',
    hint: 'Statuspage.io, Instatus, custom'),
  Field('warRoomTools', String, 'War Room Tools',
    hint: 'Incident collaboration (Slack channel, Zoom)'),
  Field('postmortemProcess', String, 'Postmortem Process',
    hint: 'Blameless postmortem template and workflow'),
  Field('notes', String, 'Notes',
    hint: 'Additional troubleshooting notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dependency health monitoring.
@StandardReferences(
  [
    'Kubernetes — liveness, readiness, and startup probes',
    'Google SRE — health checking and monitoring',
    'AWS Well-Architected — reliability pillar (health checks)',
  ],
  'Specifies how the system verifies the health of its downstream dependencies such as databases, caches, queues, and external services.',
)
@SectionId('DEHEMO')
class DependencyHealthMonitoring {
  @Form([
    // Database
    Field('databaseHealthCheck', String, 'Database Health Check',
        hint: 'Connection test, query test, replication lag'),
    Field('databaseLatencyThreshold', String, 'DB Latency Threshold',
        hint: 'Alert threshold for slow queries'),
    Field('databaseConnectionPoolHealth', bool, 'DB Pool Health',
        hint: 'Monitor pool exhaustion'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Cache subsystem checks.
  @SerializationOrder(1)
  DependencyHealthMonitoringCache cache = DependencyHealthMonitoringCache();

  /// Queue and dead-letter monitoring.
  @SerializationOrder(2)
  DependencyHealthMonitoringQueue queue = DependencyHealthMonitoringQueue();

  /// External service and certificate checks.
  @SerializationOrder(3)
  DependencyHealthMonitoringExternal external =
    DependencyHealthMonitoringExternal();

  /// Thresholds and cascade protection settings.
  @SerializationOrder(4)
  DependencyHealthMonitoringThresholds thresholds =
    DependencyHealthMonitoringThresholds();
}

/// Cache subsystem checks.
@StandardReferences(
  [
    'Google SRE — health checking and monitoring',
    'OpenTelemetry — observability signals',
  ],
  'Specifies health checks for the cache subsystem including ping, memory, and eviction-rate monitoring.',
)
@SectionId('DHMC')
class DependencyHealthMonitoringCache {
  @Form([
  Field('cacheHealthCheck', String, 'Cache Health Check',
    hint: 'Redis/Memcached ping and memory'),
  Field('cacheEvictionMonitoring', bool, 'Cache Eviction Monitoring',
    hint: 'Alert on high eviction rates'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Queue and dead-letter monitoring.
@StandardReferences(
  [
    'Google SRE — health checking and monitoring',
    'OpenTelemetry — observability signals',
  ],
  'Defines health monitoring of message queues including queue depth, consumer lag, and dead-letter-queue accumulation.',
)
@SectionId('DHMQ')
class DependencyHealthMonitoringQueue {
  @Form([
  Field('messageQueueHealth', String, 'Message Queue Health',
    hint: 'Queue depth, consumer lag'),
  Field('dlqMonitoring', bool, 'Dead Letter Queue Monitoring',
    hint: 'Alert on DLQ message accumulation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// External service and certificate checks.
@StandardReferences(
  [
    'Google SRE — health checking and monitoring',
    'ISO/IEC 20000 — service availability management',
  ],
  'Specifies connectivity, certificate-expiry, and DNS-resolution checks for the external service dependencies of the system.',
)
@SectionId('DHME')
class DependencyHealthMonitoringExternal {
  @Form([
  Field('externalServicePing', bool, 'External Service Ping',
    hint: 'Periodic connectivity tests'),
  Field('certificateExpiryCheck', bool, 'Certificate Expiry Check',
    hint: 'Monitor TLS certificate expiration'),
  Field('dnsResolutionCheck', bool, 'DNS Resolution Check',
    hint: 'Verify DNS resolution for dependencies'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Thresholds and cascade protection settings.
@StandardReferences(
  [
    'Google SRE — health checking and monitoring',
    'AWS Well-Architected — reliability pillar (health checks)',
  ],
  'Defines the thresholds that mark a dependency degraded or unavailable and the cascade-protection settings that prevent one failure from spreading.',
)
@SectionId('DHMT')
class DependencyHealthMonitoringThresholds {
  @Form([
  Field('degradedThreshold', String, 'Degraded Threshold',
    hint: 'When to mark dependency as degraded'),
  Field('unavailableThreshold', String, 'Unavailable Threshold',
    hint: 'When to mark dependency as down'),
  Field('cascadeProtection', String, 'Cascade Protection',
    hint: 'Prevent cascading failures'),
  Field('notes', String, 'Notes',
    hint: 'Additional dependency health notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 8.7.3. Capacity Planning.
@StandardReferences(
  [
    'Google SRE — capacity planning and demand forecasting',
    'ISO/IEC 20000 — capacity management process',
    'AWS Well-Architected — reliability pillar (workload scaling)',
  ],
  'Defines the overall capacity planning approach covering growth projections, scaling triggers, baselines, and review cadence.',
)
@ContentHelp('''
Specify capacity planning requirements including growth projections,
scaling triggers, and resource management. Proactive capacity planning
prevents performance degradation and outages.

**Growth Projections**:
- User growth forecasts (monthly, yearly)
- Data volume growth estimates
- Transaction/request volume projections
- Storage growth calculations
- Geographic expansion plans

**Capacity Metrics**:
- CPU utilization thresholds
- Memory consumption patterns
- Storage capacity and growth rate
- Network bandwidth utilization
- Database connection pools

**Scaling Triggers**:
- Auto-scaling metric thresholds
- Manual scaling decision criteria
- Lead time for capacity additions
- Burst capacity requirements
- Cost vs. performance trade-offs

**Resource Baselines**:
- Current resource utilization
- Peak vs. average patterns
- Seasonal variations
- Performance benchmarks
- Efficiency metrics

**Capacity Review Process**:
- Review frequency (monthly, quarterly)
- Forecasting methodology
- Budget allocation process
- Capacity planning tools
- Stakeholder reporting
''')
@SectionId('CPS')
class CapacityPlanningSection {
  @ContentHelp('''
Provide an overview of capacity planning approach.

**Include**:
- Growth projections and assumptions
- Key capacity metrics to track
- Scaling strategy and triggers
- Current capacity headroom
- Planning and review cadence

**Best Practices**:
- Plan for 2-3x peak capacity
- Use data-driven forecasting
- Implement auto-scaling where possible
- Regular capacity reviews
- Budget for growth in advance
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of capacity planning strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// User growth projections.
  @SerializationOrder(2)
  UserGrowthProjections userGrowth = UserGrowthProjections();

  /// Data growth projections.
  @SerializationOrder(3)
  DataGrowthProjections dataGrowth = DataGrowthProjections();

  /// Peak load patterns.
  @SerializationOrder(4)
  PeakLoadPatterns peakLoadPatterns = PeakLoadPatterns();

  /// Scaling triggers and thresholds.
  @SerializationOrder(5)
  ScalingTriggersAndThresholds scalingTriggers =
      ScalingTriggersAndThresholds();

  /// Resource capacity baselines.
  @SerializationOrder(6)
  ResourceCapacityBaselines resourceCapacity = ResourceCapacityBaselines();

  /// Capacity review process.
  @SerializationOrder(7)
  CapacityReviewProcess capacityReview = CapacityReviewProcess();
}

/// User growth projections.
@StandardReferences(
  [
    'Google SRE — capacity planning and demand forecasting',
    'AWS Well-Architected — reliability pillar (workload scaling)',
  ],
  'Establishes current user counts and growth projections that drive downstream capacity forecasts.',
)
@SectionId('USGRPR')
class UserGrowthProjections {
  @Form([
    // Current state
    Field('currentActiveUsers', int, 'Current Active Users',
        required: true, hint: 'Current monthly active user count'),
    Field('currentRegisteredUsers', int, 'Current Registered Users',
        hint: 'Total registered user accounts'),
    Field('currentConcurrentUsers', int, 'Current Concurrent Users',
        hint: 'Peak concurrent user count'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Growth-rate assumptions and time-based projections.
  @SerializationOrder(1)
  UserGrowthProjectionsForecast forecast = UserGrowthProjectionsForecast();

  /// User segmentation and geographic patterns.
  @SerializationOrder(2)
  UserGrowthProjectionsSegmentation segmentation =
    UserGrowthProjectionsSegmentation();

  /// Capacity thresholds and planning notes.
  @SerializationOrder(3)
  UserGrowthProjectionsThresholds thresholds =
    UserGrowthProjectionsThresholds();
}

/// Growth-rate assumptions and time-based projections.
@StandardReferences(
  [
    'Google SRE — capacity planning and demand forecasting',
    'ISO/IEC 20000 — capacity management process',
  ],
  'Projects active user counts at 6 to 36 months from a stated growth rate to drive capacity forecasts.',
)
@SectionId('UGPF')
class UserGrowthProjectionsForecast {
  @Form([
  Field('projectedGrowthRate', String, 'Projected Growth Rate',
    required: true, hint: 'Monthly/yearly user growth percentage'),
  Field('users6Months', int, 'Users at 6 Months',
    hint: 'Expected active users in 6 months'),
  Field('users12Months', int, 'Users at 12 Months',
    hint: 'Expected active users in 12 months'),
  Field('users24Months', int, 'Users at 24 Months',
    hint: 'Expected active users in 24 months'),
  Field('users36Months', int, 'Users at 36 Months',
    hint: 'Expected active users in 36 months'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// User segmentation and geographic patterns.
@StandardReferences(
  [
    'Google SRE — capacity planning and demand forecasting',
    'ISO/IEC 20000 — capacity management process',
  ],
  'Captures user segments, geographic distribution, and seasonal patterns that shape demand forecasts.',
)
@SectionId('UGPS')
class UserGrowthProjectionsSegmentation {
  @Form([
  Field('userSegments', String, 'User Segments',
    hint: 'Growth per user category (free, premium, enterprise)'),
  Field('geographicDistribution', String, 'Geographic Distribution',
    hint: 'Expected user distribution across regions'),
  Field('seasonalPatterns', String, 'Seasonal Patterns',
    hint: 'Monthly/quarterly user volume patterns'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Capacity thresholds and planning notes.
@StandardReferences(
  [
    'Google SRE — capacity planning and demand forecasting',
    'ISO/IEC 20000 — capacity management process',
  ],
  'Defines soft and hard user-capacity limits that trigger system review and scaling actions.',
)
@SectionId('UGPT')
class UserGrowthProjectionsThresholds {
  @Form([
  Field('softCapacityLimit', int, 'Soft Capacity Limit',
    hint: 'User count requiring system review'),
  Field('hardCapacityLimit', int, 'Hard Capacity Limit',
    hint: 'Maximum supportable users before scaling'),
  Field('notes', String, 'Notes',
    hint: 'Additional user growth notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data growth projections.
@StandardReferences(
  [
    'Google SRE — capacity planning and demand forecasting',
    'ISO/IEC 20000 — capacity management process',
  ],
  'Projects data, database, and file-storage growth to drive storage capacity planning.',
)
@SectionId('DAGRPR')
class DataGrowthProjections {
  @Form([
    Field('currentDataVolume', String, 'Current Data Volume',
        required: true, hint: 'Total data size (e.g. 500 GB)'),
    Field('currentDatabaseSize', String, 'Current Database Size',
        hint: 'Primary database storage usage'),
    Field('currentFileStorageSize', String, 'Current File Storage Size',
        hint: 'File/blob storage usage'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Growth-rate assumptions.
  @SerializationOrder(1)
  DataGrowthProjectionsGrowth growth = DataGrowthProjectionsGrowth();

  /// Volume projections.
  @SerializationOrder(2)
  DataGrowthProjectionsProjections projections =
      DataGrowthProjectionsProjections();

  /// Data lifecycle strategy.
  @SerializationOrder(3)
  DataGrowthProjectionsLifecycle lifecycle = DataGrowthProjectionsLifecycle();

  /// Thresholds and notes.
  @SerializationOrder(4)
  DataGrowthProjectionsThresholds thresholds =
      DataGrowthProjectionsThresholds();
}

/// Growth-rate assumptions.
@StandardReferences(
  [
    'Google SRE — capacity planning and demand forecasting',
    'ISO/IEC 20000 — capacity management process',
  ],
  'Captures data growth rate, volume per user, and transaction growth assumptions driving capacity forecasts.',
)
@SectionId('DGPG')
class DataGrowthProjectionsGrowth {
  @Form([
    Field('dataGrowthRate', String, 'Data Growth Rate',
        required: true, hint: 'Monthly data volume increase'),
    Field('dataVolumePerUser', String, 'Data Volume per User',
        hint: 'Average storage per active user'),
    Field('transactionVolumeGrowth', String, 'Transaction Volume Growth',
        hint: 'Growth in daily/monthly transactions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Volume projections.
@StandardReferences(
  [
    'Google SRE — capacity planning and demand forecasting',
    'ISO/IEC 20000 — capacity management process',
  ],
  'Projects total data volume at 6, 12, and 24 months to inform storage capacity planning.',
)
@SectionId('DGPP')
class DataGrowthProjectionsProjections {
  @Form([
    Field('projectedVolume6Months', String, 'Projected Volume at 6 Months',
        hint: 'Expected total data at 6 months'),
    Field('projectedVolume12Months', String, 'Projected Volume at 12 Months',
        hint: 'Expected total data at 12 months'),
    Field('projectedVolume24Months', String, 'Projected Volume at 24 Months',
        hint: 'Expected total data at 24 months'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data lifecycle strategy.
@StandardReferences(
  [
    'ISO/IEC 20000 — capacity management process',
    'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
  ],
  'Defines retention, archival, cleanup, and compression policies that manage data-storage capacity over time.',
)
@SectionId('DGPL')
class DataGrowthProjectionsLifecycle {
  @Form([
    Field('dataRetentionPolicy', String, 'Data Retention Policy',
        hint: 'Hot/warm/cold storage tiers'),
    Field('archivalStrategy', String, 'Archival Strategy',
        hint: 'When and how data moves to archive'),
    Field('dataCleanupPolicy', String, 'Data Cleanup Policy',
        hint: 'Automatic deletion rules'),
    Field('compressionStrategy', String, 'Compression Strategy',
        hint: 'Data compression for storage efficiency'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Thresholds and notes.
@StandardReferences(
  [
    'ISO/IEC 20000 — capacity management process',
    'Google SRE — capacity planning and demand forecasting',
  ],
  'Defines storage alert thresholds and partitioning strategy that govern data-growth capacity limits.',
)
@SectionId('DGPT')
class DataGrowthProjectionsThresholds {
  @Form([
    Field('storageAlertThreshold', String, 'Storage Alert Threshold',
        hint: 'Percentage triggering storage alert (e.g. 80%)'),
    Field('partitioningStrategy', String, 'Partitioning Strategy',
        hint: 'Table/index partitioning approach'),
    Field('notes', String, 'Notes',
        hint: 'Additional data growth notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Peak load patterns.
@StandardReferences(
  [
    'Google SRE — capacity planning and demand forecasting',
    'AWS Well-Architected — reliability pillar (workload scaling)',
  ],
  'Describes daily, weekly, monthly, and yearly peak-load patterns that drive capacity provisioning.',
)
@SectionId('PELOPA')
class PeakLoadPatterns {
  @Form([
    Field('dailyPeakHours', String, 'Daily Peak Hours',
        required: true, hint: 'Hours of highest daily traffic'),
    Field('weeklyPeakDays', String, 'Weekly Peak Days',
        hint: 'Highest traffic days of the week'),
    Field('monthlyPeakPeriods', String, 'Monthly Peak Periods',
        hint: 'Month-end processing, billing cycles'),
    Field('yearlyPeakEvents', String, 'Yearly Peak Events',
        hint: 'Black Friday, tax season, renewals'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Peak metrics.
  @SerializationOrder(1)
  PeakLoadPatternsMetrics metrics = PeakLoadPatternsMetrics();

  /// Load multipliers.
  @SerializationOrder(2)
  PeakLoadPatternsCapacity capacity = PeakLoadPatternsCapacity();

  /// Testing regime.
  @SerializationOrder(3)
  PeakLoadPatternsTesting testing = PeakLoadPatternsTesting();
}

/// Peak metrics.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
    'Google SRE — capacity planning and demand forecasting',
  ],
  'Captures peak RPS, concurrent sessions, and response-time targets that define the workload capacity envelope.',
)
@SectionId('PLPM')
class PeakLoadPatternsMetrics {
  @Form([
  Field('peakRequestsPerSecond', int, 'Peak Requests/Second',
    hint: 'Maximum expected RPS during peak'),
  Field('peakConcurrentSessions', int, 'Peak Concurrent Sessions',
    hint: 'Maximum simultaneous user sessions'),
  Field('averageResponseTimeTarget', String, 'Avg Response Time Target',
    hint: 'Target p50 response time during peak'),
  Field('p99ResponseTimeTarget', String, 'P99 Response Time Target',
    hint: 'Target p99 response time during peak'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Load multipliers.
@StandardReferences(
  [
    'Google SRE — capacity planning and demand forecasting',
    'AWS Well-Architected — reliability pillar (workload scaling)',
  ],
  'Captures peak-to-average ratios, burst capacity, and graceful-degradation plans for extreme load.',
)
@SectionId('PLPC')
class PeakLoadPatternsCapacity {
  @Form([
  Field('peakToAverageRatio', String, 'Peak-to-Average Ratio',
    hint: 'Ratio of peak to normal load (e.g. 3:1)'),
  Field('burstCapacityRequired', String, 'Burst Capacity Required',
    hint: 'Short-duration spike handling'),
  Field('gracefulDegradationPlan', String, 'Graceful Degradation Plan',
    hint: 'What degrades first under extreme load'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing regime.
@StandardReferences(
  [
    'Google SRE — site reliability engineering practices',
    'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
  ],
  'Defines the load-testing cadence, tools, and benchmark baselines used to validate peak capacity.',
)
@SectionId('PLPT')
class PeakLoadPatternsTesting {
  @Form([
  Field('loadTestingFrequency', String, 'Load Testing Frequency',
    hint: 'How often load tests are run'),
  Field('loadTestingTools', String, 'Load Testing Tools',
    hint: 'k6, JMeter, Gatling, Locust'),
  Field('benchmarkBaseline', String, 'Benchmark Baseline',
    hint: 'Current performance baseline metrics'),
  Field('notes', String, 'Notes',
    hint: 'Additional peak load notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scaling triggers and thresholds.
@StandardReferences(
  [
    'AWS Well-Architected — reliability pillar (workload scaling)',
    'Google SRE — capacity planning and demand forecasting',
  ],
  'Defines the CPU thresholds and aggregate signals that trigger horizontal or vertical scaling of the system.',
)
@SectionId('STAT')
class ScalingTriggersAndThresholds {
  @Form([
    Field('cpuScaleUpThreshold', String, 'CPU Scale-Up Threshold',
        required: true, hint: 'CPU % triggering scale-up (e.g. 70%)'),
    Field('cpuScaleDownThreshold', String, 'CPU Scale-Down Threshold',
        hint: 'CPU % triggering scale-down (e.g. 30%)'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Memory-based thresholds.
  @SerializationOrder(1)
  ScalingTriggersAndThresholdsMemory memory =
      ScalingTriggersAndThresholdsMemory();

  /// Request-based thresholds.
  @SerializationOrder(2)
  ScalingTriggersAndThresholdsRequest request =
      ScalingTriggersAndThresholdsRequest();

  /// Scaling behavior.
  @SerializationOrder(3)
  ScalingTriggersAndThresholdsBehavior behavior =
      ScalingTriggersAndThresholdsBehavior();

  /// Scaling types and providers.
  @SerializationOrder(4)
  ScalingTriggersAndThresholdsType type = ScalingTriggersAndThresholdsType();
}

/// Memory-based thresholds.
@StandardReferences(
  [
    'AWS Well-Architected — reliability pillar (workload scaling)',
    'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
  ],
  'Defines the memory-utilization thresholds that trigger scale-up and scale-down of the workload.',
)
@SectionId('STATM')
class ScalingTriggersAndThresholdsMemory {
  @Form([
    Field('memoryScaleUpThreshold', String, 'Memory Scale-Up Threshold',
        hint: 'Memory % triggering scale-up'),
    Field('memoryScaleDownThreshold', String, 'Memory Scale-Down Threshold',
        hint: 'Memory % triggering scale-down'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Request-based thresholds.
@StandardReferences(
  [
    'AWS Well-Architected — reliability pillar (workload scaling)',
    'Google SRE — site reliability engineering practices',
  ],
  'Defines request-rate, latency, and queue-depth thresholds that trigger scaling of the workload.',
)
@SectionId('STATR')
class ScalingTriggersAndThresholdsRequest {
  @Form([
    Field('requestRateScaleUpThreshold', String, 'Request Rate Scale-Up',
        hint: 'RPS threshold for scaling up'),
    Field('responseTimeScaleUpThreshold', String, 'Response Time Scale-Up',
        hint: 'Latency threshold triggering scale-up'),
    Field('queueDepthScaleUpThreshold', String, 'Queue Depth Scale-Up',
        hint: 'Message queue depth triggering scale-up'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scaling behavior.
@StandardReferences(
  [
    'AWS Well-Architected — reliability pillar (workload scaling)',
    'Google SRE — site reliability engineering practices',
  ],
  'Defines scaling cooldowns, min/max instance bounds, and step size that govern how the system scales.',
)
@SectionId('STATB')
class ScalingTriggersAndThresholdsBehavior {
  @Form([
    Field('scalingCooldownPeriod', String, 'Scaling Cooldown Period',
        hint: 'Minimum time between scaling events'),
    Field('minInstances', int, 'Minimum Instances',
        hint: 'Minimum number of running instances'),
    Field('maxInstances', int, 'Maximum Instances',
        hint: 'Maximum number of running instances'),
    Field('scalingStepSize', String, 'Scaling Step Size',
        hint: 'Instances added per scale-up event'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scaling types and providers.
@StandardReferences(
  [
    'The Twelve-Factor App — concurrency (scale out via the process model)',
    'AWS Well-Architected — reliability pillar (workload scaling)',
  ],
  'Selects horizontal versus vertical scaling, the auto-scaling provider, and scheduled scaling for known peaks.',
)
@SectionId('STATT')
class ScalingTriggersAndThresholdsType {
  @Form([
    Field('horizontalScaling', bool, 'Horizontal Scaling',
        hint: 'Add more instances'),
    Field('verticalScaling', bool, 'Vertical Scaling',
        hint: 'Increase instance resources'),
    Field('autoScalingProvider', String, 'Auto-Scaling Provider',
        hint: 'Kubernetes HPA, AWS Auto Scaling, Azure VMSS'),
    Field('scheduledScaling', String, 'Scheduled Scaling',
        hint: 'Pre-scale for known peak events'),
    Field('notes', String, 'Notes',
        hint: 'Additional scaling trigger notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Resource capacity baselines.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
    'Google SRE — capacity planning and demand forecasting',
  ],
  'Establishes normal CPU, memory, and instance-count baselines against which growth and scaling are measured.',
)
@SectionId('RECABA')
class ResourceCapacityBaselines {
  @Form([
    // Compute
    Field('cpuBaseline', String, 'CPU Baseline',
        required: true, hint: 'Normal CPU utilization per service'),
    Field('memoryBaseline', String, 'Memory Baseline',
        hint: 'Normal memory usage per service'),
    Field('instanceCountBaseline', String, 'Instance Count Baseline',
        hint: 'Normal number of running instances'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Storage baselines.
  @SerializationOrder(1)
  ResourceCapacityBaselinesStorage storage = ResourceCapacityBaselinesStorage();

  /// Network baselines.
  @SerializationOrder(2)
  ResourceCapacityBaselinesNetwork network = ResourceCapacityBaselinesNetwork();

  /// Database baselines.
  @SerializationOrder(3)
  ResourceCapacityBaselinesDatabase database =
    ResourceCapacityBaselinesDatabase();

  /// Cost baselines and notes.
  @SerializationOrder(4)
  ResourceCapacityBaselinesCost cost = ResourceCapacityBaselinesCost();
}

/// Storage baselines.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
    'ISO/IEC 20000 — capacity management process',
  ],
  'Records normal storage IOPS and throughput as capacity baselines for the workload.',
)
@SectionId('RCBS')
class ResourceCapacityBaselinesStorage {
  @Form([
  Field('storageIOPSBaseline', String, 'Storage IOPS Baseline',
    hint: 'Normal storage I/O operations per second'),
  Field('storageThroughputBaseline', String, 'Storage Throughput Baseline',
    hint: 'Normal storage throughput (MB/s)'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Network baselines.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
    'ISO/IEC 20000 — capacity management process',
  ],
  'Records normal network bandwidth and active connection counts as capacity baselines.',
)
@SectionId('RCBN')
class ResourceCapacityBaselinesNetwork {
  @Form([
  Field('networkBandwidthBaseline', String, 'Network Bandwidth Baseline',
    hint: 'Normal network usage (Mbps)'),
  Field('connectionCountBaseline', String, 'Connection Count Baseline',
    hint: 'Normal active connection count'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Database baselines.
@StandardReferences(
  [
    'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
    'ISO/IEC 20000 — capacity management process',
  ],
  'Records normal database connection-pool usage, query volume, and on-disk size as capacity baselines.',
)
@SectionId('RCBD')
class ResourceCapacityBaselinesDatabase {
  @Form([
  Field('databaseConnectionPoolBaseline', String,
    'DB Connection Pool Baseline',
    hint: 'Normal active DB connections'),
  Field('queryVolumeBaseline', String, 'Query Volume Baseline',
    hint: 'Normal queries per second'),
  Field('databaseSizeBaseline', String, 'Database Size Baseline',
    hint: 'Current database on-disk size'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cost baselines and notes.
@StandardReferences(
  [
    'AWS Well-Architected — reliability pillar (workload scaling)',
    'Google SRE — capacity planning and demand forecasting',
  ],
  'Establishes baseline infrastructure cost, cost per user, and projected cost at target scale.',
)
@SectionId('RCBC')
class ResourceCapacityBaselinesCost {
  @Form([
  Field('currentMonthlyCost', String, 'Current Monthly Cost',
    hint: 'Baseline monthly infrastructure cost'),
  Field('costPerUser', String, 'Cost Per User',
    hint: 'Infrastructure cost per active user'),
  Field('projectedCostAtScale', String, 'Projected Cost at Scale',
    hint: 'Estimated cost at target user count'),
  Field('notes', String, 'Notes',
    hint: 'Additional resource baseline notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Capacity review process.
@StandardReferences(
  [
    'ISO/IEC 20000 — capacity management process',
    'ITIL 4 — capacity and performance management',
  ],
  'Defines the recurring review cadence, participants, and checklist that govern ongoing capacity management.',
)
@SectionId('CAREPR')
class CapacityReviewProcess {
  @Form([
    Field('reviewFrequency', String, 'Review Frequency',
        required: true, hint: 'Monthly, quarterly, on-demand'),
    Field('reviewParticipants', String, 'Review Participants',
        hint: 'Engineering, ops, finance stakeholders'),
    Field('reviewChecklist', String, 'Review Checklist',
        hint: 'Standard items reviewed each cycle'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Monitoring and forecasting inputs.
  @SerializationOrder(1)
  CapacityReviewProcessMonitoring monitoring =
    CapacityReviewProcessMonitoring();

  /// Escalation and emergency scaling decisions.
  @SerializationOrder(2)
  CapacityReviewProcessEscalation escalation =
    CapacityReviewProcessEscalation();

  /// Budgeting and rightsizing planning.
  @SerializationOrder(3)
  CapacityReviewProcessPlanning planning = CapacityReviewProcessPlanning();
}

/// Monitoring and forecasting inputs for capacity review.
@StandardReferences(
  [
    'Google SRE — capacity planning and demand forecasting',
    'ISO/IEC 20000 — capacity management process',
  ],
  'Captures the dashboards, trend analysis, and forecasting models that feed capacity review decisions.',
)
@SectionId('CAREPRMO')
class CapacityReviewProcessMonitoring {
  @Form([
  Field('capacityDashboard', bool, 'Capacity Dashboard',
    hint: 'Dedicated capacity monitoring dashboard'),
  Field('trendAnalysis', bool, 'Trend Analysis',
    hint: 'Automated growth trend detection'),
  Field('forecastingModel', String, 'Forecasting Model',
    hint: 'Linear, exponential, ML-based forecasting'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Escalation and emergency scaling decisions for capacity review.
@StandardReferences(
  [
    'ITIL 4 — capacity and performance management',
    'Google SRE — site reliability engineering practices',
  ],
  'Defines capacity alert thresholds, escalation procedures, and emergency scaling steps for the capacity review process.',
)
@SectionId('CRPE')
class CapacityReviewProcessEscalation {
  @Form([
  Field('capacityAlertThresholds', String, 'Capacity Alert Thresholds',
    hint: 'Warning: 70%, critical: 85%, emergency: 95%'),
  Field('escalationProcedure', String, 'Escalation Procedure',
    hint: 'Who to notify at each threshold level'),
  Field('emergencyScalingProcedure', String, 'Emergency Scaling Procedure',
    hint: 'Steps for urgent capacity increase'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Budgeting and rightsizing planning for capacity review.
@StandardReferences(
  [
    'ISO/IEC 20000 — capacity management process',
    'Google SRE — capacity planning and demand forecasting',
  ],
  'Captures budget integration, procurement lead time, and rightsizing decisions produced by the capacity review.',
)
@SectionId('CRPP')
class CapacityReviewProcessPlanning {
  @Form([
  Field('budgetPlanningIntegration', bool, 'Budget Planning Integration',
    hint: 'Capacity forecasts feed into budget cycles'),
  Field('procurementLeadTime', String, 'Procurement Lead Time',
    hint: 'Time to provision new resources'),
  Field('rightsizingReview', bool, 'Rightsizing Review',
    hint: 'Periodic over-provisioning review'),
  Field('notes', String, 'Notes',
    hint: 'Additional capacity review notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 8.8. Security Requirements.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security management system',
    'NIST Cybersecurity Framework — identify, protect, detect, respond, recover',
    'OWASP ASVS — application security verification standard',
  ],
  'Defines the technical security requirements: IT security standards, data protection and privacy, and security audit; the access-control model itself is specified in SBP.12 Security and Access and referenced here.',
)
@DetailedIn(D06ArchitectureTechnologySpecification)
@SecondLevelSectionId(D06ArchitectureTechnologySpecification, 'ATS-SEC')
@ContentHelp('''
Define comprehensive security requirements including IT security standards,
data protection, privacy, and security auditing. Security is foundational
and must be considered throughout the system lifecycle.

**Subsections**:
- **IT Security Standards**: OWASP compliance, infrastructure hardening,
  vulnerability management, security development lifecycle
- **Data Protection and Privacy**: GDPR/CCPA compliance, data residency,
  consent management, data subject rights, encryption
- **Security Audit Requirements**: Penetration testing, code review,
  dependency scanning, certifications, compliance audits

**Security Principles**:
- Defense in depth
- Least privilege
- Zero trust architecture
- Secure by default
- Fail securely

**Security Domains** (technical requirements and standards only):
- Application security (OWASP Top 10, secure coding)
- Infrastructure security (network, cloud, endpoints)
- Data security (encryption, DLP)
- Incident response (detection, response, recovery)

**Ownership boundary**: This section owns *technical security
requirements and standards*. The identity and access-control **model**
(authentication, authorization, roles, permissions) is owned by SBP.12
`SecurityAndAccessModel` — reference it here, do not restate it.

**Reference Frameworks**: NIST Cybersecurity Framework, ISO 27001,
CIS Controls, OWASP ASVS, SOC 2 Trust Criteria.
''')
@SectionId('TSR')
class TechnicalSecurityRequirements {
  @ContentHelp('''
Provide an overview of security approach and governance.

**Include**:
- Security principles and philosophy
- Key security domains and controls
- Compliance and certification requirements
- Security team and responsibilities
- Security metrics and reporting

**Best Practices**:
- Shift security left (earlier in SDLC)
- Automate security testing
- Regular security training
- Threat modeling for new features
- Continuous security improvement
''')
  @SerializationOrder(0)
  String? content;

  /// 8.8.1. IT Security Standards.
  @SerializationOrder(1)
  ItSecurityStandardsSection itSecurityStandards =
      ItSecurityStandardsSection();

  /// 8.8.2. Data Protection and Privacy.
  @SerializationOrder(2)
  DataProtectionAndPrivacySection dataProtectionAndPrivacy =
      DataProtectionAndPrivacySection();

  /// 8.8.3. Security Audit Requirements.
  @SerializationOrder(3)
  SecurityAuditRequirementsSection securityAuditRequirements =
      SecurityAuditRequirementsSection();
}

/// 8.8.1. IT Security Standards.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security management system',
    'NIST Cybersecurity Framework — identify, protect, detect, respond, recover',
    'OWASP ASVS — application security verification standard',
  ],
  'The overall IT security standards section covering application, infrastructure, vulnerability, and incident response requirements.',
)
@ContentHelp('''
Specify IT security standards including application security, infrastructure
security, vulnerability management, and security development practices.
Following established standards reduces security risk systematically.

**Application Security (OWASP)**:
- OWASP Top 10 mitigation (injection, XSS, CSRF, etc.)
- OWASP ASVS (Application Security Verification Standard)
- Secure coding guidelines by language
- Input validation and output encoding
- Authentication and session management

**Infrastructure Security**:
- Server hardening (CIS Benchmarks)
- Network security (firewall rules, segmentation)
- Cloud security configuration (AWS/Azure/GCP best practices)
- Container security (image scanning, runtime protection)
- Endpoint security (device management, AV/EDR)

**Security Development Lifecycle**:
- Threat modeling during design
- Security requirements in user stories
- Security code review process
- Security testing (SAST, DAST, IAST)
- Secure deployment practices

**Vulnerability Management**:
- Vulnerability scanning frequency
- CVE monitoring and response time
- Patch management procedures
- Risk-based prioritization
- Vulnerability disclosure process

**Incident Response**:
- Incident detection mechanisms
- Response playbooks
- Communication templates
- Recovery procedures
- Postmortem process
''')
@SectionId('ISSS')
class ItSecurityStandardsSection {
  @ContentHelp('''
Provide an overview of IT security standards approach.

**Include**:
- Security standards adopted (OWASP, CIS, NIST)
- Application security requirements
- Infrastructure security baseline
- Vulnerability management program
- Security development integration

**Best Practices**:
- Automate security testing in CI/CD
- Regular security training for developers
- Maintain security champions in teams
- Track security metrics and trends
- Continuous security improvement
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of IT security standards strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Security standards and frameworks — contains 0+× SecurityStandard.
  @StandardReferences(
    ['ISO/IEC 27001 — information security management system'],
    'The catalog of security standards and frameworks the system conforms to.',
  )
  @SectionId('SESTEN-STAN-LST')
  @SectionIdPattern('SESTEN-STAN-xxx')
  @ContentHelp('Add one entry per security standard.')
  @SerializationOrder(2)
  List<SecurityStandardEntry> standards = [];

  /// Application security requirements (OWASP).
  @SerializationOrder(3)
  ApplicationSecurityRequirements applicationSecurity =
      ApplicationSecurityRequirements();

  /// Infrastructure security hardening.
  @SerializationOrder(4)
  InfrastructureSecurityHardening infrastructureSecurity =
      InfrastructureSecurityHardening();

  /// Security development lifecycle.
  @SerializationOrder(5)
  SecurityDevelopmentLifecycle securityDevLifecycle =
      SecurityDevelopmentLifecycle();

  /// Vulnerability management.
  @SerializationOrder(6)
  VulnerabilityManagementPolicy vulnerabilityManagement =
      VulnerabilityManagementPolicy();

  /// Incident response plan.
  @SerializationOrder(7)
  IncidentResponsePlan incidentResponse = IncidentResponsePlan();
}

/// A security standard entry (form).
@StandardReferences(
  [
    'ISO/IEC 27001 — information security management system',
    'ISO/IEC 27002 — information security controls',
  ],
  'A single security standard or framework the system conforms to, with its name, version, and issuing body.',
)
@SectionId('SSE')
class SecurityStandardEntry {
  @Form([
    Field('standardName', String, 'Standard Name',
        required: true, hint: 'E.g., OWASP Top 10, ISO 27001, SOC 2, NIST CSF'),
    Field('standardVersion', String, 'Standard Version',
        hint: 'Version or year of the standard'),
    Field('standardType', String, 'Standard Type',
        hint: 'Framework, Certification, Guideline, Benchmark'),
    Field('issuingBody', String, 'Issuing Body',
        hint: 'Organization that publishes the standard'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Applicability and regulatory scope.
  @SerializationOrder(1)
  SecurityStandardEntryScope scope = SecurityStandardEntryScope();

  /// Implementation status and planning.
  @SerializationOrder(2)
  SecurityStandardEntryImplementation implementation =
      SecurityStandardEntryImplementation();

  /// Verification and ownership.
  @SerializationOrder(3)
  SecurityStandardEntryVerification verification =
      SecurityStandardEntryVerification();
}

/// Applicability and regulatory scope.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security management system',
    'NIST SP 800-53 — security and privacy controls',
  ],
  'The applicability scope and regulatory drivers that make a security standard relevant.',
)
@SectionId('SESTENSC')
class SecurityStandardEntryScope {
  @Form([
    Field('applicabilityScope', String, 'Applicability Scope',
        hint: 'Which systems, services, or data this applies to'),
    Field('mandatoryOrVoluntary', String, 'Mandatory / Voluntary',
        hint: 'Regulatory requirement or best-practice adoption'),
    Field('regulatoryDriver', String, 'Regulatory Driver',
        hint: 'Regulation requiring this standard (e.g. GDPR, PCI-DSS)'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Implementation status and planning.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security management system',
    'ISO/IEC 27002 — information security controls',
  ],
  'The implementation status, target compliance date, and gap analysis for a security standard.',
)
@SectionId('SSEI')
class SecurityStandardEntryImplementation {
  @Form([
    Field('implementationStatus', String, 'Implementation Status',
        hint: 'Planned, In Progress, Implemented, Certified'),
    Field('targetComplianceDate', String, 'Target Compliance Date',
        hint: 'Date by which compliance must be achieved'),
    Field('controlsRequired', String, 'Controls Required',
        hint: 'Key control areas to implement'),
    Field('gapAnalysis', String, 'Gap Analysis',
        hint: 'Summary of current gaps against the standard'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Verification and ownership.
@StandardReferences(
  [
    'ISO/IEC 27001 — information security management system',
    'NIST Cybersecurity Framework — identify, protect, detect, respond, recover',
  ],
  'The certification, assessment, and evidence requirements verifying conformance to a standard.',
)
@SectionId('SSEV')
class SecurityStandardEntryVerification {
  @Form([
    Field('certificationRequired', bool, 'Certification Required',
        hint: 'Whether formal certification is needed'),
    Field('assessmentFrequency', String, 'Assessment Frequency',
        hint: 'How often compliance is assessed'),
    Field('evidenceRequirements', String, 'Evidence Requirements',
        hint: 'Documentation and artifacts to maintain'),
    Field('responsibleTeam', String, 'Responsible Team',
        hint: 'Team/role accountable for compliance'),
    Field('notes', String, 'Notes',
        hint: 'Additional security standard notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Application security requirements (OWASP-based).
@StandardReferences(
  [
    'OWASP Top 10 — web application security risks',
    'OWASP ASVS — application security verification standard',
  ],
  'The application-level security requirements derived from OWASP standards.',
)
@SectionId('APSERE')
class ApplicationSecurityRequirements {
  @Form([
    Field('owaspTop10Compliance', String, 'OWASP Top 10 Compliance',
        required: true, hint: 'Current OWASP Top 10 version addressed'),
    Field('injectionPrevention', String, 'Injection Prevention',
        hint: 'SQL injection, XSS, command injection measures'),
    Field('authenticationControls', String, 'Authentication Controls',
        hint: 'Broken authentication prevention'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Core protection controls.
  @SerializationOrder(1)
  ApplicationSecurityRequirementsControls controls =
      ApplicationSecurityRequirementsControls();

  /// Input and output validation.
  @SerializationOrder(2)
  ApplicationSecurityRequirementsValidation validation =
      ApplicationSecurityRequirementsValidation();

  /// API and browser-facing protections.
  @SerializationOrder(3)
  ApplicationSecurityRequirementsApi api =
      ApplicationSecurityRequirementsApi();
}

/// Core protection controls.
@StandardReferences(
  [
    'OWASP Top 10 — web application security risks',
    'OWASP ASVS — application security verification standard',
  ],
  'Core protections against sensitive data exposure, misconfiguration, CSRF, and SSRF, with the access-control model specified in SBP.12.',
)
@SectionId('ASRC')
class ApplicationSecurityRequirementsControls {
  @Form([
    Field('sensitiveDataExposure', String, 'Sensitive Data Exposure',
        hint: 'Encryption, masking, tokenization'),
    Field('accessControlEnforcement', String, 'Access Control Enforcement',
        hint: 'Broken access control prevention'),
    Field('securityMisconfiguration', String, 'Security Misconfiguration',
        hint: 'Default credentials, open ports, debug mode'),
    Field('csrfProtection', String, 'CSRF Protection',
        hint: 'Cross-site request forgery prevention'),
    Field('ssrfProtection', String, 'SSRF Protection',
        hint: 'Server-side request forgery prevention'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Input and output validation.
@StandardReferences(
  [
    'OWASP Top 10 — web application security risks',
    'OWASP ASVS — application security verification standard',
  ],
  'Input validation, output encoding, and file upload security controls for the application.',
)
@SectionId('ASRV')
class ApplicationSecurityRequirementsValidation {
  @Form([
    Field('inputValidationStrategy', String, 'Input Validation Strategy',
        hint: 'Whitelist, sanitization, encoding'),
    Field('outputEncoding', String, 'Output Encoding',
        hint: 'HTML, URL, JavaScript encoding'),
    Field('fileUploadSecurity', String, 'File Upload Security',
        hint: 'File type, size, malware scanning'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// API and browser-facing protections.
@StandardReferences(
  [
    'OWASP Top 10 — web application security risks',
    'OWASP ASVS — application security verification standard',
  ],
  'Protections for APIs and browsers including API security standards, rate limiting, and content security policy.',
)
@SectionId('ASRA')
class ApplicationSecurityRequirementsApi {
  @Form([
    Field('apiSecurityStandard', String, 'API Security Standard',
        hint: 'OWASP API Security Top 10 measures'),
    Field('rateLimiting', String, 'Rate Limiting',
        hint: 'API rate limiting and throttling'),
    Field('contentSecurityPolicy', String, 'Content Security Policy',
        hint: 'CSP headers and directives'),
    Field('notes', String, 'Notes',
        hint: 'Additional application security notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Infrastructure security hardening.
@StandardReferences(
  [
    'CIS Benchmarks — secure configuration and hardening',
    'NIST SP 800-53 — security and privacy controls',
  ],
  'The baseline hardening of operating systems, networks, and access for the infrastructure.',
)
@SectionId('INSEHA')
class InfrastructureSecurityHardening {
  @Form([
    Field('osHardeningBaseline', String, 'OS Hardening Baseline',
        required: true, hint: 'CIS Benchmark, DISA STIG, custom baseline'),
    Field('patchManagementPolicy', String, 'Patch Management Policy',
        hint: 'Patching cadence, critical patch SLA'),
    Field('minimumInstallation', bool, 'Minimum Installation',
        hint: 'Remove unnecessary packages and services'),
    Field('firewallRules', String, 'Firewall Rules',
        hint: 'Default deny, explicit allow rules'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Container security.
  @SerializationOrder(1)
  InfrastructureSecurityHardeningContainer container =
    InfrastructureSecurityHardeningContainer();

  /// Network hardening.
  @SerializationOrder(2)
  InfrastructureSecurityHardeningNetwork network =
    InfrastructureSecurityHardeningNetwork();

  /// Access hardening.
  @SerializationOrder(3)
  InfrastructureSecurityHardeningAccess access =
    InfrastructureSecurityHardeningAccess();
}

/// Container security.
@StandardReferences(
  [
    'CIS Benchmarks — secure configuration and hardening',
    'NIST SP 800-53 — security and privacy controls',
  ],
  'Container and orchestration hardening covering base images, scanning, and runtime security.',
)
@SectionId('ISHC')
class InfrastructureSecurityHardeningContainer {
  @Form([
  Field('containerBaseImages', String, 'Container Base Images',
    hint: 'Approved base images, distroless, Alpine'),
  Field('containerScanning', String, 'Container Scanning',
    hint: 'Image vulnerability scanning tool'),
  Field('containerRuntimeSecurity', String, 'Container Runtime Security',
    hint: 'Read-only filesystems, non-root, capabilities'),
  Field('containerOrchestrationSecurity', String, 'Orchestration Security',
    hint: 'K8s RBAC, network policies, pod security'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Network hardening.
@StandardReferences(
  [
    'CIS Benchmarks — secure configuration and hardening',
    'NIST SP 800-53 — security and privacy controls',
  ],
  'Network-level hardening through segmentation, internal TLS, and DNS security policy.',
)
@SectionId('ISHN')
class InfrastructureSecurityHardeningNetwork {
  @Form([
  Field('networkSegmentation', String, 'Network Segmentation',
    hint: 'VPC, subnet, security group strategy'),
  Field('internalTlsCommunication', bool, 'Internal TLS Communication',
    hint: 'Service-to-service mTLS'),
  Field('dnsSecurityPolicy', String, 'DNS Security Policy',
    hint: 'DNSSEC, private DNS zones'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access hardening.
@StandardReferences(
  [
    'CIS Benchmarks — secure configuration and hardening',
    'NIST SP 800-53 — security and privacy controls',
  ],
  'Hardening of infrastructure access through SSH policy, privileged access management, and service accounts, with the access-control model specified in SBP.12.',
)
@SectionId('ISHA')
class InfrastructureSecurityHardeningAccess {
  @Form([
  Field('sshAccessPolicy', String, 'SSH Access Policy',
    hint: 'Key-only auth, bastion hosts, session recording'),
  Field('privilegedAccessManagement', String, 'Privileged Access Management',
    hint: 'PAM tool, just-in-time access'),
  Field('serviceAccountPolicy', String, 'Service Account Policy',
    hint: 'Least privilege, rotation, naming'),
  Field('notes', String, 'Notes',
    hint: 'Additional infrastructure security notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security development lifecycle.
@StandardReferences(
  [
    'OWASP SAMM — software assurance maturity model (secure SDLC)',
    'NIST SP 800-53 — security and privacy controls',
  ],
  'The integration of threat modeling and security controls across the software development lifecycle.',
)
@SectionId('SEDELI')
class SecurityDevelopmentLifecycle {
  @Form([
    Field('threatModeling', String, 'Threat Modeling',
        required: true, hint: 'STRIDE, PASTA, Attack Trees methodology'),
    Field('threatModelingFrequency', String, 'Threat Modeling Frequency',
        hint: 'Per feature, per release, quarterly'),
    Field('securityDesignReview', bool, 'Security Design Review',
        hint: 'Mandatory security review of architecture'),
    Field('securityRequirementsProcess', String, 'Security Requirements Process',
        hint: 'How security requirements are gathered'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Development-phase controls.
  @SerializationOrder(1)
  SecurityDevelopmentLifecycleDevelopment development =
      SecurityDevelopmentLifecycleDevelopment();

  /// Testing-phase controls.
  @SerializationOrder(2)
  SecurityDevelopmentLifecycleTesting testing =
      SecurityDevelopmentLifecycleTesting();

  /// Release-phase controls.
  @SerializationOrder(3)
  SecurityDevelopmentLifecycleRelease release =
      SecurityDevelopmentLifecycleRelease();
}

/// Development-phase controls.
@StandardReferences(
  [
    'OWASP SAMM — software assurance maturity model (secure SDLC)',
    'OWASP ASVS — application security verification standard',
  ],
  'The secure coding, static analysis, and dependency scanning controls applied during development.',
)
@SectionId('SDLD')
class SecurityDevelopmentLifecycleDevelopment {
  @Form([
    Field('secureCodeTraining', String, 'Secure Code Training',
        hint: 'Developer security training frequency'),
    Field('staticAnalysis', String, 'Static Analysis (SAST)',
        hint: 'SAST tool and integration point'),
    Field('secretDetection', String, 'Secret Detection',
        hint: 'Pre-commit hooks, CI scanning for secrets'),
    Field('dependencyScanning', String, 'Dependency Scanning (SCA)',
        hint: 'SCA tool for known vulnerabilities'),
    Field('licenseScannerPolicy', String, 'License Compliance Scanning',
        hint: 'OSS license compatibility checking'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing-phase controls.
@StandardReferences(
  [
    'OWASP SAMM — software assurance maturity model (secure SDLC)',
    'OWASP ASVS — application security verification standard',
  ],
  'The dynamic, interactive, and manual security testing performed during the testing phase.',
)
@SectionId('SDLT')
class SecurityDevelopmentLifecycleTesting {
  @Form([
    Field('dynamicAnalysis', String, 'Dynamic Analysis (DAST)',
        hint: 'DAST tool and test frequency'),
    Field('interactiveAnalysis', String, 'Interactive Analysis (IAST)',
        hint: 'IAST tool for runtime detection'),
    Field('securityTestingInCi', bool, 'Security Testing in CI',
        hint: 'Automated security tests in pipeline'),
    Field('manualCodeReview', String, 'Manual Code Review',
        hint: 'Security-focused code review process'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Release-phase controls.
@StandardReferences(
  [
    'OWASP SAMM — software assurance maturity model (secure SDLC)',
    'NIST SP 800-53 — security and privacy controls',
  ],
  'The security gates and change tracking applied before releasing software to production.',
)
@SectionId('SDLR')
class SecurityDevelopmentLifecycleRelease {
  @Form([
    Field('preReleaseSecurityGate', bool, 'Pre-Release Security Gate',
        hint: 'Security sign-off before production deploy'),
    Field('securityChangeLog', bool, 'Security Change Log',
        hint: 'Track security-relevant changes'),
    Field('notes', String, 'Notes',
        hint: 'Additional security dev lifecycle notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Vulnerability management policy.
@StandardReferences(
  [
    'NIST SP 800-40 — enterprise patch and vulnerability management',
    'CIS Controls — critical security controls',
  ],
  'The program for scanning, classifying, and remediating security vulnerabilities across systems.',
)
@SectionId('VUMAPO')
class VulnerabilityManagementPolicy {
  @Form([
    Field('vulnerabilityScanningTool', String, 'Vulnerability Scanning Tool',
        required: true, hint: 'Nessus, Qualys, Tenable, Trivy'),
    Field('scanFrequency', String, 'Scan Frequency',
        hint: 'Daily, weekly, on each deployment'),
    Field('scanScope', String, 'Scan Scope',
        hint: 'Infrastructure, applications, containers, dependencies'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Severity classification.
  @SerializationOrder(1)
  VulnerabilityManagementPolicyClassification classification =
    VulnerabilityManagementPolicyClassification();

  /// Remediation process.
  @SerializationOrder(2)
  VulnerabilityManagementPolicyProcess process =
    VulnerabilityManagementPolicyProcess();

  /// Reporting and disclosure.
  @SerializationOrder(3)
  VulnerabilityManagementPolicyReporting reporting =
    VulnerabilityManagementPolicyReporting();
}

/// Severity classification.
@StandardReferences(
  [
    'NIST SP 800-40 — enterprise patch and vulnerability management',
    'CIS Controls — critical security controls',
  ],
  'The CVSS-based severity classification and patch SLA targets for each vulnerability level.',
)
@SectionId('VMPC')
class VulnerabilityManagementPolicyClassification {
  @Form([
  Field('severityClassification', String, 'Severity Classification',
    hint: 'CVSS-based: Critical, High, Medium, Low'),
  Field('criticalVulnSla', String, 'Critical Vulnerability SLA',
    hint: 'Max time to patch critical (e.g. 24h)'),
  Field('highVulnSla', String, 'High Vulnerability SLA',
    hint: 'Max time to patch high (e.g. 7d)'),
  Field('mediumVulnSla', String, 'Medium Vulnerability SLA',
    hint: 'Max time to patch medium (e.g. 30d)'),
  Field('lowVulnSla', String, 'Low Vulnerability SLA',
    hint: 'Max time to patch low (e.g. 90d)'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Remediation process.
@StandardReferences(
  [
    'NIST SP 800-40 — enterprise patch and vulnerability management',
    'NIST SP 800-53 — security and privacy controls',
  ],
  'The remediation, risk-acceptance, and zero-day response workflow for tracked vulnerabilities.',
)
@SectionId('VMPP')
class VulnerabilityManagementPolicyProcess {
  @Form([
  Field('vulnerabilityTracking', String, 'Vulnerability Tracking',
    hint: 'Jira, dedicated vulnerability tool'),
  Field('riskAcceptanceProcess', String, 'Risk Acceptance Process',
    hint: 'When and how to accept residual risk'),
  Field('exceptionProcess', String, 'Exception Process',
    hint: 'Temporary exception workflow and approvals'),
  Field('zeroDayResponsePlan', String, 'Zero-Day Response Plan',
    hint: 'Emergency response for zero-day exploits'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reporting and disclosure.
@StandardReferences(
  [
    'NIST SP 800-40 — enterprise patch and vulnerability management',
    'OWASP SAMM — software assurance maturity model (secure SDLC)',
  ],
  'How vulnerability findings are reported and how responsible disclosure is handled.',
)
@SectionId('VMPR')
class VulnerabilityManagementPolicyReporting {
  @Form([
  Field('vulnerabilityReporting', String, 'Vulnerability Reporting',
    hint: 'Dashboard, weekly report, executive summary'),
  Field('responsibleDisclosure', String, 'Responsible Disclosure',
    hint: 'Bug bounty, security.txt, disclosure policy'),
  Field('notes', String, 'Notes',
    hint: 'Additional vulnerability management notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Incident response plan.
@StandardReferences(
  [
    'NIST Cybersecurity Framework — identify, protect, detect, respond, recover',
    'ISO/IEC 27001 — information security management system',
  ],
  'The overall plan for detecting, responding to, and recovering from security incidents.',
)
@SectionId('INREPL')
class IncidentResponsePlan {
  @Form([
    Field('incidentSeverityLevels', String, 'Incident Severity Levels',
        required: true, hint: 'SEV1-SEV4 definitions for security incidents'),
    Field('incidentCategories', String, 'Incident Categories',
        hint: 'Data breach, unauthorized access, malware, DDoS'),
    Field('detectionMechanisms', String, 'Detection Mechanisms',
        hint: 'SIEM, IDS/IPS, anomaly detection, user reports'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Response process.
  @SerializationOrder(1)
  IncidentResponsePlanProcess process = IncidentResponsePlanProcess();

  /// Communication requirements.
  @SerializationOrder(2)
  IncidentResponsePlanCommunication communication =
    IncidentResponsePlanCommunication();

  /// Post-incident activities.
  @SerializationOrder(3)
  IncidentResponsePlanPostIncident postIncident =
    IncidentResponsePlanPostIncident();
}

/// Response process.
@StandardReferences(
  [
    'NIST Cybersecurity Framework — identify, protect, detect, respond, recover',
    'NIST SP 800-53 — security and privacy controls',
  ],
  'The containment, eradication, and recovery procedures followed when responding to an incident.',
)
@SectionId('IRPP')
class IncidentResponsePlanProcess {
  @Form([
  Field('initialResponseSla', String, 'Initial Response SLA',
    hint: 'Time to acknowledge and begin triage'),
  Field('containmentProcedure', String, 'Containment Procedure',
    hint: 'Steps to isolate affected systems'),
  Field('eradicationProcedure', String, 'Eradication Procedure',
    hint: 'Steps to remove threat from systems'),
  Field('recoveryProcedure', String, 'Recovery Procedure',
    hint: 'Steps to restore normal operations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Communication requirements.
@StandardReferences(
  [
    'NIST Cybersecurity Framework — identify, protect, detect, respond, recover',
    'ISO/IEC 27001 — information security management system',
  ],
  'Notification, escalation, and external communication requirements during a security incident.',
)
@SectionId('IRPC')
class IncidentResponsePlanCommunication {
  @Form([
  Field('notificationRequirements', String, 'Notification Requirements',
    hint: 'Regulatory breach notification timelines'),
  Field('internalEscalation', String, 'Internal Escalation',
    hint: 'Escalation paths and contacts'),
  Field('externalCommunication', String, 'External Communication',
    hint: 'Customer notification, press, regulators'),
  Field('legalCounselEngagement', String, 'Legal Counsel Engagement',
    hint: 'When to engage legal team'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Post-incident activities.
@StandardReferences(
  [
    'NIST Cybersecurity Framework — identify, protect, detect, respond, recover',
    'ISO/IEC 27001 — information security management system',
  ],
  'Post-incident review and lessons-learned activities that feed findings back into prevention.',
)
@SectionId('IRPPI')
class IncidentResponsePlanPostIncident {
  @Form([
  Field('postIncidentReview', String, 'Post-Incident Review',
    hint: 'Blameless retrospective process'),
  Field('lessonsLearnedProcess', String, 'Lessons Learned Process',
    hint: 'How findings are fed back into prevention'),
  Field('incidentDocumentation', String, 'Incident Documentation',
    hint: 'What to document and retention period'),
  Field('notes', String, 'Notes',
    hint: 'Additional incident response notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 8.8.2. Data Protection and Privacy
// ---------------------------------------------------------------------------

/// 8.8.2. Data Protection and Privacy.
///
/// Comprehensive data protection and privacy requirements including
/// GDPR compliance, data residency, consent management, data subject
/// rights (erasure, portability, access), privacy impact assessments,
/// and data processing agreements.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'CCPA/CPRA — consumer privacy rights',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Overall data protection and privacy strategy covering regulation, residency, consent, and data subject rights.',
)
@ContentHelp('''
Specify data protection and privacy requirements including regulatory
compliance, data residency, consent management, and data subject rights.
Privacy compliance is mandatory in most jurisdictions.

**Privacy Regulations**:
- **GDPR** (EU): Consent, data minimization, right to erasure, DPO
- **CCPA/CPRA** (California): Consumer rights, opt-out, data sales
- **LGPD** (Brazil): Similar to GDPR, data protection officer
- **PIPEDA** (Canada): Consent and purpose limitation
- **Industry-specific**: HIPAA (health), FERPA (education), GLBA (finance)

**Data Residency**:
- Geographic data storage requirements
- Cross-border data transfer mechanisms
- Data localization requirements
- Cloud region selection considerations
- Data transfer impact assessments

**Consent Management**:
- Consent collection user experience
- Granular consent options
- Consent withdrawal mechanism
- Consent record keeping
- Cookie consent management

**Data Subject Rights**:
- **Right to Access**: Export user data in portable format
- **Right to Rectification**: Update incorrect data
- **Right to Erasure**: Delete all user data (right to be forgotten)
- **Right to Portability**: Transfer data to another provider
- **Right to Object**: Opt-out of processing

**Privacy by Design**:
- Data minimization
- Purpose limitation
- Privacy impact assessments (PIA/DPIA)
- Privacy-preserving technologies
''')
@SectionId('DPAPS')
class DataProtectionAndPrivacySection {
  @ContentHelp('''
Provide an overview of data protection and privacy strategy.

**Include**:
- Applicable privacy regulations
- Data residency requirements
- Consent management approach
- Data subject rights implementation
- Privacy governance structure

**Best Practices**:
- Implement privacy by design from start
- Maintain data inventory and mapping
- Automate data subject requests
- Regular privacy impact assessments
- Privacy training for all staff
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of data protection and privacy strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Applicable privacy regulations and compliance framework.
  @SerializationOrder(2)
  PrivacyRegulationCompliance regulationCompliance =
      PrivacyRegulationCompliance();

  /// Data residency and sovereignty requirements.
  @SerializationOrder(3)
  DataResidencyRequirements dataResidency = DataResidencyRequirements();

  /// Consent collection, tracking and management.
  @SerializationOrder(4)
  ConsentManagementRequirements consentManagement =
      ConsentManagementRequirements();

  /// Data subject rights management (access, erasure, portability).
  @SerializationOrder(5)
  DataSubjectRightsManagement dataSubjectRights =
      DataSubjectRightsManagement();

  /// Privacy impact assessment and DPIA process.
  @SerializationOrder(6)
  PrivacyImpactAssessmentProcess privacyImpactAssessment =
      PrivacyImpactAssessmentProcess();

  /// Data processing agreements with third parties.
  @SerializationOrder(7)
  DataProcessingAgreementRequirements dataProcessingAgreements =
      DataProcessingAgreementRequirements();

  /// Data protection classification and handling rules.
  @SerializationOrder(8)
  DataProtectionClassification dataClassification =
      DataProtectionClassification();
}

/// Privacy regulation compliance requirements.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'CCPA/CPRA — consumer privacy rights',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Applicable privacy regulations and the jurisdictions and authorities that govern processing.',
)
@SectionId('PRRECO')
class PrivacyRegulationCompliance {
  @Form([
    Field('applicableRegulations', String, 'Applicable Regulations',
        required: true,
        hint: 'GDPR, CCPA/CPRA, LGPD, PIPA, PIPEDA, PDPA, etc.'),
    Field('primaryJurisdiction', String, 'Primary Jurisdiction',
        required: true, hint: 'Main legal jurisdiction for data processing'),
    Field('additionalJurisdictions', String, 'Additional Jurisdictions',
        hint: 'Other jurisdictions where data subjects reside'),
    Field('regulatoryAuthority', String, 'Supervisory Authority',
        hint: 'Lead data protection authority for GDPR purposes'),
  ])
  @SerializationOrder(0)
  String? content;

  /// GDPR-specific requirements.
  @SerializationOrder(1)
  PrivacyRegulationComplianceGdpr gdpr = PrivacyRegulationComplianceGdpr();

  /// Data Protection Officer details.
  @SerializationOrder(2)
  PrivacyRegulationComplianceDpo dpo = PrivacyRegulationComplianceDpo();

  /// Records and documentation.
  @SerializationOrder(3)
  PrivacyRegulationComplianceRecords records =
      PrivacyRegulationComplianceRecords();

  /// Cross-border transfer controls.
  @SerializationOrder(4)
  PrivacyRegulationComplianceTransfers transfers =
      PrivacyRegulationComplianceTransfers();
}

/// GDPR-specific requirements.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Lawful basis, controller or processor role, and supervisory authority under GDPR.',
)
@SectionId('PRCG')
class PrivacyRegulationComplianceGdpr {
  @Form([
    Field('gdprLawfulBasis', String, 'GDPR Lawful Basis',
        hint:
            'Consent, contract, legal obligation, vital interests, public task, legitimate interests'),
    Field('gdprDataControllerRole', String, 'Data Controller Role',
        required: true,
        hint: 'Whether organization acts as controller or processor'),
    Field('gdprRepresentative', String, 'EU Representative',
        hint: 'EU-based representative if organization is outside EU'),
    Field(
        'gdprLeadSupervisoryAuthority', String, 'Lead Supervisory Authority',
        hint: 'Lead supervisory authority for cross-border processing'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data Protection Officer details.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Whether a Data Protection Officer is required and their contact and responsibilities.',
)
@SectionId('PRCD')
class PrivacyRegulationComplianceDpo {
  @Form([
    Field('dpoRequired', String, 'DPO Required',
        hint: 'Whether a Data Protection Officer is required'),
    Field('dpoContactDetails', String, 'DPO Contact Details',
        hint: 'Name, email, and reporting line of DPO'),
    Field('dpoResponsibilities', String, 'DPO Responsibilities',
        hint: 'Monitoring compliance, advising on DPIA, liaison with authority'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Records and documentation.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Records of processing activities, transparency notices, and staff training.',
)
@SectionId('PRCR')
class PrivacyRegulationComplianceRecords {
  @Form([
    Field('recordsOfProcessing', String, 'Records of Processing Activities',
        required: true,
        hint: 'ROPA maintenance process — Article 30 GDPR'),
    Field('privacyPolicyRequirements', String, 'Privacy Policy Requirements',
        hint: 'Transparency notices, layered privacy policies'),
    Field('dataProtectionTraining', String, 'Data Protection Training',
        hint: 'Staff training frequency, content, and certification'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cross-border transfer controls.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Cross-border transfer mechanisms and impact assessments for third-country processing.',
)
@SectionId('PRCT')
class PrivacyRegulationComplianceTransfers {
  @Form([
    Field('crossBorderTransferMechanism', String, 'Transfer Mechanism',
        hint:
            'Standard contractual clauses, adequacy decisions, binding corporate rules'),
    Field('transferImpactAssessment', String, 'Transfer Impact Assessment',
        hint: 'Assessment of third-country legal framework, Schrems II'),
    Field('notes', String, 'Notes',
        hint: 'Additional regulation compliance notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data residency and sovereignty requirements.
@StandardReferences(
  [
    'ISO/IEC 27018 — protection of PII in public clouds',
    'GDPR — data protection by design and by default (Article 25)',
  ],
  'Geographic residency of data storage and processing across allowed and prohibited regions.',
)
@SectionId('DARERE')
class DataResidencyRequirements {
  @Form([
    // Storage location
    Field('primaryDataRegion', String, 'Primary Data Region',
        required: true, hint: 'Geographic region for primary data storage'),
    Field('allowedDataRegions', String, 'Allowed Data Regions',
        hint: 'All permitted regions for data storage and processing'),
    Field('prohibitedDataRegions', String, 'Prohibited Data Regions',
        hint: 'Regions where data must never be stored or processed'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Governing regulation and sovereignty constraints.
  @SerializationOrder(1)
  DataResidencyRequirementsSovereignty sovereignty =
    DataResidencyRequirementsSovereignty();

  /// Backup, replication, and CDN placement rules.
  @SerializationOrder(2)
  DataResidencyRequirementsReplication replication =
    DataResidencyRequirementsReplication();

  /// Verification and transparency requirements.
  @SerializationOrder(3)
  DataResidencyRequirementsVerification verification =
    DataResidencyRequirementsVerification();
}

/// Governing regulation and sovereignty constraints.
@StandardReferences(
  [
    'ISO/IEC 27018 — protection of PII in public clouds',
    'GDPR — data protection by design and by default (Article 25)',
  ],
  'Sovereignty laws, key location, and sovereign cloud provider constraints.',
)
@SectionId('DRRS')
class DataResidencyRequirementsSovereignty {
  @Form([
  Field('dataResidencyRegulation', String, 'Residency Regulation',
    hint: 'Specific laws mandating data residency (e.g. Russia, China)'),
  Field('dataSovereigntyRequirements', String, 'Sovereignty Requirements',
    hint:
      'Government access restrictions, national security considerations'),
  Field('encryptionKeyLocation', String, 'Encryption Key Location',
    required: true,
    hint: 'Where encryption keys are stored and managed geographically'),
  Field('cloudProviderRequirements', String, 'Cloud Provider Requirements',
    hint:
      'Sovereign cloud requirements, government-certified providers'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Backup, replication, and CDN placement rules.
@StandardReferences(
  [
    'ISO/IEC 27018 — protection of PII in public clouds',
    'GDPR — storage limitation and data minimisation (Article 5)',
  ],
  'Geographic constraints on backups, cross-region replication, and CDN caching.',
)
@SectionId('DARERERE')
class DataResidencyRequirementsReplication {
  @Form([
  Field('backupDataResidency', String, 'Backup Data Residency',
    hint: 'Geographic constraints for backup and disaster recovery data'),
  Field('replicationConstraints', String, 'Replication Constraints',
    hint: 'Cross-region replication limitations and rules'),
  Field('cdnDataConstraints', String, 'CDN Data Constraints',
    hint: 'Content delivery network caching location restrictions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Verification and transparency requirements.
@StandardReferences(
  [
    'ISO/IEC 27018 — protection of PII in public clouds',
    'GDPR — data protection by design and by default (Article 25)',
  ],
  'Verification, provider certifications, and transparency about where data is stored.',
)
@SectionId('DRRV')
class DataResidencyRequirementsVerification {
  @Form([
  Field('residencyVerification', String, 'Residency Verification',
    hint: 'How data residency compliance is verified and audited'),
  Field('providerCertifications', String, 'Provider Certifications',
    hint:
      'Cloud provider certifications (ISO 27001, SOC 2, C5, ENS)'),
  Field('dataLocationTransparency', String, 'Data Location Transparency',
    hint: 'How data subjects are informed about storage locations'),
  Field('notes', String, 'Notes',
    hint: 'Additional data residency notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Consent collection, tracking and management requirements.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'ISO/IEC 27701 — privacy information management system',
    'ISO/IEC 29100 — privacy framework',
  ],
  'End-to-end consent lifecycle covering collection, storage, withdrawal, and granularity.',
)
@SectionId('COMARE')
class ConsentManagementRequirements {
  @Form([
    Field('consentCollectionMethod', String, 'Collection Method',
        required: true,
        hint:
            'How consent is obtained: opt-in checkboxes, cookie banners, in-app dialogs'),
    Field('consentGranularity', String, 'Consent Granularity',
        required: true,
        hint: 'Per-purpose consent, bundled consent, tiered consent model'),
    Field('consentRecordStorage', String, 'Consent Record Storage',
        required: true,
        hint: 'How consent records are stored with timestamp and version'),
    Field('consentWithdrawalProcess', String, 'Withdrawal Process',
        required: true,
        hint: 'How users can withdraw consent — must be as easy as giving it'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Collection requirements.
  @SerializationOrder(1)
  ConsentManagementRequirementsCollection collection =
      ConsentManagementRequirementsCollection();

  /// Consent record storage rules.
  @SerializationOrder(2)
  ConsentManagementRequirementsStorage storage =
      ConsentManagementRequirementsStorage();

  /// Preference management workflow.
  @SerializationOrder(3)
  ConsentManagementRequirementsManagement management =
      ConsentManagementRequirementsManagement();

  /// Cookie and tracking rules.
  @SerializationOrder(4)
  ConsentManagementRequirementsTracking tracking =
      ConsentManagementRequirementsTracking();

  /// Compliance evidence and reporting.
  @SerializationOrder(5)
  ConsentManagementRequirementsCompliance compliance =
      ConsentManagementRequirementsCompliance();
}

/// Collection requirements.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'ISO/IEC 29100 — privacy framework',
  ],
  'Plain-language, double opt-in, and age-verification requirements for collecting consent.',
)
@SectionId('CMRC')
class ConsentManagementRequirementsCollection {
  @Form([
    Field('consentLanguage', String, 'Consent Language',
        hint:
            'Plain language requirements, multi-language support, reading level'),
    Field('doubleOptIn', String, 'Double Opt-In',
        hint: 'Whether double opt-in is required (e.g. email verification)'),
    Field('ageVerification', String, 'Age Verification',
        hint:
            'Minimum age requirements, parental consent for minors (COPPA, GDPR Art. 8)'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Consent record storage rules.
@StandardReferences(
  [
    'GDPR — storage limitation and data minimisation (Article 5)',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Versioning and retention of consent proof records after withdrawal.',
)
@SectionId('COMAREST')
class ConsentManagementRequirementsStorage {
  @Form([
    Field('consentVersioning', String, 'Consent Versioning',
        hint: 'Tracking consent policy versions and re-consent triggers'),
    Field('consentProofRetention', String, 'Consent Proof Retention',
        hint: 'How long consent proof is retained after withdrawal'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Preference management workflow.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Self-service preference management and propagation of consent changes to downstream systems.',
)
@SectionId('CMRM')
class ConsentManagementRequirementsManagement {
  @Form([
    Field('consentPreferenceCenter', String, 'Preference Center',
        hint: 'Self-service UI for managing consent preferences'),
    Field('consentPropagation', String, 'Consent Propagation',
        hint:
            'How consent changes propagate to downstream systems and processors'),
    Field('consentSynchronization', String, 'Cross-Platform Sync',
        hint: 'Synchronizing consent across web, mobile, and third parties'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Cookie and tracking rules.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'CCPA/CPRA — consumer privacy rights',
  ],
  'Consent rules for cookies, tracking pixels, and third-party sharing.',
)
@SectionId('CMRT')
class ConsentManagementRequirementsTracking {
  @Form([
    Field('cookieConsentRequirements', String, 'Cookie Consent',
        hint:
            'Cookie categories (essential, functional, analytics, marketing)'),
    Field('trackingConsentRequirements', String, 'Tracking Consent',
        hint:
            'Analytics, advertising pixels, fingerprinting consent requirements'),
    Field('thirdPartyConsentSharing', String, 'Third-Party Consent Sharing',
        hint: 'How consent status is communicated to third-party integrations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance evidence and reporting.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Audit trails and reporting that evidence consent compliance for regulators.',
)
@SectionId('COMARECO')
class ConsentManagementRequirementsCompliance {
  @Form([
    Field('consentAuditTrail', String, 'Consent Audit Trail',
        hint: 'Audit logging of all consent events for regulatory evidence'),
    Field('consentComplianceReporting', String, 'Compliance Reporting',
        hint: 'Consent metrics, dashboards, and regulatory reports'),
    Field('notes', String, 'Notes',
        hint: 'Additional consent management notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data subject rights management.
///
/// Covers GDPR Articles 15–22: right of access, rectification, erasure,
/// restriction, portability, objection, and automated decision-making.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'CCPA/CPRA — consumer privacy rights',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Handling of data subject requests for access, erasure, portability, and objection.',
)
@SectionId('DSRM')
class DataSubjectRightsManagement {
  @Form([
    Field('rightOfAccessProcess', String, 'Right of Access Process',
        required: true,
        hint: 'How data subjects request and receive copies of their data'),
    Field('accessRequestTimeline', String, 'Access Request Timeline',
        required: true,
        hint: 'Response timeline — GDPR requires within 1 month'),
    Field('identityVerification', String, 'Identity Verification',
        required: true,
        hint: 'How requester identity is verified before disclosure'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Access and rectification handling.
  @SerializationOrder(1)
  DataSubjectRightsManagementAccess access =
      DataSubjectRightsManagementAccess();

  /// Erasure handling.
  @SerializationOrder(2)
  DataSubjectRightsManagementErasure erasure =
      DataSubjectRightsManagementErasure();

  /// Portability handling.
  @SerializationOrder(3)
  DataSubjectRightsManagementPortability portability =
      DataSubjectRightsManagementPortability();

  /// Restriction and objection handling.
  @SerializationOrder(4)
  DataSubjectRightsManagementRestriction restriction =
      DataSubjectRightsManagementRestriction();

  /// Automated decision safeguards.
  @SerializationOrder(5)
  DataSubjectRightsManagementAutomation automation =
      DataSubjectRightsManagementAutomation();

  /// Operational workflow and tracking.
  @SerializationOrder(6)
  DataSubjectRightsManagementOperations operations =
      DataSubjectRightsManagementOperations();
}

/// Access and rectification handling.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'CCPA/CPRA — consumer privacy rights',
  ],
  'Defines access data format, rectification process, and propagation of corrections.',
)
@SectionId('DSRMA')
class DataSubjectRightsManagementAccess {
  @Form([
    Field('accessDataFormat', String, 'Access Data Format',
        hint:
            'Format for providing data (structured, machine-readable, PDF)'),
    Field('rectificationProcess', String, 'Rectification Process',
        hint:
            'How data subjects request correction of inaccurate personal data'),
    Field('rectificationPropagation', String, 'Rectification Propagation',
        hint: 'How corrections propagate to recipients of the data'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Erasure handling.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'CCPA/CPRA — consumer privacy rights',
  ],
  'Defines erasure process, scope, exceptions, and verification across systems.',
)
@SectionId('DSRME')
class DataSubjectRightsManagementErasure {
  @Form([
    Field('erasureProcess', String, 'Right to Erasure Process',
        required: true,
        hint: 'How erasure requests are processed — "right to be forgotten"'),
    Field('erasureScope', String, 'Erasure Scope',
        hint: 'What data is erased: active records, backups, logs, analytics'),
    Field('erasureExceptions', String, 'Erasure Exceptions',
        hint:
            'Legal retention obligations that override erasure (tax, fraud)'),
    Field('erasureVerification', String, 'Erasure Verification',
        hint: 'How complete erasure is verified across all systems'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Portability handling.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'CCPA/CPRA — consumer privacy rights',
  ],
  'Defines structured, machine-readable data export and direct-transfer support.',
)
@SectionId('DSRMP')
class DataSubjectRightsManagementPortability {
  @Form([
    Field('portabilityProcess', String, 'Data Portability Process',
        required: true,
        hint: 'How data is exported in structured, machine-readable format'),
    Field('portabilityFormat', String, 'Portability Format',
        hint: 'Export formats: JSON, CSV, XML, API-based transfer'),
    Field('portabilityDirectTransfer', String, 'Direct Transfer',
        hint: 'Whether direct controller-to-controller transfer is supported'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Restriction and objection handling.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'CCPA/CPRA — consumer privacy rights',
  ],
  'Defines how processing restriction and objections to processing are handled.',
)
@SectionId('DSRMR')
class DataSubjectRightsManagementRestriction {
  @Form([
    Field('restrictionProcess', String, 'Restriction of Processing',
        hint: 'How processing restriction is applied while disputes are resolved'),
    Field('objectionProcess', String, 'Right to Object',
        hint:
            'How objections to processing are handled (direct marketing, profiling)'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Automated decision safeguards.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'NIST Privacy Framework — govern, control, communicate, protect',
  ],
  'Defines safeguards and human review for automated decisions with significant effects.',
)
@SectionId('DASURIMAAU')
class DataSubjectRightsManagementAutomation {
  @Form([
    Field('automatedDecisionMaking', String, 'Automated Decision-Making',
        hint:
            'Safeguards for automated decisions with legal or significant effects'),
    Field('humanReviewProcess', String, 'Human Review Process',
        hint: 'Process for requesting human review of automated decisions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Operational workflow and tracking.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'CCPA/CPRA — consumer privacy rights',
  ],
  'Defines the end-to-end DSAR workflow, tracking, and completion metrics.',
)
@SectionId('DSRMO')
class DataSubjectRightsManagementOperations {
  @Form([
    Field('dsarWorkflow', String, 'DSAR Workflow',
        hint: 'Data Subject Access Request end-to-end workflow and tooling'),
    Field('dsarTracking', String, 'DSAR Tracking',
        hint: 'Tracking system for requests, SLAs, and completion metrics'),
    Field('notes', String, 'Notes',
        hint: 'Additional data subject rights notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Privacy impact assessment and DPIA process.
@StandardReferences(
  [
    'GDPR — data protection by design and by default (Article 25)',
    'ISO/IEC 29100 — privacy framework',
    'NIST Privacy Framework — govern, control, communicate, protect',
  ],
  'Defines DPIA thresholds, screening, and methodology for high-risk processing.',
)
@SectionId('PIAP')
class PrivacyImpactAssessmentProcess {
  @Form([
    Field('dpiaThreshold', String, 'DPIA Threshold',
        required: true,
        hint:
            'Criteria triggering a DPIA: new processing, high risk, large-scale profiling'),
    Field('dpiaScreeningProcess', String, 'Screening Process',
        hint: 'Initial screening to determine if full DPIA is needed'),
    Field('mandatoryDpiaScenarios', String, 'Mandatory DPIA Scenarios',
        hint:
            'Systematic monitoring, sensitive data at scale, automated decisions'),
    Field('dpiaMethodology', String, 'DPIA Methodology',
        required: true,
        hint: 'Framework used: ICO template, CNIL PIA tool, NIST privacy'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Assessment process inputs.
  @SerializationOrder(1)
  PrivacyImpactAssessmentProcessAssessment assessment =
      PrivacyImpactAssessmentProcessAssessment();

  /// Mitigation measures.
  @SerializationOrder(2)
  PrivacyImpactAssessmentProcessMitigation mitigation =
      PrivacyImpactAssessmentProcessMitigation();

  /// Review and approval workflow.
  @SerializationOrder(3)
  PrivacyImpactAssessmentProcessReview review =
      PrivacyImpactAssessmentProcessReview();
}

/// Assessment process inputs.
@StandardReferences(
  [
    'GDPR — data protection by design and by default (Article 25)',
    'NIST Privacy Framework — govern, control, communicate, protect',
  ],
  'Defines DPIA stakeholders, data flow mapping, and risk assessment criteria.',
)
@SectionId('PIAPA')
class PrivacyImpactAssessmentProcessAssessment {
  @Form([
    Field('dpiaStakeholders', String, 'DPIA Stakeholders',
        hint:
            'Who participates: DPO, engineering, legal, business, external advisor'),
    Field('dataFlowMapping', String, 'Data Flow Mapping',
        hint:
            'Documenting data flows, storage, access, and sharing for each processing activity'),
    Field('riskAssessmentCriteria', String, 'Risk Assessment Criteria',
        hint: 'Likelihood and severity matrix, residual risk thresholds'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Mitigation measures.
@StandardReferences(
  [
    'GDPR — data protection by design and by default (Article 25)',
    'ISO/IEC 29100 — privacy framework',
    'NIST Privacy Framework — govern, control, communicate, protect',
  ],
  'Defines privacy-by-design, minimization, and de-identification measures that reduce risk.',
)
@SectionId('PIAPM')
class PrivacyImpactAssessmentProcessMitigation {
  @Form([
    Field('mitigationMeasures', String, 'Mitigation Measures',
        hint:
            'Technical and organizational measures to reduce identified risks'),
    Field('privacyByDesign', String, 'Privacy by Design',
        required: true,
        hint:
            'How privacy is embedded in system design from inception (Art. 25 GDPR)'),
    Field('privacyByDefault', String, 'Privacy by Default',
        hint:
            'Default settings protect privacy — minimal data, shortest retention'),
    Field('dataMinimization', String, 'Data Minimization',
        hint:
            'Limiting collection to what is necessary for the specified purpose'),
    Field('pseudonymization', String, 'Pseudonymization',
        hint:
            'Techniques applied: tokenization, hashing, key-coded data'),
    Field('anonymization', String, 'Anonymization',
        hint:
            'Techniques for irreversible de-identification: k-anonymity, differential privacy'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Review and approval workflow.
@StandardReferences(
  [
    'GDPR — data protection by design and by default (Article 25)',
    'NIST Privacy Framework — govern, control, communicate, protect',
  ],
  'Defines DPIA approval, supervisory consultation, and periodic review cadence.',
)
@SectionId('PIAPR')
class PrivacyImpactAssessmentProcessReview {
  @Form([
    Field('dpiaApprovalProcess', String, 'Approval Process',
        hint: 'Who reviews and approves the DPIA before processing begins'),
    Field('supervisoryConsultation', String, 'Supervisory Consultation',
        hint: 'When prior consultation with the supervisory authority is required'),
    Field('dpiaReviewFrequency', String, 'Review Frequency',
        hint: 'How often existing DPIAs are reviewed and updated'),
    Field('notes', String, 'Notes',
        hint: 'Additional privacy impact assessment notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data processing agreement requirements.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'ISO/IEC 27701 — privacy information management system',
    'ISO/IEC 27018 — protection of PII in public clouds',
  ],
  'Defines processor obligations, purpose limitation, and audit rights for data processing agreements.',
)
@SectionId('DPAR')
class DataProcessingAgreementRequirements {
  @Form([
    Field('dpaTemplate', String, 'DPA Template',
        required: true,
        hint: 'Standard data processing agreement template used'),
    Field('processorObligations', String, 'Processor Obligations',
        required: true,
        hint:
            'Article 28 GDPR: security measures, sub-processing, audits, deletion'),
    Field('processingPurposeLimitation', String, 'Purpose Limitation',
        required: true,
        hint: 'Ensuring data is processed only for specified purposes'),
    Field('auditRights', String, 'Audit Rights',
        required: true,
        hint: 'Controller right to audit processor premises and practices'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Agreement-management details.
  @SerializationOrder(1)
  DataProcessingAgreementRequirementsManagement management =
      DataProcessingAgreementRequirementsManagement();

  /// Data-handling details.
  @SerializationOrder(2)
  DataProcessingAgreementRequirementsHandling handling =
      DataProcessingAgreementRequirementsHandling();

  /// Security and audit details.
  @SerializationOrder(3)
  DataProcessingAgreementRequirementsSecurity security =
      DataProcessingAgreementRequirementsSecurity();

  /// International-transfer details.
  @SerializationOrder(4)
  DataProcessingAgreementRequirementsTransfers transfers =
      DataProcessingAgreementRequirementsTransfers();
}

/// Agreement-management details.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Defines how sub-processors are approved, monitored, and communicated to controllers.',
)
@SectionId('DPARM')
class DataProcessingAgreementRequirementsManagement {
  @Form([
    Field('subProcessorManagement', String, 'Sub-Processor Management',
        hint:
            'How sub-processors are approved, listed, and monitored'),
    Field('subProcessorNotification', String, 'Sub-Processor Notification',
        hint: 'Process for notifying controllers of sub-processor changes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data-handling details.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Defines retention, return on termination, and confidentiality obligations for processors.',
)
@SectionId('DPARH')
class DataProcessingAgreementRequirementsHandling {
  @Form([
    Field('dataRetentionInDpa', String, 'Retention in DPA',
        hint: 'Retention periods and deletion/return obligations'),
    Field('dataReturnOnTermination', String, 'Data Return on Termination',
        hint: 'Data return or certified destruction on contract end'),
    Field('confidentialityObligations', String, 'Confidentiality Obligations',
        hint:
            'Staff confidentiality commitments and access restrictions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security and audit details.
@StandardReferences(
  [
    'GDPR — data breach notification (Articles 33-34)',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Defines processor security measures, breach notification, and compliance certification.',
)
@SectionId('DPARS')
class DataProcessingAgreementRequirementsSecurity {
  @Form([
    Field('securityMeasuresInDpa', String, 'Security Measures',
        hint:
            'Technical and organizational measures required from processors'),
    Field('breachNotificationInDpa', String, 'Breach Notification',
        hint:
            'Processor obligation to notify controller of breaches without undue delay'),
    Field('complianceCertification', String, 'Compliance Certification',
        hint: 'Processor certifications accepted as audit evidence'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// International-transfer details.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'ISO/IEC 27018 — protection of PII in public clouds',
  ],
  'Defines contractual clauses and mechanisms for international personal data transfers.',
)
@SectionId('DPART')
class DataProcessingAgreementRequirementsTransfers {
  @Form([
    Field('internationalTransferClauses', String, 'International Transfer Clauses',
        hint:
            'Standard contractual clauses or other mechanisms in the DPA'),
    Field('governingLaw', String, 'Governing Law',
        hint: 'Applicable law and jurisdiction for DPA disputes'),
    Field('liabilityAndIndemnification', String, 'Liability',
        hint: 'Liability allocation and indemnification provisions'),
    Field('notes', String, 'Notes',
        hint: 'Additional data processing agreement notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data protection classification and handling rules.
///
/// Named DataProtectionClassification to avoid collision with
/// DataClassification in information_and_data_model.dart.
@StandardReferences(
  [
    'ISO/IEC 27701 — privacy information management system',
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'ISO/IEC 29100 — privacy framework',
  ],
  'Defines classification levels and personal data categories with their handling rules.',
)
@SectionId('DAPRCL')
class DataProtectionClassification {
  @Form([
    Field('classificationLevels', String, 'Classification Levels',
        required: true,
        hint: 'Public, Internal, Confidential, Restricted, Top Secret'),
    Field('personalDataCategories', String, 'Personal Data Categories',
        required: true,
        hint:
            'Basic identity, contact, financial, health, biometric, genetic'),
    Field('sensitiveDataCategories', String, 'Sensitive Data Categories',
        hint:
            'Special categories Art. 9 GDPR: race, religion, health, sexual orientation, political opinion'),
    Field('classificationResponsibility', String, 'Classification Responsibility',
        hint: 'Who is responsible for classifying data'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Handling rules.
  @SerializationOrder(1)
  DataProtectionClassificationHandling handling =
      DataProtectionClassificationHandling();

  /// Retention and disposal rules.
  @SerializationOrder(2)
  DataProtectionClassificationRetention retention =
      DataProtectionClassificationRetention();

  /// Masking and de-identification rules.
  @SerializationOrder(3)
  DataProtectionClassificationMasking masking =
      DataProtectionClassificationMasking();

  /// Incident handling.
  @SerializationOrder(4)
  DataProtectionClassificationIncident incident =
      DataProtectionClassificationIncident();
}

/// Handling rules.
@StandardReferences(
  [
    'ISO/IEC 27018 — protection of PII in public clouds',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Defines encryption, access control, and logging requirements per classification level.',
)
@SectionId('DPCH')
class DataProtectionClassificationHandling {
  @Form([
    Field('encryptionAtRest', String, 'Encryption at Rest',
        required: true,
        hint: 'Encryption requirements per classification level (AES-256)'),
    Field('encryptionInTransit', String, 'Encryption in Transit',
        required: true, hint: 'TLS 1.2+, mTLS, certificate requirements'),
    Field('accessControlByClassification', String, 'Access Control',
        hint: 'Access restrictions mapped to classification levels'),
    Field('loggingByClassification', String, 'Logging Requirements',
        hint: 'Audit logging requirements per classification level'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Retention and disposal rules.
@StandardReferences(
  [
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Defines retention periods, secure disposal, and exceptions per data category.',
)
@SectionId('DPCR')
class DataProtectionClassificationRetention {
  @Form([
    Field('retentionPolicyByCategory', String, 'Retention Policy',
        required: true,
        hint: 'Retention periods per data category and legal basis'),
    Field('disposalProcedure', String, 'Disposal Procedure',
        hint: 'Secure deletion, shredding, crypto-erasure per classification'),
    Field('retentionExceptions', String, 'Retention Exceptions',
        hint: 'Legal holds, regulatory overrides, litigation preservation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Masking and de-identification rules.
@StandardReferences(
  [
    'ISO/IEC 27018 — protection of PII in public clouds',
    'GDPR — data protection by design and by default (Article 25)',
  ],
  'Defines masking, tokenization, and de-identification standards for personal data.',
)
@SectionId('DPCM')
class DataProtectionClassificationMasking {
  @Form([
    Field('dataMaskingRules', String, 'Data Masking Rules',
        hint: 'Masking rules for non-production environments, logs, and reports'),
    Field('tokenizationRequirements', String, 'Tokenization Requirements',
        hint: 'Payment card, PII tokenization approach (PCI DSS)'),
    Field('deIdentificationStandards', String, 'De-Identification Standards',
        hint: 'HIPAA Safe Harbor, Expert Determination, k-anonymity'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Incident handling.
@StandardReferences(
  [
    'GDPR — data breach notification (Articles 33-34)',
    'ISO/IEC 27701 — privacy information management system',
  ],
  'Maps data classification to breach severity and defines exfiltration-prevention controls.',
)
@SectionId('DPCI')
class DataProtectionClassificationIncident {
  @Form([
    Field('breachClassificationMatrix', String, 'Breach Classification',
        hint: 'Mapping data classification to breach severity and response'),
    Field('dataLossPreventionControls', String, 'DLP Controls',
        hint: 'Technical controls to prevent unauthorized data exfiltration'),
    Field('notes', String, 'Notes',
        hint: 'Additional data protection classification notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 8.8.3. Security Audit Requirements
// ---------------------------------------------------------------------------

/// 8.8.3. Security Audit Requirements.
///
/// Comprehensive security audit requirements covering penetration testing,
/// security-focused code review, dependency scanning, security certifications,
/// compliance audit scheduling, and automated security testing integration.
@StandardReferences(
  [
    'ISO/IEC 27001 — internal audit and management review (Clause 9)',
    'OWASP ASVS — verification and security testing requirements',
    'NIST SP 800-53 — audit and accountability (AU) controls',
  ],
  'Comprehensive security audit requirements spanning penetration testing, code review, scanning, and compliance audits.',
)
@ContentHelp('''
Specify security audit requirements including penetration testing, code
review, dependency scanning, and compliance audits. Regular auditing
validates security controls and identifies weaknesses.

**Penetration Testing**:
- Testing scope (external, internal, web, mobile, API)
- Testing frequency (annual, quarterly, per release)
- Testing methodology (OWASP, PTES, NIST)
- Findings remediation timeline by severity
- Re-testing requirements

**Security Code Review**:
- Code review checklist for security
- Manual review requirements
- SAST tool integration
- High-risk code identification
- Security review gates

**Dependency Scanning**:
- Software composition analysis (SCA)
- CVE monitoring and alerting
- License compliance scanning
- Dependency update policy
- Vulnerable dependency remediation

**Security Certifications**:
- **SOC 2 Type II**: Trust services criteria (security, availability, etc.)
- **ISO 27001**: Information security management system
- **FedRAMP**: US government cloud security
- **Industry-specific**: HIPAA, PCI-DSS, HITRUST

**Compliance Audits**:
- Internal audit schedule
- External audit requirements
- Evidence collection and retention
- Gap remediation tracking
- Continuous compliance monitoring

**Automated Security Testing**:
- CI/CD security gates
- Dynamic security testing (DAST)
- Infrastructure security scanning
- Compliance as code
''')
@SectionId('SARS')
class SecurityAuditRequirementsSection {
  @ContentHelp('''
Provide an overview of security audit strategy.

**Include**:
- Penetration testing program
- Security code review process
- Dependency scanning approach
- Certification roadmap
- Audit schedule and responsibilities

**Best Practices**:
- Integrate security testing in CI/CD
- Act on audit findings promptly
- Maintain audit evidence repository
- Regular security review meetings
- Continuous improvement from findings
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of security audit strategy and approach.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Penetration testing requirements and schedule.
  @SerializationOrder(2)
  PenetrationTestingRequirements penetrationTesting =
      PenetrationTestingRequirements();

  /// Security-focused code review policy and process.
  @SerializationOrder(3)
  SecurityCodeReviewPolicy securityCodeReview = SecurityCodeReviewPolicy();

  /// Dependency and supply-chain scanning requirements.
  @SerializationOrder(4)
  DependencyScanningRequirements dependencyScanning =
      DependencyScanningRequirements();

  /// Security certification and compliance framework needs.
  @SerializationOrder(5)
  SecurityCertificationRequirements securityCertifications =
      SecurityCertificationRequirements();

  /// Compliance audit planning and scheduling.
  @SerializationOrder(6)
  ComplianceAuditSchedule complianceAuditSchedule = ComplianceAuditSchedule();

  /// Automated security testing integration (SAST, DAST, IAST).
  @SerializationOrder(7)
  SecurityTestingAutomation securityTestingAutomation =
      SecurityTestingAutomation();

  /// Individual security audit requirement entries — contains 0+× SecurityAudit.
  @StandardReferences(
    ['ISO/IEC 27001 — internal audit and management review (Clause 9)'],
    'The catalog of individual security audit requirements the system must satisfy.',
  )
  @SectionId('SEAUEN-AUDI-LST')
  @SectionIdPattern('SEAUEN-AUDI-xxx')
  @ContentHelp('Add one entry per security audit requirement.')
  @SerializationOrder(8)
  List<SecurityAuditEntry> auditEntries = [];
}

/// Penetration testing requirements and schedule.
@StandardReferences(
  [
    'OWASP WSTG — web security testing guide (penetration testing)',
    'OWASP ASVS — verification and security testing requirements',
    'PCI DSS — logging, monitoring, and regular security testing',
  ],
  'Penetration testing requirements covering scope, methodology, and scheduling.',
)
@SectionId('PETERE')
class PenetrationTestingRequirements {
  @Form([
    Field('pentestScope', String, 'Penetration Test Scope',
        required: true,
        hint:
            'External network, internal network, web application, mobile app, API'),
    Field('pentestMethodology', String, 'Testing Methodology',
        required: true,
        hint: 'OWASP WSTG, PTES, OSSTMM, NIST SP 800-115'),
    Field('pentestApproach', String, 'Testing Approach',
        hint: 'Black box, grey box, white box, or combination'),
    Field('pentestProvider', String, 'Testing Provider',
        hint: 'Internal red team, external firm, or both'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Frequency and scheduling.
  @SerializationOrder(1)
  PenetrationTestingRequirementsScheduling scheduling =
      PenetrationTestingRequirementsScheduling();

  /// Execution rules.
  @SerializationOrder(2)
  PenetrationTestingRequirementsExecution execution =
      PenetrationTestingRequirementsExecution();

  /// Reporting and remediation.
  @SerializationOrder(3)
  PenetrationTestingRequirementsReporting reporting =
      PenetrationTestingRequirementsReporting();
}

/// Frequency and scheduling.
@StandardReferences(
  [
    'PCI DSS — logging, monitoring, and regular security testing',
    'OWASP WSTG — web security testing guide (penetration testing)',
  ],
  'Frequency, retesting, and trigger-based scheduling for penetration testing.',
)
@SectionId('PTRS')
class PenetrationTestingRequirementsScheduling {
  @Form([
    Field('pentestFrequency', String, 'Testing Frequency',
        required: true,
        hint: 'Annual, semi-annual, quarterly, after major releases'),
    Field('retestRequirements', String, 'Retest Requirements',
        hint: 'When retesting is required after remediation'),
    Field('triggerBasedTesting', String, 'Trigger-Based Testing',
        hint:
            'Events triggering unscheduled tests: major changes, incidents, new integrations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Execution rules.
@StandardReferences(
  [
    'OWASP WSTG — web security testing guide (penetration testing)',
    'OWASP ASVS — verification and security testing requirements',
  ],
  'Execution rules for penetration testing including environment and rules of engagement.',
)
@SectionId('PTRE')
class PenetrationTestingRequirementsExecution {
  @Form([
    Field('testingEnvironment', String, 'Testing Environment',
        hint: 'Production, staging, dedicated pentest environment'),
    Field('rulesOfEngagement', String, 'Rules of Engagement',
        hint: 'Boundaries, excluded systems, testing windows, escalation'),
    Field('socialEngineeringScope', String, 'Social Engineering Scope',
        hint: 'Phishing, vishing, physical access testing if applicable'),
    Field('dosTestingAllowed', String, 'DoS Testing Allowed',
        hint: 'Whether denial-of-service testing is in scope'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reporting and remediation.
@StandardReferences(
  [
    'OWASP WSTG — web security testing guide (penetration testing)',
    'NIST SP 800-53 — audit and accountability (AU) controls',
  ],
  'Reporting format and remediation timelines for penetration testing findings.',
)
@SectionId('PTRR')
class PenetrationTestingRequirementsReporting {
  @Form([
    Field('findingSeverityScale', String, 'Finding Severity Scale',
        hint: 'CVSS, custom scale (Critical/High/Medium/Low/Info)'),
    Field('reportingFormat', String, 'Reporting Format',
        hint: 'Executive summary, technical findings, remediation guidance'),
    Field('remediationTimelines', String, 'Remediation Timelines',
        required: true,
        hint:
            'SLAs per severity: Critical 48h, High 7d, Medium 30d, Low 90d'),
    Field('managementBriefing', String, 'Management Briefing',
        hint: 'Post-test executive debrief requirements'),
    Field('notes', String, 'Notes',
        hint: 'Additional penetration testing notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security-focused code review policy.
///
/// Distinct from CodeReviewProcess (section 8.4) which covers general
/// development code review. This section focuses specifically on
/// security-oriented review requirements.
@StandardReferences(
  [
    'OWASP ASVS — verification and security testing requirements',
    'OWASP WSTG — web security testing guide (penetration testing)',
    'ISO/IEC 27001 — internal audit and management review (Clause 9)',
  ],
  'Security-focused code review policy covering triggers, scope, and methodology.',
)
@SectionId('SCRP')
class SecurityCodeReviewPolicy {
  @Form([
    Field('securityReviewTriggers', String, 'Security Review Triggers',
        required: true,
        hint:
            'New features, auth changes, crypto code, data handling changes, third-party integrations'),
    Field('securityReviewScope', String, 'Review Scope',
        hint:
            'Authentication, authorization, input validation, cryptography, session management'),
    Field('reviewMethodology', String, 'Review Methodology',
        hint: 'OWASP Code Review Guide, CWE/SANS Top 25, manual + automated'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Reviewer qualification and independence rules.
  @SerializationOrder(1)
  SecurityCodeReviewPolicyReviewers reviewers =
    SecurityCodeReviewPolicyReviewers();

  /// Review process guidance.
  @SerializationOrder(2)
  SecurityCodeReviewPolicyProcess process =
    SecurityCodeReviewPolicyProcess();

  /// Finding management and residual risk handling.
  @SerializationOrder(3)
  SecurityCodeReviewPolicyFindings findings =
    SecurityCodeReviewPolicyFindings();
}

/// Reviewer qualification and independence rules.
@StandardReferences(
  [
    'ISO 19011 — auditing management systems (audit programme)',
    'OWASP ASVS — verification and security testing requirements',
  ],
  'Reviewer qualification, independence, and rotation rules for security code review.',
)
@SectionId('SCRPR')
class SecurityCodeReviewPolicyReviewers {
  @Form([
  Field('securityReviewerRequirements', String, 'Reviewer Requirements',
    required: true,
    hint:
      'Security training certifications, experience requirements for reviewers'),
  Field('externalReviewCriteria', String, 'External Review Criteria',
    hint: 'When external security review firm is engaged'),
  Field('reviewerRotation', String, 'Reviewer Rotation',
    hint: 'How security reviewers are rotated to avoid bias'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Review process guidance for security-focused code review.
@StandardReferences(
  [
    'OWASP ASVS — verification and security testing requirements',
    'OWASP WSTG — web security testing guide (penetration testing)',
  ],
  'Process guidance for security-focused code review including checklists and threat modeling.',
)
@SectionId('SCRPP')
class SecurityCodeReviewPolicyProcess {
  @Form([
  Field('securityChecklist', String, 'Security Checklist',
    hint:
      'OWASP Top 10, injection, XSS, CSRF, auth bypass, data exposure'),
  Field('threatModelingIntegration', String, 'Threat Modeling Integration',
    hint: 'How threat models inform code review focus areas'),
  Field('securityAnnotations', String, 'Security Annotations',
    hint:
      'Code annotations marking security-critical sections for priority review'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Finding management and residual risk handling.
@StandardReferences(
  [
    'OWASP ASVS — verification and security testing requirements',
    'ISO/IEC 27001 — internal audit and management review (Clause 9)',
  ],
  'Finding classification, tracking, and residual-risk handling for security code review.',
)
@SectionId('SCRPF')
class SecurityCodeReviewPolicyFindings {
  @Form([
  Field('findingClassification', String, 'Finding Classification',
    hint: 'Vulnerability, weakness, informational, best-practice deviation'),
  Field('findingTrackingProcess', String, 'Finding Tracking',
    hint: 'How findings are tracked from discovery to resolution'),
  Field('securityDebtManagement', String, 'Security Debt Management',
    hint: 'How accepted security risks are documented and reviewed'),
  Field('notes', String, 'Notes',
    hint: 'Additional security code review notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Dependency and supply-chain scanning requirements.
@StandardReferences(
  [
    'OWASP ASVS — verification and security testing requirements',
    'NIST SP 800-53 — audit and accountability (AU) controls',
    'PCI DSS — logging, monitoring, and regular security testing',
  ],
  'Dependency and supply-chain scanning requirements including SCA tooling and severity thresholds.',
)
@SectionId('DESCRE')
class DependencyScanningRequirements {
  @Form([
    Field('scaScanningTool', String, 'SCA Scanning Tool',
        required: true,
        hint:
            'Software Composition Analysis tool: Snyk, Dependabot, OWASP Dependency-Check, Trivy'),
    Field('scanFrequency', String, 'Scan Frequency',
        required: true,
        hint: 'Every build, daily, weekly, on dependency change'),
    Field('registryScanning', String, 'Registry Scanning',
        hint: 'Scanning package registries (pub.dev, npm, Docker Hub) for known vulnerabilities'),
    Field('severityThresholds', String, 'Severity Thresholds',
        required: true,
        hint: 'Build-blocking severity: Critical blocks, High warns, etc.'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Vulnerability-management rules.
  @SerializationOrder(1)
  DependencyScanningRequirementsVulnerabilities vulnerabilities =
      DependencyScanningRequirementsVulnerabilities();

  /// SBOM requirements.
  @SerializationOrder(2)
  DependencyScanningRequirementsSbom sbom = DependencyScanningRequirementsSbom();

  /// License-compliance rules.
  @SerializationOrder(3)
  DependencyScanningRequirementsLicensing licensing =
      DependencyScanningRequirementsLicensing();

  /// Supply-chain security rules.
  @SerializationOrder(4)
  DependencyScanningRequirementsSupplyChain supplyChain =
      DependencyScanningRequirementsSupplyChain();
}

/// Vulnerability-management rules.
@StandardReferences(
  [
    'OWASP ASVS — verification and security testing requirements',
    'PCI DSS — logging, monitoring, and regular security testing',
  ],
  'Vulnerability database sources, remediation SLAs, and exception handling for dependencies.',
)
@SectionId('DSRV')
class DependencyScanningRequirementsVulnerabilities {
  @Form([
    Field('vulnerabilityDatabase', String, 'Vulnerability Database',
        hint: 'NVD, GitHub Advisory Database, OSV, vendor-specific advisories'),
    Field('remediationSla', String, 'Remediation SLA',
        hint: 'Time to patch per severity level'),
    Field('exceptionProcess', String, 'Exception Process',
        hint: 'How vulnerabilities are risk-accepted with justification'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// SBOM requirements.
@StandardReferences(
  [
    'OWASP ASVS — verification and security testing requirements',
    'NIST SP 800-53 — audit and accountability (AU) controls',
  ],
  'Software bill of materials generation, update frequency, and distribution requirements.',
)
@SectionId('DSRS')
class DependencyScanningRequirementsSbom {
  @Form([
    Field('sbomGeneration', String, 'SBOM Generation',
        hint: 'Software Bill of Materials format: SPDX, CycloneDX'),
    Field('sbomUpdateFrequency', String, 'SBOM Update Frequency',
        hint: 'How often SBOM is regenerated and published'),
    Field('sbomDistribution', String, 'SBOM Distribution',
        hint: 'Who receives SBOM: customers, auditors, regulators'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// License-compliance rules.
@StandardReferences(
  [
    'OWASP ASVS — verification and security testing requirements',
    'ISO/IEC 27002 — logging and monitoring controls',
  ],
  'License policy and automated license scanning rules for dependencies.',
)
@SectionId('DSRL')
class DependencyScanningRequirementsLicensing {
  @Form([
    Field('licensePolicy', String, 'License Policy',
        hint:
            'Allowed licenses (MIT, BSD, Apache 2.0), restricted (GPL, AGPL), review-required'),
    Field('licenseScanning', String, 'License Scanning',
        hint: 'Automated license detection and policy enforcement'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Supply-chain security rules.
@StandardReferences(
  [
    'OWASP ASVS — verification and security testing requirements',
    'NIST SP 800-53 — audit and accountability (AU) controls',
  ],
  'Supply-chain security rules covering dependency pinning, signature verification, and registry policy.',
)
@SectionId('DSRSC')
class DependencyScanningRequirementsSupplyChain {
  @Form([
    Field('dependencyPinning', String, 'Dependency Pinning',
        hint: 'Lock file requirements, version pinning strategy'),
    Field('signatureVerification', String, 'Signature Verification',
        hint: 'Package signature verification, provenance attestation'),
    Field('privateRegistryPolicy', String, 'Private Registry Policy',
        hint: 'Internal package registry, proxy settings, caching policy'),
    Field('notes', String, 'Notes',
        hint: 'Additional dependency scanning notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Security certification and compliance requirements.
@StandardReferences(
  [
    'ISO/IEC 27001 — internal audit and management review (Clause 9)',
    'SOC 2 — trust services criteria (security, audit evidence)',
    'PCI DSS — logging, monitoring, and regular security testing',
  ],
  'Target security certifications and the compliance framework the system must satisfy.',
)
@SectionId('SECERE')
class SecurityCertificationRequirements {
  @Form([
    Field('targetCertifications', String, 'Target Certifications',
        required: true,
        hint:
            'ISO 27001, SOC 2 Type II, PCI DSS, HIPAA, FedRAMP, CSA STAR'),
    Field('certificationTimeline', String, 'Certification Timeline',
        hint: 'Target dates for achieving each certification'),
    Field('certificationScope', String, 'Certification Scope',
        hint: 'Which systems, processes, and data are in scope'),
  ])
  @SerializationOrder(0)
  String? content;

  /// ISO 27001 requirements.
  @SerializationOrder(1)
  SecurityCertificationRequirementsIso27001 iso27001 =
      SecurityCertificationRequirementsIso27001();

  /// SOC 2 requirements.
  @SerializationOrder(2)
  SecurityCertificationRequirementsSoc2 soc2 =
      SecurityCertificationRequirementsSoc2();

  /// Industry-specific requirements.
  @SerializationOrder(3)
  SecurityCertificationRequirementsIndustry industry =
      SecurityCertificationRequirementsIndustry();

  /// Maintenance and budget.
  @SerializationOrder(4)
  SecurityCertificationRequirementsMaintenance maintenance =
      SecurityCertificationRequirementsMaintenance();
}

/// ISO 27001 requirements.
@StandardReferences(
  [
    'ISO/IEC 27001 — internal audit and management review (Clause 9)',
    'ISO/IEC 27002 — logging and monitoring controls',
  ],
  'ISO 27001 controls, ISMS scope, and risk assessment methodology requirements.',
)
@SectionId('SCRI')
class SecurityCertificationRequirementsIso27001 {
  @Form([
    Field('iso27001Controls', String, 'ISO 27001 Controls',
        hint: 'Annex A controls applicable, Statement of Applicability'),
    Field('ismsScope', String, 'ISMS Scope',
        hint: 'Information Security Management System boundary definition'),
    Field('riskAssessmentMethodology', String, 'Risk Assessment Methodology',
        hint: 'Risk assessment approach for ISO 27001 compliance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// SOC 2 requirements.
@StandardReferences(
  [
    'SOC 2 — trust services criteria (security, audit evidence)',
    'ISO/IEC 27001 — internal audit and management review (Clause 9)',
  ],
  'SOC 2 trust services criteria, report type, and audit period requirements.',
)
@SectionId('SCRS')
class SecurityCertificationRequirementsSoc2 {
  @Form([
    Field('soc2TrustServiceCriteria', String, 'SOC 2 Trust Criteria',
        hint: 'Security, Availability, Processing Integrity, Confidentiality, Privacy'),
    Field('soc2ReportType', String, 'SOC 2 Report Type',
        hint: 'Type I (point in time) or Type II (over period)'),
    Field('soc2AuditPeriod', String, 'SOC 2 Audit Period',
        hint: 'Observation window for Type II audit'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Industry-specific requirements.
@StandardReferences(
  [
    'PCI DSS — logging, monitoring, and regular security testing',
    'ISO/IEC 27002 — logging and monitoring controls',
  ],
  'Industry-specific certification requirements such as PCI DSS, HIPAA, and sector regulations.',
)
@SectionId('SECEREIN')
class SecurityCertificationRequirementsIndustry {
  @Form([
    Field('pciDssLevel', String, 'PCI DSS Level',
        hint: 'PCI DSS compliance level based on transaction volume'),
    Field('hipaaRequirements', String, 'HIPAA Requirements',
        hint: 'PHI handling, BAA requirements if applicable'),
    Field('industrySpecificCompliance', String, 'Industry-Specific Compliance',
        hint: 'FINRA, FDA 21 CFR Part 11, NERC CIP, etc.'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Maintenance and budget.
@StandardReferences(
  [
    'ISO/IEC 27001 — internal audit and management review (Clause 9)',
    'SOC 2 — trust services criteria (security, audit evidence)',
  ],
  'Recertification cycle, continuous monitoring, and budget for security certifications.',
)
@SectionId('SCRM')
class SecurityCertificationRequirementsMaintenance {
  @Form([
    Field('recertificationCycle', String, 'Recertification Cycle',
        hint: 'Annual surveillance audits, triennial recertification'),
    Field('continuousComplianceMonitoring', String, 'Continuous Monitoring',
        hint: 'How ongoing compliance is monitored between audits'),
    Field('certificationBudget', String, 'Certification Budget',
        hint: 'Estimated budget for certification and maintenance'),
    Field('notes', String, 'Notes',
        hint: 'Additional security certification notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Compliance audit planning and scheduling.
@StandardReferences(
  [
    'ISO/IEC 27001 — internal audit and management review (Clause 9)',
    'ISO 19011 — auditing management systems (audit programme)',
    'SOC 2 — trust services criteria (security, audit evidence)',
  ],
  'Compliance audit planning and scheduling across internal and external audits.',
)
@SectionId('COAUSC')
class ComplianceAuditSchedule {
  @Form([
    // Audit types
    Field('internalAuditFrequency', String, 'Internal Audit Frequency',
        required: true,
        hint: 'How often internal security audits are conducted'),
    Field('externalAuditFrequency', String, 'External Audit Frequency',
        required: true,
        hint: 'How often external/third-party audits are conducted'),
    Field('auditTypes', String, 'Audit Types',
        hint:
            'Technical audit, process audit, compliance audit, forensic audit'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Annual planning and scoping rules.
  @SerializationOrder(1)
  ComplianceAuditSchedulePlanning planning = ComplianceAuditSchedulePlanning();

  /// Audit execution and evidence collection.
  @SerializationOrder(2)
  ComplianceAuditScheduleExecution execution =
    ComplianceAuditScheduleExecution();

  /// Reporting and remediation follow-up.
  @SerializationOrder(3)
  ComplianceAuditScheduleReporting reporting =
    ComplianceAuditScheduleReporting();
}

/// Annual planning and scoping rules.
@StandardReferences(
  [
    'ISO/IEC 27001 — internal audit and management review (Clause 9)',
    'ISO 19011 — auditing management systems (audit programme)',
  ],
  'Annual planning and scoping rules for the compliance audit schedule.',
)
@SectionId('CASP')
class ComplianceAuditSchedulePlanning {
  @Form([
  Field('annualAuditPlan', String, 'Annual Audit Plan',
    hint: 'Documented plan with scope, schedule, resources for the year'),
  Field('auditScopeDefinition', String, 'Scope Definition',
    hint:
      'How audit scope is determined: risk-based, regulatory, coverage rotation'),
  Field('auditResourceRequirements', String, 'Resource Requirements',
    hint: 'Internal staff, external auditors, tools, budget'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Audit execution and evidence collection.
@StandardReferences(
  [
    'ISO 19011 — auditing management systems (audit programme)',
    'SOC 2 — trust services criteria (security, audit evidence)',
  ],
  'Auditor qualifications, evidence collection, and interview process for the compliance audit schedule.',
)
@SectionId('CASE')
class ComplianceAuditScheduleExecution {
  @Form([
  Field('auditorQualifications', String, 'Auditor Qualifications',
    hint: 'CISA, CISSP, ISO 27001 Lead Auditor, industry-specific'),
  Field('auditEvidenceCollection', String, 'Evidence Collection',
    hint: 'How audit evidence is gathered, documented, and preserved'),
  Field('auditInterviewProcess', String, 'Interview Process',
    hint: 'Staff interview methodology during audits'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Reporting and remediation follow-up.
@StandardReferences(
  [
    'ISO/IEC 27001 — internal audit and management review (Clause 9)',
    'SOC 2 — trust services criteria (security, audit evidence)',
  ],
  'Reporting structure and remediation follow-up for the compliance audit schedule.',
)
@SectionId('CASR')
class ComplianceAuditScheduleReporting {
  @Form([
  Field('auditReportingStructure', String, 'Reporting Structure',
    hint: 'Finding format, severity rating, recommendation structure'),
  Field('findingRemediationTracking', String, 'Remediation Tracking',
    hint: 'How audit findings are tracked to resolution'),
  Field('managementResponseTimeline', String, 'Management Response Timeline',
    hint: 'Time for management to respond to audit findings'),
  Field('auditCommitteeReporting', String, 'Committee Reporting',
    hint: 'How audit results are reported to board/audit committee'),
  Field('notes', String, 'Notes',
    hint: 'Additional compliance audit schedule notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Automated security testing integration.
///
/// Requirements for SAST, DAST, IAST, and fuzzing integration
/// into the CI/CD pipeline and development workflow.
@StandardReferences(
  [
    'OWASP ASVS — verification and security testing requirements',
    'PCI DSS — logging, monitoring, and regular security testing',
    'NIST SP 800-53 — audit and accountability (AU) controls',
  ],
  'Automated security testing integration covering SAST, DAST, IAST, and fuzzing in the pipeline.',
)
@SectionId('SETEAU')
class SecurityTestingAutomation {
  @Form([
    Field('sastTool', String, 'SAST Tool',
        required: true,
        hint:
            'Static Application Security Testing: SonarQube, Semgrep, Fortify, Checkmarx'),
    Field('sastIntegration', String, 'SAST Integration',
        hint: 'CI/CD pipeline integration point: pre-commit, PR, build'),
    Field('sastRuleConfiguration', String, 'SAST Rule Configuration',
        hint: 'Custom rules, severity mapping, false-positive management'),
    Field('securityQualityGates', String, 'Security Quality Gates',
        required: true,
        hint:
            'Build-blocking criteria: no critical/high SAST findings, clean container scan'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Dynamic analysis configuration.
  @SerializationOrder(1)
  SecurityTestingAutomationDast dast = SecurityTestingAutomationDast();

  /// Interactive analysis configuration.
  @SerializationOrder(2)
  SecurityTestingAutomationIast iast = SecurityTestingAutomationIast();

  /// Fuzzing configuration.
  @SerializationOrder(3)
  SecurityTestingAutomationFuzzing fuzzing =
      SecurityTestingAutomationFuzzing();

  /// Container and IaC scanning.
  @SerializationOrder(4)
  SecurityTestingAutomationScanning scanning =
      SecurityTestingAutomationScanning();

  /// Governance and reporting.
  @SerializationOrder(5)
  SecurityTestingAutomationGovernance governance =
      SecurityTestingAutomationGovernance();
}

/// Dynamic analysis configuration.
@StandardReferences(
  [
    'OWASP WSTG — web security testing guide (penetration testing)',
    'OWASP ASVS — verification and security testing requirements',
  ],
  'Dynamic application security testing configuration within automated security testing.',
)
@SectionId('STAD')
class SecurityTestingAutomationDast {
  @Form([
    Field('dastTool', String, 'DAST Tool',
        hint:
            'Dynamic Application Security Testing: OWASP ZAP, Burp Suite, Nuclei'),
    Field('dastScanSchedule', String, 'DAST Scan Schedule',
        hint: 'Automated scan frequency against staging/QA environment'),
    Field('dastAuthenticationConfig', String, 'DAST Authentication',
        hint: 'How DAST scanner authenticates to test protected resources'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Interactive analysis configuration.
@StandardReferences(
  [
    'OWASP ASVS — verification and security testing requirements',
    'OWASP WSTG — web security testing guide (penetration testing)',
  ],
  'Interactive application security testing configuration within automated security testing.',
)
@SectionId('STAI')
class SecurityTestingAutomationIast {
  @Form([
    Field('iastTool', String, 'IAST Tool',
        hint:
            'Interactive Application Security Testing: Contrast Security, Hdiv'),
    Field('iastDeploymentModel', String, 'IAST Deployment',
        hint: 'Agent-based in QA/staging, runtime instrumentation approach'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Fuzzing configuration.
@StandardReferences(
  [
    'OWASP WSTG — web security testing guide (penetration testing)',
    'OWASP ASVS — verification and security testing requirements',
  ],
  'Fuzzing requirements and targets within automated security testing.',
)
@SectionId('STAF')
class SecurityTestingAutomationFuzzing {
  @Form([
    Field('fuzzingRequirements', String, 'Fuzzing Requirements',
        hint: 'API fuzzing, protocol fuzzing, input mutation testing'),
    Field('fuzzingTargets', String, 'Fuzzing Targets',
        hint: 'API endpoints, file parsers, protocol handlers to fuzz'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Container and IaC scanning.
@StandardReferences(
  [
    'OWASP ASVS — verification and security testing requirements',
    'NIST SP 800-53 — audit and accountability (AU) controls',
  ],
  'Container image, infrastructure-as-code, and secrets scanning within automated security testing.',
)
@SectionId('STAS')
class SecurityTestingAutomationScanning {
  @Form([
    Field('containerScanning', String, 'Container Scanning',
        hint: 'Docker image vulnerability scanning: Trivy, Grype, Snyk Container'),
    Field('infrastructureAsCodeScanning', String, 'IaC Scanning',
        hint: 'Terraform, CloudFormation scanning: Checkov, tfsec, KICS'),
    Field('secretsDetection', String, 'Secrets Detection',
        hint: 'Pre-commit secrets scanning: GitLeaks, TruffleHog, detect-secrets'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Governance and reporting.
@StandardReferences(
  [
    'OWASP ASVS — verification and security testing requirements',
    'PCI DSS — logging, monitoring, and regular security testing',
  ],
  'Governance and reporting for automated security testing, including false-positive triage and dashboards.',
)
@SectionId('STAG')
class SecurityTestingAutomationGovernance {
  @Form([
    Field('falsePositiveProcess', String, 'False Positive Process',
        hint: 'How false positives are triaged, suppressed, and documented'),
    Field('securityDashboard', String, 'Security Dashboard',
        hint: 'Centralized security metrics and trend visualization'),
    Field('notes', String, 'Notes',
        hint: 'Additional security testing automation notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A security audit requirement entry (form).
@StandardReferences(
  [
    'ISO/IEC 27001 — internal audit and management review (Clause 9)',
    'ISO 19011 — auditing management systems (audit programme)',
  ],
  'A single security audit requirement with its schedule, execution, and follow-up.',
)
@SectionId('SAE')
class SecurityAuditEntry {
  @Form([
    // Audit identification
    Field('auditName', String, 'Audit Name',
        required: true, hint: 'Name or title of the audit requirement'),
    Field('auditCategory', String, 'Audit Category',
        hint:
            'Penetration test, compliance audit, code audit, infrastructure audit'),
    Field('auditDescription', String, 'Description',
        hint: 'Detailed description of what the audit covers'),
  Field('frequency', String, 'Frequency',
    required: true, hint: 'Annual, semi-annual, quarterly, on-demand'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Audit schedule and cadence.
  @SerializationOrder(1)
  SecurityAuditEntryScheduling scheduling = SecurityAuditEntryScheduling();

  /// Scope, standards, and execution model.
  @SerializationOrder(2)
  SecurityAuditEntryExecution execution = SecurityAuditEntryExecution();

  /// Deliverables, ownership, and notes.
  @SerializationOrder(3)
  SecurityAuditEntryFollowUp followUp = SecurityAuditEntryFollowUp();
}

/// Audit schedule and cadence.
@StandardReferences(
  [
    'ISO 19011 — auditing management systems (audit programme)',
    'PCI DSS — logging, monitoring, and regular security testing',
  ],
  'Schedule and cadence for a security audit requirement.',
)
@SectionId('SAES')
class SecurityAuditEntryScheduling {
  @Form([
  Field('lastAuditDate', String, 'Last Audit Date',
    hint: 'Date of most recent audit'),
  Field('nextAuditDate', String, 'Next Audit Date',
    hint: 'Planned date for next audit'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scope, standards, and execution model.
@StandardReferences(
  [
    'ISO 19011 — auditing management systems (audit programme)',
    'ISO/IEC 27001 — internal audit and management review (Clause 9)',
  ],
  'Scope, applicable standards, and execution model for a security audit requirement.',
)
@SectionId('SAEE')
class SecurityAuditEntryExecution {
  @Form([
  Field('auditScope', String, 'Audit Scope',
    hint: 'Systems, processes, and data in scope'),
  Field('auditStandard', String, 'Audit Standard',
    hint: 'Standard or framework: ISO 27001, SOC 2, OWASP, PCI DSS'),
  Field('auditorType', String, 'Auditor Type',
    hint: 'Internal team, external firm, regulatory body'),
  Field('estimatedDuration', String, 'Estimated Duration',
    hint: 'Expected duration of the audit engagement'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Deliverables, ownership, and notes.
@StandardReferences(
  [
    'ISO 19011 — auditing management systems (audit programme)',
    'NIST SP 800-53 — audit and accountability (AU) controls',
  ],
  'Deliverables, ownership, and remediation follow-up for a security audit requirement.',
)
@SectionId('SAEFU')
class SecurityAuditEntryFollowUp {
  @Form([
  Field('expectedDeliverables', String, 'Expected Deliverables',
    hint: 'Audit report, remediation plan, certification, attestation'),
  Field('remediationTimeline', String, 'Remediation Timeline',
    hint: 'Expected timeline for addressing findings'),
  Field('responsibleParty', String, 'Responsible Party',
    hint: 'Team or individual responsible for coordinating the audit'),
  Field('notes', String, 'Notes',
    hint: 'Additional audit requirement notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 8.9 System Architecture
// ---------------------------------------------------------------------------

/// 8.9. System Architecture.
///
/// Detailed internal architecture (layers, packages, patterns). Covers
///
///
/// Class named `SystemArchitectureSpec` to avoid colliding with any other
/// architecture-related identifier in the model.
@SectionId('SYARSP')
@DetailedIn(D06ArchitectureTechnologySpecification)
@SecondLevelSectionId(D06ArchitectureTechnologySpecification, 'ATS-ARC')
class SystemArchitectureSpec {
  @ContentHelp('''
System-level architecture description: layering, package structure,
significant design patterns, boundary definitions, and architectural
drivers / trade-offs.

**What to capture:**
- Layering strategy (presentation / application / domain / infrastructure)
- Package / module structure and dependency direction rules
- Design patterns adopted (CQRS, event sourcing, hexagonal, etc.)
- Architectural drivers (performance, security, maintainability)
- Trade-offs explicitly accepted
- Reference architecture diagrams (high-level + key views)
- Technology-radar alignment (Adopt / Trial / Assess / Hold)
''')
  @SerializationOrder(0)
  String? content;
}

/// A single maintenance procedure entry.
@SectionId('MAINT')
class MaintenanceProcedureEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}
