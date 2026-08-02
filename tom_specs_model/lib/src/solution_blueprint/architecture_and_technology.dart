/// Section 8: Technical Framework Concept. Seeds → ATS.
///
/// Technical framework requirements and constraints.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// The closed set of things that can start a scheduled job ([ScheduledJobEntry]).
///
/// The discriminator enum for the `ScheduledJobEntry` `@OneOf` group. The three
/// arms are not variants of one shape — each is started by a different thing and
/// therefore authors a different rule, so each binds its own case subsection:
///
/// - [cron] fires on a recurring clock expression.
/// - [calendar] fires on a date rule that a clock expression cannot state —
///   month-end, the third Monday of a quarter.
/// - [event] does not fire on time at all: it runs when something in the system
///   happens, and the payload of that occurrence is what the work reads.
///
/// The set is closed at three because it is exactly the trigger vocabulary the
/// CodeSpecs surface realises (`codespecs_mapping.md` §5.29); a fourth arm would
/// be a specification that cannot be generated.
enum ScheduledJobTrigger {
  cron,
  calendar,
  event,
}

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
class TechnicalFrameworkConcept extends DocSpecsSection {
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
  @override
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
  StandardSoftwareRequirements standardSoftware =
      StandardSoftwareRequirements();

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
class BasicTechnicalRequirements extends DocSpecsSection {
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
  @override
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
class PlatformAndLanguage extends DocSpecsSection {
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
  @override
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
class TargetPlatformEntry extends DocSpecsSection {
  @Form([
    Field(
      'platformName',
      String,
      'Platform Name',
      required: true,
      hint: 'E.g., Linux, Windows Server, macOS, iOS, Android',
    ),
    Field(
      'platformCategory',
      String,
      'Category',
      hint:
          'Operating System, Runtime Environment, Container Platform, Cloud Platform',
    ),
    Field('platformType', String, 'Type', hint: 'Server, Desktop, Mobile, IoT'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Version requirements.
  @SectionId('TPEVR')
  @StandardReferences(
    ['Semantic Versioning (SemVer) — version numbering'],
    'The minimum, recommended and maximum supported versions of a target platform.',
  )
  @Form([
    Field(
      'minimumVersion',
      String,
      'Minimum Version',
      required: true,
      hint: 'Earliest supported version',
    ),
    Field(
      'recommendedVersion',
      String,
      'Recommended Version',
      hint: 'Preferred target version',
    ),
    Field(
      'maximumVersion',
      String,
      'Maximum Version',
      hint: 'Latest tested/supported version',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? version;

  /// Architecture details.
  @SectionId('TPEAR')
  @StandardReferences([
    'ISO/IEC 25010 — portability/compatibility',
  ], 'The processor architectures and bitness a target platform supports.')
  @Form([
    Field(
      'supportedArchitectures',
      String,
      'Supported Architectures',
      hint: 'E.g., x86_64, ARM64, WASM',
    ),
    Field('bitness', String, 'Bitness', hint: '32-bit, 64-bit, Both'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? architecture;

  /// Requirements and constraints.
  @SectionId('TPERQ')
  @StandardReferences(
    ['ISO/IEC 25010 — portability/compatibility'],
    'The minimum memory, storage and OS features a target platform must provide.',
  )
  @Form([
    Field(
      'minimumMemory',
      String,
      'Minimum Memory',
      hint: 'Minimum RAM requirement',
    ),
    Field(
      'minimumStorage',
      String,
      'Minimum Storage',
      hint: 'Minimum disk space',
    ),
    Field(
      'requiredFeatures',
      String,
      'Required Features',
      hint: 'Specific OS features or capabilities needed',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? requirements;

  /// Lifecycle and compliance.
  @SectionId('TPELC')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The justification, support scope, end-of-life date and certification requirements for a target platform.',
  )
  @Form([
    Field(
      'justification',
      String,
      'Justification',
      hint: 'Reason for selecting this platform',
    ),
    Field(
      'supportScope',
      String,
      'Support Scope',
      hint: 'Primary, Secondary, Limited',
    ),
    Field(
      'endOfLifeDate',
      String,
      'End of Life Date',
      hint: 'Platform EOL date for planning',
    ),
    Field(
      'certificationRequirements',
      String,
      'Certification Requirements',
      hint: 'Required platform certifications',
    ),
    Field('notes', String, 'Notes', hint: 'Additional platform-specific notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? lifecycle;
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
class ProgrammingLanguageEntry extends DocSpecsSection {
  @Form([
    Field(
      'languageName',
      String,
      'Language Name',
      required: true,
      hint: 'E.g., Dart, TypeScript, Python, Rust',
    ),
    Field(
      'languageVariant',
      String,
      'Variant',
      hint: 'E.g., Sound null safety, Strict mode',
    ),
    Field(
      'minimumVersion',
      String,
      'Minimum Version',
      required: true,
      hint: 'Earliest supported language version',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Version requirements.
  @SectionId('PLGVR')
  @StandardReferences(
    ['Semantic Versioning (SemVer) — version numbering'],
    'The recommended and maximum supported versions of a programming language.',
  )
  @Form([
    Field(
      'recommendedVersion',
      String,
      'Recommended Version',
      hint: 'Preferred target version',
    ),
    Field(
      'maximumVersion',
      String,
      'Maximum Version',
      hint: 'Latest tested/supported version',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? version;

  /// SDK configuration.
  @SectionId('PLGSK')
  @StandardReferences(
    [
      'Semantic Versioning (SemVer) — version numbering',
      'language standard (ISO/ECMA/PEP) — programming language specification',
    ],
    'The SDK name and minimum/recommended versions for a programming language.',
  )
  @Form([
    Field('sdkName', String, 'SDK Name', hint: 'E.g., Dart SDK, Node.js'),
    Field(
      'sdkMinVersion',
      String,
      'SDK Min Version',
      hint: 'Minimum SDK version',
    ),
    Field(
      'sdkRecommendedVersion',
      String,
      'SDK Recommended Version',
      hint: 'Recommended SDK version',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? sdk;

  /// Usage context.
  @SectionId('PLGUS')
  @StandardReferences(
    [
      'language standard (ISO/ECMA/PEP) — programming language specification',
      'Domain-Driven Design — layered/hexagonal architecture',
    ],
    'Where and how a programming language is used — context, share of the codebase, primary status and required language features.',
  )
  @Form([
    Field(
      'usageContext',
      String,
      'Usage Context',
      hint: 'Backend, Frontend, Full-stack, Scripting, Build tools, Testing',
    ),
    Field(
      'codebasePercentage',
      String,
      'Codebase %',
      hint: 'Approximate percentage of codebase',
    ),
    Field(
      'isPrimaryLanguage',
      bool,
      'Primary Language',
      hint: 'Is this the main implementation language?',
    ),
    Field(
      'requiredFeatures',
      String,
      'Required Language Features',
      hint: 'Specific language features needed',
    ),
    Field(
      'enabledLanguageOptions',
      String,
      'Enabled Options',
      hint: 'Compiler/interpreter options to enable',
    ),
    Field(
      'disabledLanguageOptions',
      String,
      'Disabled Options',
      hint: 'Compiler/interpreter options to disable',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? usage;

  /// Quality settings.
  @SectionId('PLGQU')
  @StandardReferences(
    [
      'ISO/IEC 25010 — product quality (maintainability/portability)',
      'language standard (ISO/ECMA/PEP) — programming language specification',
    ],
    'The linting, static analysis and code-style standards enforced for a programming language.',
  )
  @Form([
    Field(
      'lintingRules',
      String,
      'Linting Rules',
      hint: 'Required linting configuration',
    ),
    Field(
      'staticAnalysis',
      String,
      'Static Analysis',
      hint: 'Static analysis requirements',
    ),
    Field(
      'codeStyle',
      String,
      'Code Style',
      hint: 'Code style/formatting standard',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? quality;

  /// Justification and notes.
  @SectionId('PLGJT')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'arc42 — architecture documentation template',
    ],
    'The rationale for choosing a programming language, the alternatives considered and its migration path.',
  )
  @Form([
    Field(
      'justification',
      String,
      'Justification',
      required: true,
      hint: 'Reason for selecting this language',
    ),
    Field(
      'alternativesConsidered',
      String,
      'Alternatives Considered',
      hint: 'Other languages evaluated',
    ),
    Field(
      'migrationPath',
      String,
      'Migration Path',
      hint: 'Upgrade/migration strategy',
    ),
    Field('notes', String, 'Notes', hint: 'Additional language notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? justification;
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
class FrameworkRequirementEntry extends DocSpecsSection {
  @Form([
    Field(
      'frameworkName',
      String,
      'Framework/Library Name',
      required: true,
      hint: 'E.g., Flutter, Angular, Django, Spring Boot',
    ),
    Field(
      'frameworkCategory',
      String,
      'Category',
      hint: 'UI Framework, Backend Framework, Testing, State Management',
    ),
    Field(
      'purpose',
      String,
      'Purpose',
      required: true,
      hint: 'What problem this framework solves',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Identity details.
  @SectionId('FWRID')
  @StandardReferences([
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'The publisher and license identity of a framework or library.')
  @Form([
    Field('publisher', String, 'Publisher', hint: 'Framework publisher/owner'),
    Field(
      'license',
      String,
      'License',
      hint: 'License type (MIT, Apache, etc.)',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identity;

  /// Version requirements.
  @SectionId('FWRVR')
  @StandardReferences(
    ['Semantic Versioning (SemVer) — version numbering'],
    'The minimum, recommended and maximum versions and version constraint for a framework.',
  )
  @Form([
    Field(
      'minimumVersion',
      String,
      'Minimum Version',
      required: true,
      hint: 'Earliest supported version',
    ),
    Field(
      'recommendedVersion',
      String,
      'Recommended Version',
      hint: 'Preferred target version',
    ),
    Field(
      'maximumVersion',
      String,
      'Maximum Version',
      hint: 'Latest tested/supported version',
    ),
    Field(
      'versionConstraint',
      String,
      'Version Constraint',
      hint: 'E.g., ^3.0.0, >=2.0.0 <4.0.0',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? version;

  /// Scope and plugins.
  @SectionId('FWRSC')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'Domain-Driven Design — layered/hexagonal architecture',
    ],
    'The usage scope, integration points and required/optional plugins of a framework in the architecture.',
  )
  @Form([
    Field(
      'usageScope',
      String,
      'Usage Scope',
      hint: 'Core, Feature-specific, Development-only, Testing-only',
    ),
    Field(
      'integrationPoints',
      String,
      'Integration Points',
      hint: 'Where this framework integrates in the architecture',
    ),
    Field(
      'requiredPlugins',
      String,
      'Required Plugins/Extensions',
      hint: 'Mandatory plugins or extensions',
    ),
    Field(
      'optionalPlugins',
      String,
      'Optional Plugins/Extensions',
      hint: 'Recommended optional plugins',
    ),
    Field(
      'excludedFeatures',
      String,
      'Excluded Features',
      hint: 'Framework features that should not be used',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? scope;

  /// Compatibility.
  @SectionId('FWRCP')
  @StandardReferences(
    ['ISO/IEC 25010 — portability/compatibility'],
    'The compatibility, conflicts and deprecation warnings of a framework relative to others.',
  )
  @Form([
    Field(
      'compatibleWith',
      String,
      'Compatible With',
      hint: 'Other frameworks/versions this is compatible with',
    ),
    Field(
      'conflictsWith',
      String,
      'Conflicts With',
      hint: 'Known conflicts with other frameworks',
    ),
    Field(
      'deprecationWarnings',
      String,
      'Deprecation Warnings',
      hint: 'Known deprecations to address',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? compatibility;

  /// Support status.
  @SectionId('FWRSP')
  @StandardReferences(
    ['ISO/IEC 12207 — software lifecycle processes'],
    'The support status, community size and documentation quality of a framework.',
  )
  @Form([
    Field(
      'supportStatus',
      String,
      'Support Status',
      hint: 'Active, Maintenance, Deprecated',
    ),
    Field(
      'communitySize',
      String,
      'Community Size',
      hint: 'Small, Medium, Large',
    ),
    Field(
      'documentationQuality',
      String,
      'Documentation Quality',
      hint: 'Excellent, Good, Fair, Poor',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? support;

  /// Justification.
  @SectionId('FWRJT')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'arc42 — architecture documentation template',
    ],
    'The rationale for selecting a framework, the alternatives considered and its risk assessment.',
  )
  @Form([
    Field(
      'justification',
      String,
      'Justification',
      required: true,
      hint: 'Reason for selecting this framework',
    ),
    Field(
      'alternativesConsidered',
      String,
      'Alternatives Considered',
      hint: 'Other frameworks evaluated',
    ),
    Field(
      'riskAssessment',
      String,
      'Risk Assessment',
      hint: 'Vendor lock-in, maintenance, complexity risks',
    ),
    Field('notes', String, 'Notes', hint: 'Additional framework notes'),
  ])
  @SerializationOrder(6)
  DocSpecsSection? justification;
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
class BuildToolchainEntry extends DocSpecsSection {
  @Form([
    Field(
      'toolName',
      String,
      'Tool Name',
      required: true,
      hint: 'E.g., Gradle, CMake, Webpack, Dart build_runner',
    ),
    Field(
      'toolCategory',
      String,
      'Category',
      hint:
          'Build System, Compiler, Bundler, Code Generator, Task Runner, Package Manager',
    ),
    Field(
      'platform',
      String,
      'Platform',
      hint: 'Which platform(s) this tool is used for',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Version requirements.
  @SectionId('BTCVR')
  @StandardReferences([
    'Semantic Versioning (SemVer) — version numbering',
  ], 'The minimum and recommended versions of a build-toolchain tool.')
  @Form([
    Field(
      'minimumVersion',
      String,
      'Minimum Version',
      required: true,
      hint: 'Earliest supported version',
    ),
    Field(
      'recommendedVersion',
      String,
      'Recommended Version',
      hint: 'Preferred target version',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? versions;

  /// Configuration and plugins.
  @SectionId('BTCCF')
  @StandardReferences(
    ['Twelve-Factor App — cloud-native methodology'],
    'The configuration file and required/optional plugins for a build-toolchain tool.',
  )
  @Form([
    Field(
      'configurationFile',
      String,
      'Configuration File',
      hint: 'Primary configuration file name',
    ),
    Field(
      'requiredPlugins',
      String,
      'Required Plugins',
      hint: 'Mandatory build plugins',
    ),
    Field(
      'optionalPlugins',
      String,
      'Optional Plugins',
      hint: 'Recommended optional plugins',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? configuration;

  /// Build profile settings.
  @SectionId('BTEP')
  @StandardReferences(
    ['Twelve-Factor App — cloud-native methodology'],
    'The build profiles (debug, release, production) and default profile for a build-toolchain tool.',
  )
  @Form([
    Field(
      'buildProfiles',
      String,
      'Build Profiles',
      hint: 'E.g., Debug, Release, Profile, Production',
    ),
    Field(
      'defaultProfile',
      String,
      'Default Profile',
      hint: 'Default build profile',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? profiles;

  /// Integration touchpoints.
  @SectionId('BTEI')
  @StandardReferences([
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 12207 — software lifecycle processes',
  ], 'The CI/CD and IDE integration points of a build-toolchain tool.')
  @Form([
    Field(
      'cicdIntegration',
      String,
      'CI/CD Integration',
      hint: 'Integration with CI/CD pipelines',
    ),
    Field(
      'ideIntegration',
      String,
      'IDE Integration',
      hint: 'Integration with development IDEs',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? integration;

  /// Output artifact settings.
  @SectionId('BTEO')
  @StandardReferences(
    ['ISO/IEC 12207 — software lifecycle processes'],
    'The output artifacts produced by a build-toolchain tool and where they are stored.',
  )
  @Form([
    Field(
      'outputArtifacts',
      String,
      'Output Artifacts',
      hint: 'Types of artifacts produced',
    ),
    Field(
      'outputLocations',
      String,
      'Output Locations',
      hint: 'Where build artifacts are stored',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? outputs;

  /// Performance and rationale.
  @SectionId('BUTOENOP')
  @StandardReferences(
    [
      'ISO/IEC 25010 — product quality (maintainability/portability)',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'The caching strategy, parallelization and rationale governing a build-toolchain tool.',
  )
  @Form([
    Field(
      'cachingStrategy',
      String,
      'Caching Strategy',
      hint: 'Build caching approach',
    ),
    Field(
      'parallelization',
      String,
      'Parallelization',
      hint: 'Parallel build capabilities',
    ),
    Field(
      'justification',
      String,
      'Justification',
      hint: 'Reason for selecting this tool',
    ),
    Field('notes', String, 'Notes', hint: 'Additional toolchain notes'),
  ])
  @SerializationOrder(6)
  DocSpecsSection? operations;
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
class DeploymentTargetEntry extends DocSpecsSection {
  @Form([
    Field(
      'targetName',
      String,
      'Target Name',
      required: true,
      hint: 'E.g., Production Web, iOS App Store, Docker Hub',
    ),
    Field(
      'targetCategory',
      String,
      'Category',
      hint: 'Web, Mobile App, Desktop App, Cloud Service, Container, Embedded',
    ),
    Field(
      'targetEnvironment',
      String,
      'Environment',
      hint: 'Development, Staging, Production',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Platform specifics.
  @SectionId('DTEP')
  @StandardReferences([
    'ISO/IEC 25010 — portability/compatibility',
  ], 'The platform target and distribution channel of a deployment target.')
  @Form([
    Field(
      'platformTarget',
      String,
      'Platform Target',
      hint: 'Specific platform/OS this deployment targets',
    ),
    Field(
      'distributionChannel',
      String,
      'Distribution Channel',
      hint: 'App Store, Play Store, Web hosting, Container registry',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? platform;

  /// Build output configuration.
  @SectionId('DTEBO')
  @StandardReferences(
    ['ISO/IEC 12207 — software lifecycle processes'],
    'The artifact format, naming, signing, size limit and performance targets for a deployment target build output.',
  )
  @Form([
    Field(
      'artifactFormat',
      String,
      'Artifact Format',
      hint: 'E.g., APK, AAB, IPA, EXE, Docker image, WASM',
    ),
    Field(
      'artifactNaming',
      String,
      'Artifact Naming',
      hint: 'Naming convention for artifacts',
    ),
    Field(
      'signingRequirements',
      String,
      'Signing Requirements',
      hint: 'Code signing requirements',
    ),
    Field('sizeLimit', String, 'Size Limit', hint: 'Maximum artifact size'),
    Field(
      'performanceTargets',
      String,
      'Performance Targets',
      hint: 'Startup time, memory footprint targets',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? buildOutput;

  /// Platform requirements.
  @SectionId('DTER')
  @StandardReferences(
    ['ISO/IEC 25010 — portability/compatibility'],
    'The minimum OS version, target SDK, permissions and capabilities a deployment target requires.',
  )
  @Form([
    Field(
      'minimumOsVersion',
      String,
      'Minimum OS Version',
      hint: 'Minimum target OS version',
    ),
    Field(
      'targetSdkVersion',
      String,
      'Target SDK Version',
      hint: 'Target SDK/API level',
    ),
    Field(
      'requiredPermissions',
      String,
      'Required Permissions',
      hint: 'Platform permissions needed',
    ),
    Field(
      'requiredCapabilities',
      String,
      'Required Capabilities',
      hint: 'Platform capabilities needed',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? requirements;

  /// Deployment process configuration.
  @SectionId('DETAENPR')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'The deployment method, rollback strategy and feature-flag support for a deployment target.',
  )
  @Form([
    Field(
      'deploymentMethod',
      String,
      'Deployment Method',
      hint: 'Manual, CI/CD, Blue-green, Rolling',
    ),
    Field(
      'rollbackStrategy',
      String,
      'Rollback Strategy',
      hint: 'How to rollback failed deployments',
    ),
    Field(
      'featureFlagsSupport',
      String,
      'Feature Flags Support',
      hint: 'Feature flag implementation',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? process;

  /// Compliance and notes.
  @SectionId('DTEC')
  @StandardReferences(
    ['ISO/IEC 12207 — software lifecycle processes'],
    'The compliance, privacy, priority and launch-date details for a deployment target.',
  )
  @Form([
    Field(
      'complianceRequirements',
      String,
      'Compliance Requirements',
      hint: 'Store guidelines, regulatory requirements',
    ),
    Field(
      'privacyRequirements',
      String,
      'Privacy Requirements',
      hint: 'Privacy manifest, tracking transparency',
    ),
    Field('priority', String, 'Priority', hint: 'Primary, Secondary, Future'),
    Field(
      'targetLaunchDate',
      String,
      'Target Launch Date',
      hint: 'Target date for this deployment',
    ),
    Field('notes', String, 'Notes', hint: 'Additional deployment notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? compliance;
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
class DependencyManagement extends DocSpecsSection {
  @Form([
    // Package manager
    Field(
      'primaryPackageManager',
      String,
      'Primary Package Manager',
      hint: 'E.g., pub.dev, npm, pip, Maven',
    ),
    Field(
      'secondaryPackageManagers',
      String,
      'Secondary Package Managers',
      hint: 'Additional package managers used',
    ),
    Field(
      'registryUrls',
      String,
      'Registry URLs',
      hint: 'Package registry URLs (public and private)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Versioning and update policy.
  @SectionId('DEMAVE')
  @StandardReferences([
    'Semantic Versioning (SemVer) — version numbering',
  ], 'The versioning, update and lockfile policies for managing dependencies.')
  @Form([
    Field(
      'versioningPolicy',
      String,
      'Versioning Policy',
      hint: 'SemVer, CalVer, custom',
    ),
    Field(
      'dependencyUpdatePolicy',
      String,
      'Update Policy',
      hint: 'How and when to update dependencies',
    ),
    Field(
      'lockfilePolicy',
      String,
      'Lockfile Policy',
      hint: 'Required, Recommended, Optional',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? versioning;

  /// Security and trust controls.
  @SectionId('DEMASE')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'ISO/IEC 25010 — product quality (maintainability/portability)',
    ],
    'The security scanning, license compliance and source-trust controls applied to dependencies.',
  )
  @Form([
    Field(
      'securityScanning',
      String,
      'Security Scanning',
      hint: 'Dependency vulnerability scanning requirements',
    ),
    Field(
      'licenseCompliance',
      String,
      'License Compliance',
      hint: 'Allowed and prohibited licenses',
    ),
    Field(
      'sourceTrust',
      String,
      'Source Trust',
      hint: 'Trusted sources and verification',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? security;

  /// Internal package and workspace strategy.
  @SectionId('DEMAIN')
  @StandardReferences(
    [
      'Domain-Driven Design — layered/hexagonal architecture',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'The internal package and monorepo/workspace strategy for managing dependencies.',
  )
  @Form([
    Field(
      'internalPackages',
      String,
      'Internal Packages',
      hint: 'Internal/private packages to use',
    ),
    Field(
      'monorepoStrategy',
      String,
      'Monorepo Strategy',
      hint: 'Workspace/monorepo dependency management',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? internal;

  /// Caching and offline behavior.
  @SectionId('DEMAOP')
  @StandardReferences([
    'Twelve-Factor App — cloud-native methodology',
  ], 'The caching and offline-build behavior for managing dependencies.')
  @Form([
    Field(
      'cachingStrategy',
      String,
      'Caching Strategy',
      hint: 'Dependency caching approach',
    ),
    Field(
      'offlineSupport',
      String,
      'Offline Support',
      hint: 'Offline build requirements',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional dependency management notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? operations;
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
class RuntimeEnvironment extends DocSpecsSection {
  @Form([
    Field(
      'minimumMemory',
      String,
      'Minimum Memory',
      hint: 'Minimum RAM for runtime',
    ),
    Field(
      'recommendedMemory',
      String,
      'Recommended Memory',
      hint: 'Recommended RAM for optimal performance',
    ),
    Field(
      'minimumCpuCores',
      String,
      'Minimum CPU Cores',
      hint: 'Minimum CPU cores required',
    ),
    Field(
      'minimumDiskSpace',
      String,
      'Minimum Disk Space',
      hint: 'Minimum disk space for installation',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Memory limits.
  @SectionId('RUENME')
  @StandardReferences([
    'ISO/IEC 25010 — product quality (maintainability/portability)',
  ], 'The hard memory limits or caps for the runtime environment.')
  @Form([
    Field(
      'memoryLimits',
      String,
      'Memory Limits',
      hint: 'Hard memory limits or caps',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? memory;

  /// CPU and graphics requirements.
  @SectionId('RUENCP')
  @StandardReferences(
    ['ISO/IEC 25010 — portability/compatibility'],
    'The required CPU architecture and GPU/graphics requirements of the runtime environment.',
  )
  @Form([
    Field(
      'cpuArchitecture',
      String,
      'CPU Architecture',
      hint: 'Required CPU architecture',
    ),
    Field(
      'gpuRequirements',
      String,
      'GPU Requirements',
      hint: 'GPU/graphics requirements if any',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? cpu;

  /// Storage requirements.
  @SectionId('RUENST')
  @StandardReferences(
    ['ISO/IEC 25010 — product quality (maintainability/portability)'],
    'The temporary space and storage type required by the runtime environment.',
  )
  @Form([
    Field(
      'temporarySpace',
      String,
      'Temporary Space',
      hint: 'Temporary storage requirements',
    ),
    Field(
      'storageType',
      String,
      'Storage Type',
      hint: 'SSD required, HDD acceptable',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? storage;

  /// Network requirements.
  @SectionId('RUENNE')
  @StandardReferences(
    ['Twelve-Factor App — cloud-native methodology'],
    'The connectivity, bandwidth and latency requirements of the runtime environment.',
  )
  @Form([
    Field(
      'networkRequirements',
      String,
      'Network Requirements',
      hint: 'Connectivity requirements',
    ),
    Field(
      'bandwidthRequirements',
      String,
      'Bandwidth Requirements',
      hint: 'Minimum bandwidth',
    ),
    Field(
      'latencyRequirements',
      String,
      'Latency Requirements',
      hint: 'Maximum acceptable latency',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? network;

  /// Environment variables.
  @SectionId('RUENVA')
  @StandardReferences(
    ['Twelve-Factor App — cloud-native methodology'],
    'The required and optional environment variables that configure the runtime environment.',
  )
  @Form([
    Field(
      'requiredEnvVariables',
      String,
      'Required Environment Variables',
      hint: 'Mandatory environment variables',
    ),
    Field(
      'optionalEnvVariables',
      String,
      'Optional Environment Variables',
      hint: 'Optional configuration variables',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? variables;

  /// Runtime dependencies.
  @SectionId('RUENDE')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'Domain-Driven Design — layered/hexagonal architecture',
    ],
    'The system libraries and external services the runtime environment depends on.',
  )
  @Form([
    Field(
      'systemDependencies',
      String,
      'System Dependencies',
      hint: 'Required system libraries or services',
    ),
    Field(
      'externalServices',
      String,
      'External Services',
      hint: 'Required external services (DB, cache, etc.)',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? dependencies;

  /// Scaling characteristics.
  @SectionId('RUENSC')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 25010 — product quality (maintainability/portability)',
    ],
    'The horizontal, vertical and auto-scaling characteristics of the runtime environment.',
  )
  @Form([
    Field(
      'horizontalScaling',
      String,
      'Horizontal Scaling',
      hint: 'Horizontal scaling support',
    ),
    Field(
      'verticalScaling',
      String,
      'Vertical Scaling',
      hint: 'Vertical scaling support',
    ),
    Field(
      'autoScalingRules',
      String,
      'Auto-Scaling Rules',
      hint: 'Auto-scaling triggers and limits',
    ),
  ])
  @SerializationOrder(7)
  DocSpecsSection? scaling;

  /// Additional notes.
  @SectionId('RUENNO')
  @StandardReferences([
    'arc42 — architecture documentation template',
  ], 'Additional free-form notes about the runtime environment.')
  @Form([
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional runtime environment notes',
    ),
  ])
  @SerializationOrder(8)
  DocSpecsSection? runtimeNotes;
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
class ArchitectureStyle extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Architecture overview and primary style selection.
  @SerializationOrder(1)
  ArchitectureOverview overview = ArchitectureOverview();

  /// Architecture principles guiding design decisions.
  @StandardReferences([
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — architectural quality attributes',
  ], 'The guiding architecture principles the design adheres to.')
  @SectionId('ARPR-PRIN-LST')
  @SectionIdPattern('ARPR-PRIN-xxx')
  @ContentHelp('Add one entry per architecture principle.')
  @SerializationOrder(2)
  List<ArchitecturePrincipleEntry> principles = [];

  /// System component organization and boundaries.
  @SerializationOrder(3)
  ComponentOrganization componentOrganization = ComponentOrganization();

  /// Component/service catalog.
  @StandardReferences([
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
    'C4 model — software architecture diagrams',
  ], 'The catalog of components and services that make up the architecture.')
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
  @StandardReferences([
    'ADR (Architecture Decision Records) — decision capture',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'The recorded architecture decisions and their rationale.')
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
class ArchitectureOverview extends DocSpecsSection {
  @Form([
    Field(
      'primaryStyle',
      String,
      'Primary Architecture Style',
      required: true,
      hint:
          'Monolith, Modular Monolith, Microservices, Event-Driven, Serverless, Hybrid',
    ),
    Field(
      'secondaryStyles',
      String,
      'Secondary Styles',
      hint: 'Additional architectural patterns used',
    ),
    Field(
      'styleSummary',
      String,
      'Style Summary',
      hint: 'Brief description of the chosen architecture',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Architecture drivers.
  @SectionId('AROVDR')
  @StandardReferences([
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
  ], 'The business and technical drivers that justify the architecture choice.')
  @Form([
    Field(
      'justification',
      String,
      'Justification',
      required: true,
      hint: 'Why this architecture style was chosen',
    ),
    Field(
      'businessDrivers',
      String,
      'Business Drivers',
      hint: 'Business requirements driving the choice',
    ),
    Field(
      'technicalDrivers',
      String,
      'Technical Drivers',
      hint: 'Technical requirements driving the choice',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? drivers;

  /// Trade-offs and alternatives.
  @SectionId('AOTO')
  @StandardReferences([
    'ADR (Architecture Decision Records) — decision capture',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'The trade-offs accepted and the alternatives considered and rejected.')
  @Form([
    Field(
      'benefitsExpected',
      String,
      'Expected Benefits',
      hint: 'Advantages of this architecture',
    ),
    Field(
      'tradeOffsAccepted',
      String,
      'Trade-offs Accepted',
      hint: 'Known compromises and their rationale',
    ),
    Field(
      'risksIdentified',
      String,
      'Risks Identified',
      hint: 'Architectural risks and mitigation',
    ),
    Field(
      'alternativesConsidered',
      String,
      'Alternatives Considered',
      hint: 'Other architectures evaluated',
    ),
    Field(
      'rejectionReasons',
      String,
      'Rejection Reasons',
      hint: 'Why alternatives were not chosen',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? tradeOffs;

  /// Evolution planning.
  @SectionId('AROVEV')
  @StandardReferences([
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
  ], 'The planned evolution path and migration strategy for the architecture.')
  @Form([
    Field(
      'evolutionPath',
      String,
      'Evolution Path',
      hint: 'How the architecture may evolve',
    ),
    Field(
      'migrationStrategy',
      String,
      'Migration Strategy',
      hint: 'Strategy for migrating from current state',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? evolution;

  /// Compliance considerations.
  @SectionId('AROVCO')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'ISO/IEC 25010 — architectural quality attributes',
    ],
    'The compliance requirements and industry benchmarks that constrain the architecture.',
  )
  @Form([
    Field(
      'complianceRequirements',
      String,
      'Compliance Requirements',
      hint: 'Regulatory or compliance constraints',
    ),
    Field(
      'industryBenchmarks',
      String,
      'Industry Benchmarks',
      hint: 'Reference to industry-standard architectures',
    ),
    Field('notes', String, 'Notes', hint: 'Additional architecture notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? compliance;
}

/// Architecture principle entry.
@StandardReferences([
  'ISO/IEC/IEEE 42010 — architecture description',
  'ISO/IEC 25010 — architectural quality attributes',
], 'A single architecture principle guiding design decisions.')
@SectionId('ARPR')
class ArchitecturePrincipleEntry extends DocSpecsSection {
  @Form([
    Field(
      'principleName',
      String,
      'Principle Name',
      required: true,
      hint: 'E.g., Separation of Concerns, DRY, SOLID',
    ),
    Field(
      'category',
      String,
      'Category',
      hint: 'Design, Implementation, Deployment, Security, Performance, Data',
    ),
    Field(
      'statement',
      String,
      'Statement',
      required: true,
      hint: 'Clear statement of the principle',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Rationale and practical implications.
  @SectionId('APEG')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'ISO/IEC 25010 — architectural quality attributes',
    ],
    'The rationale and practical implications of following this architecture principle.',
  )
  @Form([
    Field('rationale', String, 'Rationale', hint: 'Why this principle matters'),
    Field(
      'implications',
      String,
      'Implications',
      hint: 'What following this principle means in practice',
    ),
    Field(
      'violations',
      String,
      'Violation Examples',
      hint: 'Examples of what would violate this principle',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? guidance;

  /// Enforcement and applicability context.
  @SectionId('ARPRENGO')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'ISO/IEC 25010 — architectural quality attributes',
    ],
    'The enforcement level, mechanism, and applicable scope of this architecture principle.',
  )
  @Form([
    Field(
      'enforcementLevel',
      String,
      'Enforcement Level',
      hint: 'Mandatory, Recommended, Advisory',
    ),
    Field(
      'enforcementMechanism',
      String,
      'Enforcement Mechanism',
      hint: 'How compliance is ensured (review, linting, etc.)',
    ),
    Field(
      'applicableScope',
      String,
      'Applicable Scope',
      hint: 'Where this principle applies',
    ),
    Field(
      'exceptions',
      String,
      'Exceptions',
      hint: 'Allowed exceptions to this principle',
    ),
    Field(
      'relatedPrinciples',
      String,
      'Related Principles',
      hint: 'Other principles that relate to this one',
    ),
    Field('notes', String, 'Notes', hint: 'Additional principle notes'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? governance;
}

/// Component organization and boundaries.
@StandardReferences([
  'ISO/IEC/IEEE 42010 — architecture description',
  'arc42 — architecture documentation template',
  'C4 model — software architecture diagrams',
], 'How system components are organized and how their boundaries are defined.')
@SectionId('COOR')
class ComponentOrganization extends DocSpecsSection {
  @Form([
    Field(
      'organizationStrategy',
      String,
      'Organization Strategy',
      hint: 'By feature, by layer, by domain, hybrid',
    ),
    Field(
      'boundaryDefinition',
      String,
      'Boundary Definition',
      hint: 'How component boundaries are defined',
    ),
    Field(
      'modularityApproach',
      String,
      'Modularity Approach',
      hint: 'How modules/components are structured',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Layering rules.
  @SectionId('COORLA')
  @StandardReferences([
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
    'C4 model — software architecture diagrams',
  ], 'The architectural layers and the allowed dependencies between them.')
  @Form([
    Field(
      'layerStructure',
      String,
      'Layer Structure',
      hint: 'Architectural layers (presentation, domain, data, infra)',
    ),
    Field(
      'layerDependencies',
      String,
      'Layer Dependencies',
      hint: 'Allowed dependencies between layers',
    ),
    Field(
      'crossCuttingConcerns',
      String,
      'Cross-Cutting Concerns',
      hint: 'How cross-cutting concerns are handled',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? layering;

  /// Domain boundaries.
  @SectionId('COORDO')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / layered architecture',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The domain boundaries, shared kernel, and anti-corruption layers between contexts.',
  )
  @Form([
    Field(
      'domainBoundaries',
      String,
      'Domain Boundaries',
      hint: 'Bounded contexts or domain boundaries',
    ),
    Field(
      'sharedKernel',
      String,
      'Shared Kernel',
      hint: 'Components shared across domains',
    ),
    Field(
      'antiCorruptionLayers',
      String,
      'Anti-Corruption Layers',
      hint: 'Isolation between different domains/systems',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? domain;

  /// Coupling guidance.
  @SectionId('COORCO')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'Domain-Driven Design — bounded contexts / layered architecture',
    ],
    'The guidance on minimizing coupling and maximizing cohesion between components.',
  )
  @Form([
    Field(
      'couplingGuidelines',
      String,
      'Coupling Guidelines',
      hint: 'How to minimize coupling',
    ),
    Field(
      'cohesionGuidelines',
      String,
      'Cohesion Guidelines',
      hint: 'How to maximize cohesion',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? coupling;

  /// Dependency management rules.
  @SectionId('COORDE')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'arc42 — architecture documentation template',
    ],
    'The rules governing dependency direction, interface contracts, and versioning between components.',
  )
  @Form([
    Field(
      'dependencyDirection',
      String,
      'Dependency Direction',
      hint: 'Rules for dependency direction',
    ),
    Field(
      'interfaceContracts',
      String,
      'Interface Contracts',
      hint: 'How interfaces between components are defined',
    ),
    Field(
      'versioningStrategy',
      String,
      'Versioning Strategy',
      hint: 'How component versions are managed',
    ),
    Field('notes', String, 'Notes', hint: 'Additional organization notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? dependencies;
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
@CodeSpecKind(
  [CodeSpecPart.serviceUnit],
  note:
      'Architecture-level naming of a component/service boundary; informs '
      'the CE-SU service-unit slice (codespecs_mapping.md §5.1). The concrete '
      'CsServiceUnit code is server-only and derived from the D02/D05 '
      'operations, not from this narrative entry.',
)
class ArchitectureComponentEntry extends DocSpecsSection {
  @Form([
    Field(
      'componentName',
      String,
      'Component Name',
      required: true,
      hint: 'Unique name for this component',
    ),
    Field(
      'componentType',
      String,
      'Component Type',
      required: true,
      hint: 'Service, Module, Library, Package, Microservice, Function',
    ),
    Field('domain', String, 'Domain', hint: 'Business domain this belongs to'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Purpose and ownership boundaries.
  @SectionId('ACEP')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'arc42 — architecture documentation template',
    ],
    'The purpose and responsibilities of a component and what it is not responsible for.',
  )
  @Form([
    Field(
      'purpose',
      String,
      'Purpose',
      required: true,
      hint: 'What this component does',
    ),
    Field(
      'responsibilities',
      String,
      'Responsibilities',
      hint: 'List of responsibilities',
    ),
    Field(
      'notResponsibleFor',
      String,
      'Not Responsible For',
      hint: 'Explicitly out of scope',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? purpose;

  /// Public and private boundaries.
  @SectionId('ACEB')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'C4 model — software architecture diagrams',
    ],
    'The public interface and private implementation boundaries of a component.',
  )
  @Form([
    Field(
      'publicInterface',
      String,
      'Public Interface',
      hint: 'Exposed APIs or interfaces',
    ),
    Field(
      'privateImplementation',
      String,
      'Private Implementation',
      hint: 'Internal implementation details',
    ),
    Field(
      'dataOwnership',
      String,
      'Data Ownership',
      hint: 'Data entities this component owns',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? boundaries;

  /// Dependency relationships.
  @SectionId('ACED')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'C4 model — software architecture diagrams',
    ],
    'The upstream, downstream, and external dependency relationships of a component.',
  )
  @Form([
    Field(
      'upstreamDependencies',
      String,
      'Upstream Dependencies',
      hint: 'Components this depends on',
    ),
    Field(
      'downstreamDependents',
      String,
      'Downstream Dependents',
      hint: 'Components that depend on this',
    ),
    Field(
      'externalDependencies',
      String,
      'External Dependencies',
      hint: 'External systems this integrates with',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? dependencies;

  /// Technical delivery characteristics.
  @SectionId('ACET')
  @StandardReferences(
    [
      'REST / microservices — architectural style',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'The technology stack, deployment unit, and scaling characteristics of a component.',
  )
  @Form([
    Field(
      'technology',
      String,
      'Technology Stack',
      hint: 'Specific technologies used',
    ),
    Field(
      'deploymentUnit',
      String,
      'Deployment Unit',
      hint: 'Is this separately deployable?',
    ),
    Field(
      'scalingCharacteristics',
      String,
      'Scaling Characteristics',
      hint: 'How this component scales',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? technical;

  /// Team ownership and service expectations.
  @SectionId('ACEO')
  @StandardReferences([
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — architectural quality attributes',
  ], 'The team ownership and expected service level for a component.')
  @Form([
    Field(
      'teamOwnership',
      String,
      'Team Ownership',
      hint: 'Team responsible for this component',
    ),
    Field(
      'serviceLevel',
      String,
      'Service Level',
      hint: 'Expected availability and performance',
    ),
    Field('notes', String, 'Notes', hint: 'Additional component notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? ownership;
}

/// Communication patterns between components.
@StandardReferences([
  'REST / microservices — architectural style',
  'ISO/IEC/IEEE 42010 — architecture description',
], 'The communication patterns and protocols used between components.')
@SectionId('COMPAT')
class CommunicationPatterns extends DocSpecsSection {
  @Form([
    Field(
      'primaryPattern',
      String,
      'Primary Communication Pattern',
      hint: 'Synchronous REST, Async messaging, Event-driven, RPC',
    ),
    Field(
      'secondaryPatterns',
      String,
      'Secondary Patterns',
      hint: 'Additional patterns used',
    ),
    Field(
      'syncProtocols',
      String,
      'Synchronous Protocols',
      hint: 'REST, gRPC, GraphQL, SOAP',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Synchronous communication details.
  @SectionId('COPASY')
  @StandardReferences([
    'REST / microservices — architectural style',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'The synchronous request-response patterns and API gateway details.')
  @Form([
    Field(
      'syncPatterns',
      String,
      'Synchronous Patterns',
      hint: 'Request-response, Service mesh',
    ),
    Field(
      'apiGateway',
      String,
      'API Gateway',
      hint: 'Central gateway pattern details',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? synchronous;

  /// Asynchronous communication details.
  @SectionId('COPAAS')
  @StandardReferences(
    [
      'REST / microservices — architectural style',
      'POSA — patterns of software architecture',
    ],
    'The asynchronous messaging protocols and event patterns used between components.',
  )
  @Form([
    Field(
      'asyncProtocols',
      String,
      'Asynchronous Protocols',
      hint: 'Message brokers, event streaming',
    ),
    Field(
      'messageFormats',
      String,
      'Message Formats',
      hint: 'JSON, Protobuf, Avro, MessagePack',
    ),
    Field(
      'eventPatterns',
      String,
      'Event Patterns',
      hint: 'Pub/Sub, Event sourcing, CQRS',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? asynchronous;

  /// Data exchange contracts.
  @SectionId('CPDE')
  @StandardReferences(
    [
      'REST / microservices — architectural style',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The data contracts, schema evolution, and serialization used in component communication.',
  )
  @Form([
    Field(
      'dataContracts',
      String,
      'Data Contracts',
      hint: 'API contracts and schemas',
    ),
    Field(
      'schemaEvolution',
      String,
      'Schema Evolution',
      hint: 'How schemas evolve over time',
    ),
    Field(
      'serialization',
      String,
      'Serialization',
      hint: 'Serialization approach',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? dataExchange;

  /// Reliability controls.
  @SectionId('COPARE')
  @StandardReferences(
    [
      'POSA — patterns of software architecture',
      'ISO/IEC 25010 — architectural quality attributes',
    ],
    'The reliability controls such as retries, circuit breakers, timeouts, and idempotency.',
  )
  @Form([
    Field(
      'retryPolicies',
      String,
      'Retry Policies',
      hint: 'Retry and backoff strategies',
    ),
    Field(
      'circuitBreakers',
      String,
      'Circuit Breakers',
      hint: 'Circuit breaker patterns',
    ),
    Field('timeouts', String, 'Timeouts', hint: 'Timeout strategies'),
    Field('idempotency', String, 'Idempotency', hint: 'Idempotency guarantees'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? reliability;

  /// Observability settings.
  @SectionId('COPAOB')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 25010 — architectural quality attributes',
    ],
    'The tracing, logging, and metrics settings for observing component communication.',
  )
  @Form([
    Field('tracing', String, 'Distributed Tracing', hint: 'Tracing approach'),
    Field('logging', String, 'Logging Strategy', hint: 'Logging approach'),
    Field('metrics', String, 'Metrics', hint: 'Metrics collection'),
    Field('notes', String, 'Notes', hint: 'Additional communication notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? observability;
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
class DataArchitecture extends DocSpecsSection {
  @Form([
    Field(
      'dataStrategy',
      String,
      'Data Strategy',
      hint: 'Centralized, Distributed, Federated, Mesh',
    ),
    Field(
      'dataOwnership',
      String,
      'Data Ownership Model',
      hint: 'How data ownership is assigned',
    ),
    Field(
      'dataGovernance',
      String,
      'Data Governance',
      hint: 'Governance policies',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Storage decisions.
  @SectionId('DAARST')
  @StandardReferences([
    'ISO/IEC/IEEE 42010 — architecture description',
    'arc42 — architecture documentation template',
  ], 'The primary and secondary storage choices and storage topology.')
  @Form([
    Field(
      'primaryStorage',
      String,
      'Primary Storage',
      hint: 'Main database type and technology',
    ),
    Field(
      'secondaryStorage',
      String,
      'Secondary Storage',
      hint: 'Additional storage (cache, search, etc.)',
    ),
    Field(
      'storageTopology',
      String,
      'Storage Topology',
      hint: 'Single, Replicated, Sharded, Multi-region',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? storage;

  /// Data access patterns.
  @SectionId('DAARAC')
  @StandardReferences(
    [
      'POSA — patterns of software architecture',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The data access, query, and caching patterns used against the data stores.',
  )
  @Form([
    Field(
      'dataAccessPatterns',
      String,
      'Data Access Patterns',
      hint: 'CRUD, CQRS, Event sourcing',
    ),
    Field(
      'queryPatterns',
      String,
      'Query Patterns',
      hint: 'How data is queried',
    ),
    Field('caching', String, 'Caching Strategy', hint: 'Caching approach'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? access;

  /// Consistency model and transactions.
  @SectionId('DAARCO')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'ISO/IEC 25010 — architectural quality attributes',
    ],
    'The consistency model, transaction scope, and conflict resolution for data.',
  )
  @Form([
    Field(
      'consistencyModel',
      String,
      'Consistency Model',
      hint: 'Strong, Eventual, Causal',
    ),
    Field(
      'transactionScope',
      String,
      'Transaction Scope',
      hint: 'Local, Distributed, Saga',
    ),
    Field(
      'conflictResolution',
      String,
      'Conflict Resolution',
      hint: 'How conflicts are resolved',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? consistency;

  /// Lifecycle controls.
  @SectionId('DAARLI')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'ISO/IEC 25010 — architectural quality attributes',
    ],
    'The data retention, archiving, and recovery controls over the data lifecycle.',
  )
  @Form([
    Field(
      'dataRetention',
      String,
      'Data Retention',
      hint: 'Retention policies',
    ),
    Field(
      'archiving',
      String,
      'Archiving Strategy',
      hint: 'How old data is archived',
    ),
    Field(
      'dataRecovery',
      String,
      'Data Recovery',
      hint: 'Recovery point and time objectives',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? lifecycle;

  /// Privacy and security controls.
  @SectionId('DAARSE')
  @StandardReferences(
    [
      'ISO/IEC 25010 — architectural quality attributes',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The data classification, encryption, and access-control security controls.',
  )
  @Form([
    Field(
      'dataClassification',
      String,
      'Data Classification',
      hint: 'Classification levels',
    ),
    Field(
      'encryptionStrategy',
      String,
      'Encryption Strategy',
      hint: 'At-rest and in-transit encryption',
    ),
    Field(
      'accessControl',
      String,
      'Access Control',
      hint: 'Data access control model',
    ),
    Field('notes', String, 'Notes', hint: 'Additional data architecture notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? security;
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
class ScalabilityArchitecture extends DocSpecsSection {
  @Form([
    Field(
      'scalabilityModel',
      String,
      'Scalability Model',
      hint: 'Horizontal, Vertical, Both',
    ),
    Field(
      'elasticityApproach',
      String,
      'Elasticity Approach',
      hint: 'Manual, Auto-scaling, Serverless',
    ),
    Field(
      'scalingTriggers',
      String,
      'Scaling Triggers',
      hint: 'What triggers scaling actions',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Capacity planning assumptions.
  @SectionId('SCARCA')
  @StandardReferences(
    [
      'ISO/IEC 25010 — architectural quality attributes',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The expected load, peak load, and growth projections used for capacity planning.',
  )
  @Form([
    Field(
      'expectedLoad',
      String,
      'Expected Load',
      hint: 'Expected concurrent users/requests',
    ),
    Field('peakLoad', String, 'Peak Load', hint: 'Peak load expectations'),
    Field(
      'growthProjection',
      String,
      'Growth Projection',
      hint: 'Expected growth over time',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? capacity;

  /// Performance targets.
  @SectionId('SCARTA')
  @StandardReferences(
    [
      'ISO/IEC 25010 — architectural quality attributes',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The response-time, throughput, and availability targets for the architecture.',
  )
  @Form([
    Field(
      'responseTimeTargets',
      String,
      'Response Time Targets',
      hint: 'Target response times by tier',
    ),
    Field(
      'throughputTargets',
      String,
      'Throughput Targets',
      hint: 'Target transactions per second',
    ),
    Field(
      'availabilityTarget',
      String,
      'Availability Target',
      hint: 'Target availability (e.g., 99.9%)',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? targets;

  /// Performance patterns.
  @SectionId('SCARPA')
  @StandardReferences(
    [
      'POSA — patterns of software architecture',
      'ISO/IEC 25010 — architectural quality attributes',
    ],
    'The caching, load-balancing, and queueing patterns used to meet performance goals.',
  )
  @Form([
    Field(
      'cachingStrategy',
      String,
      'Caching Strategy',
      hint: 'Multi-level caching approach',
    ),
    Field(
      'loadBalancing',
      String,
      'Load Balancing',
      hint: 'Load balancing approach',
    ),
    Field(
      'queueingStrategy',
      String,
      'Queueing Strategy',
      hint: 'Request queueing and throttling',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? patterns;

  /// Resource optimization controls.
  @SectionId('SCAROP')
  @StandardReferences(
    [
      'ISO/IEC 25010 — architectural quality attributes',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'The connection pooling, resource limits, and graceful-degradation controls under load.',
  )
  @Form([
    Field(
      'connectionPooling',
      String,
      'Connection Pooling',
      hint: 'Connection pool management',
    ),
    Field(
      'resourceLimits',
      String,
      'Resource Limits',
      hint: 'Per-component resource limits',
    ),
    Field(
      'gracefulDegradation',
      String,
      'Graceful Degradation',
      hint: 'How system degrades under load',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? optimization;

  /// Testing and benchmarks.
  @SectionId('SCARTE')
  @StandardReferences(
    [
      'ISO/IEC 25010 — architectural quality attributes',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The performance and load testing approach and benchmarks the architecture must meet.',
  )
  @Form([
    Field(
      'performanceTesting',
      String,
      'Performance Testing',
      hint: 'Performance testing approach',
    ),
    Field('loadTesting', String, 'Load Testing', hint: 'Load testing approach'),
    Field(
      'benchmarks',
      String,
      'Benchmarks',
      hint: 'Performance benchmarks to meet',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional scalability/performance notes',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? testing;
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
class IntegrationArchitecture extends DocSpecsSection {
  @Form([
    Field(
      'integrationStrategy',
      String,
      'Integration Strategy',
      hint: 'Point-to-point, Hub-and-spoke, ESB, API-led',
    ),
    Field(
      'integrationPatterns',
      String,
      'Integration Patterns',
      hint: 'Adapters, Facades, Gateways',
    ),
    Field(
      'apiManagement',
      String,
      'API Management',
      hint: 'How APIs are managed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// External system landscape.
  @SectionId('INARSY')
  @StandardReferences(
    [
      'REST / microservices — architectural style',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The landscape of external systems, their integration types, and real-time needs.',
  )
  @Form([
    Field(
      'externalSystemCount',
      String,
      'External System Count',
      hint: 'Number of external integrations',
    ),
    Field(
      'integrationTypes',
      String,
      'Integration Types',
      hint: 'REST, SOAP, File, Database, Events',
    ),
    Field(
      'realTimeIntegrations',
      String,
      'Real-Time Integrations',
      hint: 'Integrations requiring real-time sync',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? systems;

  /// Data exchange approach.
  @SectionId('INARDA')
  @StandardReferences(
    [
      'REST / microservices — architectural style',
      'POSA — patterns of software architecture',
    ],
    'The data transformation, master-data management, and synchronization across systems.',
  )
  @Form([
    Field(
      'dataTransformation',
      String,
      'Data Transformation',
      hint: 'How data is transformed between systems',
    ),
    Field(
      'masterDataManagement',
      String,
      'Master Data Management',
      hint: 'How master data is managed across systems',
    ),
    Field(
      'dataSynchronization',
      String,
      'Data Synchronization',
      hint: 'Synchronization patterns and frequency',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? data;

  /// Security model for integrations.
  @SectionId('INARSE')
  @StandardReferences(
    [
      'ISO/IEC 25010 — architectural quality attributes',
      'REST / microservices — architectural style',
    ],
    'The authentication, authorization, and transport-security model for integrations.',
  )
  @Form([
    Field(
      'authenticationApproach',
      String,
      'Authentication Approach',
      hint: 'How integrations are authenticated',
    ),
    Field(
      'authorizationApproach',
      String,
      'Authorization Approach',
      hint: 'How integrations are authorized',
    ),
    Field(
      'secureTransport',
      String,
      'Secure Transport',
      hint: 'Transport security (TLS, VPN)',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? security;

  /// Reliability controls.
  @SectionId('INARRE')
  @StandardReferences(
    [
      'POSA — patterns of software architecture',
      'ISO/IEC 25010 — architectural quality attributes',
    ],
    'The error handling, retry, and compensating-action controls for integration reliability.',
  )
  @Form([
    Field(
      'errorHandling',
      String,
      'Error Handling',
      hint: 'How integration errors are handled',
    ),
    Field(
      'retryStrategy',
      String,
      'Retry Strategy',
      hint: 'Retry policies for failed integrations',
    ),
    Field(
      'compensatingActions',
      String,
      'Compensating Actions',
      hint: 'Actions when integration fails',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? reliability;

  /// Monitoring and SLA management.
  @SectionId('INAROP')
  @StandardReferences([
    'Twelve-Factor App — cloud-native methodology',
    'ISO/IEC 25010 — architectural quality attributes',
  ], 'The monitoring and SLA management for external integrations.')
  @Form([
    Field(
      'integrationMonitoring',
      String,
      'Integration Monitoring',
      hint: 'How integrations are monitored',
    ),
    Field('slaManagement', String, 'SLA Management', hint: 'Integration SLAs'),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional integration architecture notes',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? operations;
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
class DeploymentTopology extends DocSpecsSection {
  @Form([
    Field(
      'topologyType',
      String,
      'Topology Type',
      hint: 'Single-tier, Multi-tier, Distributed, Cloud-native',
    ),
    Field(
      'deploymentModel',
      String,
      'Deployment Model',
      hint: 'On-premise, Cloud, Hybrid, Multi-cloud',
    ),
    Field(
      'cloudProviders',
      String,
      'Cloud Providers',
      hint: 'Cloud providers used',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Infrastructure layout.
  @SectionId('DETOIN')
  @StandardReferences([
    'REST / microservices — architectural style',
    'Twelve-Factor App — cloud-native methodology',
  ], 'The compute model, network topology, and storage infrastructure layout.')
  @Form([
    Field(
      'computeModel',
      String,
      'Compute Model',
      hint: 'VMs, Containers, Serverless, Kubernetes',
    ),
    Field(
      'networkTopology',
      String,
      'Network Topology',
      hint: 'Network architecture',
    ),
    Field(
      'storageInfrastructure',
      String,
      'Storage Infrastructure',
      hint: 'Storage systems used',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? infrastructure;

  /// Environment layout.
  @SectionId('DETOEN')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'REST / microservices — architectural style',
    ],
    'The environments, their isolation, and per-environment configuration management.',
  )
  @Form([
    Field(
      'environments',
      String,
      'Environments',
      hint: 'Dev, Test, Staging, Production',
    ),
    Field(
      'environmentIsolation',
      String,
      'Environment Isolation',
      hint: 'How environments are isolated',
    ),
    Field(
      'configurationManagement',
      String,
      'Configuration Management',
      hint: 'How configuration differs per environment',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? environmentsConfig;

  /// High-availability settings.
  @SectionId('DETOAV')
  @StandardReferences(
    [
      'ISO/IEC 25010 — architectural quality attributes',
      'REST / microservices — architectural style',
    ],
    'The redundancy model, failover strategy, and disaster recovery for high availability.',
  )
  @Form([
    Field(
      'redundancyModel',
      String,
      'Redundancy Model',
      hint: 'Active-passive, Active-active',
    ),
    Field(
      'failoverStrategy',
      String,
      'Failover Strategy',
      hint: 'How failover is handled',
    ),
    Field(
      'disasterRecovery',
      String,
      'Disaster Recovery',
      hint: 'DR strategy and targets',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? availability;

  /// Geographic distribution.
  @SectionId('DETOGE')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'REST / microservices — architectural style',
    ],
    'The geographic distribution, data residency, and latency considerations for deployment.',
  )
  @Form([
    Field(
      'geographicDistribution',
      String,
      'Geographic Distribution',
      hint: 'Single-region, Multi-region, Global',
    ),
    Field(
      'dataResidency',
      String,
      'Data Residency',
      hint: 'Data residency requirements',
    ),
    Field(
      'latencyConsiderations',
      String,
      'Latency Considerations',
      hint: 'Geographic latency requirements',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? geography;

  /// Infrastructure-as-code strategy.
  @SectionId('DTIAC')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'REST / microservices — architectural style',
    ],
    'The infrastructure-as-code approach, immutability, and versioning strategy.',
  )
  @Form([
    Field(
      'iacApproach',
      String,
      'IaC Approach',
      hint: 'Terraform, CloudFormation, Pulumi',
    ),
    Field(
      'immutableInfrastructure',
      String,
      'Immutable Infrastructure',
      hint: 'Immutable infrastructure approach',
    ),
    Field(
      'infrastructureVersioning',
      String,
      'Infrastructure Versioning',
      hint: 'How infrastructure is versioned',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional deployment topology notes',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? infrastructureAsCode;
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
class ArchitectureDecisionRecord extends DocSpecsSection {
  @Form([
    Field(
      'decisionId',
      String,
      'Decision ID',
      required: true,
      hint: 'Unique identifier (e.g., ADR-001)',
    ),
    Field(
      'title',
      String,
      'Title',
      required: true,
      hint: 'Short title of the decision',
    ),
    Field(
      'date',
      String,
      'Date',
      required: true,
      hint: 'When the decision was made',
    ),
    Field(
      'status',
      String,
      'Status',
      required: true,
      hint: 'Proposed, Accepted, Deprecated, Superseded',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Decision context and constraints.
  @SectionId('ADRC')
  @StandardReferences(
    [
      'ADR (Architecture Decision Records) — decision capture',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The context, problem, and constraints that prompted an architecture decision.',
  )
  @Form([
    Field(
      'context',
      String,
      'Context',
      required: true,
      hint: 'What prompted this decision',
    ),
    Field(
      'problem',
      String,
      'Problem Statement',
      hint: 'The specific problem being addressed',
    ),
    Field(
      'constraints',
      String,
      'Constraints',
      hint: 'Constraints that influenced the decision',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? contextDetails;

  /// Decision outcome and rationale.
  @SectionId('ADRO')
  @StandardReferences(
    [
      'ADR (Architecture Decision Records) — decision capture',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The decision made, its rationale, alternatives considered, and decision makers.',
  )
  @Form([
    Field(
      'decision',
      String,
      'Decision',
      required: true,
      hint: 'What was decided',
    ),
    Field(
      'rationale',
      String,
      'Rationale',
      required: true,
      hint: 'Why this decision was made',
    ),
    Field(
      'alternativesConsidered',
      String,
      'Alternatives Considered',
      hint: 'Other options that were evaluated',
    ),
    Field(
      'decisionMakers',
      String,
      'Decision Makers',
      hint: 'Who made this decision',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? outcome;

  /// Consequences and review.
  @SectionId('ARDERECO')
  @StandardReferences(
    [
      'ADR (Architecture Decision Records) — decision capture',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The positive and negative consequences of an architecture decision and its review date.',
  )
  @Form([
    Field(
      'consequences',
      String,
      'Consequences',
      hint: 'Impact of this decision',
    ),
    Field(
      'positiveConsequences',
      String,
      'Positive Consequences',
      hint: 'Benefits of this decision',
    ),
    Field(
      'negativeConsequences',
      String,
      'Negative Consequences',
      hint: 'Drawbacks of this decision',
    ),
    Field(
      'reviewDate',
      String,
      'Review Date',
      hint: 'When this decision should be reviewed',
    ),
    Field('notes', String, 'Notes', hint: 'Additional decision notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? consequences;

  /// Related decision links.
  @SectionId('ADRR')
  @StandardReferences(
    [
      'ADR (Architecture Decision Records) — decision capture',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'The links between an architecture decision and related, superseded, or superseding decisions.',
  )
  @Form([
    Field(
      'relatedDecisions',
      String,
      'Related Decisions',
      hint: 'Other ADRs related to this one',
    ),
    Field(
      'supersedes',
      String,
      'Supersedes',
      hint: 'Previous decisions this supersedes',
    ),
    Field(
      'supersededBy',
      String,
      'Superseded By',
      hint: 'Decision that supersedes this one',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? relations;
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
class DesignPatternsAndStandards extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of design patterns and standards approach.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Required design patterns catalog.
  @StandardReferences([
    'GoF design patterns — reusable OO design',
    'POSA — patterns of software architecture',
    'Domain-Driven Design — tactical patterns (entities/aggregates/repositories)',
  ], 'The design patterns the implementation is expected to apply.')
  @SectionId('DSPT-DESI-LST')
  @SectionIdPattern('DSPT-DESI-xxx')
  @ContentHelp('Add one entry per design pattern.')
  @SerializationOrder(2)
  List<DesignPatternEntry> designPatterns = [];

  /// Coding standards and style guidelines.
  @StandardReferences([
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ], 'The coding standards and style guidelines the code must comply with.')
  @SectionId('COSTEN-CODI-LST')
  @SectionIdPattern('COSTEN-CODI-xxx')
  @ContentHelp('Add one entry per coding standard.')
  @SerializationOrder(3)
  List<CodingStandardEntry> codingStandards = [];

  /// Development conventions and best practices.
  @StandardReferences([
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ], 'The development practices and workflow conventions the team must follow.')
  @SectionId('DECOEN-DEVE-LST')
  @SectionIdPattern('DECOEN-DEVE-xxx')
  @ContentHelp('Add one entry per development convention.')
  @SerializationOrder(4)
  List<DevelopmentConventionEntry> developmentConventions = [];

  /// Industry standards compliance requirements.
  @StandardReferences([
    'industry standards compliance (ISO/IEC / W3C / IETF)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ], 'The industry standards the system is required to comply with.')
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
@StandardReferences([
  'GoF design patterns — reusable OO design',
  'POSA — patterns of software architecture',
  'Domain-Driven Design — tactical patterns (entities/aggregates/repositories)',
], 'A single design pattern the implementation is expected to apply.')
@SectionId('DSPT')
class DesignPatternEntry extends DocSpecsSection {
  @Form([
    Field(
      'patternName',
      String,
      'Pattern Name',
      required: true,
      hint: 'E.g., Repository, Factory, Observer, State, Command',
    ),
    Field(
      'patternCategory',
      String,
      'Category',
      required: true,
      hint: 'Creational, Structural, Behavioral, Architectural, UI',
    ),
    Field(
      'patternSource',
      String,
      'Source',
      hint: 'GoF, Enterprise Patterns, DDD, UI Patterns',
    ),
    Field(
      'purpose',
      String,
      'Purpose',
      required: true,
      hint: 'What problem this pattern solves',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Applicability guidance.
  @SectionId('DPEA')
  @StandardReferences([
    'GoF design patterns — reusable OO design',
    'POSA — patterns of software architecture',
  ], 'Describes when a design pattern applies and when it should be avoided.')
  @Form([
    Field(
      'applicability',
      String,
      'When to Use',
      hint: 'Situations where this pattern applies',
    ),
    Field(
      'notApplicable',
      String,
      'When NOT to Use',
      hint: 'Situations where this pattern should be avoided',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? applicability;

  /// Structural composition.
  @SectionId('DEPAENST')
  @StandardReferences(
    [
      'GoF design patterns — reusable OO design',
      'POSA — patterns of software architecture',
    ],
    'Describes the participants, collaborations, and variations of a design pattern.',
  )
  @Form([
    Field(
      'participants',
      String,
      'Participants',
      hint: 'Key classes/objects involved in this pattern',
    ),
    Field(
      'collaborations',
      String,
      'Collaborations',
      hint: 'How participants interact',
    ),
    Field(
      'variations',
      String,
      'Variations',
      hint: 'Supported variations of this pattern',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? structure;

  /// Implementation guidance.
  @SectionId('DPEI')
  @StandardReferences([
    'GoF design patterns — reusable OO design',
    'Domain-Driven Design — tactical patterns (entities/aggregates/repositories)',
  ], 'Describes how a design pattern is implemented within the project.')
  @Form([
    Field(
      'implementationGuidelines',
      String,
      'Implementation Guidelines',
      hint: 'How to implement this pattern in the project',
    ),
    Field(
      'codeTemplate',
      String,
      'Code Template/Example',
      hint: 'Reference to template or example code',
    ),
    Field(
      'frameworkSupport',
      String,
      'Framework Support',
      hint: 'How the framework supports this pattern',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? implementation;

  /// Architectural context.
  @SectionId('DEPAENCO')
  @StandardReferences(
    [
      'POSA — patterns of software architecture',
      'GoF design patterns — reusable OO design',
    ],
    'Describes where a design pattern applies in the architecture and related patterns.',
  )
  @Form([
    Field(
      'usageScope',
      String,
      'Usage Scope',
      hint: 'Where in the architecture this pattern applies',
    ),
    Field(
      'relatedPatterns',
      String,
      'Related Patterns',
      hint: 'Other patterns commonly used with this one',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? context;

  /// Enforcement and notes.
  @SectionId('DPEE')
  @StandardReferences([
    'GoF design patterns — reusable OO design',
    'ISO/IEC 25010 — maintainability quality attributes',
  ], 'Describes how design-pattern compliance is enforced and verified.')
  @Form([
    Field(
      'enforcementLevel',
      String,
      'Enforcement Level',
      hint: 'Mandatory, Recommended, Optional',
    ),
    Field(
      'verificationMethod',
      String,
      'Verification Method',
      hint: 'How compliance is verified',
    ),
    Field('notes', String, 'Notes', hint: 'Additional pattern notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? enforcement;
}

/// Coding standard entry — a coding style or convention requirement.
@StandardReferences([
  'coding standards (e.g. Effective Dart / language style guide)',
  'SOLID principles — object-oriented design',
], 'A single coding style or convention requirement the code must satisfy.')
@SectionId('CSE')
class CodingStandardEntry extends DocSpecsSection {
  @Form([
    Field(
      'standardName',
      String,
      'Standard Name',
      required: true,
      hint: 'E.g., Effective Dart, Clean Code, Project-specific',
    ),
    Field(
      'standardCategory',
      String,
      'Category',
      required: true,
      hint: 'Naming, Formatting, Comments, Structure, Imports',
    ),
    Field(
      'applicableLanguage',
      String,
      'Applicable Language',
      hint: 'Which programming language(s) this applies to',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Rule description.
  @SectionId('CSERD')
  @StandardReferences([
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ], 'States a coding rule together with its rationale and examples.')
  @Form([
    Field(
      'rule',
      String,
      'Rule',
      required: true,
      hint: 'Clear statement of the coding rule',
    ),
    Field('rationale', String, 'Rationale', hint: 'Why this rule matters'),
    Field('examples', String, 'Examples', hint: 'Good and bad code examples'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? ruleDetails;

  /// Naming requirements.
  @SectionId('CSEN')
  @StandardReferences([
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ], 'Defines the naming conventions and prefix/suffix rules for identifiers.')
  @Form([
    Field(
      'namingConvention',
      String,
      'Naming Convention',
      hint: 'camelCase, PascalCase, snake_case rules',
    ),
    Field(
      'prefixSuffix',
      String,
      'Prefix/Suffix Rules',
      hint: 'Required prefixes or suffixes',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? naming;

  /// Formatting requirements.
  @SectionId('CSEF')
  @StandardReferences(
    [
      'coding standards (e.g. Effective Dart / language style guide)',
      'SOLID principles — object-oriented design',
    ],
    'Defines indentation, line-length, and bracing formatting rules for the code.',
  )
  @Form([
    Field(
      'indentation',
      String,
      'Indentation',
      hint: 'Spaces vs tabs, indentation size',
    ),
    Field('lineLength', String, 'Line Length', hint: 'Maximum line length'),
    Field(
      'bracingStyle',
      String,
      'Bracing Style',
      hint: 'Where braces should appear',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? formatting;

  /// Enforcement details.
  @SectionId('CSEE')
  @StandardReferences(
    [
      'coding standards (e.g. Effective Dart / language style guide)',
      'SOLID principles — object-oriented design',
    ],
    'Describes how a coding standard is enforced via linters, severity, and CI checks.',
  )
  @Form([
    Field(
      'linterRule',
      String,
      'Linter Rule',
      hint: 'Corresponding linter rule name',
    ),
    Field('severity', String, 'Severity', hint: 'Error, Warning, Info'),
    Field(
      'enforcementMethod',
      String,
      'Enforcement Method',
      hint: 'Linter, Code review, CI check',
    ),
    Field(
      'autoFixable',
      bool,
      'Auto-Fixable',
      hint: 'Can be automatically fixed',
    ),
    Field('notes', String, 'Notes', hint: 'Additional standard notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? enforcement;
}

/// Development convention entry — a development practice or workflow convention.
@StandardReferences([
  'coding standards (e.g. Effective Dart / language style guide)',
  'SOLID principles — object-oriented design',
], 'A single development practice or workflow convention the team must follow.')
@SectionId('DCE')
class DevelopmentConventionEntry extends DocSpecsSection {
  @Form([
    Field(
      'conventionName',
      String,
      'Convention Name',
      required: true,
      hint: 'Name of the development convention',
    ),
    Field(
      'conventionCategory',
      String,
      'Category',
      required: true,
      hint:
          'Version Control, Code Review, Branching, Commit, CI/CD, Deployment',
    ),
    Field(
      'description',
      String,
      'Description',
      required: true,
      hint: 'What the convention requires',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Background and workflow.
  @SectionId('DCEO')
  @StandardReferences(
    [
      'coding standards (e.g. Effective Dart / language style guide)',
      'SOLID principles — object-oriented design',
    ],
    'Explains the rationale and step-by-step workflow behind a development convention.',
  )
  @Form([
    Field(
      'rationale',
      String,
      'Rationale',
      hint: 'Why this convention is important',
    ),
    Field(
      'workflow',
      String,
      'Workflow',
      hint: 'Step-by-step workflow if applicable',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? overview;

  /// Version control requirements.
  @SectionId('DCEVC')
  @StandardReferences(
    [
      'coding standards (e.g. Effective Dart / language style guide)',
      'SOLID principles — object-oriented design',
    ],
    'Defines branching, commit, and pull-request requirements for version control.',
  )
  @Form([
    Field(
      'branchingStrategy',
      String,
      'Branching Strategy',
      hint: 'GitFlow, trunk-based, feature branches',
    ),
    Field(
      'branchNaming',
      String,
      'Branch Naming',
      hint: 'Branch naming convention',
    ),
    Field(
      'commitFormat',
      String,
      'Commit Message Format',
      hint: 'Conventional commits, custom format',
    ),
    Field('prProcess', String, 'PR Process', hint: 'Pull request requirements'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? versionControl;

  /// Code review expectations.
  @SectionId('DCER')
  @StandardReferences([
    'coding standards (e.g. Effective Dart / language style guide)',
    'SOLID principles — object-oriented design',
  ], 'Defines the code-review requirements and checklist the team applies.')
  @Form([
    Field(
      'reviewRequirements',
      String,
      'Review Requirements',
      hint: 'Minimum reviewers, approval rules',
    ),
    Field(
      'reviewChecklist',
      String,
      'Review Checklist',
      hint: 'Items to check during review',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? review;

  /// Automation integration.
  @SectionId('DCEA')
  @StandardReferences(
    [
      'coding standards (e.g. Effective Dart / language style guide)',
      'SOLID principles — object-oriented design',
    ],
    'Describes how a development convention integrates with CI/CD automation and triggers.',
  )
  @Form([
    Field(
      'automationIntegration',
      String,
      'Automation Integration',
      hint: 'How this integrates with CI/CD',
    ),
    Field(
      'triggers',
      String,
      'Triggers',
      hint: 'What triggers this convention',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? automation;

  /// Enforcement and exceptions.
  @SectionId('DCEE')
  @StandardReferences(
    [
      'coding standards (e.g. Effective Dart / language style guide)',
      'SOLID principles — object-oriented design',
    ],
    'Describes how a development convention is enforced and which exceptions are allowed.',
  )
  @Form([
    Field(
      'enforcementLevel',
      String,
      'Enforcement Level',
      hint: 'Mandatory, Recommended, Advisory',
    ),
    Field(
      'enforcementMethod',
      String,
      'Enforcement Method',
      hint: 'Git hooks, CI checks, manual',
    ),
    Field(
      'exceptions',
      String,
      'Exceptions',
      hint: 'Allowed exceptions to this convention',
    ),
    Field('notes', String, 'Notes', hint: 'Additional convention notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? enforcement;
}

/// Industry standard entry — compliance with industry standards.
@StandardReferences([
  'industry standards compliance (ISO/IEC / W3C / IETF)',
  'ISO/IEC 25010 — maintainability quality attributes',
], 'A single industry standard the system is required to comply with.')
@SectionId('ISE')
class IndustryStandardEntry extends DocSpecsSection {
  @Form([
    Field(
      'standardName',
      String,
      'Standard Name',
      required: true,
      hint: 'E.g., ISO 27001, OWASP, IEEE 830, GDPR',
    ),
    Field(
      'standardBody',
      String,
      'Standard Body',
      hint: 'ISO, IEEE, OWASP, NIST, ECMA',
    ),
    Field('version', String, 'Version', hint: 'Version of the standard'),
    Field(
      'publicationDate',
      String,
      'Publication Date',
      hint: 'Standard publication date',
    ),
    Field(
      'category',
      String,
      'Category',
      required: true,
      hint: 'Security, Quality, Process, Documentation, Accessibility',
    ),
    Field(
      'complianceLevel',
      String,
      'Compliance Level',
      required: true,
      hint: 'Full, Partial, Certified, In Progress',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Scope details.
  @SectionId('ISES')
  @StandardReferences([
    'industry standards compliance (ISO/IEC / W3C / IETF)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ], 'Defines which parts of the system an industry standard applies to.')
  @Form([
    Field(
      'applicableAreas',
      String,
      'Applicable Areas',
      hint: 'Which parts of the system this applies to',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? scope;

  /// Requirement applicability.
  @SectionId('ISEC')
  @StandardReferences(
    [
      'industry standards compliance (ISO/IEC / W3C / IETF)',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Identifies which requirements of an industry standard apply and which are excluded.',
  )
  @Form([
    Field(
      'applicableRequirements',
      String,
      'Applicable Requirements',
      hint: 'Specific sections or requirements that apply',
    ),
    Field(
      'excludedRequirements',
      String,
      'Excluded Requirements',
      hint: 'Requirements that do not apply',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? compliance;

  /// Certification details.
  @SectionId('INSTENCE')
  @StandardReferences(
    [
      'industry standards compliance (ISO/IEC / W3C / IETF)',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Describes whether formal certification is required for an industry standard and its scope.',
  )
  @Form([
    Field(
      'certificationRequired',
      bool,
      'Certification Required',
      hint: 'Is formal certification required?',
    ),
    Field(
      'certificationBody',
      String,
      'Certification Body',
      hint: 'Who provides certification',
    ),
    Field(
      'certificationScope',
      String,
      'Certification Scope',
      hint: 'Scope of certification',
    ),
    Field(
      'certificationTarget',
      String,
      'Certification Target Date',
      hint: 'Target date for certification',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? certification;

  /// Verification settings.
  @SectionId('ISEV')
  @StandardReferences(
    [
      'industry standards compliance (ISO/IEC / W3C / IETF)',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Defines how compliance with an industry standard is audited and evidenced.',
  )
  @Form([
    Field(
      'auditFrequency',
      String,
      'Audit Frequency',
      hint: 'How often compliance is audited',
    ),
    Field(
      'verificationMethod',
      String,
      'Verification Method',
      hint: 'How compliance is verified',
    ),
    Field(
      'evidenceRequired',
      String,
      'Evidence Required',
      hint: 'Documentation required for compliance',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? verification;

  /// Reference metadata.
  @SectionId('ISER')
  @StandardReferences([
    'industry standards compliance (ISO/IEC / W3C / IETF)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ], 'Holds reference links and notes for an industry standard.')
  @Form([
    Field(
      'referenceUrl',
      String,
      'Reference URL',
      hint: 'Link to standard documentation',
    ),
    Field('notes', String, 'Notes', hint: 'Additional compliance notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? reference;
}

/// Code quality metrics and thresholds.
@StandardReferences([
  'ISO/IEC 25010 — maintainability quality attributes',
  'coding standards (e.g. Effective Dart / language style guide)',
], 'Defines the code-quality metrics and thresholds the codebase must meet.')
@SectionId('COQUME')
class CodeQualityMetrics extends DocSpecsSection {
  @Form([
    Field(
      'testCoverageMinimum',
      String,
      'Test Coverage Minimum',
      hint: 'Minimum test coverage percentage',
    ),
    Field(
      'branchCoverageMinimum',
      String,
      'Branch Coverage Minimum',
      hint: 'Minimum branch coverage percentage',
    ),
    Field(
      'mutationScoreMinimum',
      String,
      'Mutation Score Minimum',
      hint: 'Minimum mutation testing score',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Complexity limits.
  @SectionId('CQMC')
  @StandardReferences([
    'ISO/IEC 25010 — maintainability quality attributes',
    'coding standards (e.g. Effective Dart / language style guide)',
  ], 'Defines maximum complexity and length limits per method and class.')
  @Form([
    Field(
      'cyclomaticComplexityMax',
      String,
      'Cyclomatic Complexity Max',
      hint: 'Maximum cyclomatic complexity per method',
    ),
    Field(
      'cognitiveComplexityMax',
      String,
      'Cognitive Complexity Max',
      hint: 'Maximum cognitive complexity per method',
    ),
    Field(
      'methodLengthMax',
      String,
      'Method Length Max',
      hint: 'Maximum lines of code per method',
    ),
    Field(
      'classLengthMax',
      String,
      'Class Length Max',
      hint: 'Maximum lines of code per class',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? complexity;

  /// Coupling metrics.
  @SectionId('COQUMECO')
  @StandardReferences([
    'ISO/IEC 25010 — maintainability quality attributes',
    'SOLID principles — object-oriented design',
  ], 'Defines acceptable afferent/efferent coupling and instability ranges.')
  @Form([
    Field(
      'afferentCouplingMax',
      String,
      'Afferent Coupling Max',
      hint: 'Maximum incoming dependencies',
    ),
    Field(
      'efferentCouplingMax',
      String,
      'Efferent Coupling Max',
      hint: 'Maximum outgoing dependencies',
    ),
    Field(
      'instabilityRange',
      String,
      'Instability Range',
      hint: 'Acceptable instability range',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? coupling;

  /// Duplication thresholds.
  @SectionId('CQMD')
  @StandardReferences(
    [
      'ISO/IEC 25010 — maintainability quality attributes',
      'coding standards (e.g. Effective Dart / language style guide)',
    ],
    'Defines the maximum acceptable code duplication and detection block size.',
  )
  @Form([
    Field(
      'duplicationMax',
      String,
      'Code Duplication Max',
      hint: 'Maximum code duplication percentage',
    ),
    Field(
      'duplicationBlockSize',
      String,
      'Duplication Block Size',
      hint: 'Minimum lines to consider duplication',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? duplication;

  /// Static analysis thresholds.
  @SectionId('CQMSA')
  @StandardReferences(
    [
      'ISO/IEC 25010 — maintainability quality attributes',
      'coding standards (e.g. Effective Dart / language style guide)',
    ],
    'Defines allowed static-analysis warnings, critical issues, and technical-debt targets.',
  )
  @Form([
    Field(
      'warningsAllowed',
      String,
      'Warnings Allowed',
      hint: 'Maximum allowed static analysis warnings',
    ),
    Field(
      'criticalIssuesAllowed',
      String,
      'Critical Issues Allowed',
      hint: 'Maximum critical issues allowed (usually 0)',
    ),
    Field(
      'technicalDebtTarget',
      String,
      'Technical Debt Target',
      hint: 'Target technical debt ratio',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? staticAnalysis;

  /// Tooling and reporting.
  @SectionId('CQMT')
  @StandardReferences(
    [
      'ISO/IEC 25010 — maintainability quality attributes',
      'coding standards (e.g. Effective Dart / language style guide)',
    ],
    'Defines the tools, frequency, and trend monitoring used to measure code quality.',
  )
  @Form([
    Field(
      'analysisTools',
      String,
      'Analysis Tools',
      hint: 'Tools used for quality measurement',
    ),
    Field(
      'reportingFrequency',
      String,
      'Reporting Frequency',
      hint: 'How often metrics are reported',
    ),
    Field(
      'trendMonitoring',
      String,
      'Trend Monitoring',
      hint: 'How quality trends are monitored',
    ),
    Field('notes', String, 'Notes', hint: 'Additional quality metrics notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? tooling;
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
class DocumentationStandards extends DocSpecsSection {
  @Form([
    Field(
      'publicApiDocRequired',
      bool,
      'Public API Doc Required',
      hint: 'All public APIs must be documented',
    ),
    Field(
      'docCommentFormat',
      String,
      'Doc Comment Format',
      hint: 'Dartdoc, JSDoc, Javadoc format',
    ),
    Field(
      'parameterDocRequired',
      bool,
      'Parameter Doc Required',
      hint: 'Parameters must be documented',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Code documentation requirements.
  @SectionId('DSCD')
  @StandardReferences([
    'coding standards (e.g. Effective Dart / language style guide)',
    'ISO/IEC 25010 — maintainability quality attributes',
  ], 'Defines requirements for documenting return values and examples in code.')
  @Form([
    Field(
      'returnDocRequired',
      bool,
      'Return Doc Required',
      hint: 'Return values must be documented',
    ),
    Field(
      'exampleRequired',
      bool,
      'Example Required',
      hint: 'Examples required for complex APIs',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? codeDocs;

  /// Content requirements.
  @SectionId('DOSTCO')
  @StandardReferences(
    [
      'coding standards (e.g. Effective Dart / language style guide)',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Defines minimum content, cross-referencing, and deprecation-notice requirements for docs.',
  )
  @Form([
    Field(
      'minimumDescription',
      String,
      'Minimum Description',
      hint: 'Minimum description length/content',
    ),
    Field(
      'crossReferenceRequired',
      bool,
      'Cross-Reference Required',
      hint: 'Related items must be cross-referenced',
    ),
    Field(
      'deprecationNotice',
      String,
      'Deprecation Notice',
      hint: 'How to document deprecations',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? contentRequirements;

  /// Architecture documentation requirements.
  @SectionId('DOSTAR')
  @StandardReferences([
    'ISO/IEC/IEEE 42010 — architecture description',
    'coding standards (e.g. Effective Dart / language style guide)',
  ], 'Defines the required architecture documentation, diagrams, and READMEs.')
  @Form([
    Field(
      'architectureDocRequired',
      bool,
      'Architecture Doc Required',
      hint: 'Architecture documentation required',
    ),
    Field(
      'diagramsRequired',
      String,
      'Diagrams Required',
      hint: 'Required diagram types',
    ),
    Field(
      'readmeRequired',
      bool,
      'README Required',
      hint: 'README required for each package/module',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? architecture;

  /// Changelog and versioning requirements.
  @SectionId('DOSTVE')
  @StandardReferences(
    [
      'coding standards (e.g. Effective Dart / language style guide)',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Defines the changelog and versioning-scheme requirements for the project.',
  )
  @Form([
    Field(
      'changelogRequired',
      bool,
      'Changelog Required',
      hint: 'Changelog must be maintained',
    ),
    Field(
      'changelogFormat',
      String,
      'Changelog Format',
      hint: 'Keep a Changelog, custom format',
    ),
    Field(
      'versioningScheme',
      String,
      'Versioning Scheme',
      hint: 'Semantic versioning, CalVer',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? versioning;

  /// Review and publication settings.
  @SectionId('DOSTPR')
  @StandardReferences(
    [
      'coding standards (e.g. Effective Dart / language style guide)',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Defines documentation review, generation tooling, and publishing requirements.',
  )
  @Form([
    Field(
      'docReviewRequired',
      bool,
      'Doc Review Required',
      hint: 'Documentation changes require review',
    ),
    Field(
      'technicalWriterReview',
      bool,
      'Technical Writer Review',
      hint: 'Professional tech writer review',
    ),
    Field(
      'docGenerationTool',
      String,
      'Doc Generation Tool',
      hint: 'Tool for generating documentation',
    ),
    Field(
      'publishingLocation',
      String,
      'Publishing Location',
      hint: 'Where documentation is published',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional documentation standards notes',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? process;
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
class ErrorHandlingStandards extends DocSpecsSection {
  @Form([
    Field(
      'errorPhilosophy',
      String,
      'Error Handling Philosophy',
      hint: 'Exceptions, Result types, Either, Error codes',
    ),
    Field(
      'failFastApproach',
      String,
      'Fail-Fast Approach',
      hint: 'When and how to fail fast',
    ),
    Field(
      'gracefulDegradation',
      String,
      'Graceful Degradation',
      hint: 'How to degrade gracefully',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Exception type conventions.
  @SectionId('EHSE')
  @StandardReferences(
    [
      'coding standards (e.g. Effective Dart / language style guide)',
      'SOLID principles — object-oriented design',
    ],
    'Defines the exception hierarchy, custom-exception policy, and naming conventions.',
  )
  @Form([
    Field(
      'exceptionHierarchy',
      String,
      'Exception Hierarchy',
      hint: 'Base exception class structure',
    ),
    Field(
      'customExceptions',
      String,
      'Custom Exceptions',
      hint: 'When to create custom exceptions',
    ),
    Field(
      'exceptionNaming',
      String,
      'Exception Naming',
      hint: 'Naming convention for exceptions',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? exceptions;

  /// Handling pattern defaults.
  @SectionId('EHSP')
  @StandardReferences(
    [
      'GoF design patterns — reusable OO design',
      'POSA — patterns of software architecture',
    ],
    'Defines default handling patterns such as catch-all policy, retry, and circuit breaker.',
  )
  @Form([
    Field(
      'catchAllPolicy',
      String,
      'Catch-All Policy',
      hint: 'Policy on catch-all handlers',
    ),
    Field(
      'retryPolicy',
      String,
      'Retry Policy',
      hint: 'When and how to retry operations',
    ),
    Field(
      'circuitBreakerPolicy',
      String,
      'Circuit Breaker Policy',
      hint: 'Circuit breaker implementation',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? patterns;

  /// Reporting standards.
  @SectionId('EHSR')
  @StandardReferences(
    [
      'coding standards (e.g. Effective Dart / language style guide)',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Defines how errors are logged, tracked, and how sensitive data is handled in reports.',
  )
  @Form([
    Field(
      'errorLogging',
      String,
      'Error Logging',
      hint: 'How errors are logged',
    ),
    Field(
      'errorTracking',
      String,
      'Error Tracking',
      hint: 'Error tracking service/approach',
    ),
    Field(
      'sensitiveDataHandling',
      String,
      'Sensitive Data Handling',
      hint: 'How to handle sensitive data in errors',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? reporting;

  /// User-facing communication rules.
  @SectionId('EHSUC')
  @StandardReferences(
    [
      'coding standards (e.g. Effective Dart / language style guide)',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Defines standards for user-facing error messages, error codes, and localization.',
  )
  @Form([
    Field(
      'userErrorMessages',
      String,
      'User Error Messages',
      hint: 'User-facing error message standards',
    ),
    Field(
      'errorCodes',
      String,
      'Error Codes',
      hint: 'Error code format and catalog',
    ),
    Field(
      'localization',
      String,
      'Localization',
      hint: 'Error message localization',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? userCommunication;

  /// Recovery guidance.
  @SectionId('ERHASTRE')
  @StandardReferences(
    [
      'POSA — patterns of software architecture',
      'GoF design patterns — reusable OO design',
    ],
    'Defines standard recovery strategies and compensating actions for partial failures.',
  )
  @Form([
    Field(
      'recoveryStrategies',
      String,
      'Recovery Strategies',
      hint: 'Standard recovery strategies',
    ),
    Field(
      'compensatingActions',
      String,
      'Compensating Actions',
      hint: 'How to handle partial failures',
    ),
    Field('notes', String, 'Notes', hint: 'Additional error handling notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? recovery;
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
class TestingStandards extends DocSpecsSection {
  @Form([
    Field(
      'unitTestRequired',
      bool,
      'Unit Test Required',
      hint: 'Unit tests required for all code',
    ),
    Field(
      'integrationTestRequired',
      bool,
      'Integration Test Required',
      hint: 'Integration tests required',
    ),
    Field(
      'e2eTestRequired',
      bool,
      'E2E Test Required',
      hint: 'End-to-end tests required',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Additional test types and organization.
  @SectionId('TESTOR')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — software testing',
      'xUnit / test patterns — automated testing',
    ],
    'Defines additional test types, naming conventions, and test-file organization.',
  )
  @Form([
    Field(
      'performanceTestRequired',
      bool,
      'Performance Test Required',
      hint: 'Performance tests required',
    ),
    Field(
      'testNamingConvention',
      String,
      'Test Naming Convention',
      hint: 'How tests should be named',
    ),
    Field(
      'testFileOrganization',
      String,
      'Test File Organization',
      hint: 'How test files are organized',
    ),
    Field(
      'testDataManagement',
      String,
      'Test Data Management',
      hint: 'How test data is managed',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? organization;

  /// Preferred testing patterns.
  @SectionId('TESTPA')
  @StandardReferences(
    [
      'xUnit / test patterns — automated testing',
      'ISO/IEC/IEEE 29119 — software testing',
    ],
    'Defines preferred testing patterns such as Arrange-Act-Assert, Given-When-Then, and mocking strategy.',
  )
  @Form([
    Field(
      'arrangActAssert',
      bool,
      'Arrange-Act-Assert',
      hint: 'Use AAA pattern',
    ),
    Field(
      'givenWhenThen',
      bool,
      'Given-When-Then',
      hint: 'Use GWT pattern for BDD',
    ),
    Field(
      'mockingStrategy',
      String,
      'Mocking Strategy',
      hint: 'When and how to use mocks',
    ),
    Field(
      'stubStrategy',
      String,
      'Stub Strategy',
      hint: 'When to use stubs vs mocks',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? patterns;

  /// Quality requirements for tests.
  @SectionId('TESTQU')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — software testing',
      'xUnit / test patterns — automated testing',
    ],
    'Defines test-quality requirements such as isolation, determinism, and flaky-test policy.',
  )
  @Form([
    Field(
      'testIsolation',
      String,
      'Test Isolation',
      hint: 'Test isolation requirements',
    ),
    Field(
      'deterministicTests',
      bool,
      'Deterministic Tests Required',
      hint: 'Tests must be deterministic',
    ),
    Field(
      'flakyTestPolicy',
      String,
      'Flaky Test Policy',
      hint: 'How to handle flaky tests',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? quality;

  /// Testing tools and CI integration.
  @SectionId('TESTTO')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29119 — software testing',
      'xUnit / test patterns — automated testing',
    ],
    'Defines the testing frameworks, coverage tools, and CI test-execution approach.',
  )
  @Form([
    Field(
      'testFramework',
      String,
      'Test Framework',
      hint: 'Testing framework to use',
    ),
    Field(
      'mockingFramework',
      String,
      'Mocking Framework',
      hint: 'Mocking framework to use',
    ),
    Field(
      'coverageTools',
      String,
      'Coverage Tools',
      hint: 'Code coverage tools',
    ),
    Field(
      'ciTestExecution',
      String,
      'CI Test Execution',
      hint: 'How tests run in CI',
    ),
    Field(
      'parallelExecution',
      String,
      'Parallel Execution',
      hint: 'Test parallelization approach',
    ),
    Field(
      'testReporting',
      String,
      'Test Reporting',
      hint: 'Test report format and location',
    ),
    Field('notes', String, 'Notes', hint: 'Additional testing standards notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? tooling;
}

/// 8.2. Software Design Requirements.
@DetailedIn(D06ArchitectureTechnologySpecification)
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
class SoftwareDesignRequirements extends DocSpecsSection {
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
  @override
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
class LayeringAndModuleStructure extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of the layering and modularization approach.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Software layer definitions.
  @StandardReferences([
    'Clean Architecture — dependency rule / layering',
  ], 'The software layers that make up the application.')
  @SectionId('SOLAEN-SOFT-LST')
  @SectionIdPattern('SOLAEN-SOFT-xxx')
  @ContentHelp('Add one entry per software layer.')
  @SerializationOrder(2)
  List<SoftwareLayerEntry> softwareLayers = [];

  /// Layer communication rules and constraints.
  @SerializationOrder(3)
  LayerCommunicationRules layerCommunicationRules = LayerCommunicationRules();

  /// Bounded contexts (DDD) definitions.
  @StandardReferences([
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ], 'The DDD bounded contexts that partition the application domain.')
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
  @StandardReferences([
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ], 'The shared libraries and common code reused across the application.')
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
  @StandardReferences([
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ], 'The feature modules that make up the application as vertical slices.')
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
class SoftwareLayerEntry extends DocSpecsSection {
  @Form([
    Field(
      'layerName',
      String,
      'Layer Name',
      required: true,
      hint:
          'E.g., Presentation, Application, Domain, Infrastructure, Data Access',
    ),
    Field(
      'layerLevel',
      String,
      'Level',
      hint: 'Numeric level (0 = bottom, higher = top)',
    ),
    Field(
      'layerPattern',
      String,
      'Pattern',
      hint: 'E.g., Clean Architecture, Onion, Hexagonal, N-Tier',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Responsibilities and constraints.
  @SectionId('SLER')
  @StandardReferences(
    [
      'Clean Architecture — dependency rule / layering',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Defines the purpose, key responsibilities, and prohibitions of a software layer.',
  )
  @Form([
    Field(
      'purpose',
      String,
      'Purpose',
      required: true,
      hint: 'Primary responsibility of this layer',
    ),
    Field(
      'responsibilities',
      String,
      'Key Responsibilities',
      hint: 'Specific functions this layer handles',
    ),
    Field(
      'prohibitions',
      String,
      'Prohibitions',
      hint: 'What this layer must NOT do',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? responsibilities;

  /// Typical components and organization.
  @SectionId('SLEC')
  @StandardReferences(
    [
      'Clean Architecture — dependency rule / layering',
      'C4 model — software architecture diagrams',
    ],
    'Describes the typical components, naming conventions, and folder structure of a software layer.',
  )
  @Form([
    Field(
      'typicalComponents',
      String,
      'Typical Components',
      hint: 'Types of classes/components in this layer',
    ),
    Field(
      'namingConventions',
      String,
      'Naming Conventions',
      hint: 'Naming patterns for components in this layer',
    ),
    Field(
      'folderStructure',
      String,
      'Folder Structure',
      hint: 'Directory organization for this layer',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? components;

  /// Dependency rules.
  @SectionId('SLED')
  @StandardReferences(
    [
      'Clean Architecture — dependency rule / layering',
      'C4 model — software architecture diagrams',
    ],
    'Defines the allowed, forbidden, and external dependencies of a software layer.',
  )
  @Form([
    Field(
      'allowedDependencies',
      String,
      'Allowed Dependencies',
      hint: 'Layers this layer may depend on',
    ),
    Field(
      'forbiddenDependencies',
      String,
      'Forbidden Dependencies',
      hint: 'Layers this layer must NOT depend on',
    ),
    Field(
      'externalDependencies',
      String,
      'External Dependencies',
      hint: 'External packages allowed in this layer',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? dependencies;

  /// Technology and testing notes.
  @SectionId('SLET')
  @StandardReferences(
    [
      'Clean Architecture — dependency rule / layering',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the frameworks, implementation notes, and testing approach for a software layer.',
  )
  @Form([
    Field(
      'frameworksUsed',
      String,
      'Frameworks Used',
      hint: 'Frameworks applicable to this layer',
    ),
    Field(
      'implementationNotes',
      String,
      'Implementation Notes',
      hint: 'Specific implementation guidelines',
    ),
    Field(
      'testingApproach',
      String,
      'Testing Approach',
      hint: 'How components in this layer are tested',
    ),
    Field('notes', String, 'Notes', hint: 'Additional layer notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? technology;
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
class LayerCommunicationRules extends DocSpecsSection {
  @Form([
    Field(
      'communicationDirection',
      String,
      'Communication Direction',
      hint: 'Top-down only, bottom-up callbacks, etc.',
    ),
    Field(
      'dependencyRule',
      String,
      'Dependency Rule',
      hint: 'Dependencies always point inward/downward',
    ),
    Field(
      'abstractionPrinciple',
      String,
      'Abstraction Principle',
      hint: 'Dependency inversion, interface segregation',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Interface requirements between layers.
  @SectionId('LCRI')
  @StandardReferences(
    [
      'Clean Architecture — dependency rule / layering',
      'SOLID principles — object-oriented design',
    ],
    'Defines the interface, DTO, and mapping requirements at boundaries between layers.',
  )
  @Form([
    Field(
      'interfaceRequirements',
      String,
      'Interface Requirements',
      hint: 'Whether interfaces required at boundaries',
    ),
    Field(
      'dtoUsage',
      String,
      'DTO Usage',
      hint: 'Data Transfer Object patterns between layers',
    ),
    Field(
      'mappingStrategy',
      String,
      'Mapping Strategy',
      hint: 'How data is mapped between layers',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? interfaces;

  /// Cross-layer event and exception flow.
  @SectionId('LCRF')
  @StandardReferences(
    [
      'Clean Architecture — dependency rule / layering',
      'C4 model — software architecture diagrams',
    ],
    'Describes how events, exceptions, and logging context propagate across layers.',
  )
  @Form([
    Field(
      'eventPropagation',
      String,
      'Event Propagation',
      hint: 'How events flow across layers',
    ),
    Field(
      'exceptionHandling',
      String,
      'Exception Handling',
      hint: 'How exceptions propagate across layers',
    ),
    Field(
      'loggingPropagation',
      String,
      'Logging Propagation',
      hint: 'How logging context flows',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? flow;

  /// Boundary enforcement and validation rules.
  @SectionId('LCRG')
  @StandardReferences(
    [
      'Clean Architecture — dependency rule / layering',
      'C4 model — software architecture diagrams',
    ],
    'Defines how layer boundaries and validation responsibilities are enforced and violations detected.',
  )
  @Form([
    Field(
      'validationResponsibility',
      String,
      'Validation Responsibility',
      hint: 'Which layer validates what',
    ),
    Field(
      'boundaryEnforcement',
      String,
      'Boundary Enforcement',
      hint: 'How layer boundaries are enforced',
    ),
    Field(
      'violationDetection',
      String,
      'Violation Detection',
      hint: 'How boundary violations are detected',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional layer communication notes',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;
}

/// Bounded context entry — a DDD bounded context.
@StandardReferences([
  'Domain-Driven Design — bounded contexts / modules',
  'SOLID principles — object-oriented design',
], 'Describes a single DDD bounded context, its domain area, and owning team.')
@SectionId('BCE')
class BoundedContextEntry extends DocSpecsSection {
  @Form([
    Field(
      'contextName',
      String,
      'Context Name',
      required: true,
      hint: 'E.g., Order, Inventory, Customer, Billing',
    ),
    Field(
      'domainArea',
      String,
      'Domain Area',
      required: true,
      hint: 'Business domain this context covers',
    ),
    Field(
      'owningTeam',
      String,
      'Owning Team',
      hint: 'Team responsible for this context',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Scope and language definitions.
  @SectionId('BCES')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'SOLID principles — object-oriented design',
    ],
    'Defines the scope, included/excluded concepts, and ubiquitous language of a bounded context.',
  )
  @Form([
    Field('purpose', String, 'Purpose', hint: 'Why this context exists'),
    Field(
      'includedConcepts',
      String,
      'Included Concepts',
      hint: 'Domain concepts within this context',
    ),
    Field(
      'excludedConcepts',
      String,
      'Excluded Concepts',
      hint: 'Domain concepts explicitly outside this context',
    ),
    Field(
      'ubiquitousLanguage',
      String,
      'Ubiquitous Language',
      hint: 'Key terms and their definitions',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? scope;

  /// Boundary relationships.
  @SectionId('BCEB')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'SOLID principles — object-oriented design',
    ],
    'Describes the boundary type and upstream/downstream relationships of a bounded context.',
  )
  @Form([
    Field(
      'boundaryType',
      String,
      'Boundary Type',
      hint: 'Conformist, Anti-corruption layer, Open-host, etc.',
    ),
    Field(
      'upstreamContexts',
      String,
      'Upstream Contexts',
      hint: 'Contexts this one depends on',
    ),
    Field(
      'downstreamContexts',
      String,
      'Downstream Contexts',
      hint: 'Contexts that depend on this one',
    ),
    Field(
      'sharedKernel',
      String,
      'Shared Kernel',
      hint: 'Shared code with other contexts',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? boundaries;

  /// Implementation footprint.
  @SectionId('BCEI')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'SOLID principles — object-oriented design',
    ],
    'Records the code location, schema, and published/consumed events that implement a bounded context.',
  )
  @Form([
    Field(
      'repositoryNamespace',
      String,
      'Repository/Namespace',
      hint: 'Code location for this context',
    ),
    Field(
      'databaseSchema',
      String,
      'Database Schema',
      hint: 'Database schema or partition',
    ),
    Field(
      'publishedEvents',
      String,
      'Published Events',
      hint: 'Domain events this context publishes',
    ),
    Field(
      'consumedEvents',
      String,
      'Consumed Events',
      hint: 'Domain events this context subscribes to',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? implementation;

  /// Integration and notes.
  @SectionId('BOCOENIN')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'SOLID principles — object-oriented design',
    ],
    'Describes the API endpoints and integration patterns through which a bounded context connects to others.',
  )
  @Form([
    Field(
      'apiEndpoints',
      String,
      'API Endpoints',
      hint: 'Public API endpoints exposed',
    ),
    Field(
      'integrationPatterns',
      String,
      'Integration Patterns',
      hint: 'How this context integrates with others',
    ),
    Field('notes', String, 'Notes', hint: 'Additional context notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? integration;
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
class PackageOrganization extends DocSpecsSection {
  @Form([
    Field(
      'namingConvention',
      String,
      'Naming Convention',
      hint: 'Package/module naming pattern',
    ),
    Field(
      'prefixStrategy',
      String,
      'Prefix Strategy',
      hint: 'Prefix for all packages (e.g., org name)',
    ),
    Field(
      'suffixConventions',
      String,
      'Suffix Conventions',
      hint: 'Standard suffixes (_core, _ui, _api, etc.)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Repository and directory structure.
  @SectionId('PAORST')
  @StandardReferences([
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ], 'Describes the repository and directory layout used to organize packages.')
  @Form([
    Field(
      'monorepoVsPolyrepo',
      String,
      'Monorepo vs Polyrepo',
      hint: 'Single vs multiple repositories',
    ),
    Field(
      'directoryLayout',
      String,
      'Directory Layout',
      hint: 'Top-level directory organization',
    ),
    Field(
      'featureGrouping',
      String,
      'Feature Grouping',
      hint: 'How features are grouped in structure',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? structure;

  /// Package categorization.
  @SectionId('PAORTY')
  @StandardReferences([
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — maintainability / modularity quality attributes',
  ], 'Categorizes packages into core, feature, shared, and platform types.')
  @Form([
    Field(
      'corePackages',
      String,
      'Core Packages',
      hint: 'Foundation packages required by all',
    ),
    Field(
      'featurePackages',
      String,
      'Feature Packages',
      hint: 'Business feature packages',
    ),
    Field(
      'sharedPackages',
      String,
      'Shared Packages',
      hint: 'Shared utility packages',
    ),
    Field(
      'platformPackages',
      String,
      'Platform Packages',
      hint: 'Platform-specific packages',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? types;

  /// Dependency management rules.
  @SectionId('PAORDE')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'SOLID principles — object-oriented design',
    ],
    'Defines how internal and external package dependencies are managed and versioned.',
  )
  @Form([
    Field(
      'dependencyManagement',
      String,
      'Dependency Management',
      hint: 'How package dependencies are managed',
    ),
    Field(
      'internalDependencyRules',
      String,
      'Internal Dependency Rules',
      hint: 'Rules for internal package dependencies',
    ),
    Field(
      'externalDependencyPolicy',
      String,
      'External Dependency Policy',
      hint: 'Policy for external dependencies',
    ),
    Field(
      'versioningStrategy',
      String,
      'Versioning Strategy',
      hint: 'Semantic versioning or other scheme',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? dependencies;

  /// Documentation expectations.
  @SectionId('PAORDO')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability / modularity quality attributes',
    ],
    'Defines the documentation and dependency-diagram expectations for each package.',
  )
  @Form([
    Field(
      'packageDocumentation',
      String,
      'Package Documentation',
      hint: 'Required documentation per package',
    ),
    Field(
      'dependencyDiagram',
      String,
      'Dependency Diagram',
      hint: 'Package dependency visualization',
    ),
    Field('notes', String, 'Notes', hint: 'Additional organization notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? documentation;
}

/// Module entry — a discrete module or component.
@StandardReferences([
  'Domain-Driven Design — bounded contexts / modules',
  'SOLID principles — object-oriented design',
], 'Describes a single discrete module or component in the module catalog.')
@SectionId('MODENT')
class ModuleEntry extends DocSpecsSection {
  @Form([
    Field(
      'moduleName',
      String,
      'Module Name',
      required: true,
      hint: 'Unique module identifier',
    ),
    Field(
      'moduleType',
      String,
      'Module Type',
      hint: 'Core, Feature, Shared, Platform, Plugin',
    ),
    Field('version', String, 'Version', hint: 'Current module version'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Purpose and API.
  @SectionId('MOENDE')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'SOLID principles — object-oriented design',
    ],
    'Describes the purpose, functionality, public API, and entry points of a module.',
  )
  @Form([
    Field(
      'purpose',
      String,
      'Purpose',
      required: true,
      hint: 'What this module provides',
    ),
    Field(
      'functionality',
      String,
      'Functionality',
      hint: 'Specific features/functions',
    ),
    Field(
      'publicApi',
      String,
      'Public API',
      hint: 'Key public interfaces/classes',
    ),
    Field(
      'entryPoints',
      String,
      'Entry Points',
      hint: 'Main entry points to the module',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? description;

  /// Dependency information.
  @SectionId('MOEND1')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'SOLID principles — object-oriented design',
    ],
    'Records the required, optional, external, and peer dependencies of a module.',
  )
  @Form([
    Field(
      'requiredModules',
      String,
      'Required Modules',
      hint: 'Internal modules this depends on',
    ),
    Field(
      'optionalModules',
      String,
      'Optional Modules',
      hint: 'Optional internal dependencies',
    ),
    Field(
      'externalDependencies',
      String,
      'External Dependencies',
      hint: 'Third-party dependencies',
    ),
    Field(
      'peerDependencies',
      String,
      'Peer Dependencies',
      hint: 'Required peer modules',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? dependencies;

  /// Ownership information.
  @SectionId('MOENOW')
  @StandardReferences([
    'Domain-Driven Design — bounded contexts / modules',
    'SOLID principles — object-oriented design',
  ], 'Records which context, team, and maintainer own a module.')
  @Form([
    Field(
      'owningContext',
      String,
      'Owning Context',
      hint: 'Bounded context this belongs to',
    ),
    Field(
      'owningTeam',
      String,
      'Owning Team',
      hint: 'Team responsible for this module',
    ),
    Field('maintainer', String, 'Maintainer', hint: 'Primary maintainer'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? ownership;

  /// Configuration settings.
  @SectionId('MOENCO')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'SOLID principles — object-oriented design',
    ],
    'Describes the configuration options, feature flags, and environment variables of a module.',
  )
  @Form([
    Field(
      'configurationOptions',
      String,
      'Configuration Options',
      hint: 'Available configuration settings',
    ),
    Field(
      'featureFlags',
      String,
      'Feature Flags',
      hint: 'Feature flags controlling behavior',
    ),
    Field(
      'environmentVariables',
      String,
      'Environment Variables',
      hint: 'Required environment variables',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? configuration;

  /// Testing and notes.
  @SectionId('MOENTE')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'SOLID principles — object-oriented design',
    ],
    'Captures the test-coverage and integration-testing expectations for a module.',
  )
  @Form([
    Field(
      'testCoverage',
      String,
      'Test Coverage',
      hint: 'Required test coverage level',
    ),
    Field(
      'integrationTests',
      String,
      'Integration Tests',
      hint: 'Integration test requirements',
    ),
    Field('notes', String, 'Notes', hint: 'Additional module notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? testing;
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
class SharedLibraryEntry extends DocSpecsSection {
  @Form([
    Field(
      'libraryName',
      String,
      'Library Name',
      required: true,
      hint: 'Library identifier',
    ),
    Field(
      'libraryType',
      String,
      'Library Type',
      hint: 'Utility, Domain, Infrastructure, UI',
    ),
    Field('version', String, 'Version', hint: 'Current version'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Description and usage.
  @SectionId('SHLIENDE')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability / modularity quality attributes',
    ],
    'Captures the purpose, target consumers, and usage guidelines of a shared library.',
  )
  @Form([
    Field(
      'purpose',
      String,
      'Purpose',
      required: true,
      hint: 'What the library provides',
    ),
    Field(
      'targetConsumers',
      String,
      'Target Consumers',
      hint: 'Modules/contexts that should use this',
    ),
    Field(
      'usageGuidelines',
      String,
      'Usage Guidelines',
      hint: 'How to properly use this library',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? description;

  /// API details.
  @SectionId('SLEA')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability / modularity quality attributes',
    ],
    'Describes the public classes, functions, and extension points exposed by a shared library.',
  )
  @Form([
    Field(
      'publicClasses',
      String,
      'Public Classes',
      hint: 'Key public classes/interfaces',
    ),
    Field(
      'publicFunctions',
      String,
      'Public Functions',
      hint: 'Key public functions',
    ),
    Field(
      'extensionPoints',
      String,
      'Extension Points',
      hint: 'How consumers can extend',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? api;

  /// Constraints and lifecycle.
  @SectionId('SLEL')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability / modularity quality attributes',
    ],
    'Captures the compatibility, performance, thread-safety, and deprecation lifecycle of a shared library.',
  )
  @Form([
    Field(
      'compatibilityRequirements',
      String,
      'Compatibility Requirements',
      hint: 'Platform/version requirements',
    ),
    Field(
      'performanceCharacteristics',
      String,
      'Performance Characteristics',
      hint: 'Expected performance profile',
    ),
    Field(
      'threadSafety',
      String,
      'Thread Safety',
      hint: 'Thread safety guarantees',
    ),
    Field(
      'deprecationPolicy',
      String,
      'Deprecation Policy',
      hint: 'How APIs are deprecated',
    ),
    Field(
      'changelogLocation',
      String,
      'Changelog Location',
      hint: 'Where changes are documented',
    ),
    Field('notes', String, 'Notes', hint: 'Additional library notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? lifecycle;
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
class DependencyInjectionStructure extends DocSpecsSection {
  @Form([
    Field(
      'diFramework',
      String,
      'DI Framework',
      hint: 'GetIt, Riverpod, Provider, Injectable, etc.',
    ),
    Field(
      'registrationPattern',
      String,
      'Registration Pattern',
      hint: 'How dependencies are registered',
    ),
    Field(
      'scopeManagement',
      String,
      'Scope Management',
      hint: 'Singleton, factory, scoped, lazy',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Registration organization.
  @SectionId('DISR')
  @StandardReferences(
    [
      'SOLID principles — object-oriented design',
      'Clean Architecture — dependency rule / layering',
    ],
    'Describes how modules register their dependencies, in what order, and which are lazily initialized.',
  )
  @Form([
    Field(
      'moduleRegistration',
      String,
      'Module Registration',
      hint: 'How modules register their dependencies',
    ),
    Field(
      'registrationOrder',
      String,
      'Registration Order',
      hint: 'Order of dependency registration',
    ),
    Field(
      'lazyInitialization',
      String,
      'Lazy Initialization',
      hint: 'Which dependencies are lazy',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? registration;

  /// Interface binding rules.
  @SectionId('DISB')
  @StandardReferences(
    [
      'SOLID principles — object-oriented design',
      'Clean Architecture — dependency rule / layering',
    ],
    'Defines when interfaces are bound to implementations and how they are swapped for testing.',
  )
  @Form([
    Field(
      'interfaceBindingRule',
      String,
      'Interface Binding Rule',
      hint: 'When to use interface bindings',
    ),
    Field(
      'mockingStrategy',
      String,
      'Mocking Strategy',
      hint: 'How to swap implementations for testing',
    ),
    Field(
      'overrideCapability',
      String,
      'Override Capability',
      hint: 'How to override registrations',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? binding;

  /// Environment-specific configuration.
  @SectionId('DISC')
  @StandardReferences(
    [
      'SOLID principles — object-oriented design',
      'Clean Architecture — dependency rule / layering',
    ],
    'Describes how dependency-injection registrations vary by environment, feature flag, and platform.',
  )
  @Form([
    Field(
      'environmentConfiguration',
      String,
      'Environment Configuration',
      hint: 'Different configs per environment',
    ),
    Field(
      'featureFlagIntegration',
      String,
      'Feature Flag Integration',
      hint: 'How feature flags affect DI',
    ),
    Field(
      'conditionalRegistration',
      String,
      'Conditional Registration',
      hint: 'Platform/config conditional registration',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? configuration;

  /// Troubleshooting support.
  @SectionId('DIST')
  @StandardReferences(
    [
      'SOLID principles — object-oriented design',
      'Clean Architecture — dependency rule / layering',
    ],
    'Describes how dependency-injection problems such as circular dependencies are debugged and prevented.',
  )
  @Form([
    Field('debugSupport', String, 'Debug Support', hint: 'Debugging DI issues'),
    Field(
      'circularDependencyHandling',
      String,
      'Circular Dependency Handling',
      hint: 'How circular deps are prevented/detected',
    ),
    Field('notes', String, 'Notes', hint: 'Additional DI notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? troubleshooting;
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
class CrossCuttingConcerns extends DocSpecsSection {
  @Form([
    Field(
      'loggingStrategy',
      String,
      'Logging Strategy',
      hint: 'Centralized logging approach',
    ),
    Field(
      'logLevels',
      String,
      'Log Levels',
      hint: 'Available log levels and usage',
    ),
    Field('logFormat', String, 'Log Format', hint: 'Log message format'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Error handling concerns.
  @SectionId('CCCE')
  @StandardReferences(
    [
      'Clean Architecture — dependency rule / layering',
      'SOLID principles — object-oriented design',
    ],
    'Describes the centralized error-handling, reporting, and user-notification cross-cutting concern.',
  )
  @Form([
    Field(
      'errorHandlingStrategy',
      String,
      'Error Handling Strategy',
      hint: 'Centralized error handling',
    ),
    Field(
      'errorReporting',
      String,
      'Error Reporting',
      hint: 'How errors are reported/collected',
    ),
    Field(
      'userNotification',
      String,
      'User Notification',
      hint: 'How users are notified of errors',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? errors;

  /// Security concerns.
  @SectionId('CCCS')
  @StandardReferences(
    [
      'Clean Architecture — dependency rule / layering',
      'SOLID principles — object-oriented design',
    ],
    'Describes how authentication and authorization flow across layers as a cross-cutting concern.',
  )
  @Form([
    Field(
      'securityConcerns',
      String,
      'Security Concerns',
      hint: 'Cross-cutting security aspects',
    ),
    Field(
      'authenticationIntegration',
      String,
      'Authentication Integration',
      hint: 'How auth flows through layers',
    ),
    Field(
      'authorizationIntegration',
      String,
      'Authorization Integration',
      hint: 'How authz is checked across layers',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? security;

  /// Caching approach.
  @SectionId('CCCC')
  @StandardReferences(
    [
      'Clean Architecture — dependency rule / layering',
      'SOLID principles — object-oriented design',
    ],
    'Describes the caching strategy and invalidation applied across layers as a cross-cutting concern.',
  )
  @Form([
    Field(
      'cachingStrategy',
      String,
      'Caching Strategy',
      hint: 'Cross-cutting caching approach',
    ),
    Field(
      'cacheInvalidation',
      String,
      'Cache Invalidation',
      hint: 'How cache is invalidated',
    ),
    Field(
      'cacheLayers',
      String,
      'Cache Layers',
      hint: 'Where caching is applied',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? caching;

  /// Observability capabilities.
  @SectionId('CCCO')
  @StandardReferences(
    [
      'Clean Architecture — dependency rule / layering',
      'SOLID principles — object-oriented design',
    ],
    'Describes the metrics, tracing, and health-check capabilities applied as a cross-cutting concern.',
  )
  @Form([
    Field(
      'metricsCollection',
      String,
      'Metrics Collection',
      hint: 'Performance and business metrics',
    ),
    Field('tracing', String, 'Tracing', hint: 'Distributed tracing approach'),
    Field(
      'healthChecks',
      String,
      'Health Checks',
      hint: 'Health check implementation',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? observability;

  /// Other shared capabilities.
  @SectionId('CRCUCOSH')
  @StandardReferences(
    [
      'Clean Architecture — dependency rule / layering',
      'SOLID principles — object-oriented design',
    ],
    'Captures additional shared cross-cutting capabilities such as localization and validation.',
  )
  @Form([
    Field(
      'localization',
      String,
      'Localization',
      hint: 'i18n/l10n implementation',
    ),
    Field('validation', String, 'Validation', hint: 'Cross-cutting validation'),
    Field('notes', String, 'Notes', hint: 'Additional cross-cutting notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? shared;
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
class FeatureModuleEntry extends DocSpecsSection {
  @Form([
    Field(
      'featureName',
      String,
      'Feature Name',
      required: true,
      hint: 'Feature identifier',
    ),
    Field(
      'featureArea',
      String,
      'Feature Area',
      hint: 'Business area this feature belongs to',
    ),
    Field(
      'boundedContext',
      String,
      'Bounded Context',
      hint: 'Owning bounded context',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Purpose and value.
  @SectionId('FMED')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability / modularity quality attributes',
    ],
    'Captures the purpose, user stories, and business value delivered by a feature module.',
  )
  @Form([
    Field('purpose', String, 'Purpose', hint: 'What the feature provides'),
    Field(
      'userStories',
      String,
      'User Stories',
      hint: 'Supported user stories/use cases',
    ),
    Field(
      'businessValue',
      String,
      'Business Value',
      hint: 'Business value delivered',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? description;

  /// Structural scope.
  @SectionId('FMES')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'Clean Architecture — dependency rule / layering',
    ],
    'Describes the UI, domain, data, and API components that make up a feature module vertical slice.',
  )
  @Form([
    Field(
      'uiComponents',
      String,
      'UI Components',
      hint: 'Screens, widgets, views in this feature',
    ),
    Field(
      'domainLogic',
      String,
      'Domain Logic',
      hint: 'Business logic in this feature',
    ),
    Field('dataAccess', String, 'Data Access', hint: 'Data access components'),
    Field(
      'apiEndpoints',
      String,
      'API Endpoints',
      hint: 'API endpoints related to this feature',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? structure;

  /// Dependencies.
  @SectionId('FEMOENDE')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'SOLID principles — object-oriented design',
    ],
    'Records the shared, feature, and external dependencies a feature module relies on.',
  )
  @Form([
    Field(
      'sharedDependencies',
      String,
      'Shared Dependencies',
      hint: 'Shared modules this feature uses',
    ),
    Field(
      'featureDependencies',
      String,
      'Feature Dependencies',
      hint: 'Other features this depends on',
    ),
    Field(
      'externalIntegrations',
      String,
      'External Integrations',
      hint: 'External systems integrated',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? dependencies;

  /// Feature configuration.
  @SectionId('FMEC')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability / modularity quality attributes',
    ],
    'Defines the flags, options, and enablement criteria that configure a feature module.',
  )
  @Form([
    Field(
      'featureFlags',
      String,
      'Feature Flags',
      hint: 'Flags controlling this feature',
    ),
    Field(
      'configurationOptions',
      String,
      'Configuration Options',
      hint: 'Feature-specific configuration',
    ),
    Field(
      'enablementCriteria',
      String,
      'Enablement Criteria',
      hint: 'When this feature is available',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? configuration;

  /// Navigation and notes.
  @SectionId('FMEN')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability / modularity quality attributes',
    ],
    'Captures the navigation routes and deep-linking behaviour exposed by a feature module.',
  )
  @Form([
    Field(
      'routeDefinitions',
      String,
      'Route Definitions',
      hint: 'Navigation routes for this feature',
    ),
    Field(
      'deepLinkSupport',
      String,
      'Deep Link Support',
      hint: 'Deep linking patterns',
    ),
    Field('notes', String, 'Notes', hint: 'Additional feature notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? navigation;
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
class ModuleVersioningStrategy extends DocSpecsSection {
  @Form([
    Field(
      'versioningScheme',
      String,
      'Versioning Scheme',
      hint: 'SemVer, CalVer, custom',
    ),
    Field(
      'majorVersionPolicy',
      String,
      'Major Version Policy',
      hint: 'When to bump major version',
    ),
    Field(
      'minorVersionPolicy',
      String,
      'Minor Version Policy',
      hint: 'When to bump minor version',
    ),
    Field(
      'patchVersionPolicy',
      String,
      'Patch Version Policy',
      hint: 'When to bump patch version',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Compatibility policy.
  @SectionId('MVSC')
  @StandardReferences(
    [
      'ISO/IEC 25010 — maintainability / modularity quality attributes',
      'Domain-Driven Design — bounded contexts / modules',
    ],
    'Defines the backwards-compatibility guarantees and breaking-change handling for modules.',
  )
  @Form([
    Field(
      'backwardsCompatibility',
      String,
      'Backwards Compatibility',
      hint: 'Compatibility guarantees',
    ),
    Field(
      'breakingChangePolicy',
      String,
      'Breaking Change Policy',
      hint: 'How breaking changes are handled',
    ),
    Field(
      'deprecationTimeline',
      String,
      'Deprecation Timeline',
      hint: 'Timeline for deprecated APIs',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? compatibility;

  /// Release management process.
  @SectionId('MVSRM')
  @StandardReferences([
    'ISO/IEC 12207 — software lifecycle processes',
    'Domain-Driven Design — bounded contexts / modules',
  ], 'Describes how module versions are released, labelled, and documented.')
  @Form([
    Field(
      'releaseProcess',
      String,
      'Release Process',
      hint: 'How versions are released',
    ),
    Field(
      'preReleaseLabels',
      String,
      'Pre-Release Labels',
      hint: 'alpha, beta, rc conventions',
    ),
    Field(
      'releaseNotes',
      String,
      'Release Notes',
      hint: 'Release notes requirements',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? releaseManagement;

  /// Dependency versioning rules.
  @SectionId('MVSD')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability / modularity quality attributes',
    ],
    'Defines how module dependency versions are specified, locked, and updated.',
  )
  @Form([
    Field(
      'dependencyVersioning',
      String,
      'Dependency Versioning',
      hint: 'How dependency versions are specified',
    ),
    Field(
      'lockfilePolicy',
      String,
      'Lockfile Policy',
      hint: 'Lockfile usage and update policy',
    ),
    Field(
      'updateStrategy',
      String,
      'Update Strategy',
      hint: 'How dependencies are updated',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? dependencies;

  /// Cross-module coordination.
  @SectionId('MOVESTCO')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability / modularity quality attributes',
    ],
    'Captures how module versions are coordinated and constrained across the module set.',
  )
  @Form([
    Field(
      'crossModuleCoordination',
      String,
      'Cross-Module Coordination',
      hint: 'Coordinating versions across modules',
    ),
    Field(
      'versionConstraints',
      String,
      'Version Constraints',
      hint: 'Constraints between module versions',
    ),
    Field('notes', String, 'Notes', hint: 'Additional versioning notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? coordination;
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
class DevelopmentEnvironment extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of development environment requirements.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// IDE and editor requirements.
  @StandardReferences([
    'Twelve-Factor App — cloud-native methodology',
  ], 'The IDEs and editors required for the development environment.')
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
class IdeRequirementEntry extends DocSpecsSection {
  @Form([
    // Identity
    Field(
      'ideName',
      String,
      'IDE/Editor Name',
      required: true,
      hint: 'E.g., VS Code, IntelliJ IDEA, Android Studio',
    ),
    Field(
      'version',
      String,
      'Version Requirements',
      hint: 'Minimum version or version range',
    ),
    Field('platform', String, 'Platform', hint: 'Windows, macOS, Linux, Web'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Extension and workspace configuration.
  @SectionId('IREC')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures IDE extension and workspace configuration including required extensions and settings templates.',
  )
  @Form([
    Field(
      'requiredExtensions',
      String,
      'Required Extensions',
      hint: 'Extensions/plugins that must be installed',
    ),
    Field(
      'recommendedExtensions',
      String,
      'Recommended Extensions',
      hint: 'Optional but helpful extensions',
    ),
    Field(
      'settingsTemplate',
      String,
      'Settings Template',
      hint: 'Reference to shared settings file',
    ),
    Field(
      'workspaceConfiguration',
      String,
      'Workspace Configuration',
      hint: 'Required workspace setup',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? configuration;

  /// Debugger, linting, and formatting integration.
  @SectionId('IREI')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures IDE integration for debuggers, linters, format-on-save, and Git tooling.',
  )
  @Form([
    Field(
      'debuggerSupport',
      String,
      'Debugger Support',
      hint: 'Required debugger integration',
    ),
    Field(
      'linterIntegration',
      String,
      'Linter Integration',
      hint: 'How linter integrates with IDE',
    ),
    Field(
      'formatOnSave',
      bool,
      'Format on Save',
      hint: 'Require format on save',
    ),
    Field(
      'gitIntegration',
      String,
      'Git Integration',
      hint: 'Required Git tooling',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? integration;

  /// Shared team standardization settings.
  @SectionId('IRES')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'Captures shared team IDE standardization settings including config location and sync mechanism.',
  )
  @Form([
    Field(
      'sharedConfigLocation',
      String,
      'Shared Config Location',
      hint: 'Where team configs are stored',
    ),
    Field(
      'syncMechanism',
      String,
      'Sync Mechanism',
      hint: 'How settings are synced across team',
    ),
    Field('notes', String, 'Notes', hint: 'Additional IDE notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? standardization;
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
class BuildToolsConfiguration extends DocSpecsSection {
  @Form([
    Field(
      'packageManager',
      String,
      'Package Manager',
      hint: 'Pub, npm, yarn, pnpm, Gradle',
    ),
    Field(
      'packageManagerVersion',
      String,
      'Package Manager Version',
      hint: 'Required version',
    ),
    Field(
      'lockfileManagement',
      String,
      'Lockfile Management',
      hint: 'Lockfile policies',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Build system settings.
  @SectionId('BTCBS')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'Captures build system settings including the build system, version, and build configuration files.',
  )
  @Form([
    Field(
      'buildSystem',
      String,
      'Build System',
      hint: 'Flutter build, Gradle, Make, Melos',
    ),
    Field(
      'buildSystemVersion',
      String,
      'Build System Version',
      hint: 'Required version',
    ),
    Field(
      'buildConfiguration',
      String,
      'Build Configuration',
      hint: 'Build configuration files',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? buildSystemSettings;

  /// Compilation settings.
  @SectionId('BTCC')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'Captures compilation settings including compiler/SDK version, compilation mode, and optimization level.',
  )
  @Form([
    Field(
      'compilerVersion',
      String,
      'Compiler/SDK Version',
      hint: 'Dart SDK, JDK version',
    ),
    Field(
      'compilationMode',
      String,
      'Compilation Mode',
      hint: 'JIT, AOT, mixed',
    ),
    Field(
      'optimizationLevel',
      String,
      'Optimization Level',
      hint: 'Debug, profile, release settings',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? compilation;

  /// Script integration.
  @SectionId('BTCS')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'Captures build script integration including build scripts, pre-commit hooks, and post-build actions.',
  )
  @Form([
    Field(
      'buildScripts',
      String,
      'Build Scripts',
      hint: 'Custom build scripts location',
    ),
    Field(
      'preCommitHooks',
      String,
      'Pre-Commit Hooks',
      hint: 'Pre-commit hook configuration',
    ),
    Field(
      'postBuildActions',
      String,
      'Post-Build Actions',
      hint: 'Actions after successful build',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? scripts;

  /// Artifact management.
  @SectionId('BTCA')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'Semantic Versioning (SemVer) — build / release versioning',
    ],
    'Captures build artifact management including artifact location, naming, and cache policies.',
  )
  @Form([
    Field(
      'artifactLocation',
      String,
      'Artifact Location',
      hint: 'Where build artifacts are stored',
    ),
    Field(
      'artifactNaming',
      String,
      'Artifact Naming',
      hint: 'Artifact naming convention',
    ),
    Field(
      'cacheManagement',
      String,
      'Cache Management',
      hint: 'Build cache policies',
    ),
    Field('notes', String, 'Notes', hint: 'Additional build tool notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? artifacts;
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
class VersionControlConfiguration extends DocSpecsSection {
  @Form([
    Field('vcsSystem', String, 'VCS System', hint: 'Git, Mercurial, SVN'),
    Field(
      'vcsVersion',
      String,
      'VCS Version',
      hint: 'Minimum version required',
    ),
    Field(
      'hostingPlatform',
      String,
      'Hosting Platform',
      hint: 'GitHub, GitLab, Bitbucket, Azure DevOps',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Repository structure settings.
  @SectionId('VCCR')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'Captures repository structure settings such as monorepo/polyrepo layout, submodule policy, and LFS usage.',
  )
  @Form([
    Field(
      'repositoryStructure',
      String,
      'Repository Structure',
      hint: 'Monorepo, polyrepo, hybrid',
    ),
    Field(
      'submodulePolicy',
      String,
      'Submodule Policy',
      hint: 'Use of Git submodules',
    ),
    Field('lfsUsage', String, 'LFS Usage', hint: 'Git LFS for large files'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? repository;

  /// Branching policy.
  @SectionId('VCCB')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'Semantic Versioning (SemVer) — build / release versioning',
    ],
    'Captures branching policy including branching strategy, branch naming, and hotfix workflow.',
  )
  @Form([
    Field(
      'branchingStrategy',
      String,
      'Branching Strategy',
      hint: 'GitFlow, trunk-based, GitHub Flow',
    ),
    Field(
      'mainBranchName',
      String,
      'Main Branch Name',
      hint: 'main, master, develop',
    ),
    Field(
      'featureBranchNaming',
      String,
      'Feature Branch Naming',
      hint: 'feature/TICKET-description',
    ),
    Field(
      'releaseBranchNaming',
      String,
      'Release Branch Naming',
      hint: 'release/v1.2.3',
    ),
    Field(
      'hotfixPolicy',
      String,
      'Hotfix Policy',
      hint: 'Hotfix branch workflow',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? branching;

  /// Commit and merge policy.
  @SectionId('VCCC')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'Semantic Versioning (SemVer) — build / release versioning',
    ],
    'Captures commit and merge policy including message format, commit signing, and squash/merge rules.',
  )
  @Form([
    Field(
      'commitMessageFormat',
      String,
      'Commit Message Format',
      hint: 'Conventional Commits, custom format',
    ),
    Field(
      'commitSigningRequired',
      bool,
      'Commit Signing Required',
      hint: 'GPG signing requirement',
    ),
    Field(
      'squashMergePolicy',
      String,
      'Squash/Merge Policy',
      hint: 'When to squash vs merge',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? commits;

  /// Tagging and file attribute settings.
  @SectionId('VCCM')
  @StandardReferences(
    [
      'Semantic Versioning (SemVer) — build / release versioning',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures tagging conventions, tag signing, and file attribute settings for the repository.',
  )
  @Form([
    Field(
      'tagNamingConvention',
      String,
      'Tag Naming Convention',
      hint: 'v1.2.3, yyyy-MM-dd, custom',
    ),
    Field(
      'tagSigningRequired',
      bool,
      'Tag Signing Required',
      hint: 'GPG signing for tags',
    ),
    Field(
      'gitignoreTemplate',
      String,
      'Gitignore Template',
      hint: 'Standard gitignore file',
    ),
    Field(
      'gitattributes',
      String,
      'Git Attributes',
      hint: 'Line endings, merge drivers',
    ),
    Field('notes', String, 'Notes', hint: 'Additional VCS notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? metadata;
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
class CiCdPipelineConfiguration extends DocSpecsSection {
  @Form([
    // Platform
    Field(
      'cicdPlatform',
      String,
      'CI/CD Platform',
      hint: 'GitHub Actions, GitLab CI, Jenkins, CircleCI',
    ),
    Field(
      'configurationLocation',
      String,
      'Configuration Location',
      hint: 'Where pipeline configs live',
    ),
    Field(
      'secretsManagement',
      String,
      'Secrets Management',
      hint: 'How secrets are stored and accessed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Pipeline stages.
  @StandardReferences([
    'CI/CD — continuous integration / delivery pipelines',
  ], 'The stages that make up the delivery pipeline.')
  @SectionId('PISTEN-STAG-LST')
  @SectionIdPattern('PISTEN-STAG-xxx')
  @ContentHelp('Add one entry per pipeline stage.')
  @SerializationOrder(1)
  List<PipelineStageEntry> stages = [];

  /// Build jobs.
  @StandardReferences([
    'CI/CD — continuous integration / delivery pipelines',
  ], 'The build jobs that run within the delivery pipeline.')
  @SectionId('PIJOEN-JOBS-LST')
  @SectionIdPattern('PIJOEN-JOBS-xxx')
  @ContentHelp('Add one entry per pipeline job.')
  @SerializationOrder(2)
  List<PipelineJobEntry> jobs = [];

  /// Deployment environments.
  @StandardReferences([
    'CI/CD — continuous integration / delivery pipelines',
  ], 'The deployment environments targeted by the pipeline.')
  @SectionId('DEENEN-ENVI-LST')
  @SectionIdPattern('DEENEN-ENVI-xxx')
  @ContentHelp('Add one entry per deployment environment.')
  @SerializationOrder(3)
  List<DeploymentEnvironmentEntry> environments = [];
}

/// Pipeline stage entry.
@StandardReferences([
  'CI/CD — continuous integration / delivery pipelines',
  'Twelve-Factor App — cloud-native methodology',
], 'Describes a single pipeline stage including its name, order, and purpose.')
@SectionId('PSE')
class PipelineStageEntry extends DocSpecsSection {
  @Form([
    // Identity
    Field(
      'stageName',
      String,
      'Stage Name',
      required: true,
      hint: 'E.g., Build, Test, Deploy, Release',
    ),
    Field('stageOrder', String, 'Order', hint: 'Execution order'),
    Field('description', String, 'Description', hint: 'What this stage does'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Triggering conditions and approval gates.
  @SectionId('PSET')
  @StandardReferences([
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ], 'Captures pipeline stage triggering conditions and manual approval gates.')
  @Form([
    Field(
      'triggers',
      String,
      'Triggers',
      hint: 'What triggers this stage (push, PR, schedule)',
    ),
    Field(
      'conditions',
      String,
      'Conditions',
      hint: 'Conditions for stage to run',
    ),
    Field(
      'manualApproval',
      bool,
      'Manual Approval',
      hint: 'Requires human approval',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? trigger;

  /// Execution environment and job strategy.
  @SectionId('PSEE')
  @StandardReferences(
    [
      'CI/CD — continuous integration / delivery pipelines',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'Captures pipeline stage execution including runner requirements, timeouts, and parallel job strategy.',
  )
  @Form([
    Field(
      'runnerRequirements',
      String,
      'Runner Requirements',
      hint: 'Required runner type/labels',
    ),
    Field(
      'timeoutMinutes',
      String,
      'Timeout',
      hint: 'Stage timeout in minutes',
    ),
    Field(
      'parallelJobs',
      bool,
      'Parallel Jobs',
      hint: 'Jobs in stage run in parallel',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? execution;

  /// Artifact flow between stages.
  @SectionId('PSEA')
  @StandardReferences(
    [
      'CI/CD — continuous integration / delivery pipelines',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'Captures artifact flow between pipeline stages including input and output artifacts.',
  )
  @Form([
    Field(
      'inputArtifacts',
      String,
      'Input Artifacts',
      hint: 'Required artifacts from previous stages',
    ),
    Field(
      'outputArtifacts',
      String,
      'Output Artifacts',
      hint: 'Artifacts produced by this stage',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? artifacts;

  /// Failure handling and retry behavior.
  @SectionId('PSEF')
  @StandardReferences([
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ], 'Captures pipeline stage failure behavior and retry policy.')
  @Form([
    Field(
      'failureBehavior',
      String,
      'Failure Behavior',
      hint: 'Continue, stop, retry',
    ),
    Field(
      'retryPolicy',
      String,
      'Retry Policy',
      hint: 'Automatic retry configuration',
    ),
    Field('notes', String, 'Notes', hint: 'Additional stage notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? failure;
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
class PipelineJobEntry extends DocSpecsSection {
  @Form([
    Field(
      'jobName',
      String,
      'Job Name',
      required: true,
      hint: 'Job identifier',
    ),
    Field(
      'parentStage',
      String,
      'Parent Stage',
      hint: 'Stage this job belongs to',
    ),
    Field('description', String, 'Description', hint: 'What this job does'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Execution environment.
  @SectionId('PJEE')
  @StandardReferences(
    [
      'CI/CD — continuous integration / delivery pipelines',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'Captures the pipeline job execution environment including runner type, container image, and environment variables.',
  )
  @Form([
    Field(
      'runnerType',
      String,
      'Runner Type',
      hint: 'Self-hosted, cloud, container',
    ),
    Field(
      'containerImage',
      String,
      'Container Image',
      hint: 'Docker image if containerized',
    ),
    Field(
      'environmentVariables',
      String,
      'Environment Variables',
      hint: 'Required environment variables',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? environment;

  /// Job steps.
  @SectionId('PJES')
  @StandardReferences([
    'CI/CD — continuous integration / delivery pipelines',
    'Twelve-Factor App — cloud-native methodology',
  ], 'Captures pipeline job steps including setup, main, and cleanup steps.')
  @Form([
    Field(
      'setupSteps',
      String,
      'Setup Steps',
      hint: 'Checkout, install dependencies',
    ),
    Field('mainSteps', String, 'Main Steps', hint: 'Main job steps'),
    Field('cleanupSteps', String, 'Cleanup Steps', hint: 'Cleanup after job'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? steps;

  /// Job dependencies.
  @SectionId('PJED')
  @StandardReferences(
    [
      'CI/CD — continuous integration / delivery pipelines',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'Captures pipeline job dependencies including upstream jobs, backing services, and caching.',
  )
  @Form([
    Field(
      'dependsOn',
      String,
      'Depends On',
      hint: 'Other jobs this depends on',
    ),
    Field(
      'services',
      String,
      'Services',
      hint: 'Required services (DB, cache)',
    ),
    Field('caching', String, 'Caching', hint: 'Cache configuration'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? dependencies;

  /// Outputs and notes.
  @SectionId('PJEO')
  @StandardReferences(
    [
      'CI/CD — continuous integration / delivery pipelines',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'Captures pipeline job outputs such as test reports, coverage reports, and artifacts.',
  )
  @Form([
    Field('testReports', String, 'Test Reports', hint: 'Test report locations'),
    Field(
      'coverageReports',
      String,
      'Coverage Reports',
      hint: 'Coverage report locations',
    ),
    Field('artifacts', String, 'Artifacts', hint: 'Produced artifacts'),
    Field('notes', String, 'Notes', hint: 'Additional job notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? outputs;
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
class DeploymentEnvironmentEntry extends DocSpecsSection {
  @Form([
    // Identity
    Field(
      'environmentName',
      String,
      'Environment Name',
      required: true,
      hint: 'E.g., dev, staging, production',
    ),
    Field(
      'environmentType',
      String,
      'Type',
      hint: 'Development, Staging, Production',
    ),
    Field('url', String, 'URL', hint: 'Environment URL'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Deployment method and rollback controls.
  @SectionId('DEED')
  @StandardReferences(
    [
      'CI/CD — continuous integration / delivery pipelines',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'Captures the deployment method, deployment configuration, and rollback strategy for an environment.',
  )
  @Form([
    Field(
      'deploymentMethod',
      String,
      'Deployment Method',
      hint: 'Kubernetes, serverless, VM, container',
    ),
    Field(
      'deploymentConfig',
      String,
      'Deployment Config',
      hint: 'Reference to deployment configuration',
    ),
    Field(
      'rollbackStrategy',
      String,
      'Rollback Strategy',
      hint: 'How to rollback failed deployments',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? deployment;

  /// Approval and protection rules.
  @SectionId('DEEP')
  @StandardReferences(
    [
      'CI/CD — continuous integration / delivery pipelines',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'Captures deployment protection rules including required approvers and self-approval prevention.',
  )
  @Form([
    Field(
      'protectionRules',
      String,
      'Protection Rules',
      hint: 'Required reviewers, branch protection',
    ),
    Field(
      'requiredApprovers',
      String,
      'Required Approvers',
      hint: 'Who must approve deployments',
    ),
    Field(
      'preventSelfApproval',
      bool,
      'Prevent Self-Approval',
      hint: 'Cannot approve own deployments',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? protection;

  /// Configuration and secrets sourcing.
  @SectionId('DEEC')
  @StandardReferences([
    'Twelve-Factor App — cloud-native methodology',
    'CI/CD — continuous integration / delivery pipelines',
  ], 'Captures per-environment configuration source and secrets scoping.')
  @Form([
    Field(
      'secretsScope',
      String,
      'Secrets Scope',
      hint: 'Environment-specific secrets',
    ),
    Field(
      'configurationSource',
      String,
      'Configuration Source',
      hint: 'Where config comes from',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? configuration;

  /// Health verification and environment notes.
  @SectionId('DEEM')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'CI/CD — continuous integration / delivery pipelines',
    ],
    'Captures deployment health verification via health check URLs and post-deployment checks.',
  )
  @Form([
    Field(
      'healthCheckUrl',
      String,
      'Health Check URL',
      hint: 'URL for health verification',
    ),
    Field(
      'deploymentVerification',
      String,
      'Deployment Verification',
      hint: 'Post-deployment checks',
    ),
    Field('notes', String, 'Notes', hint: 'Additional environment notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? monitoring;
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
class CodeReviewProcess extends DocSpecsSection {
  @Form([
    Field('prRequired', bool, 'PR Required', hint: 'All changes via PR'),
    Field('prTemplate', String, 'PR Template', hint: 'Pull request template'),
    Field(
      'prNamingConvention',
      String,
      'PR Naming Convention',
      hint: 'PR title format',
    ),
    Field('draftPrSupport', bool, 'Draft PR Support', hint: 'Use draft PRs'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Reviewer requirements.
  @SectionId('CRPR')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'CI/CD — continuous integration / delivery pipelines',
    ],
    'Captures reviewer requirements including minimum reviewers, code owners, and reviewer assignment.',
  )
  @Form([
    Field(
      'minimumReviewers',
      String,
      'Minimum Reviewers',
      hint: 'Required number of approvals',
    ),
    Field('codeOwners', String, 'Code Owners', hint: 'CODEOWNERS file usage'),
    Field(
      'automaticReviewerAssignment',
      String,
      'Auto-Assignment',
      hint: 'How reviewers are assigned',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? requirements;

  /// Review workflow.
  @SectionId('CRPW')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'CI/CD — continuous integration / delivery pipelines',
    ],
    'Captures the review workflow including checklists, inline comments, suggestion format, and discussion resolution.',
  )
  @Form([
    Field(
      'reviewChecklist',
      String,
      'Review Checklist',
      hint: 'Standard review checklist',
    ),
    Field(
      'inlineComments',
      bool,
      'Inline Comments Required',
      hint: 'Must use inline comments',
    ),
    Field(
      'suggestionFormat',
      String,
      'Suggestion Format',
      hint: 'Format for code suggestions',
    ),
    Field(
      'discussionResolution',
      String,
      'Discussion Resolution',
      hint: 'How discussions are resolved',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? workflow;

  /// Automation requirements.
  @SectionId('CRPA')
  @StandardReferences(
    [
      'CI/CD — continuous integration / delivery pipelines',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures review automation such as required automated checks, linting, tests, and coverage thresholds.',
  )
  @Form([
    Field(
      'automatedChecks',
      String,
      'Automated Checks',
      hint: 'Required automated checks',
    ),
    Field(
      'lintingRequired',
      bool,
      'Linting Required',
      hint: 'Linting must pass',
    ),
    Field('testsRequired', bool, 'Tests Required', hint: 'Tests must pass'),
    Field(
      'coverageThreshold',
      String,
      'Coverage Threshold',
      hint: 'Minimum coverage for approval',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? automation;

  /// Merge policy.
  @SectionId('CRPM')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'CI/CD — continuous integration / delivery pipelines',
    ],
    'Captures the merge policy including merge strategy, branch deletion, and required status checks.',
  )
  @Form([
    Field(
      'mergeStrategy',
      String,
      'Merge Strategy',
      hint: 'Squash, merge, rebase',
    ),
    Field(
      'deleteSourceBranch',
      bool,
      'Delete Source Branch',
      hint: 'Auto-delete after merge',
    ),
    Field(
      'requiredStatusChecks',
      String,
      'Required Status Checks',
      hint: 'Checks that must pass before merge',
    ),
    Field('notes', String, 'Notes', hint: 'Additional review process notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? merge;
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
class LocalDevelopmentSetup extends DocSpecsSection {
  @Form([
    Field(
      'systemRequirements',
      String,
      'System Requirements',
      hint: 'OS, RAM, disk space requirements',
    ),
    Field(
      'prerequisiteSoftware',
      String,
      'Prerequisite Software',
      hint: 'Required software before setup',
    ),
    Field('sdkVersions', String, 'SDK Versions', hint: 'Required SDK versions'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Setup workflow.
  @SectionId('LDSW')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'Captures the local setup workflow including clone instructions, setup scripts, and configuration files.',
  )
  @Form([
    Field(
      'cloneInstructions',
      String,
      'Clone Instructions',
      hint: 'How to clone the repository',
    ),
    Field(
      'setupScript',
      String,
      'Setup Script',
      hint: 'Automated setup script location',
    ),
    Field(
      'manualSetupSteps',
      String,
      'Manual Setup Steps',
      hint: 'Manual steps if needed',
    ),
    Field(
      'configurationFiles',
      String,
      'Configuration Files',
      hint: 'Config files to create/modify',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? workflow;

  /// Dependencies and local services.
  @SectionId('LDSD')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures dependency installation and local backing services such as databases and Docker Compose.',
  )
  @Form([
    Field(
      'dependencyInstallation',
      String,
      'Dependency Installation',
      hint: 'How to install dependencies',
    ),
    Field(
      'localServices',
      String,
      'Local Services',
      hint: 'Required local services (DB, Redis)',
    ),
    Field(
      'dockerCompose',
      String,
      'Docker Compose',
      hint: 'Docker Compose for services',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? dependencies;

  /// Running configuration.
  @SectionId('LDSR')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures how the application is run locally including run commands, hot reload, and watch mode.',
  )
  @Form([
    Field(
      'runCommands',
      String,
      'Run Commands',
      hint: 'Commands to run the application',
    ),
    Field(
      'hotReload',
      bool,
      'Hot Reload Available',
      hint: 'Hot reload support',
    ),
    Field(
      'watchMode',
      String,
      'Watch Mode',
      hint: 'File watching configuration',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? running;

  /// Test setup.
  @SectionId('LDST')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures local test setup including running tests locally, test databases, and mock services.',
  )
  @Form([
    Field(
      'runTestsLocally',
      String,
      'Run Tests Locally',
      hint: 'How to run tests locally',
    ),
    Field(
      'testDatabaseSetup',
      String,
      'Test Database Setup',
      hint: 'Test database configuration',
    ),
    Field(
      'mockServices',
      String,
      'Mock Services',
      hint: 'How to use mock services',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? testing;

  /// Troubleshooting details.
  @SectionId('LODESETR')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures local-setup troubleshooting including common issues and support channels.',
  )
  @Form([
    Field(
      'commonIssues',
      String,
      'Common Issues',
      hint: 'Common setup issues and solutions',
    ),
    Field(
      'supportChannel',
      String,
      'Support Channel',
      hint: 'Where to get help',
    ),
    Field('notes', String, 'Notes', hint: 'Additional setup notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? troubleshooting;
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
class DebuggingConfiguration extends DocSpecsSection {
  @Form([
    Field(
      'debuggerTool',
      String,
      'Debugger Tool',
      hint: 'IDE debugger, DevTools, custom',
    ),
    Field(
      'debuggerConfiguration',
      String,
      'Debugger Configuration',
      hint: 'Launch configurations',
    ),
    Field(
      'remoteDebugging',
      String,
      'Remote Debugging',
      hint: 'Remote debugging setup',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Breakpoint and watch setup.
  @SectionId('DECOBR')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures breakpoint types, log points, and standard watch expressions for debugging.',
  )
  @Form([
    Field(
      'breakpointTypes',
      String,
      'Breakpoint Types',
      hint: 'Line, conditional, exception breakpoints',
    ),
    Field('logPoints', String, 'Log Points', hint: 'Non-breaking log points'),
    Field(
      'watchExpressions',
      String,
      'Watch Expressions',
      hint: 'Standard watch expressions',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? breakpoints;

  /// Logging setup for debugging.
  @SectionId('DECOLO')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures debug logging configuration, log levels, and structured logging options.',
  )
  @Form([
    Field(
      'loggingConfiguration',
      String,
      'Logging Configuration',
      hint: 'Debug logging setup',
    ),
    Field('logLevels', String, 'Log Levels', hint: 'Available log levels'),
    Field(
      'structuredLogging',
      bool,
      'Structured Logging',
      hint: 'JSON/structured logs',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? logging;

  /// State and runtime inspection.
  @SectionId('DECOIN')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures state, network, and performance inspection tooling used during debugging.',
  )
  @Form([
    Field(
      'stateInspection',
      String,
      'State Inspection',
      hint: 'How to inspect app state',
    ),
    Field(
      'networkInspection',
      String,
      'Network Inspection',
      hint: 'Network call debugging',
    ),
    Field(
      'performanceInspection',
      String,
      'Performance Inspection',
      hint: 'Performance profiling tools',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? inspection;

  /// Flutter-specific tooling.
  @SectionId('DECOFL')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures Flutter-specific debugging tooling such as the widget inspector, DevTools features, and repaint rainbow.',
  )
  @Form([
    Field(
      'widgetInspector',
      String,
      'Widget Inspector',
      hint: 'Flutter widget inspector',
    ),
    Field(
      'devToolsFeatures',
      String,
      'DevTools Features',
      hint: 'Required DevTools features',
    ),
    Field(
      'repaintRainbow',
      bool,
      'Repaint Rainbow',
      hint: 'Visual repaint debugging',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? flutter;

  /// Error tracking details.
  @SectionId('DECOER')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures development-time error tracking and local crash reporting setup.',
  )
  @Form([
    Field(
      'errorTrackingSetup',
      String,
      'Error Tracking Setup',
      hint: 'Error tracking in development',
    ),
    Field(
      'crashReporting',
      String,
      'Crash Reporting',
      hint: 'Local crash reporting',
    ),
    Field('notes', String, 'Notes', hint: 'Additional debugging notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? errors;
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
class EnvironmentManagement extends DocSpecsSection {
  @Form([
    Field(
      'environmentTypes',
      String,
      'Environment Types',
      hint: 'development, staging, production, etc.',
    ),
    Field(
      'environmentNaming',
      String,
      'Environment Naming',
      hint: 'Naming convention for environments',
    ),
    Field(
      'environmentPurposes',
      String,
      'Environment Purposes',
      hint: 'Purpose of each environment',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Configuration settings.
  @SectionId('ENMACO')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'CI/CD — continuous integration / delivery pipelines',
    ],
    'Captures the configuration method, config file formats, and configuration hierarchy across environments.',
  )
  @Form([
    Field(
      'configurationMethod',
      String,
      'Configuration Method',
      hint: 'Environment variables, files, remote',
    ),
    Field(
      'configFileFormat',
      String,
      'Config File Format',
      hint: '.env, YAML, JSON',
    ),
    Field(
      'configurationHierarchy',
      String,
      'Configuration Hierarchy',
      hint: 'Default → environment → local',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? configuration;

  /// Secrets handling.
  @SectionId('ENMASE')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'CI/CD — continuous integration / delivery pipelines',
    ],
    'Captures local secrets management, secrets templates, and never-commit rules per environment.',
  )
  @Form([
    Field(
      'localSecretsManagement',
      String,
      'Local Secrets Management',
      hint: 'How secrets are managed locally',
    ),
    Field(
      'secretsTemplate',
      String,
      'Secrets Template',
      hint: 'Template for required secrets',
    ),
    Field(
      'secretsNeverCommit',
      String,
      'Never Commit',
      hint: 'Secrets that must never be committed',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? secrets;

  /// Environment switching.
  @SectionId('ENMASW')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'CI/CD — continuous integration / delivery pipelines',
    ],
    'Captures the mechanism for switching environments, build flavor support, and runtime switching.',
  )
  @Form([
    Field(
      'switchingMechanism',
      String,
      'Switching Mechanism',
      hint: 'How to switch environments',
    ),
    Field(
      'flavorSupport',
      String,
      'Flavor/Variant Support',
      hint: 'Build flavors for environments',
    ),
    Field(
      'runtimeSwitching',
      bool,
      'Runtime Switching',
      hint: 'Can switch at runtime',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? switching;

  /// Parity and notes.
  @SectionId('ENMAPA')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'CI/CD — continuous integration / delivery pipelines',
    ],
    'Captures dev-prod parity, data seeding, and mocking strategy across environments.',
  )
  @Form([
    Field(
      'devProdParity',
      String,
      'Dev-Prod Parity',
      hint: 'How similar dev is to prod',
    ),
    Field(
      'dataSeeding',
      String,
      'Data Seeding',
      hint: 'Test data for environments',
    ),
    Field(
      'mockingStrategy',
      String,
      'Mocking Strategy',
      hint: 'Service mocking per environment',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional environment management notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? parity;
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
class DeveloperOnboarding extends DocSpecsSection {
  @Form([
    Field(
      'onboardingGuide',
      String,
      'Onboarding Guide',
      hint: 'Location of onboarding documentation',
    ),
    Field(
      'architectureOverview',
      String,
      'Architecture Overview',
      hint: 'System architecture docs',
    ),
    Field(
      'codingStandardsDocs',
      String,
      'Coding Standards Docs',
      hint: 'Where to find coding standards',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Setup expectations.
  @SectionId('DEONSE')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures onboarding setup expectations including estimated setup time and automated setup availability.',
  )
  @Form([
    Field(
      'estimatedSetupTime',
      String,
      'Estimated Setup Time',
      hint: 'How long initial setup takes',
    ),
    Field(
      'automatedSetup',
      bool,
      'Automated Setup',
      hint: 'Setup is automated',
    ),
    Field(
      'setupVideoGuide',
      String,
      'Setup Video Guide',
      hint: 'Video walkthrough if available',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? setup;

  /// Access provisioning.
  @SectionId('DEONAC')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures onboarding access provisioning such as required access, request processes, and VPN setup.',
  )
  @Form([
    Field(
      'requiredAccess',
      String,
      'Required Access',
      hint: 'Access needed (repos, services, tools)',
    ),
    Field(
      'accessRequestProcess',
      String,
      'Access Request Process',
      hint: 'How to request access',
    ),
    Field('vpnSetup', String, 'VPN Setup', hint: 'VPN configuration if needed'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? access;

  /// Learning support.
  @SectionId('DEONLE')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures onboarding learning support including required reading, code walkthroughs, and pairing buddies.',
  )
  @Form([
    Field(
      'requiredReading',
      String,
      'Required Reading',
      hint: 'Must-read documentation',
    ),
    Field(
      'codeWalkthrough',
      String,
      'Code Walkthrough',
      hint: 'Guided code tour',
    ),
    Field(
      'pairProgrammingBuddy',
      bool,
      'Pair Programming Buddy',
      hint: 'Assigned onboarding buddy',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? learning;

  /// Early task expectations.
  @SectionId('DOFT')
  @StandardReferences(
    [
      'ISO/IEC 12207 — software lifecycle processes',
      'Twelve-Factor App — cloud-native methodology',
    ],
    'Captures early-task expectations for new developers such as starter tasks, shadowing, and first-PR timing.',
  )
  @Form([
    Field('starterTasks', String, 'Starter Tasks', hint: 'Good first issues'),
    Field(
      'shadowingPeriod',
      String,
      'Shadowing Period',
      hint: 'Time spent shadowing',
    ),
    Field(
      'firstPrExpectation',
      String,
      'First PR Expectation',
      hint: 'Expected time to first PR',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? firstTasks;

  /// Completion verification.
  @SectionId('DEONVE')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native methodology',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures onboarding completion verification via checklists and defined completion criteria.',
  )
  @Form([
    Field(
      'onboardingChecklist',
      String,
      'Onboarding Checklist',
      hint: 'Checklist to complete',
    ),
    Field(
      'completionCriteria',
      String,
      'Completion Criteria',
      hint: 'When onboarding is complete',
    ),
    Field('notes', String, 'Notes', hint: 'Additional onboarding notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? verification;
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
class DevelopmentQualityGates extends DocSpecsSection {
  @Form([
    Field(
      'staticAnalysis',
      String,
      'Static Analysis',
      hint: 'Required static analysis tools',
    ),
    Field(
      'linterConfiguration',
      String,
      'Linter Configuration',
      hint: 'Linter rules and configuration',
    ),
    Field(
      'formatterConfiguration',
      String,
      'Formatter Configuration',
      hint: 'Code formatter settings',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Coverage requirements.
  @SectionId('DQGC')
  @StandardReferences(
    [
      'CI/CD — continuous integration / delivery pipelines',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Captures test coverage quality gates including minimum coverage thresholds and coverage exclusions.',
  )
  @Form([
    Field(
      'unitTestCoverageMinimum',
      String,
      'Unit Test Coverage Minimum',
      hint: 'Minimum unit test coverage',
    ),
    Field(
      'integrationTestRequirement',
      String,
      'Integration Test Requirement',
      hint: 'Integration test requirements',
    ),
    Field(
      'coverageExclusions',
      String,
      'Coverage Exclusions',
      hint: 'What is excluded from coverage',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? coverage;

  /// Complexity thresholds.
  @SectionId('DEQUGACO')
  @StandardReferences(
    [
      'ISO/IEC 25010 — maintainability quality attributes',
      'CI/CD — continuous integration / delivery pipelines',
    ],
    'Captures complexity quality gates such as cyclomatic complexity, file size, and function size limits.',
  )
  @Form([
    Field(
      'complexityThresholds',
      String,
      'Complexity Thresholds',
      hint: 'Max cyclomatic complexity',
    ),
    Field(
      'fileSizeLimit',
      String,
      'File Size Limit',
      hint: 'Maximum lines per file',
    ),
    Field(
      'functionSizeLimit',
      String,
      'Function Size Limit',
      hint: 'Maximum lines per function',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? complexity;

  /// Security checks.
  @SectionId('DQGS')
  @StandardReferences(
    [
      'CI/CD — continuous integration / delivery pipelines',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Captures security quality gates including dependency scanning, secrets scanning, and license compliance.',
  )
  @Form([
    Field(
      'dependencyScanning',
      String,
      'Dependency Scanning',
      hint: 'Vulnerability scanning',
    ),
    Field(
      'secretsScanning',
      bool,
      'Secrets Scanning',
      hint: 'Check for leaked secrets',
    ),
    Field(
      'licenseCompliance',
      String,
      'License Compliance',
      hint: 'OSS license checking',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? security;

  /// Documentation requirements.
  @SectionId('DQGD')
  @StandardReferences(
    [
      'ISO/IEC 25010 — maintainability quality attributes',
      'CI/CD — continuous integration / delivery pipelines',
    ],
    'Captures documentation quality gates such as required API docs, changelog, and README updates.',
  )
  @Form([
    Field(
      'apiDocumentation',
      String,
      'API Documentation',
      hint: 'Required API documentation',
    ),
    Field(
      'changelogRequired',
      bool,
      'Changelog Required',
      hint: 'Must update changelog',
    ),
    Field(
      'readmeRequired',
      bool,
      'README Required',
      hint: 'README for new features',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? documentation;

  /// Performance checks.
  @SectionId('DQGP')
  @StandardReferences(
    [
      'CI/CD — continuous integration / delivery pipelines',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Captures performance quality gates such as budgets, bundle size, and startup time limits enforced in the pipeline.',
  )
  @Form([
    Field(
      'performanceBudgets',
      String,
      'Performance Budgets',
      hint: 'Performance constraints',
    ),
    Field(
      'bundleSizeLimit',
      String,
      'Bundle Size Limit',
      hint: 'Maximum bundle size',
    ),
    Field(
      'startupTimeLimit',
      String,
      'Startup Time Limit',
      hint: 'Maximum startup time',
    ),
    Field('notes', String, 'Notes', hint: 'Additional quality gate notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? performance;
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
class ReusableComponentsSection extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of reusability strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Reusability principles and guidelines.
  @SerializationOrder(2)
  ReusabilityPrinciples principles = ReusabilityPrinciples();

  /// Shared component library catalog.
  @StandardReferences([
    'DRY — reusable component design',
    'Semantic Versioning (SemVer) — library versioning',
  ], 'The shared libraries reused across the system.')
  @SectionId('SHLCP-SHAR-LST')
  @SectionIdPattern('SHLCP-SHAR-xxx')
  @ContentHelp('Add one entry per shared library.')
  @SerializationOrder(3)
  List<SharedLibraryComponentEntry> sharedLibraries = [];

  /// UI component library entries.
  @StandardReferences([
    'DRY — reusable component design',
    'SOLID principles — object-oriented design',
  ], 'The reusable UI components shared across the system.')
  @SectionId('RUICMP-UICO-LST')
  @SectionIdPattern('RUICMP-UICO-xxx')
  @ContentHelp('Add one entry per UI component.')
  @SerializationOrder(4)
  List<ReusableUiComponentEntry> uiComponents = [];

  /// Business logic components.
  @StandardReferences([
    'Domain-Driven Design — bounded contexts / modules',
    'ISO/IEC 25010 — reusability quality attributes',
  ], 'The reusable business logic components shared across the system.')
  @SectionId('BUCOEN-BUSI-LST')
  @SectionIdPattern('BUCOEN-BUSI-xxx')
  @ContentHelp('Add one entry per business component.')
  @SerializationOrder(5)
  List<BusinessComponentEntry> businessComponents = [];

  /// Infrastructure components.
  @StandardReferences([
    'DRY — reusable component design',
    'ISO/IEC 25010 — maintainability quality attributes',
  ], 'The reusable infrastructure components shared across the system.')
  @SectionId('INCOEN-INFR-LST')
  @SectionIdPattern('INCOEN-INFR-xxx')
  @ContentHelp('Add one entry per infrastructure component.')
  @SerializationOrder(6)
  List<InfrastructureComponentEntry> infrastructureComponents = [];

  /// Third-party frameworks and libraries.
  @StandardReferences([
    'package management (pub / npm / Maven) — dependency management',
    'Semantic Versioning (SemVer) — library versioning',
  ], 'The third-party frameworks and libraries reused across the system.')
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
class ReusabilityPrinciples extends DocSpecsSection {
  @Form([
    Field(
      'reuseFirstPolicy',
      String,
      'Reuse-First Policy',
      hint: 'Policy on preferring existing components',
    ),
    Field(
      'extractionCriteria',
      String,
      'Extraction Criteria',
      hint: 'When to extract code into reusable components',
    ),
    Field(
      'granularityGuidelines',
      String,
      'Granularity Guidelines',
      hint: 'Right size for reusable components',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Abstraction rules.
  @SectionId('REPRAB')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'SOLID principles — object-oriented design',
    ],
    'Captures the abstraction level, interface standards, and dependency rules for reusable components.',
  )
  @Form([
    Field(
      'abstractionLevel',
      String,
      'Abstraction Level',
      hint: 'Required abstraction for reusability',
    ),
    Field(
      'interfaceStandards',
      String,
      'Interface Standards',
      hint: 'Standards for component interfaces',
    ),
    Field(
      'dependencyRules',
      String,
      'Dependency Rules',
      hint: 'Rules for component dependencies',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? abstraction;

  /// Quality expectations.
  @SectionId('REPRQU')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'SOLID principles — object-oriented design',
    ],
    'Captures the documentation, testing, and code-review quality requirements for reusable components.',
  )
  @Form([
    Field(
      'documentationRequirements',
      String,
      'Documentation Requirements',
      hint: 'Required documentation for reusable components',
    ),
    Field(
      'testingRequirements',
      String,
      'Testing Requirements',
      hint: 'Test coverage for reusable components',
    ),
    Field(
      'codeReviewProcess',
      String,
      'Code Review Process',
      hint: 'Review process for shared components',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? quality;

  /// Versioning policy.
  @SectionId('REPRVE')
  @StandardReferences(
    [
      'Semantic Versioning (SemVer) — library versioning',
      'DRY — reusable component design',
    ],
    'Captures the versioning, breaking-change, and deprecation policies for reusable components.',
  )
  @Form([
    Field(
      'versioningPolicy',
      String,
      'Versioning Policy',
      hint: 'How reusable components are versioned',
    ),
    Field(
      'breakingChangePolicy',
      String,
      'Breaking Change Policy',
      hint: 'Handling breaking changes in shared components',
    ),
    Field(
      'deprecationProcess',
      String,
      'Deprecation Process',
      hint: 'How components are deprecated',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? versioning;

  /// Ownership and contribution.
  @SectionId('REPROW')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'SOLID principles — object-oriented design',
    ],
    'Captures the ownership model and contribution process for reusable components.',
  )
  @Form([
    Field(
      'ownershipModel',
      String,
      'Ownership Model',
      hint: 'Who owns shared components',
    ),
    Field(
      'contributionProcess',
      String,
      'Contribution Process',
      hint: 'How to contribute to shared components',
    ),
    Field('notes', String, 'Notes', hint: 'Additional principles notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? ownership;
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
class SharedLibraryComponentEntry extends DocSpecsSection {
  @Form([
    Field(
      'componentName',
      String,
      'Component Name',
      required: true,
      hint: 'Unique library name',
    ),
    Field(
      'componentType',
      String,
      'Component Type',
      hint: 'Core, Utility, Domain, Integration, Extension',
    ),
    Field('version', String, 'Version', hint: 'Current version'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Purpose and consumers.
  @SectionId('SLCED')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'Semantic Versioning (SemVer) — library versioning',
    ],
    'Captures the package name, purpose, functionality, and target consumers of the shared library component.',
  )
  @Form([
    Field(
      'packageName',
      String,
      'Package/Module Name',
      hint: 'Package identifier',
    ),
    Field(
      'purpose',
      String,
      'Purpose',
      required: true,
      hint: 'What problem this component solves',
    ),
    Field(
      'functionality',
      String,
      'Functionality',
      hint: 'Key features provided',
    ),
    Field(
      'targetConsumers',
      String,
      'Target Consumers',
      hint: 'Who should use this component',
    ),
    Field('useCases', String, 'Use Cases', hint: 'Example use cases'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? description;

  /// Technical API details.
  @SectionId('SLCET')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'package management (pub / npm / Maven) — dependency management',
    ],
    'Captures the public API, extension points, configuration, and dependencies of the shared library component.',
  )
  @Form([
    Field(
      'publicApi',
      String,
      'Public API',
      hint: 'Key public classes/functions',
    ),
    Field(
      'extensionPoints',
      String,
      'Extension Points',
      hint: 'How consumers can extend',
    ),
    Field(
      'configuration',
      String,
      'Configuration Options',
      hint: 'Available configuration',
    ),
    Field(
      'dependencies',
      String,
      'Dependencies',
      hint: 'Required dependencies',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? technical;

  /// Quality and documentation.
  @SectionId('SLCEQ')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'package management (pub / npm / Maven) — dependency management',
    ],
    'Captures the test coverage, documentation, and examples location for the shared library component.',
  )
  @Form([
    Field('testCoverage', String, 'Test Coverage', hint: 'Current coverage'),
    Field(
      'documentationUrl',
      String,
      'Documentation URL',
      hint: 'Link to documentation',
    ),
    Field(
      'examplesLocation',
      String,
      'Examples Location',
      hint: 'Where to find examples',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? quality;

  /// Ownership and lifecycle.
  @SectionId('SLCEO')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'Semantic Versioning (SemVer) — library versioning',
    ],
    'Captures the owner, maintainers, support channel, and maturity level of the shared library component.',
  )
  @Form([
    Field('owner', String, 'Owner', hint: 'Team/person responsible'),
    Field('maintainers', String, 'Maintainers', hint: 'List of maintainers'),
    Field(
      'supportChannel',
      String,
      'Support Channel',
      hint: 'Where to get help',
    ),
    Field(
      'maturityLevel',
      String,
      'Maturity Level',
      hint: 'Experimental, Beta, Stable, Deprecated',
    ),
    Field('lastUpdated', String, 'Last Updated', hint: 'Last update date'),
    Field('notes', String, 'Notes', hint: 'Additional component notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? ownership;
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
class ReusableUiComponentEntry extends DocSpecsSection {
  @Form([
    Field(
      'componentName',
      String,
      'Component Name',
      required: true,
      hint: 'Widget or pattern name',
    ),
    Field(
      'componentCategory',
      String,
      'Category',
      hint: 'Input, Display, Navigation, Layout, Feedback, Data',
    ),
    Field('purpose', String, 'Purpose', hint: 'What this component does'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Description and use cases.
  @SectionId('RUCED')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'SOLID principles — object-oriented design',
    ],
    'Captures the visual description, use cases, and anti-patterns for the UI component.',
  )
  @Form([
    Field('version', String, 'Version', hint: 'Component version'),
    Field(
      'visualDescription',
      String,
      'Visual Description',
      hint: 'How it looks and behaves',
    ),
    Field('useCases', String, 'Use Cases', hint: 'When to use this component'),
    Field(
      'antiPatterns',
      String,
      'Anti-Patterns',
      hint: 'When NOT to use this component',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? description;

  /// Design specifications.
  @SectionId('REUICOENDE')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'SOLID principles — object-oriented design',
    ],
    'Captures the design tokens, variants, states, and responsive behavior of the UI component.',
  )
  @Form([
    Field(
      'designTokens',
      String,
      'Design Tokens Used',
      hint: 'Colors, spacing, typography tokens',
    ),
    Field(
      'variants',
      String,
      'Variants',
      hint: 'Available variants (size, style)',
    ),
    Field(
      'states',
      String,
      'States',
      hint: 'Supported states (disabled, loading, error)',
    ),
    Field(
      'responsiveBehavior',
      String,
      'Responsive Behavior',
      hint: 'How component adapts to screen sizes',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? design;

  /// Interaction and accessibility.
  @SectionId('RUCEI')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'SOLID principles — object-oriented design',
    ],
    'Captures the interaction patterns, accessibility features, and animations of the UI component.',
  )
  @Form([
    Field(
      'interactionPatterns',
      String,
      'Interaction Patterns',
      hint: 'Touch, keyboard, mouse behaviors',
    ),
    Field(
      'accessibility',
      String,
      'Accessibility',
      hint: 'A11y features and requirements',
    ),
    Field('animations', String, 'Animations', hint: 'Animation specifications'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? interaction;

  /// Component API.
  @SectionId('RUCEA')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'SOLID principles — object-oriented design',
    ],
    'Captures the required/optional properties, callbacks, and slots forming the UI component API.',
  )
  @Form([
    Field(
      'requiredProperties',
      String,
      'Required Properties',
      hint: 'Required parameters',
    ),
    Field(
      'optionalProperties',
      String,
      'Optional Properties',
      hint: 'Optional parameters',
    ),
    Field('callbacks', String, 'Callbacks', hint: 'Event callbacks supported'),
    Field('slots', String, 'Slots/Children', hint: 'Child content areas'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? api;

  /// Implementation details.
  @SectionId('REUICOENIM')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'SOLID principles — object-oriented design',
    ],
    'Captures the implementing widget class, example code, and demo references for the UI component.',
  )
  @Form([
    Field(
      'flutterWidget',
      String,
      'Flutter Widget Class',
      hint: 'Implementing Flutter widget',
    ),
    Field(
      'exampleCode',
      String,
      'Example Code',
      hint: 'Code snippet or reference',
    ),
    Field(
      'storybook',
      String,
      'Storybook/Demo',
      hint: 'Link to component demo',
    ),
    Field('notes', String, 'Notes', hint: 'Additional UI component notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? implementation;
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
class BusinessComponentEntry extends DocSpecsSection {
  @Form([
    Field(
      'componentName',
      String,
      'Component Name',
      required: true,
      hint: 'Business component name',
    ),
    Field(
      'componentType',
      String,
      'Component Type',
      hint: 'Service, Repository, UseCase, Validator, Calculator',
    ),
    Field(
      'boundedContext',
      String,
      'Bounded Context',
      hint: 'Domain area this belongs to',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Purpose and business rules.
  @SectionId('BCED')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — reusability quality attributes',
    ],
    'Captures the purpose, business rules, and capabilities of the business logic component.',
  )
  @Form([
    Field('purpose', String, 'Purpose', hint: 'Business problem this solves'),
    Field(
      'businessRules',
      String,
      'Business Rules',
      hint: 'Key business rules implemented',
    ),
    Field(
      'capabilities',
      String,
      'Capabilities',
      hint: 'What operations this provides',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? description;

  /// Public interface details.
  @SectionId('BUCOENIN')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Captures the public interface, input/output types, and error handling of the business component.',
  )
  @Form([
    Field(
      'publicInterface',
      String,
      'Public Interface',
      hint: 'Key public methods',
    ),
    Field('inputTypes', String, 'Input Types', hint: 'Expected inputs'),
    Field('outputTypes', String, 'Output Types', hint: 'Produced outputs'),
    Field(
      'errorHandling',
      String,
      'Error Handling',
      hint: 'How errors are handled',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? interface;

  /// Dependency mapping.
  @SectionId('BUCOENDE')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Captures the required services, data access, and external integrations of the business component.',
  )
  @Form([
    Field(
      'requiredServices',
      String,
      'Required Services',
      hint: 'Services this depends on',
    ),
    Field('dataAccess', String, 'Data Access', hint: 'Data repositories used'),
    Field(
      'externalIntegrations',
      String,
      'External Integrations',
      hint: 'External systems accessed',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? dependencies;

  /// Testing details.
  @SectionId('BCET')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Captures the test strategy, mockable interfaces, and test data requirements of the business component.',
  )
  @Form([
    Field('testStrategy', String, 'Test Strategy', hint: 'How this is tested'),
    Field(
      'mockableInterfaces',
      String,
      'Mockable Interfaces',
      hint: 'Interfaces for testing',
    ),
    Field(
      'testDataRequirements',
      String,
      'Test Data Requirements',
      hint: 'Required test data',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? testing;

  /// Reuse and customization notes.
  @SectionId('BCER')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — reusability quality attributes',
    ],
    'Captures the reuse scenarios and customization points of the business logic component.',
  )
  @Form([
    Field(
      'reuseScenarios',
      String,
      'Reuse Scenarios',
      hint: 'Where this can be reused',
    ),
    Field(
      'customizationPoints',
      String,
      'Customization Points',
      hint: 'How behavior can be customized',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional business component notes',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? reuse;
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
class InfrastructureComponentEntry extends DocSpecsSection {
  @Form([
    Field(
      'componentName',
      String,
      'Component Name',
      required: true,
      hint: 'Infrastructure component name',
    ),
    Field(
      'componentType',
      String,
      'Component Type',
      hint: 'Logging, Caching, Messaging, Storage, Network',
    ),
    Field('layer', String, 'Layer', hint: 'Infrastructure layer'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Purpose and technology choices.
  @SectionId('ICED')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Captures the purpose, capabilities, and technology stack of the infrastructure component.',
  )
  @Form([
    Field(
      'purpose',
      String,
      'Purpose',
      hint: 'What infrastructure need this addresses',
    ),
    Field(
      'capabilities',
      String,
      'Capabilities',
      hint: 'Infrastructure capabilities provided',
    ),
    Field(
      'technologyStack',
      String,
      'Technology Stack',
      hint: 'Underlying technologies',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? description;

  /// Configuration requirements.
  @SectionId('ICEC')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Captures the configuration options, environment variables, and secrets required by the infrastructure component.',
  )
  @Form([
    Field(
      'configurationOptions',
      String,
      'Configuration Options',
      hint: 'Available configuration',
    ),
    Field(
      'environmentVariables',
      String,
      'Environment Variables',
      hint: 'Required environment variables',
    ),
    Field('secrets', String, 'Secrets', hint: 'Required secrets'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? configuration;

  /// Integration lifecycle.
  @SectionId('ICEI')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Captures the service interface and initialization/shutdown lifecycle of the infrastructure component.',
  )
  @Form([
    Field(
      'serviceInterface',
      String,
      'Service Interface',
      hint: 'Public service interface',
    ),
    Field(
      'initializationProcess',
      String,
      'Initialization Process',
      hint: 'How to initialize',
    ),
    Field(
      'shutdownProcess',
      String,
      'Shutdown Process',
      hint: 'Graceful shutdown procedure',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? integration;

  /// Operational behavior.
  @SectionId('ICEO')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Captures the monitoring, health-check, and scalability operational behavior of the infrastructure component.',
  )
  @Form([
    Field(
      'monitoring',
      String,
      'Monitoring',
      hint: 'Monitoring and observability',
    ),
    Field(
      'healthCheck',
      String,
      'Health Check',
      hint: 'Health check implementation',
    ),
    Field('scalability', String, 'Scalability', hint: 'Scaling considerations'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? operations;

  /// Resiliency behavior.
  @SectionId('ICER')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'ISO/IEC 25010 — reliability quality attributes',
    ],
    'Captures the failure handling, retry, and circuit-breaker resiliency behavior of the infrastructure component.',
  )
  @Form([
    Field(
      'failureHandling',
      String,
      'Failure Handling',
      hint: 'How failures are handled',
    ),
    Field('retryPolicy', String, 'Retry Policy', hint: 'Retry configuration'),
    Field(
      'circuitBreaker',
      String,
      'Circuit Breaker',
      hint: 'Circuit breaker configuration',
    ),
    Field('notes', String, 'Notes', hint: 'Additional infrastructure notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? resiliency;
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
class ThirdPartyLibraryEntry extends DocSpecsSection {
  @Form([
    Field(
      'libraryName',
      String,
      'Library Name',
      required: true,
      hint: 'Package name',
    ),
    Field(
      'packageSource',
      String,
      'Package Source',
      hint: 'pub.dev, npm, Maven, GitHub',
    ),
    Field(
      'version',
      String,
      'Version',
      required: true,
      hint: 'Version constraint',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Evaluation and selection.
  @SectionId('TPLEE')
  @StandardReferences(
    [
      'package management (pub / npm / Maven) — dependency management',
      'Semantic Versioning (SemVer) — library versioning',
    ],
    'Captures the evaluation, alternatives considered, and rationale for selecting the third-party library.',
  )
  @Form([
    Field('homepage', String, 'Homepage', hint: 'Library homepage URL'),
    Field('purpose', String, 'Purpose', hint: 'Why this library is used'),
    Field(
      'alternatives',
      String,
      'Alternatives Considered',
      hint: 'Other options evaluated',
    ),
    Field(
      'selectionRationale',
      String,
      'Selection Rationale',
      hint: 'Why this was chosen',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? evaluation;

  /// Licensing details.
  @SectionId('TPLEL')
  @StandardReferences(
    [
      'package management (pub / npm / Maven) — dependency management',
      'Semantic Versioning (SemVer) — library versioning',
    ],
    'Captures the license, compliance status, and attribution requirements of the third-party library.',
  )
  @Form([
    Field(
      'license',
      String,
      'License',
      required: true,
      hint: 'MIT, Apache, GPL, BSD',
    ),
    Field(
      'licenseCompliance',
      String,
      'License Compliance',
      hint: 'Compliance status',
    ),
    Field(
      'attributionRequired',
      bool,
      'Attribution Required',
      hint: 'Requires attribution',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? licenseInfo;

  /// Risk profile.
  @SectionId('TPLER')
  @StandardReferences(
    [
      'package management (pub / npm / Maven) — dependency management',
      'Semantic Versioning (SemVer) — library versioning',
    ],
    'Captures the maintenance, community, security, and lock-in risk profile of the third-party library.',
  )
  @Form([
    Field(
      'maintenanceStatus',
      String,
      'Maintenance Status',
      hint: 'Active, Maintained, Stale, Abandoned',
    ),
    Field(
      'communitySize',
      String,
      'Community Size',
      hint: 'Community support level',
    ),
    Field(
      'securityHistory',
      String,
      'Security History',
      hint: 'Known security issues',
    ),
    Field(
      'vendorLockIn',
      String,
      'Vendor Lock-In Risk',
      hint: 'Lock-in considerations',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? risk;

  /// Usage and upgrade strategy.
  @SectionId('TPLEU')
  @StandardReferences(
    [
      'package management (pub / npm / Maven) — dependency management',
      'Semantic Versioning (SemVer) — library versioning',
    ],
    'Captures where the third-party library is used and the strategy for wrapping and upgrading it.',
  )
  @Form([
    Field(
      'usageScope',
      String,
      'Usage Scope',
      hint: 'Where in project this is used',
    ),
    Field(
      'wrapperRequired',
      bool,
      'Wrapper Required',
      hint: 'Should be wrapped in abstraction',
    ),
    Field(
      'upgradeStrategy',
      String,
      'Upgrade Strategy',
      hint: 'How upgrades are handled',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? usage;

  /// Monitoring and notes.
  @SectionId('TPLEM')
  @StandardReferences(
    [
      'package management (pub / npm / Maven) — dependency management',
      'Semantic Versioning (SemVer) — library versioning',
    ],
    'Captures how updates and deprecations of the third-party library are monitored and handled.',
  )
  @Form([
    Field(
      'updateNotifications',
      String,
      'Update Notifications',
      hint: 'How updates are monitored',
    ),
    Field(
      'deprecationHandling',
      String,
      'Deprecation Handling',
      hint: 'Plan if library deprecated',
    ),
    Field('notes', String, 'Notes', hint: 'Additional library notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? monitoring;
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
class ComponentGovernance extends DocSpecsSection {
  @Form([
    Field(
      'ownershipModel',
      String,
      'Ownership Model',
      hint: 'Central team, federated, individual',
    ),
    Field(
      'sharedComponentsTeam',
      String,
      'Shared Components Team',
      hint: 'Team responsible for shared components',
    ),
    Field(
      'escalationPath',
      String,
      'Escalation Path',
      hint: 'How issues are escalated',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Contribution governance.
  @SectionId('COGOCO')
  @StandardReferences(
    [
      'Domain-Driven Design — bounded contexts / modules',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Captures the contribution guidelines, review process, and acceptance criteria for shared components.',
  )
  @Form([
    Field(
      'contributionGuidelines',
      String,
      'Contribution Guidelines',
      hint: 'How to contribute',
    ),
    Field(
      'reviewProcess',
      String,
      'Review Process',
      hint: 'Review process for contributions',
    ),
    Field(
      'acceptanceCriteria',
      String,
      'Acceptance Criteria',
      hint: 'Criteria for accepting components',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? contribution;

  /// Quality expectations.
  @SectionId('COGOQU')
  @StandardReferences(
    [
      'ISO/IEC 25010 — maintainability quality attributes',
      'Domain-Driven Design — bounded contexts / modules',
    ],
    'Captures the quality, testing, and documentation standards required of governed shared components.',
  )
  @Form([
    Field(
      'qualityStandards',
      String,
      'Quality Standards',
      hint: 'Quality requirements for shared components',
    ),
    Field(
      'testingRequirements',
      String,
      'Testing Requirements',
      hint: 'Required test coverage',
    ),
    Field(
      'documentationRequirements',
      String,
      'Documentation Requirements',
      hint: 'Required documentation',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? quality;

  /// Lifecycle policies.
  @SectionId('COGOLI')
  @StandardReferences(
    [
      'ISO/IEC 25010 — maintainability quality attributes',
      'Domain-Driven Design — bounded contexts / modules',
    ],
    'Captures the promotion, deprecation, and retirement policies governing the component lifecycle.',
  )
  @Form([
    Field(
      'promotionProcess',
      String,
      'Promotion Process',
      hint: 'How components move to production',
    ),
    Field(
      'deprecationProcess',
      String,
      'Deprecation Process',
      hint: 'How components are deprecated',
    ),
    Field(
      'retirementProcess',
      String,
      'Retirement Process',
      hint: 'How components are retired',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? lifecycle;

  /// Metrics and notes.
  @SectionId('COGOME')
  @StandardReferences(
    [
      'ISO/IEC 25010 — maintainability quality attributes',
      'Domain-Driven Design — bounded contexts / modules',
    ],
    'Captures the metrics and success criteria used to measure component adoption and quality.',
  )
  @Form([
    Field(
      'adoptionMetrics',
      String,
      'Adoption Metrics',
      hint: 'How usage is tracked',
    ),
    Field(
      'qualityMetrics',
      String,
      'Quality Metrics',
      hint: 'Quality measurements',
    ),
    Field(
      'successCriteria',
      String,
      'Success Criteria',
      hint: 'How success is measured',
    ),
    Field('notes', String, 'Notes', hint: 'Additional governance notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? metrics;
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
class ComponentRegistry extends DocSpecsSection {
  @Form([
    Field(
      'registryType',
      String,
      'Registry Type',
      hint: 'Wiki, catalog tool, package registry',
    ),
    Field(
      'registryLocation',
      String,
      'Registry Location',
      hint: 'URL or location of registry',
    ),
    Field(
      'searchCapabilities',
      String,
      'Search Capabilities',
      hint: 'How to search for components',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Metadata requirements.
  @SectionId('COREME')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Captures the metadata, tagging, and categorization requirements for components in the registry.',
  )
  @Form([
    Field(
      'requiredMetadata',
      String,
      'Required Metadata',
      hint: 'Metadata required for each component',
    ),
    Field(
      'taggingConventions',
      String,
      'Tagging Conventions',
      hint: 'How components are tagged',
    ),
    Field(
      'categorizationScheme',
      String,
      'Categorization Scheme',
      hint: 'How components are categorized',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? metadata;

  /// Discovery workflow.
  @SectionId('COREDI')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'ISO/IEC 25010 — reusability quality attributes',
    ],
    'Captures the workflow by which developers discover and are recommended existing reusable components.',
  )
  @Form([
    Field(
      'discoveryProcess',
      String,
      'Discovery Process',
      hint: 'How developers find components',
    ),
    Field(
      'recommendationEngine',
      String,
      'Recommendation Engine',
      hint: 'Component recommendations',
    ),
    Field(
      'integration',
      String,
      'IDE Integration',
      hint: 'Integration with development tools',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? discovery;

  /// Documentation requirements.
  @SectionId('COREDO')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Captures the documentation standards and formats required for registered reusable components.',
  )
  @Form([
    Field(
      'documentationFormat',
      String,
      'Documentation Format',
      hint: 'Standard documentation format',
    ),
    Field(
      'exampleRequirements',
      String,
      'Example Requirements',
      hint: 'Required examples',
    ),
    Field(
      'apiDocGeneration',
      String,
      'API Doc Generation',
      hint: 'Automated API documentation',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? documentation;

  /// Update communication.
  @SectionId('COREUP')
  @StandardReferences(
    [
      'DRY — reusable component design',
      'ISO/IEC 25010 — maintainability quality attributes',
    ],
    'Captures how component updates and changes are communicated to consumers through the registry.',
  )
  @Form([
    Field(
      'updateNotifications',
      String,
      'Update Notifications',
      hint: 'How updates are communicated',
    ),
    Field(
      'changelogRequirements',
      String,
      'Changelog Requirements',
      hint: 'Changelog format',
    ),
    Field(
      'migrationGuides',
      String,
      'Migration Guides',
      hint: 'Migration documentation',
    ),
    Field('notes', String, 'Notes', hint: 'Additional registry notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? updates;
}

/// 8.3. Standard Application Software Requirements.
@DetailedIn(D06ArchitectureTechnologySpecification)
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
class StandardSoftwareRequirements extends DocSpecsSection {
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
  @override
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
class CompatibilityRequirementsSection extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of compatibility strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Operating system compatibility requirements.
  @StandardReferences([
    'POSIX / ISO/IEC 9945 — operating-system interface',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ], 'The operating systems the system must support.')
  @SectionId('OSCOEN-OSCO-LST')
  @SectionIdPattern('OSCOEN-OSCO-xxx')
  @ContentHelp('Add one entry per supported operating system.')
  @SerializationOrder(2)
  List<OsCompatibilityEntry> osCompatibility = [];

  /// Browser compatibility requirements.
  @StandardReferences([
    'WHATWG / W3C — web platform / browser standards',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ], 'The browsers the system must support.')
  @SectionId('BRCOEN-BROW-LST')
  @SectionIdPattern('BRCOEN-BROW-xxx')
  @ContentHelp('Add one entry per supported browser.')
  @SerializationOrder(3)
  List<BrowserCompatibilityEntry> browserCompatibility = [];

  /// Database compatibility requirements.
  @StandardReferences([
    'ISO/IEC 9075 (SQL) — relational database standard',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ], 'The databases the system must remain compatible with.')
  @SectionId('DACOEN-DATA-LST')
  @SectionIdPattern('DACOEN-DATA-xxx')
  @ContentHelp('Add one entry per supported database.')
  @SerializationOrder(4)
  List<DatabaseCompatibilityEntry> databaseCompatibility = [];

  /// Enterprise system compatibility requirements.
  @StandardReferences([
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'The enterprise systems the system must integrate with.')
  @SectionId('ESCE-ENTE-LST')
  @SectionIdPattern('ESCE-ENTE-xxx')
  @ContentHelp('Add one entry per enterprise system.')
  @SerializationOrder(5)
  List<EnterpriseSystemCompatibilityEntry> enterpriseSystemCompatibility = [];

  /// API and protocol compatibility requirements.
  @StandardReferences([
    'OpenAPI / REST — API interoperability',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ], 'The APIs and protocols the system must remain compatible with.')
  @SectionId('APCP-APIC-LST')
  @SectionIdPattern('APCP-APIC-xxx')
  @ContentHelp('Add one entry per API or protocol.')
  @SerializationOrder(6)
  List<ApiCompatibilityEntry> apiCompatibility = [];

  /// Legacy system compatibility requirements.
  @StandardReferences([
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'The legacy systems the system must remain compatible with.')
  @SectionId('LECOEN-LEGA-LST')
  @SectionIdPattern('LECOEN-LEGA-xxx')
  @ContentHelp('Add one entry per legacy system.')
  @SerializationOrder(7)
  List<LegacyCompatibilityEntry> legacyCompatibility = [];

  /// Mobile device compatibility requirements.
  @StandardReferences([
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'The mobile platforms the system must support.')
  @SectionId('MOCOEN-MOBI-LST')
  @SectionIdPattern('MOCOEN-MOBI-xxx')
  @ContentHelp('Add one entry per supported mobile platform.')
  @SerializationOrder(8)
  List<MobileCompatibilityEntry> mobileCompatibility = [];

  /// Third-party software compatibility requirements.
  @StandardReferences([
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'The third-party software the system must co-exist with.')
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
  InteroperabilityRequirements interoperability =
      InteroperabilityRequirements();
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
class OsCompatibilityEntry extends DocSpecsSection {
  @Form([
    Field(
      'osName',
      String,
      'Operating System',
      required: true,
      hint: 'E.g., Windows, macOS, Linux, iOS, Android',
    ),
    Field('osFamily', String, 'OS Family', hint: 'Windows, Unix, Mobile'),
    Field(
      'minVersion',
      String,
      'Minimum Version',
      required: true,
      hint: 'Minimum supported version',
    ),
    Field(
      'maxVersion',
      String,
      'Maximum Version',
      hint: 'Maximum tested version',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Support level and prioritization.
  @SectionId('OCES')
  @StandardReferences(
    [
      'POSIX / ISO/IEC 9945 — operating-system interface',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures the support level, priority, and target market share for the operating system.',
  )
  @Form([
    Field(
      'supportLevel',
      String,
      'Support Level',
      hint: 'Full, Partial, Best-effort, Unsupported',
    ),
    Field(
      'priority',
      String,
      'Priority',
      hint: 'Primary, Secondary, Edge case',
    ),
    Field(
      'marketShare',
      String,
      'Market Share',
      hint: 'Target market share percentage',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? support;

  /// Platform requirements.
  @SectionId('OCER')
  @StandardReferences(
    [
      'POSIX / ISO/IEC 9945 — operating-system interface',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures the CPU architectures, memory, storage, and prerequisites required on the operating system.',
  )
  @Form([
    Field('architectures', String, 'Architectures', hint: 'x64, ARM64, x86'),
    Field('minMemory', String, 'Minimum Memory', hint: 'Minimum RAM required'),
    Field(
      'minStorage',
      String,
      'Minimum Storage',
      hint: 'Minimum disk space required',
    ),
    Field(
      'prerequisites',
      String,
      'Prerequisites',
      hint: 'Required runtime, frameworks',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? requirements;

  /// Testing expectations.
  @SectionId('OCET')
  @StandardReferences(
    [
      'POSIX / ISO/IEC 9945 — operating-system interface',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures the test environment, frequency, and known issues for the operating system.',
  )
  @Form([
    Field(
      'testEnvironment',
      String,
      'Test Environment',
      hint: 'VM, physical, cloud',
    ),
    Field(
      'testFrequency',
      String,
      'Test Frequency',
      hint: 'Every release, periodic, on-demand',
    ),
    Field('knownIssues', String, 'Known Issues', hint: 'OS-specific issues'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? testing;

  /// Lifecycle notes.
  @SectionId('OCEL')
  @StandardReferences(
    [
      'POSIX / ISO/IEC 9945 — operating-system interface',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures special handling and end-of-life planning for the operating system.',
  )
  @Form([
    Field(
      'specialConsiderations',
      String,
      'Special Considerations',
      hint: 'Special handling for this OS',
    ),
    Field(
      'eolPlanning',
      String,
      'EOL Planning',
      hint: 'Plan for OS end-of-life',
    ),
    Field('notes', String, 'Notes', hint: 'Additional OS compatibility notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? lifecycle;
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
class BrowserCompatibilityEntry extends DocSpecsSection {
  @Form([
    Field(
      'browserName',
      String,
      'Browser',
      required: true,
      hint: 'E.g., Chrome, Firefox, Safari, Edge',
    ),
    Field(
      'browserEngine',
      String,
      'Browser Engine',
      hint: 'Chromium, Gecko, WebKit',
    ),
    Field(
      'minVersion',
      String,
      'Minimum Version',
      required: true,
      hint: 'Minimum supported version',
    ),
    Field(
      'maxVersion',
      String,
      'Maximum Version',
      hint: 'Maximum tested version',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Support level and priority.
  @SectionId('BRCOENSU')
  @StandardReferences(
    [
      'WHATWG / W3C — web platform / browser standards',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures the support level, priority, and expected user share for the browser.',
  )
  @Form([
    Field(
      'supportLevel',
      String,
      'Support Level',
      hint: 'Full, Partial, Polyfill required, Unsupported',
    ),
    Field(
      'priority',
      String,
      'Priority',
      hint: 'Primary, Secondary, Edge case',
    ),
    Field(
      'userShare',
      String,
      'User Share',
      hint: 'Expected user share percentage',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? support;

  /// Feature support requirements.
  @SectionId('BCEF')
  @StandardReferences(
    [
      'WHATWG / W3C — web platform / browser standards',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures the required browser features, polyfills, and graceful-degradation strategy.',
  )
  @Form([
    Field(
      'requiredFeatures',
      String,
      'Required Features',
      hint: 'JS features, APIs required',
    ),
    Field('polyfills', String, 'Polyfills Required', hint: 'Polyfills needed'),
    Field(
      'gracefulDegradation',
      String,
      'Graceful Degradation',
      hint: 'Fallback behavior',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? features;

  /// Mobile and PWA support.
  @SectionId('BCEM')
  @StandardReferences(
    [
      'WHATWG / W3C — web platform / browser standards',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures mobile-browser support, PWA capability, and offline support requirements.',
  )
  @Form([
    Field(
      'mobileSupport',
      String,
      'Mobile Support',
      hint: 'Mobile browser support level',
    ),
    Field('pwa', String, 'PWA Support', hint: 'Progressive Web App support'),
    Field(
      'offlineSupport',
      String,
      'Offline Support',
      hint: 'Offline capability',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? mobile;

  /// Testing notes.
  @SectionId('BRCOENTE')
  @StandardReferences(
    [
      'WHATWG / W3C — web platform / browser standards',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures where and how the browser is tested, including automation and known issues.',
  )
  @Form([
    Field(
      'testPlatforms',
      String,
      'Test Platforms',
      hint: 'Where browser is tested',
    ),
    Field(
      'automatedTesting',
      String,
      'Automated Testing',
      hint: 'Automated browser testing',
    ),
    Field(
      'knownIssues',
      String,
      'Known Issues',
      hint: 'Browser-specific issues',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional browser compatibility notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? testing;
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
class DatabaseCompatibilityEntry extends DocSpecsSection {
  @Form([
    Field(
      'databaseName',
      String,
      'Database',
      required: true,
      hint: 'E.g., PostgreSQL, MySQL, MongoDB, SQLite',
    ),
    Field(
      'databaseType',
      String,
      'Type',
      hint: 'RDBMS, Document, Key-Value, Graph',
    ),
    Field(
      'minVersion',
      String,
      'Minimum Version',
      required: true,
      hint: 'Minimum supported version',
    ),
    Field(
      'maxVersion',
      String,
      'Maximum Version',
      hint: 'Maximum tested version',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Support options.
  @SectionId('DCES')
  @StandardReferences([
    'ISO/IEC 9075 (SQL) — relational database standard',
    'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
  ], 'Captures the support level and cloud-hosted variants for the database.')
  @Form([
    Field(
      'supportLevel',
      String,
      'Support Level',
      hint: 'Primary, Secondary, Experimental',
    ),
    Field(
      'cloudVariants',
      String,
      'Cloud Variants',
      hint: 'AWS RDS, Azure SQL, Cloud SQL',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? support;

  /// Feature requirements.
  @SectionId('DCEF')
  @StandardReferences(
    [
      'ISO/IEC 9075 (SQL) — relational database standard',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures the required and optional database features and extensions the system depends on.',
  )
  @Form([
    Field(
      'requiredFeatures',
      String,
      'Required Features',
      hint: 'Required database features',
    ),
    Field(
      'optionalFeatures',
      String,
      'Optional Features',
      hint: 'Optional performance features',
    ),
    Field(
      'extensions',
      String,
      'Extensions',
      hint: 'Required extensions/plugins',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? features;

  /// Connection requirements.
  @SectionId('DCEC')
  @StandardReferences(
    [
      'ISO/IEC 9075 (SQL) — relational database standard',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures the connection driver, pooling, and SSL/TLS requirements for the database.',
  )
  @Form([
    Field(
      'connectionDriver',
      String,
      'Connection Driver',
      hint: 'Driver/client library',
    ),
    Field(
      'connectionPooling',
      String,
      'Connection Pooling',
      hint: 'Pooling requirements',
    ),
    Field('ssl', String, 'SSL Requirements', hint: 'SSL/TLS requirements'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? connection;

  /// Performance and notes.
  @SectionId('DCEP')
  @StandardReferences(
    [
      'ISO/IEC 9075 (SQL) — relational database standard',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures database-specific performance notes, scaling considerations, and known limitations.',
  )
  @Form([
    Field(
      'performanceNotes',
      String,
      'Performance Notes',
      hint: 'DB-specific performance',
    ),
    Field(
      'scalingConsiderations',
      String,
      'Scaling Considerations',
      hint: 'Scaling with this database',
    ),
    Field(
      'knownLimitations',
      String,
      'Known Limitations',
      hint: 'Database-specific limitations',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional database compatibility notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? performance;
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
class EnterpriseSystemCompatibilityEntry extends DocSpecsSection {
  @Form([
    Field(
      'systemName',
      String,
      'System Name',
      required: true,
      hint: 'E.g., SAP, Salesforce, Oracle ERP',
    ),
    Field(
      'systemType',
      String,
      'System Type',
      hint: 'ERP, CRM, HR, Finance, Supply Chain',
    ),
    Field('vendor', String, 'Vendor', hint: 'System vendor'),
    Field('version', String, 'Version', hint: 'Supported versions'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Integration details.
  @SectionId('ESCEI')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the integration method, protocol, data exchanged, and frequency for the enterprise system.',
  )
  @Form([
    Field(
      'integrationMethod',
      String,
      'Integration Method',
      hint: 'API, File transfer, Middleware, Direct',
    ),
    Field(
      'integrationProtocol',
      String,
      'Integration Protocol',
      hint: 'REST, SOAP, OData, BAPI',
    ),
    Field(
      'dataExchange',
      String,
      'Data Exchange',
      hint: 'Data exchanged with system',
    ),
    Field(
      'frequency',
      String,
      'Frequency',
      hint: 'Real-time, batch, on-demand',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? integration;

  /// Authentication and access.
  @SectionId('ESCES')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the authentication, authorization, and SSO integration with the enterprise system.',
  )
  @Form([
    Field(
      'authentication',
      String,
      'Authentication',
      hint: 'Auth method for system',
    ),
    Field(
      'authorization',
      String,
      'Authorization',
      hint: 'Required permissions/roles',
    ),
    Field('sso', String, 'SSO Integration', hint: 'Single sign-on support'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? security;

  /// Setup requirements.
  @SectionId('ESCER')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the prerequisites, configuration, and customization needed to integrate the enterprise system.',
  )
  @Form([
    Field(
      'prerequisites',
      String,
      'Prerequisites',
      hint: 'Required adapters, middleware',
    ),
    Field(
      'configuration',
      String,
      'Configuration',
      hint: 'Required configuration',
    ),
    Field(
      'customization',
      String,
      'Customization',
      hint: 'Required customizations',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? requirements;

  /// Testing and notes.
  @SectionId('ESCET')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the test environment and approach for verifying enterprise-system integration.',
  )
  @Form([
    Field(
      'testEnvironment',
      String,
      'Test Environment',
      hint: 'Sandbox, dev instance',
    ),
    Field(
      'testApproach',
      String,
      'Test Approach',
      hint: 'Integration testing approach',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional enterprise compatibility notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? testing;
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
class ApiCompatibilityEntry extends DocSpecsSection {
  @Form([
    Field(
      'apiName',
      String,
      'API/Protocol Name',
      required: true,
      hint: 'Name of API or protocol',
    ),
    Field(
      'apiType',
      String,
      'API Type',
      hint: 'REST, GraphQL, gRPC, SOAP, WebSocket',
    ),
    Field(
      'version',
      String,
      'Version',
      required: true,
      hint: 'Supported API versions',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Compatibility policy.
  @SectionId('APCOENPO')
  @StandardReferences(
    [
      'OpenAPI / REST — API interoperability',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures the API versioning strategy, backwards-compatibility stance, and deprecation policy.',
  )
  @Form([
    Field(
      'versioningStrategy',
      String,
      'Versioning Strategy',
      hint: 'URL path, header, query param',
    ),
    Field(
      'backwardsCompatibility',
      String,
      'Backwards Compatibility',
      hint: 'Support for older versions',
    ),
    Field(
      'deprecationPolicy',
      String,
      'Deprecation Policy',
      hint: 'How deprecated APIs handled',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? policy;

  /// Data-format requirements.
  @SectionId('ACEF')
  @StandardReferences(
    [
      'OpenAPI / REST — API interoperability',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures the data format, encoding, and compression the API must interoperate with.',
  )
  @Form([
    Field('dataFormat', String, 'Data Format', hint: 'JSON, XML, Protobuf'),
    Field('encoding', String, 'Encoding', hint: 'UTF-8, character encoding'),
    Field('compression', String, 'Compression', hint: 'gzip, deflate support'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? format;

  /// Transport requirements.
  @SectionId('APCOENTR')
  @StandardReferences(
    [
      'OpenAPI / REST — API interoperability',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures the transport, security, and authentication requirements for the API.',
  )
  @Form([
    Field('transport', String, 'Transport', hint: 'HTTP, HTTPS, WebSocket'),
    Field('security', String, 'Security', hint: 'TLS version, certificates'),
    Field(
      'authentication',
      String,
      'Authentication',
      hint: 'OAuth, API key, JWT',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? transportDetails;

  /// Specification references.
  @SectionId('ACES')
  @StandardReferences(
    [
      'OpenAPI / REST — API interoperability',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures the API specification references, schema validation, and conformance level required.',
  )
  @Form([
    Field(
      'specificationUrl',
      String,
      'Specification URL',
      hint: 'OpenAPI, AsyncAPI URL',
    ),
    Field(
      'schemaValidation',
      String,
      'Schema Validation',
      hint: 'Schema validation requirements',
    ),
    Field(
      'conformanceLevel',
      String,
      'Conformance Level',
      hint: 'Strict, relaxed',
    ),
    Field('notes', String, 'Notes', hint: 'Additional API compatibility notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? specification;
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
class LegacyCompatibilityEntry extends DocSpecsSection {
  @Form([
    Field(
      'systemName',
      String,
      'System Name',
      required: true,
      hint: 'Legacy system name',
    ),
    Field('systemAge', String, 'System Age', hint: 'How old the system is'),
    Field('technology', String, 'Technology', hint: 'COBOL, mainframe, etc.'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Integration approach.
  @SectionId('LCEI')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures how the system integrates with the legacy system, including the adapter approach and data access.',
  )
  @Form([
    Field(
      'integrationApproach',
      String,
      'Integration Approach',
      hint: 'Wrapper, adapter, gateway',
    ),
    Field(
      'dataAccess',
      String,
      'Data Access',
      hint: 'How legacy data is accessed',
    ),
    Field('bidirectional', bool, 'Bidirectional', hint: 'Two-way data flow'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? integration;

  /// Constraints and limitations.
  @SectionId('LCEC')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the constraints, limitations, and performance impact of integrating with the legacy system.',
  )
  @Form([
    Field(
      'constraints',
      String,
      'Constraints',
      hint: 'Legacy system constraints',
    ),
    Field(
      'limitations',
      String,
      'Limitations',
      hint: 'Integration limitations',
    ),
    Field(
      'performanceImpact',
      String,
      'Performance Impact',
      hint: 'Impact on performance',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? constraintsSection;

  /// Migration planning.
  @SectionId('LCEM')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the migration path away from the legacy system, coexistence period, and data-sync approach.',
  )
  @Form([
    Field(
      'migrationPath',
      String,
      'Migration Path',
      hint: 'Path to replace legacy',
    ),
    Field(
      'coexistencePeriod',
      String,
      'Coexistence Period',
      hint: 'How long systems coexist',
    ),
    Field(
      'dataSync',
      String,
      'Data Synchronization',
      hint: 'How data stays in sync',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? migration;

  /// Risk management.
  @SectionId('LCER')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the risks of integrating with the legacy system and the fallback plan if integration fails.',
  )
  @Form([
    Field(
      'riskAssessment',
      String,
      'Risk Assessment',
      hint: 'Risks of integration',
    ),
    Field(
      'fallbackPlan',
      String,
      'Fallback Plan',
      hint: 'If integration fails',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional legacy compatibility notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? risk;
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
class MobileCompatibilityEntry extends DocSpecsSection {
  @Form([
    Field(
      'platform',
      String,
      'Platform',
      required: true,
      hint: 'iOS, Android, Cross-platform',
    ),
    Field(
      'minVersion',
      String,
      'Minimum Version',
      required: true,
      hint: 'Minimum OS version',
    ),
    Field(
      'maxVersion',
      String,
      'Maximum Version',
      hint: 'Maximum tested version',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Supported devices.
  @SectionId('MCED')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the device types, screen sizes, and specific named devices the mobile app must support.',
  )
  @Form([
    Field(
      'deviceTypes',
      String,
      'Device Types',
      hint: 'Phone, tablet, foldable',
    ),
    Field(
      'screenSizes',
      String,
      'Screen Sizes',
      hint: 'Supported screen sizes',
    ),
    Field(
      'specificDevices',
      String,
      'Specific Devices',
      hint: 'Named device support',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? devices;

  /// Hardware requirements.
  @SectionId('MCEH')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the minimum device hardware (RAM, storage, sensors) required on the mobile platform.',
  )
  @Form([
    Field('minRam', String, 'Minimum RAM', hint: 'Minimum device RAM'),
    Field(
      'minStorage',
      String,
      'Minimum Storage',
      hint: 'Minimum storage needed',
    ),
    Field(
      'requiredHardware',
      String,
      'Required Hardware',
      hint: 'Camera, GPS, biometric',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? hardware;

  /// Platform capabilities.
  @SectionId('MCEC')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the mobile-platform capabilities the app relies on, such as permissions, background mode, and push.',
  )
  @Form([
    Field(
      'permissions',
      String,
      'Permissions Required',
      hint: 'App permissions needed',
    ),
    Field(
      'backgroundMode',
      String,
      'Background Mode',
      hint: 'Background execution',
    ),
    Field(
      'offlineSupport',
      String,
      'Offline Support',
      hint: 'Offline capabilities',
    ),
    Field(
      'pushNotifications',
      String,
      'Push Notifications',
      hint: 'Push notification support',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? capabilities;

  /// Distribution details.
  @SectionId('MOCOENDI')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the app-store and enterprise distribution channels for the mobile platform.',
  )
  @Form([
    Field('appStore', String, 'App Store', hint: 'Distribution channels'),
    Field(
      'enterpriseDistribution',
      String,
      'Enterprise Distribution',
      hint: 'MDM, enterprise deployment',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional mobile compatibility notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? distribution;
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
class ThirdPartyCompatibilityEntry extends DocSpecsSection {
  @Form([
    Field(
      'softwareName',
      String,
      'Software Name',
      required: true,
      hint: 'Third-party software name',
    ),
    Field('vendor', String, 'Vendor', hint: 'Software vendor'),
    Field(
      'category',
      String,
      'Category',
      hint: 'Antivirus, Firewall, MDM, Office',
    ),
    Field('version', String, 'Version', hint: 'Supported versions'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Compatibility characteristics.
  @SectionId('TPCEC')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the compatibility level, co-existence behavior, and known conflicts with third-party software.',
  )
  @Form([
    Field(
      'compatibilityLevel',
      String,
      'Compatibility Level',
      hint: 'Certified, Compatible, Known issues',
    ),
    Field('coexistence', String, 'Coexistence', hint: 'How they work together'),
    Field(
      'conflicts',
      String,
      'Known Conflicts',
      hint: 'Known compatibility issues',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? compatibility;

  /// Integration characteristics.
  @SectionId('TPCEI')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the integration points, shared data, and operational coordination with third-party software.',
  )
  @Form([
    Field(
      'integrationPoints',
      String,
      'Integration Points',
      hint: 'Where systems integrate',
    ),
    Field(
      'sharedData',
      String,
      'Shared Data',
      hint: 'Data shared between systems',
    ),
    Field(
      'coordination',
      String,
      'Coordination',
      hint: 'How operations coordinate',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? integration;

  /// Testing and certification details.
  @SectionId('TPCET')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the test matrix, vendor certification status, and testing cadence for third-party co-existence.',
  )
  @Form([
    Field('testMatrix', String, 'Test Matrix', hint: 'Combinations tested'),
    Field(
      'certificationStatus',
      String,
      'Certification Status',
      hint: 'Vendor certification',
    ),
    Field('testFrequency', String, 'Test Frequency', hint: 'How often tested'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? testing;

  /// Support and escalation.
  @SectionId('TPCES')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the joint support arrangement and escalation path for co-existing third-party software.',
  )
  @Form([
    Field(
      'supportArrangement',
      String,
      'Support Arrangement',
      hint: 'Joint support process',
    ),
    Field(
      'escalationPath',
      String,
      'Escalation Path',
      hint: 'Issue escalation',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional third-party compatibility notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? support;
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
class DataFormatCompatibility extends DocSpecsSection {
  @Form([
    Field(
      'defaultEncoding',
      String,
      'Default Encoding',
      hint: 'UTF-8, UTF-16, ISO-8859-1',
    ),
    Field(
      'supportedEncodings',
      String,
      'Supported Encodings',
      hint: 'All supported encodings',
    ),
    Field(
      'encodingConversion',
      String,
      'Encoding Conversion',
      hint: 'How encoding conversion handled',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Data format compatibility.
  @SectionId('DFCF')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'OpenAPI / REST — API interoperability',
    ],
    'Captures the primary and supported data formats and how the system converts between them.',
  )
  @Form([
    Field(
      'primaryFormat',
      String,
      'Primary Data Format',
      hint: 'JSON, XML, CSV, Binary',
    ),
    Field(
      'supportedFormats',
      String,
      'Supported Formats',
      hint: 'All supported formats',
    ),
    Field(
      'formatConversion',
      String,
      'Format Conversion',
      hint: 'Format conversion support',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? formats;

  /// Date and time formatting.
  @SectionId('DFCDT')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures date/time formats, time-zone handling, and calendar systems the system must remain compatible with.',
  )
  @Form([
    Field(
      'dateFormat',
      String,
      'Date Format',
      hint: 'ISO 8601, locale-specific',
    ),
    Field(
      'timeZoneHandling',
      String,
      'Time Zone Handling',
      hint: 'UTC, local, configurable',
    ),
    Field(
      'calendarSystems',
      String,
      'Calendar Systems',
      hint: 'Gregorian, other calendars',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? dateTime;

  /// Numeric formatting.
  @SectionId('DFCN')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures number, currency, and precision formatting the system must interoperate with.',
  )
  @Form([
    Field(
      'numberFormat',
      String,
      'Number Format',
      hint: 'Decimal separator, grouping',
    ),
    Field(
      'currencyFormat',
      String,
      'Currency Format',
      hint: 'Currency representation',
    ),
    Field(
      'precision',
      String,
      'Numeric Precision',
      hint: 'Decimal precision handling',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? numbers;

  /// Locale settings.
  @SectionId('DFCL')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures locale handling, right-to-left support, and the Unicode version the system supports.',
  )
  @Form([
    Field('localeSupport', String, 'Locale Support', hint: 'Locale handling'),
    Field('rtlSupport', bool, 'RTL Support', hint: 'Right-to-left languages'),
    Field(
      'unicodeSupport',
      String,
      'Unicode Support',
      hint: 'Unicode version, emoji',
    ),
    Field('notes', String, 'Notes', hint: 'Additional data format notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? locale;
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
class BackwardsCompatibilityRequirements extends DocSpecsSection {
  @Form([
    Field(
      'compatibilityPolicy',
      String,
      'Compatibility Policy',
      hint: 'How many versions supported',
    ),
    Field(
      'breakingChangePolicy',
      String,
      'Breaking Change Policy',
      hint: 'When breaking changes allowed',
    ),
    Field(
      'deprecationTimeline',
      String,
      'Deprecation Timeline',
      hint: 'Deprecation notice period',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Data compatibility requirements.
  @SectionId('BCRD')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures how stored data formats stay compatible across versions, including migration and rollback support.',
  )
  @Form([
    Field(
      'dataCompatibility',
      String,
      'Data Compatibility',
      hint: 'Data format compatibility',
    ),
    Field(
      'migrationSupport',
      String,
      'Migration Support',
      hint: 'Automatic migration support',
    ),
    Field(
      'rollbackSupport',
      String,
      'Rollback Support',
      hint: 'Can rollback to older version',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? data;

  /// API compatibility requirements.
  @SectionId('BCRA')
  @StandardReferences(
    [
      'OpenAPI / REST — API interoperability',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures the API versioning approach, multi-version support, and client grace periods for backwards compatibility.',
  )
  @Form([
    Field(
      'apiVersioning',
      String,
      'API Versioning',
      hint: 'API versioning approach',
    ),
    Field(
      'multipleVersionSupport',
      String,
      'Multiple Version Support',
      hint: 'Supporting multiple versions',
    ),
    Field(
      'clientUpdateGracePeriod',
      String,
      'Client Update Grace Period',
      hint: 'Time for clients to update',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? api;

  /// Database compatibility requirements.
  @SectionId('BACOREDA')
  @StandardReferences(
    [
      'ISO/IEC 9075 (SQL) — relational database standard',
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
    ],
    'Captures how database schema evolution, data migration, and backfill preserve backwards compatibility.',
  )
  @Form([
    Field(
      'schemaEvolution',
      String,
      'Schema Evolution',
      hint: 'Database schema changes',
    ),
    Field(
      'dataMigration',
      String,
      'Data Migration',
      hint: 'Data migration approach',
    ),
    Field(
      'backfillStrategy',
      String,
      'Backfill Strategy',
      hint: 'New field population',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? database;

  /// Communication and support requirements.
  @SectionId('BCRC')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC 12207 — software lifecycle processes',
    ],
    'Captures how backwards-compatibility changes are communicated, documented, and supported for consumers.',
  )
  @Form([
    Field(
      'changeNotification',
      String,
      'Change Notification',
      hint: 'How changes communicated',
    ),
    Field(
      'documentation',
      String,
      'Documentation',
      hint: 'Migration documentation',
    ),
    Field(
      'supportChannels',
      String,
      'Support Channels',
      hint: 'Migration support',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional backwards compatibility notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? communication;
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
class InteroperabilityRequirements extends DocSpecsSection {
  @Form([
    Field(
      'interopStrategy',
      String,
      'Interoperability Strategy',
      hint: 'Overall interop approach',
    ),
    Field(
      'integrationPatterns',
      String,
      'Integration Patterns',
      hint: 'API, Events, File, Message',
    ),
    Field(
      'communicationProtocols',
      String,
      'Communication Protocols',
      hint: 'Supported protocols',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Data-exchange definitions.
  @SectionId('IRDE')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'OpenAPI / REST — API interoperability',
    ],
    'Captures the data-exchange formats, schema registry, and data contracts used for interoperability.',
  )
  @Form([
    Field(
      'dataExchangeFormats',
      String,
      'Data Exchange Formats',
      hint: 'JSON, XML, Protobuf, Avro',
    ),
    Field(
      'schemaRegistry',
      String,
      'Schema Registry',
      hint: 'Schema management',
    ),
    Field(
      'dataContracts',
      String,
      'Data Contracts',
      hint: 'Contract definition approach',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? dataExchange;

  /// Standards and certifications.
  @SectionId('INREST')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the industry and open standards the system conforms to and any interoperability certifications.',
  )
  @Form([
    Field(
      'industryStandards',
      String,
      'Industry Standards',
      hint: 'HL7, EDI, SWIFT',
    ),
    Field(
      'openStandards',
      String,
      'Open Standards',
      hint: 'Open standard adoption',
    ),
    Field(
      'certifications',
      String,
      'Certifications',
      hint: 'Interop certifications',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? standards;

  /// Interoperability testing.
  @SectionId('INRETE')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'OpenAPI / REST — API interoperability',
    ],
    'Captures how interoperability is verified, including partner testing and conformance to standards.',
  )
  @Form([
    Field(
      'interopTesting',
      String,
      'Interoperability Testing',
      hint: 'Testing approach',
    ),
    Field(
      'testPartners',
      String,
      'Test Partners',
      hint: 'Partners for testing',
    ),
    Field(
      'conformanceTests',
      String,
      'Conformance Tests',
      hint: 'Standard conformance',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? testing;

  /// Governance and fallback behavior.
  @SectionId('INREGO')
  @StandardReferences(
    [
      'ISO/IEC 25010 — compatibility (co-existence / interoperability)',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures how interface changes are managed and how the system degrades when interoperability fails.',
  )
  @Form([
    Field(
      'changeManagement',
      String,
      'Change Management',
      hint: 'Managing interface changes',
    ),
    Field(
      'versionNegotiation',
      String,
      'Version Negotiation',
      hint: 'How versions negotiated',
    ),
    Field(
      'fallbackBehavior',
      String,
      'Fallback Behavior',
      hint: 'When interop fails',
    ),
    Field('notes', String, 'Notes', hint: 'Additional interoperability notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? governance;
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
class StandardsComplianceSection extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of standards compliance strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// IT standards compliance (ISO, IEEE, NIST).
  @StandardReferences([
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'The IT standards the system must comply with.')
  @SectionId('ISCE-ITST-LST')
  @SectionIdPattern('ISCE-ITST-xxx')
  @ContentHelp('Add one entry per IT standard.')
  @SerializationOrder(2)
  List<ItStandardComplianceEntry> itStandards = [];

  /// Industry protocols compliance.
  @StandardReferences([
    'HL7 / FHIR / ISO 20022 — industry data-exchange standards',
    'ISO 9001 — quality management systems',
  ], 'The industry protocols the system must comply with.')
  @SectionId('IPCE-INDU-LST')
  @SectionIdPattern('IPCE-INDU-xxx')
  @ContentHelp('Add one entry per industry protocol.')
  @SerializationOrder(3)
  List<IndustryProtocolComplianceEntry> industryProtocols = [];

  /// Interface specification standards.
  @StandardReferences([
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'The interface specification standards the system must follow.')
  @SectionId('INSPEN-INTE-LST')
  @SectionIdPattern('INSPEN-INTE-xxx')
  @ContentHelp('Add one entry per interface specification.')
  @SerializationOrder(4)
  List<InterfaceSpecificationEntry> interfaceSpecifications = [];

  /// Regulatory compliance requirements.
  @StandardReferences([
    'GDPR — data protection regulation',
    'ISO/IEC 27001 — information security management',
  ], 'The regulatory frameworks the system must comply with.')
  @SectionId('RECOEN-REGU-LST')
  @SectionIdPattern('RECOEN-REGU-xxx')
  @ContentHelp('Add one entry per regulation.')
  @SerializationOrder(5)
  List<RegulatoryComplianceEntry> regulatoryCompliance = [];

  /// Security standards compliance.
  @StandardReferences([
    'ISO/IEC 27001 — information security management',
    'ISO/IEC 27002 — information security controls',
  ], 'The security standards the system must comply with.')
  @SectionId('SSCE-SECU-LST')
  @SectionIdPattern('SSCE-SECU-xxx')
  @ContentHelp('Add one entry per security standard.')
  @SerializationOrder(6)
  List<SecurityStandardComplianceEntry> securityStandards = [];

  /// Accessibility standards compliance.
  @StandardReferences([
    'WCAG 2.2 — web content accessibility',
  ], 'The accessibility standards the system must conform to.')
  @SectionId('ACCSTD-ACCE-LST')
  @SectionIdPattern('ACCSTD-ACCE-xxx')
  @ContentHelp('Add one entry per accessibility standard.')
  @SerializationOrder(7)
  List<AccessibilityStandardEntry> accessibilityStandards = [];

  /// Quality management standards.
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ], 'The quality management standards the system must comply with.')
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
@StandardReferences([
  'ISO/IEC 25010 — product quality model',
  'ISO/IEC/IEEE 42010 — architecture description',
], 'Describes a single IT standard the system must comply with.')
@SectionId('ITSTCOEN')
class ItStandardComplianceEntry extends DocSpecsSection {
  @Form([
    Field(
      'standardName',
      String,
      'Standard Name',
      required: true,
      hint: 'E.g., ISO 27001, IEEE 802.11, NIST SP 800-53',
    ),
    Field(
      'standardBody',
      String,
      'Standard Body',
      required: true,
      hint: 'ISO, IEEE, NIST, OASIS, W3C',
    ),
    Field(
      'standardId',
      String,
      'Standard ID',
      hint: 'Official standard identifier',
    ),
    Field('version', String, 'Version', hint: 'Standard version'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Applicability and priority.
  @SectionId('ISCES')
  @StandardReferences([
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'Captures the applicability scope and priority of an IT standard.')
  @Form([
    Field(
      'applicabilityScope',
      String,
      'Applicability Scope',
      hint: 'Which parts of the system this applies to',
    ),
    Field(
      'complianceLevel',
      String,
      'Compliance Level',
      hint: 'Full, Partial, Target',
    ),
    Field('priority', String, 'Priority', hint: 'Critical, High, Medium, Low'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? scope;

  /// Control requirements.
  @SectionId('ISCER')
  @StandardReferences([
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'Captures the applicable controls and exclusions for an IT standard.')
  @Form([
    Field(
      'controlsApplicable',
      String,
      'Applicable Controls',
      hint: 'Specific controls that apply',
    ),
    Field('exclusions', String, 'Exclusions', hint: 'Controls not applicable'),
    Field(
      'customizations',
      String,
      'Customizations',
      hint: 'Organization-specific adaptations',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? requirements;

  /// Compliance timeline.
  @SectionId('ISCET')
  @StandardReferences([
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'Captures the target date and current status for IT standard compliance.')
  @Form([
    Field(
      'targetDate',
      String,
      'Target Compliance Date',
      hint: 'When to achieve compliance',
    ),
    Field(
      'currentStatus',
      String,
      'Current Status',
      hint: 'Not started, In progress, Compliant',
    ),
    Field(
      'lastAssessment',
      String,
      'Last Assessment Date',
      hint: 'Date of last assessment',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? timeline;

  /// Ownership and support.
  @SectionId('ISCEO')
  @StandardReferences([
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'Captures the compliance owner and external support for an IT standard.')
  @Form([
    Field(
      'complianceOwner',
      String,
      'Compliance Owner',
      hint: 'Responsible person/team',
    ),
    Field(
      'externalSupport',
      String,
      'External Support',
      hint: 'External consultants if any',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? ownership;

  /// Evidence and notes.
  @SectionId('ISCEE')
  @StandardReferences([
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'Captures the evidence required to demonstrate IT standard compliance.')
  @Form([
    Field(
      'evidenceRequired',
      String,
      'Evidence Required',
      hint: 'Documentation needed for compliance',
    ),
    Field('notes', String, 'Notes', hint: 'Additional IT standard notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? evidence;
}

/// Industry protocol compliance entry.
@StandardReferences([
  'HL7 / FHIR / ISO 20022 — industry data-exchange standards',
  'ISO 9001 — quality management systems',
], 'Describes a single industry protocol the system complies with.')
@SectionId('INPRCOEN')
class IndustryProtocolComplianceEntry extends DocSpecsSection {
  @Form([
    Field(
      'protocolName',
      String,
      'Protocol Name',
      required: true,
      hint: 'E.g., HTTP/2, MQTT, AMQP, WebSocket',
    ),
    Field(
      'category',
      String,
      'Category',
      hint: 'Network, Messaging, Security, Data exchange',
    ),
    Field(
      'specificationVersion',
      String,
      'Specification Version',
      required: true,
      hint: 'Protocol version',
    ),
    Field(
      'specificationUrl',
      String,
      'Specification URL',
      hint: 'Link to official specification',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Compliance scope and features.
  @SectionId('IPCES')
  @StandardReferences([
    'HL7 / FHIR / ISO 20022 — industry data-exchange standards',
    'ISO 9001 — quality management systems',
  ], 'Captures the mandatory and optional protocol features implemented.')
  @Form([
    Field(
      'complianceScope',
      String,
      'Compliance Scope',
      hint: 'Which features are implemented',
    ),
    Field(
      'mandatoryFeatures',
      String,
      'Mandatory Features',
      hint: 'Required protocol features',
    ),
    Field(
      'optionalFeatures',
      String,
      'Optional Features',
      hint: 'Optional features implemented',
    ),
    Field(
      'extensionsUsed',
      String,
      'Extensions Used',
      hint: 'Protocol extensions used',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? scope;

  /// Implementation details.
  @SectionId('IPCEI')
  @StandardReferences(
    [
      'HL7 / FHIR / ISO 20022 — industry data-exchange standards',
      'ISO 9001 — quality management systems',
    ],
    'Captures the implementation library and performance profile for a protocol.',
  )
  @Form([
    Field(
      'implementationLibrary',
      String,
      'Implementation Library',
      hint: 'Library used for implementation',
    ),
    Field(
      'implementationNotes',
      String,
      'Implementation Notes',
      hint: 'Specific implementation details',
    ),
    Field(
      'performanceProfile',
      String,
      'Performance Profile',
      hint: 'Expected performance characteristics',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? implementation;

  /// Testing details.
  @SectionId('IPCET')
  @StandardReferences([
    'HL7 / FHIR / ISO 20022 — industry data-exchange standards',
    'ISO 9001 — quality management systems',
  ], 'Captures how protocol conformance is tested and certified.')
  @Form([
    Field(
      'conformanceTest',
      String,
      'Conformance Testing',
      hint: 'How conformance is tested',
    ),
    Field(
      'testTools',
      String,
      'Test Tools',
      hint: 'Tools for testing compliance',
    ),
    Field(
      'certificationStatus',
      String,
      'Certification Status',
      hint: 'Official certification if any',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? testing;

  /// Interoperability notes.
  @SectionId('INPRCOENIN')
  @StandardReferences([
    'HL7 / FHIR / ISO 20022 — industry data-exchange standards',
    'ISO 9001 — quality management systems',
  ], 'Captures the interoperability partners and known issues for a protocol.')
  @Form([
    Field(
      'interopPartners',
      String,
      'Interop Partners',
      hint: 'Partners tested for interop',
    ),
    Field(
      'knownIssues',
      String,
      'Known Issues',
      hint: 'Known interoperability issues',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional protocol compliance notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? interoperability;
}

/// Interface specification entry (REST, GraphQL, gRPC, SOAP).
@StandardReferences([
  'ISO/IEC 25010 — product quality model',
  'ISO/IEC/IEEE 42010 — architecture description',
], 'Describes a single interface specification the system implements.')
@SectionId('INTSPEENT')
class InterfaceSpecificationEntry extends DocSpecsSection {
  @Form([
    Field(
      'specificationName',
      String,
      'Specification Name',
      required: true,
      hint: 'E.g., REST, GraphQL, gRPC, SOAP',
    ),
    Field(
      'specificationVersion',
      String,
      'Version',
      hint: 'Specification version',
    ),
    Field(
      'standardsBody',
      String,
      'Standards Body',
      hint: 'IETF, W3C, OASIS, etc.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Definition storage and validation.
  @SectionId('ISED')
  @StandardReferences([
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'Captures how an interface definition is stored and validated.')
  @Form([
    Field(
      'definitionFormat',
      String,
      'Definition Format',
      hint: 'OpenAPI, AsyncAPI, GraphQL SDL, WSDL',
    ),
    Field(
      'definitionLocation',
      String,
      'Definition Location',
      hint: 'Where spec is stored',
    ),
    Field(
      'schemaValidation',
      String,
      'Schema Validation',
      hint: 'How schemas are validated',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? definition;

  /// Interface conventions.
  @SectionId('INSPENCO')
  @StandardReferences(
    [
      'ISO/IEC 25010 — product quality model',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the naming, versioning, and error-handling conventions for an interface.',
  )
  @Form([
    Field(
      'namingConventions',
      String,
      'Naming Conventions',
      hint: 'API naming conventions',
    ),
    Field(
      'versioningStrategy',
      String,
      'Versioning Strategy',
      hint: 'URL path, header, query',
    ),
    Field(
      'errorHandling',
      String,
      'Error Handling',
      hint: 'Error format/codes',
    ),
    Field('pagination', String, 'Pagination', hint: 'Pagination approach'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? conventions;

  /// Documentation expectations.
  @SectionId('INSPENDO')
  @StandardReferences([
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'Captures the documentation expectations for an interface specification.')
  @Form([
    Field(
      'documentationFormat',
      String,
      'Documentation Format',
      hint: 'Swagger UI, ReDoc, etc.',
    ),
    Field(
      'examplesRequired',
      bool,
      'Examples Required',
      hint: 'Require request/response examples',
    ),
    Field(
      'changelogMaintained',
      bool,
      'Changelog Maintained',
      hint: 'Maintain API changelog',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? documentation;

  /// Tooling and notes.
  @SectionId('ISET')
  @StandardReferences([
    'ISO/IEC 25010 — product quality model',
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'Captures the tooling supporting an interface specification.')
  @Form([
    Field(
      'generatedClients',
      String,
      'Generated Clients',
      hint: 'Client SDKs generated',
    ),
    Field('mockServer', String, 'Mock Server', hint: 'Mock server for testing'),
    Field(
      'gatewayIntegration',
      String,
      'Gateway Integration',
      hint: 'API gateway used',
    ),
    Field('notes', String, 'Notes', hint: 'Additional interface spec notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? tooling;
}

/// Regulatory compliance entry (GDPR, HIPAA, PCI-DSS, SOX).
@StandardReferences([
  'GDPR — data protection regulation',
  'PCI DSS — payment card data security',
  'ISO/IEC 27001 — information security management',
], 'Describes a single regulation the system must comply with.')
@SectionId('RCE')
class RegulatoryComplianceEntry extends DocSpecsSection {
  @Form([
    Field(
      'regulationName',
      String,
      'Regulation Name',
      required: true,
      hint: 'E.g., GDPR, HIPAA, PCI-DSS, SOX',
    ),
    Field(
      'jurisdiction',
      String,
      'Jurisdiction',
      required: true,
      hint: 'Geographic/industry scope',
    ),
    Field(
      'regulatoryBody',
      String,
      'Regulatory Body',
      hint: 'Authority enforcing regulation',
    ),
    Field(
      'effectiveDate',
      String,
      'Effective Date',
      hint: 'When regulation took effect',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Applicability analysis.
  @SectionId('RECOENAP')
  @StandardReferences([
    'GDPR — data protection regulation',
    'ISO/IEC 27001 — information security management',
  ], 'Captures why a regulation applies and the data categories it covers.')
  @Form([
    Field(
      'applicabilityReason',
      String,
      'Why Applicable',
      hint: 'Why this regulation applies',
    ),
    Field(
      'dataCategories',
      String,
      'Data Categories',
      hint: 'Types of data covered',
    ),
    Field(
      'processesAffected',
      String,
      'Processes Affected',
      hint: 'Business processes affected',
    ),
    Field('userRights', String, 'User Rights', hint: 'Rights granted to users'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? applicability;

  /// Compliance requirements.
  @SectionId('RECOENRE')
  @StandardReferences([
    'GDPR — data protection regulation',
    'ISO/IEC 27001 — information security management',
  ], 'Captures the technical and procedural controls required by a regulation.')
  @Form([
    Field(
      'keyRequirements',
      String,
      'Key Requirements',
      hint: 'Main requirements to meet',
    ),
    Field(
      'technicalControls',
      String,
      'Technical Controls',
      hint: 'Required technical measures',
    ),
    Field(
      'proceduralControls',
      String,
      'Procedural Controls',
      hint: 'Required procedures',
    ),
    Field(
      'documentationRequired',
      String,
      'Documentation Required',
      hint: 'Required documentation',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? requirements;

  /// Penalties and reporting.
  @SectionId('RCEP')
  @StandardReferences(
    [
      'GDPR — data protection regulation',
      'ISO/IEC 27001 — information security management',
    ],
    'Captures the penalties and breach reporting obligations for a regulation.',
  )
  @Form([
    Field(
      'penaltiesForNonCompliance',
      String,
      'Penalties',
      hint: 'Consequences of non-compliance',
    ),
    Field(
      'reportingObligations',
      String,
      'Reporting Obligations',
      hint: 'Breach reporting requirements',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? penalties;

  /// Ownership and review.
  @SectionId('RCEO')
  @StandardReferences([
    'GDPR — data protection regulation',
    'ISO/IEC 27001 — information security management',
  ], 'Captures the compliance officer and legal review for a regulation.')
  @Form([
    Field('dpo', String, 'DPO/Compliance Officer', hint: 'Responsible officer'),
    Field('legalReview', String, 'Legal Review', hint: 'Legal review status'),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional regulatory compliance notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? ownership;
}

/// Security standard compliance entry (SOC2, ISO 27001, CIS).
@StandardReferences([
  'ISO/IEC 27001 — information security management',
  'ISO/IEC 27002 — information security controls',
], 'Describes a single security standard the system must comply with.')
@SectionId('SESTCOEN')
class SecurityStandardComplianceEntry extends DocSpecsSection {
  @Form([
    Field(
      'standardName',
      String,
      'Standard Name',
      required: true,
      hint: 'E.g., SOC 2, ISO 27001, CIS Controls',
    ),
    Field(
      'standardType',
      String,
      'Standard Type',
      hint: 'Framework, Certification, Benchmark',
    ),
    Field('version', String, 'Version', hint: 'Standard version'),
    Field(
      'trustServiceCriteria',
      String,
      'Trust Service Criteria',
      hint: 'For SOC 2: Security, Availability, etc.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Scope details.
  @SectionId('SESTCOENSC')
  @StandardReferences([
    'ISO/IEC 27001 — information security management',
    'ISO/IEC 27002 — information security controls',
  ], 'Captures the systems and data in scope for a security standard.')
  @Form([
    Field(
      'systemsInScope',
      String,
      'Systems in Scope',
      hint: 'Systems covered',
    ),
    Field(
      'dataInScope',
      String,
      'Data in Scope',
      hint: 'Data categories covered',
    ),
    Field('exclusions', String, 'Exclusions', hint: 'What is excluded'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? scope;

  /// Control definitions.
  @SectionId('SSCEC')
  @StandardReferences([
    'ISO/IEC 27002 — information security controls',
    'ISO/IEC 27001 — information security management',
  ], 'Captures the control framework and categories for a security standard.')
  @Form([
    Field(
      'controlFramework',
      String,
      'Control Framework',
      hint: 'Framework used',
    ),
    Field(
      'controlCategories',
      String,
      'Control Categories',
      hint: 'Categories of controls',
    ),
    Field(
      'highRiskControls',
      String,
      'High-Risk Controls',
      hint: 'Critical controls',
    ),
    Field(
      'compensatingControls',
      String,
      'Compensating Controls',
      hint: 'Alternative controls',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? controls;

  /// Assessment schedule.
  @SectionId('SSCEA')
  @StandardReferences([
    'ISO/IEC 27001 — information security management',
    'ISO/IEC 27002 — information security controls',
  ], 'Captures the assessment schedule and auditor for a security standard.')
  @Form([
    Field(
      'assessmentFrequency',
      String,
      'Assessment Frequency',
      hint: 'How often assessed',
    ),
    Field(
      'lastAuditDate',
      String,
      'Last Audit Date',
      hint: 'Date of last audit',
    ),
    Field(
      'nextAuditDate',
      String,
      'Next Audit Date',
      hint: 'Date of next audit',
    ),
    Field('auditor', String, 'Auditor', hint: 'External auditor'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? assessment;

  /// Overall status.
  @SectionId('SESTCOENST')
  @StandardReferences([
    'ISO/IEC 27001 — information security management',
    'ISO/IEC 27002 — information security controls',
  ], 'Captures the overall compliance status for a security standard.')
  @Form([
    Field(
      'complianceStatus',
      String,
      'Compliance Status',
      hint: 'Current compliance status',
    ),
    Field('notes', String, 'Notes', hint: 'Additional security standard notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? status;
}

/// Accessibility standard entry (WCAG, Section 508, ADA).
@StandardReferences([
  'WCAG 2.2 — web content accessibility',
], 'Describes a single accessibility standard the system must conform to.')
@SectionId('ACCSTD')
class AccessibilityStandardEntry extends DocSpecsSection {
  @Form([
    Field(
      'standardName',
      String,
      'Standard Name',
      required: true,
      hint: 'E.g., WCAG 2.1, Section 508, EN 301 549',
    ),
    Field('version', String, 'Version', hint: 'Standard version'),
    Field(
      'conformanceLevel',
      String,
      'Conformance Level',
      required: true,
      hint: 'A, AA, AAA for WCAG',
    ),
    Field(
      'jurisdiction',
      String,
      'Jurisdiction',
      hint: 'Legal requirement region',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Scope and affected users.
  @SectionId('ASES')
  @StandardReferences(
    ['WCAG 2.2 — web content accessibility'],
    'Captures the content scope and user groups an accessibility standard covers.',
  )
  @Form([
    Field(
      'applicableContent',
      String,
      'Applicable Content',
      hint: 'Web, mobile, documents',
    ),
    Field(
      'userGroups',
      String,
      'User Groups',
      hint: 'Disability types accommodated',
    ),
    Field(
      'assistiveTechnologies',
      String,
      'Assistive Technologies',
      hint: 'Screen readers, etc. supported',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? scope;

  /// Conformance requirements.
  @SectionId('ASER')
  @StandardReferences(
    ['WCAG 2.2 — web content accessibility'],
    'Captures the perceivable, operable, understandable, and robust conformance requirements.',
  )
  @Form([
    Field(
      'perceivableRequirements',
      String,
      'Perceivable Requirements',
      hint: 'Alt text, captions, contrast',
    ),
    Field(
      'operableRequirements',
      String,
      'Operable Requirements',
      hint: 'Keyboard, timing, navigation',
    ),
    Field(
      'understandableRequirements',
      String,
      'Understandable Requirements',
      hint: 'Readable, predictable',
    ),
    Field(
      'robustRequirements',
      String,
      'Robust Requirements',
      hint: 'Compatible with AT',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? requirements;

  /// Testing approach.
  @SectionId('ASET')
  @StandardReferences([
    'WCAG 2.2 — web content accessibility',
  ], 'Captures the testing approach and tools used to verify accessibility.')
  @Form([
    Field(
      'testingApproach',
      String,
      'Testing Approach',
      hint: 'Manual, automated, user testing',
    ),
    Field(
      'testingTools',
      String,
      'Testing Tools',
      hint: 'axe, WAVE, NVDA, VoiceOver',
    ),
    Field(
      'userTesting',
      String,
      'User Testing',
      hint: 'Testing with disabled users',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? testing;

  /// Documentation artifacts.
  @SectionId('ASED')
  @StandardReferences([
    'WCAG 2.2 — web content accessibility',
  ], 'Captures the accessibility conformance reports and statements produced.')
  @Form([
    Field('vpat', String, 'VPAT/ACR', hint: 'Accessibility conformance report'),
    Field(
      'accessibilityStatement',
      String,
      'Accessibility Statement',
      hint: 'Public statement URL',
    ),
    Field('notes', String, 'Notes', hint: 'Additional accessibility notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? documentation;
}

/// Quality standard entry (CMMI, ISO 9001).
@StandardReferences([
  'ISO 9001 — quality management systems',
  'ISO/IEC 25010 — product quality model',
], 'Describes a single quality standard the system must comply with.')
@SectionId('QLSTD')
class QualityStandardEntry extends DocSpecsSection {
  @Form([
    Field(
      'standardName',
      String,
      'Standard Name',
      required: true,
      hint: 'E.g., CMMI, ISO 9001, Six Sigma',
    ),
    Field(
      'maturityLevel',
      String,
      'Maturity Level',
      hint: 'For CMMI: Level 1-5',
    ),
    Field('version', String, 'Version', hint: 'Standard version'),
    Field(
      'scope',
      String,
      'Scope',
      hint: 'Organization-wide or project-specific',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Process coverage.
  @SectionId('QSEP')
  @StandardReferences(
    [
      'ISO 9001 — quality management systems',
      'ISO/IEC 25010 — product quality model',
    ],
    'Captures the process areas and quality objectives covered by a quality standard.',
  )
  @Form([
    Field(
      'processAreas',
      String,
      'Process Areas',
      hint: 'Covered process areas',
    ),
    Field(
      'qualityObjectives',
      String,
      'Quality Objectives',
      hint: 'Measurable quality goals',
    ),
    Field('kpis', String, 'KPIs', hint: 'Key performance indicators'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? processes;

  /// Improvement implementation.
  @SectionId('QSEI')
  @StandardReferences(
    [
      'ISO 9001 — quality management systems',
      'ISO/IEC 25010 — product quality model',
    ],
    'Captures the maturity gap analysis and improvement plan for a quality standard.',
  )
  @Form([
    Field('currentLevel', String, 'Current Level', hint: 'Current maturity'),
    Field('targetLevel', String, 'Target Level', hint: 'Target maturity'),
    Field('gapAnalysis', String, 'Gap Analysis', hint: 'Identified gaps'),
    Field(
      'improvementPlan',
      String,
      'Improvement Plan',
      hint: 'Plan to close gaps',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? implementation;

  /// Certification status.
  @SectionId('QSEC')
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ], 'Captures the certification status for a quality standard.')
  @Form([
    Field(
      'certificationBody',
      String,
      'Certification Body',
      hint: 'Who certifies',
    ),
    Field(
      'certificationStatus',
      String,
      'Certification Status',
      hint: 'Current certification',
    ),
    Field(
      'certificationExpiry',
      String,
      'Certification Expiry',
      hint: 'When certification expires',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? certification;

  /// Maintenance expectations.
  @SectionId('QSEM')
  @StandardReferences(
    [
      'ISO 9001 — quality management systems',
      'ISO/IEC 25010 — product quality model',
    ],
    'Captures the audit frequency and continuous improvement for a quality standard.',
  )
  @Form([
    Field(
      'auditFrequency',
      String,
      'Audit Frequency',
      hint: 'How often audited',
    ),
    Field(
      'continuousImprovement',
      String,
      'Continuous Improvement',
      hint: 'Improvement process',
    ),
    Field('notes', String, 'Notes', hint: 'Additional quality standard notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? maintenance;
}

/// Documentation standards section.
@StandardReferences([
  'ISO 9001 — quality management systems',
  'ISO/IEC 25010 — product quality model',
], 'Describes the documentation standards the project must follow.')
@SectionId('DOSTSE')
class DocumentationStandardsSection extends DocSpecsSection {
  @Form([
    Field(
      'documentationPolicy',
      String,
      'Documentation Policy',
      hint: 'Overall documentation policy',
    ),
    Field(
      'templateStandards',
      String,
      'Template Standards',
      hint: 'Required templates',
    ),
    Field('styleGuide', String, 'Style Guide', hint: 'Writing style guide'),
    Field(
      'terminology',
      String,
      'Terminology',
      hint: 'Standard terminology/glossary',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Technical documentation standards.
  @SectionId('DSST')
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ], 'Captures the standards for technical documentation and API docs.')
  @Form([
    Field(
      'technicalDocFormat',
      String,
      'Technical Doc Format',
      hint: 'Markdown, Confluence, etc.',
    ),
    Field(
      'apiDocStandard',
      String,
      'API Doc Standard',
      hint: 'OpenAPI, JSDoc, etc.',
    ),
    Field(
      'codeCommentStyle',
      String,
      'Code Comment Style',
      hint: 'Comment style guide',
    ),
    Field(
      'inlineDocRequirements',
      String,
      'Inline Doc Requirements',
      hint: 'Required inline documentation',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? technical;

  /// User documentation standards.
  @SectionId('DSSU')
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ], 'Captures the standards for user-facing documentation and help systems.')
  @Form([
    Field(
      'userDocFormat',
      String,
      'User Doc Format',
      hint: 'User documentation format',
    ),
    Field(
      'helpSystemStandard',
      String,
      'Help System Standard',
      hint: 'Contextual help approach',
    ),
    Field(
      'localizationRequirements',
      String,
      'Localization Requirements',
      hint: 'Translation requirements',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? user;

  /// Documentation process rules.
  @SectionId('DSSP')
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ], 'Captures the review, versioning, and archival process for documentation.')
  @Form([
    Field(
      'reviewProcess',
      String,
      'Review Process',
      hint: 'Documentation review process',
    ),
    Field(
      'versionControl',
      String,
      'Version Control',
      hint: 'Doc version control',
    ),
    Field(
      'archivalPolicy',
      String,
      'Archival Policy',
      hint: 'How docs are archived',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? process;

  /// Documentation quality rules.
  @SectionId('DSSQ')
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ], 'Captures the quality rules documentation must satisfy.')
  @Form([
    Field(
      'spellCheckRequired',
      bool,
      'Spell Check Required',
      hint: 'Require spell checking',
    ),
    Field(
      'accessibilityRequired',
      bool,
      'Accessibility Required',
      hint: 'Accessible documents',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional documentation standard notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? quality;
}

/// Coding standards section.
@StandardReferences([
  'ISO 9001 — quality management systems',
  'ISO/IEC 25010 — product quality model',
], 'Describes the coding standards and conventions the codebase must follow.')
@SectionId('COSTSE')
class CodingStandardsSection extends DocSpecsSection {
  @Form([
    Field(
      'primaryLanguages',
      String,
      'Primary Languages',
      hint: 'Main programming languages',
    ),
    Field('styleGuide', String, 'Style Guide', hint: 'Official style guide'),
    Field('linterTool', String, 'Linter Tool', hint: 'Required linter'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Formatting and layout rules.
  @SectionId('CSSF')
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ], 'Captures the formatting and layout rules for source code.')
  @Form([
    Field('indentation', String, 'Indentation', hint: 'Spaces vs tabs, count'),
    Field('lineLength', String, 'Max Line Length', hint: 'Maximum line length'),
    Field('formatterTool', String, 'Formatter Tool', hint: 'Code formatter'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? formatting;

  /// Naming and structure rules.
  @SectionId('CSSN')
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ], 'Captures the naming conventions and directory structure rules for code.')
  @Form([
    Field(
      'namingConventions',
      String,
      'Naming Conventions',
      hint: 'Variable, class, method naming',
    ),
    Field('fileNaming', String, 'File Naming', hint: 'File naming conventions'),
    Field(
      'directoryStructure',
      String,
      'Directory Structure',
      hint: 'Required directory layout',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? naming;

  /// Static quality checks.
  @SectionId('CSSQ')
  @StandardReferences([
    'ISO/IEC 25010 — product quality model',
    'ISO 9001 — quality management systems',
  ], 'Captures the static analysis and complexity checks applied to code.')
  @Form([
    Field(
      'staticAnalysis',
      String,
      'Static Analysis',
      hint: 'Static analysis tools',
    ),
    Field(
      'complexityLimits',
      String,
      'Complexity Limits',
      hint: 'Cyclomatic complexity limits',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? quality;

  /// Development practices.
  @SectionId('CSSP')
  @StandardReferences(
    [
      'ISO 9001 — quality management systems',
      'ISO/IEC 25010 — product quality model',
    ],
    'Captures the development practices for error handling, logging, testing, and security.',
  )
  @Form([
    Field(
      'errorHandling',
      String,
      'Error Handling',
      hint: 'Error handling patterns',
    ),
    Field(
      'loggingStandard',
      String,
      'Logging Standard',
      hint: 'Logging conventions',
    ),
    Field(
      'testingRequirements',
      String,
      'Testing Requirements',
      hint: 'Required test coverage',
    ),
    Field(
      'securityPractices',
      String,
      'Security Practices',
      hint: 'Secure coding practices',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? practices;

  /// Review expectations.
  @SectionId('CSSR')
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 25010 — product quality model',
  ], 'Captures the code review expectations and checklists.')
  @Form([
    Field(
      'codeReviewChecklist',
      String,
      'Code Review Checklist',
      hint: 'Review checklist',
    ),
    Field(
      'pairProgramming',
      String,
      'Pair Programming',
      hint: 'Pair programming policy',
    ),
    Field('notes', String, 'Notes', hint: 'Additional coding standard notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? review;
}

/// Certification requirements section.
@StandardReferences([
  'ISO 9001 — quality management systems',
  'ISO/IEC 27001 — information security management',
], 'Describes the certifications the system must obtain and maintain.')
@SectionId('CERESE')
class CertificationRequirementsSection extends DocSpecsSection {
  @Form([
    Field(
      'requiredCertifications',
      String,
      'Required Certifications',
      hint: 'List of required certs',
    ),
    Field(
      'targetCertifications',
      String,
      'Target Certifications',
      hint: 'Future certifications',
    ),
    Field(
      'industryMandates',
      String,
      'Industry Mandates',
      hint: 'Industry-required certs',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Certification process.
  @SectionId('CRSP')
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ], 'Captures the process steps for achieving certification.')
  @Form([
    Field(
      'certificationProcess',
      String,
      'Certification Process',
      hint: 'Steps to get certified',
    ),
    Field(
      'preAssessment',
      String,
      'Pre-Assessment',
      hint: 'Internal assessment first',
    ),
    Field('gapRemediation', String, 'Gap Remediation', hint: 'How to fix gaps'),
    Field(
      'auditorSelection',
      String,
      'Auditor Selection',
      hint: 'How auditors chosen',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? process;

  /// Timeline requirements.
  @SectionId('CRST')
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ], 'Captures the timeline and renewal schedule for certification.')
  @Form([
    Field(
      'certificationTimeline',
      String,
      'Certification Timeline',
      hint: 'Timeline for certification',
    ),
    Field(
      'renewalSchedule',
      String,
      'Renewal Schedule',
      hint: 'When certs must renew',
    ),
    Field(
      'maintenanceRequirements',
      String,
      'Maintenance Requirements',
      hint: 'Ongoing maintenance',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? timeline;

  /// Cost requirements.
  @SectionId('CRSC')
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ], 'Captures the budget and resource requirements for certification.')
  @Form([
    Field(
      'certificationBudget',
      String,
      'Certification Budget',
      hint: 'Budget for certification',
    ),
    Field('ongoingCosts', String, 'Ongoing Costs', hint: 'Recurring costs'),
    Field(
      'resourceRequirements',
      String,
      'Resource Requirements',
      hint: 'Personnel needed',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? costs;

  /// Marketing and notes.
  @SectionId('CRSM')
  @StandardReferences(
    [
      'ISO 9001 — quality management systems',
      'ISO/IEC 27001 — information security management',
    ],
    'Captures how achieved certifications are displayed and used in marketing.',
  )
  @Form([
    Field(
      'certificationDisplay',
      String,
      'Certification Display',
      hint: 'How to display certs',
    ),
    Field('marketingUse', String, 'Marketing Use', hint: 'Use in marketing'),
    Field('notes', String, 'Notes', hint: 'Additional certification notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? marketing;
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
class ComplianceVerificationSection extends DocSpecsSection {
  @Form([
    Field(
      'verificationStrategy',
      String,
      'Verification Strategy',
      hint: 'Overall verification approach',
    ),
    Field(
      'frequencyOfReview',
      String,
      'Review Frequency',
      hint: 'How often to verify',
    ),
    Field(
      'automatedChecks',
      String,
      'Automated Checks',
      hint: 'Automated compliance checks',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Manual review procedures.
  @SectionId('CVSR')
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ], 'Captures the manual review procedures for verifying compliance.')
  @Form([
    Field(
      'manualReviews',
      String,
      'Manual Reviews',
      hint: 'Manual review process',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? review;

  /// Tooling and dashboards.
  @SectionId('CVST')
  @StandardReferences([
    'ISO/IEC 27001 — information security management',
    'ISO 9001 — quality management systems',
  ], 'Captures the tooling and dashboards used to track compliance.')
  @Form([
    Field(
      'complianceTools',
      String,
      'Compliance Tools',
      hint: 'Tools for compliance tracking',
    ),
    Field(
      'dashboards',
      String,
      'Compliance Dashboards',
      hint: 'Compliance dashboards',
    ),
    Field('alerting', String, 'Alerting', hint: 'Compliance alert mechanism'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? tools;

  /// Audit procedures.
  @SectionId('CVSA')
  @StandardReferences(
    [
      'ISO 9001 — quality management systems',
      'ISO/IEC 27001 — information security management',
    ],
    'Captures the internal and external audit procedures for compliance verification.',
  )
  @Form([
    Field(
      'internalAuditProcess',
      String,
      'Internal Audit Process',
      hint: 'Internal audit approach',
    ),
    Field(
      'externalAuditProcess',
      String,
      'External Audit Process',
      hint: 'External audit approach',
    ),
    Field(
      'auditTrail',
      String,
      'Audit Trail',
      hint: 'Audit trail requirements',
    ),
    Field(
      'findingsResolution',
      String,
      'Findings Resolution',
      hint: 'How findings are resolved',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? auditing;

  /// Reporting requirements.
  @SectionId('COVESERE')
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ], 'Captures compliance, management, and regulatory reporting requirements.')
  @Form([
    Field(
      'complianceReporting',
      String,
      'Compliance Reporting',
      hint: 'Reporting requirements',
    ),
    Field(
      'managementReporting',
      String,
      'Management Reporting',
      hint: 'Reports to management',
    ),
    Field(
      'regulatoryReporting',
      String,
      'Regulatory Reporting',
      hint: 'Reports to regulators',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? reporting;

  /// Continuous monitoring and improvement.
  @SectionId('CVSC')
  @StandardReferences([
    'ISO 9001 — quality management systems',
    'ISO/IEC 27001 — information security management',
  ], 'Captures continuous monitoring and improvement of compliance posture.')
  @Form([
    Field(
      'continuousMonitoring',
      String,
      'Continuous Monitoring',
      hint: 'Ongoing monitoring',
    ),
    Field(
      'improvementProcess',
      String,
      'Improvement Process',
      hint: 'Continuous improvement',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional compliance verification notes',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? continuous;
}

/// 8.4. Hardware Concept Requirements.
@DetailedIn(D06ArchitectureTechnologySpecification)
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
class HardwareRequirements extends DocSpecsSection {
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
  @override
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
class ServerRequirementsSection extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of server infrastructure strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Server environment tiers (dev, staging, production, DR).
  @StandardReferences([
    'IaaS / cloud infrastructure — server provisioning',
  ], 'The server environments the system is deployed to.')
  @SectionId('SEENEN-ENVI-LST')
  @SectionIdPattern('SEENEN-ENVI-xxx')
  @ContentHelp('Add one entry per server environment.')
  @SerializationOrder(2)
  List<ServerEnvironmentEntry> environments = [];

  /// Server role definitions (app server, db server, web server).
  @StandardReferences([
    'ISO/IEC/IEEE 42010 — architecture description',
  ], 'The server roles that make up the deployment.')
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
  HighAvailabilityRequirements highAvailability =
      HighAvailabilityRequirements();

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
class ServerEnvironmentEntry extends DocSpecsSection {
  @Form([
    Field(
      'environmentName',
      String,
      'Environment Name',
      required: true,
      hint: 'E.g., Development, Staging, Production',
    ),
    Field(
      'environmentType',
      String,
      'Environment Type',
      hint: 'Development, QA, UAT, Staging, Production, DR',
    ),
    Field(
      'environmentCode',
      String,
      'Environment Code',
      hint: 'dev, stg, prod, dr',
    ),
    Field(
      'purpose',
      String,
      'Purpose',
      hint: 'Primary purpose of this environment',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Location details.
  @SectionId('SEEL')
  @StandardReferences(
    [
      'TIA-942 — data center infrastructure',
      'IaaS / cloud infrastructure — server provisioning',
    ],
    'Captures the region, data center, and availability zone for a server environment.',
  )
  @Form([
    Field('region', String, 'Region', hint: 'Geographic region'),
    Field('dataCenter', String, 'Data Center', hint: 'Data center location'),
    Field(
      'availabilityZone',
      String,
      'Availability Zone',
      hint: 'Availability zone',
    ),
    Field('cloudRegion', String, 'Cloud Region', hint: 'Cloud provider region'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? location;

  /// Scale expectations.
  @SectionId('SEES')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the server count, expected users, and load for a server environment.',
  )
  @Form([
    Field(
      'serverCount',
      int,
      'Server Count',
      hint: 'Number of servers in environment',
    ),
    Field(
      'expectedUsers',
      String,
      'Expected Users',
      hint: 'Concurrent users expected',
    ),
    Field('expectedLoad', String, 'Expected Load', hint: 'Requests per second'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? scale;

  /// Access rules.
  @SectionId('SEEA')
  @StandardReferences(
    ['ISO/IEC 27033 — network / infrastructure security'],
    'Captures the access restrictions, network segment, and VPN requirements for a server environment.',
  )
  @Form([
    Field(
      'accessRestrictions',
      String,
      'Access Restrictions',
      hint: 'Who can access this environment',
    ),
    Field(
      'networkSegment',
      String,
      'Network Segment',
      hint: 'VPC/network segment',
    ),
    Field('vpnRequired', bool, 'VPN Required', hint: 'VPN access required'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? access;

  /// Lifecycle rules.
  @SectionId('SEENENLI')
  @StandardReferences(
    [
      'IaaS / cloud infrastructure — server provisioning',
      'Twelve-Factor App — cloud-native deployment',
    ],
    'Captures the refresh schedule and retention policy for a server environment.',
  )
  @Form([
    Field(
      'refreshSchedule',
      String,
      'Refresh Schedule',
      hint: 'Data refresh schedule',
    ),
    Field(
      'retentionPolicy',
      String,
      'Retention Policy',
      hint: 'Data retention policy',
    ),
    Field('notes', String, 'Notes', hint: 'Additional environment notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? lifecycle;
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
class ServerRoleEntry extends DocSpecsSection {
  @Form([
    Field(
      'roleName',
      String,
      'Role Name',
      required: true,
      hint: 'E.g., Application Server, Database Server',
    ),
    Field(
      'roleType',
      String,
      'Role Type',
      hint: 'App, Web, Database, Cache, Queue, Gateway',
    ),
    Field(
      'roleAbbreviation',
      String,
      'Abbreviation',
      hint: 'Short code for role',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Software stack details.
  @SectionId('SRES')
  @StandardReferences([
    'ISO/IEC/IEEE 42010 — architecture description',
    'C4 model — deployment diagrams',
  ], 'Captures the software stack, runtime, and OS for a server role.')
  @Form([
    Field(
      'softwareStack',
      String,
      'Software Stack',
      hint: 'Software installed on this server',
    ),
    Field(
      'runtimeEnvironment',
      String,
      'Runtime Environment',
      hint: 'JVM, Node.js, .NET, Python',
    ),
    Field(
      'osType',
      String,
      'Operating System',
      hint: 'Linux distro, Windows Server',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? software;

  /// Capacity requirements.
  @SectionId('SREC')
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ], 'Captures the CPU architecture and memory sizing for a server role.')
  @Form([
    Field('cpuArchitecture', String, 'CPU Architecture', hint: 'x64, ARM64'),
    Field('minMemoryGb', int, 'Minimum Memory (GB)', hint: 'Minimum RAM in GB'),
    Field(
      'recommendedMemoryGb',
      int,
      'Recommended Memory (GB)',
      hint: 'Recommended RAM in GB',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? capacity;

  /// Storage requirements.
  @SectionId('SEROENST')
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'TIA-942 — data center infrastructure',
  ], 'Captures the storage type, capacity, and IOPS for a server role.')
  @Form([
    Field('storageType', String, 'Storage Type', hint: 'SSD, HDD, NVMe'),
    Field(
      'storageCapacityGb',
      int,
      'Storage Capacity (GB)',
      hint: 'Required storage in GB',
    ),
    Field(
      'iopsRequired',
      int,
      'IOPS Required',
      hint: 'Required I/O operations per second',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? storage;

  /// Networking requirements.
  @SectionId('SREN')
  @StandardReferences([
    'ISO/IEC 27033 — network / infrastructure security',
    'C4 model — deployment diagrams',
  ], 'Captures the network bandwidth and exposed ports for a server role.')
  @Form([
    Field(
      'networkBandwidth',
      String,
      'Network Bandwidth',
      hint: 'Required network bandwidth',
    ),
    Field(
      'exposedPorts',
      String,
      'Exposed Ports',
      hint: 'Ports exposed by this server',
    ),
    Field('notes', String, 'Notes', hint: 'Additional server role notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? networking;
}

/// Compute resource requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency / resource utilization'],
  'Captures the CPU core, architecture, and benchmark requirements for server compute.',
)
@SectionId('CORERE')
class ComputeResourceRequirements extends DocSpecsSection {
  @Form([
    Field(
      'minCpuCores',
      String,
      'Minimum CPU Cores',
      hint: 'Total minimum CPU cores',
    ),
    Field(
      'recommendedCpuCores',
      String,
      'Recommended CPU Cores',
      hint: 'Recommended CPU cores',
    ),
    Field(
      'cpuArchitecture',
      String,
      'CPU Architecture',
      hint: 'x64, ARM64, or both',
    ),
    Field(
      'cpuGeneration',
      String,
      'CPU Generation',
      hint: 'Intel Xeon, AMD EPYC',
    ),
    Field(
      'specIntBenchmark',
      String,
      'SPECint Benchmark',
      hint: 'Minimum SPECint score',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Memory requirements.
  @SectionId('CRRM')
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ], 'Captures the server memory sizing, type, and ECC requirements.')
  @Form([
    Field(
      'minMemoryGb',
      String,
      'Minimum Memory (GB)',
      hint: 'Total minimum RAM',
    ),
    Field(
      'recommendedMemoryGb',
      String,
      'Recommended Memory (GB)',
      hint: 'Recommended RAM',
    ),
    Field('memoryType', String, 'Memory Type', hint: 'DDR4, DDR5'),
    Field('eccRequired', bool, 'ECC Required', hint: 'Error-correcting memory'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? memory;

  /// GPU requirements.
  @SectionId('CRRG')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the GPU type, memory, and count required for compute-intensive workloads.',
  )
  @Form([
    Field('gpuRequired', bool, 'GPU Required', hint: 'GPU computation needed'),
    Field('gpuType', String, 'GPU Type', hint: 'NVIDIA A100, T4, etc.'),
    Field('gpuMemoryGb', int, 'GPU Memory (GB)', hint: 'GPU memory required'),
    Field('gpuCount', int, 'GPU Count', hint: 'Number of GPUs'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? gpu;

  /// Special hardware requirements.
  @SectionId('CRRS')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency / resource utilization',
      'ISO/IEC 27033 — network / infrastructure security',
    ],
    'Captures special hardware needs such as TPM and secure enclave requirements.',
  )
  @Form([
    Field('tpmRequired', bool, 'TPM Required', hint: 'Trusted Platform Module'),
    Field(
      'secureEnclaveRequired',
      bool,
      'Secure Enclave Required',
      hint: 'SGX or similar',
    ),
    Field('notes', String, 'Notes', hint: 'Additional compute notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? special;
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
class ServerStorageRequirements extends DocSpecsSection {
  @Form([
    Field(
      'primaryStorageType',
      String,
      'Primary Storage Type',
      hint: 'SSD, NVMe, HDD',
    ),
    Field(
      'primaryStorageCapacity',
      String,
      'Primary Storage Capacity',
      hint: 'Total primary storage',
    ),
    Field('primaryIops', String, 'Primary IOPS', hint: 'Required IOPS'),
    Field(
      'readWriteRatio',
      String,
      'Read/Write Ratio',
      hint: 'Expected R/W ratio',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Database storage requirements.
  @SectionId('SSRD')
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'TIA-942 — data center infrastructure',
  ], 'Captures the database storage type, capacity, and IOPS requirements.')
  @Form([
    Field(
      'databaseStorageType',
      String,
      'Database Storage Type',
      hint: 'Storage for databases',
    ),
    Field(
      'databaseStorageCapacity',
      String,
      'Database Storage Capacity',
      hint: 'Database storage size',
    ),
    Field('databaseIops', String, 'Database IOPS', hint: 'Database IOPS'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? database;

  /// File storage requirements.
  @SectionId('SSRFS')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency / resource utilization',
      'TIA-942 — data center infrastructure',
    ],
    'Captures the file storage type, capacity, and network file system requirements.',
  )
  @Form([
    Field(
      'fileStorageType',
      String,
      'File Storage Type',
      hint: 'NAS, SAN, object storage',
    ),
    Field(
      'fileStorageCapacity',
      String,
      'File Storage Capacity',
      hint: 'File storage size',
    ),
    Field(
      'networkFileSystem',
      String,
      'Network File System',
      hint: 'NFS, SMB, etc.',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? fileStorage;

  /// Backup storage requirements.
  @SectionId('SSRB')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency / resource utilization',
      'TIA-942 — data center infrastructure',
    ],
    'Captures the backup storage medium, capacity, and retention requirements.',
  )
  @Form([
    Field(
      'backupStorageType',
      String,
      'Backup Storage Type',
      hint: 'Backup storage medium',
    ),
    Field(
      'backupStorageCapacity',
      String,
      'Backup Storage Capacity',
      hint: 'Backup storage size',
    ),
    Field(
      'backupRetention',
      String,
      'Backup Retention',
      hint: 'Retention period',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? backup;

  /// Performance requirements and notes.
  @SectionId('SSRP')
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ], 'Captures the storage throughput and latency performance requirements.')
  @Form([
    Field(
      'throughputRequired',
      String,
      'Throughput Required',
      hint: 'MB/s throughput',
    ),
    Field(
      'latencyRequirement',
      String,
      'Latency Requirement',
      hint: 'Maximum latency',
    ),
    Field('notes', String, 'Notes', hint: 'Additional storage notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? performance;
}

/// Load profile requirements.
@StandardReferences([
  'ISO/IEC 25010 — performance efficiency / resource utilization',
], 'Captures the user and load profile that sizes the server capacity plan.')
@SectionId('LOPRRE')
class LoadProfileRequirements extends DocSpecsSection {
  @Form([
    Field(
      'peakConcurrentUsers',
      String,
      'Peak Concurrent Users',
      hint: 'Maximum concurrent users',
    ),
    Field(
      'averageConcurrentUsers',
      String,
      'Average Concurrent Users',
      hint: 'Typical concurrent users',
    ),
    Field(
      'totalRegisteredUsers',
      String,
      'Total Registered Users',
      hint: 'Total user base',
    ),
    Field(
      'userGrowthRate',
      String,
      'User Growth Rate',
      hint: 'Expected growth %/year',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Request volume assumptions.
  @SectionId('LPRRL')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the request-rate and payload-size assumptions that drive server load.',
  )
  @Form([
    Field(
      'peakRequestsPerSecond',
      String,
      'Peak Requests/Second',
      hint: 'Maximum RPS',
    ),
    Field(
      'averageRequestsPerSecond',
      String,
      'Average Requests/Second',
      hint: 'Typical RPS',
    ),
    Field(
      'requestSizeAverage',
      String,
      'Average Request Size',
      hint: 'Average payload size',
    ),
    Field(
      'responseSizeAverage',
      String,
      'Average Response Size',
      hint: 'Average response size',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? requestLoad;

  /// Temporal and seasonal patterns.
  @SectionId('LPRP')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the temporal, seasonal, and event-driven load patterns for capacity planning.',
  )
  @Form([
    Field('peakHours', String, 'Peak Hours', hint: 'Time of day for peak load'),
    Field('peakDays', String, 'Peak Days', hint: 'Days of week for peak load'),
    Field(
      'seasonalPatterns',
      String,
      'Seasonal Patterns',
      hint: 'Seasonal variations',
    ),
    Field(
      'eventDrivenSpikes',
      String,
      'Event-Driven Spikes',
      hint: 'Known spike events',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? patterns;

  /// Performance target metrics.
  @SectionId('LPRPT')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the response-time percentile targets that the server tier must meet.',
  )
  @Form([
    Field(
      'responseTimeP50',
      String,
      'Response Time P50',
      hint: '50th percentile latency',
    ),
    Field(
      'responseTimeP95',
      String,
      'Response Time P95',
      hint: '95th percentile latency',
    ),
    Field(
      'responseTimeP99',
      String,
      'Response Time P99',
      hint: '99th percentile latency',
    ),
    Field('notes', String, 'Notes', hint: 'Additional load profile notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? performanceTargets;
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
class ScalingRequirements extends DocSpecsSection {
  @Form([
    Field(
      'scalingStrategy',
      String,
      'Scaling Strategy',
      hint: 'Horizontal, Vertical, Both',
    ),
    Field(
      'scalingApproach',
      String,
      'Scaling Approach',
      hint: 'Manual, Auto, Scheduled',
    ),
    Field(
      'scalingTriggers',
      String,
      'Scaling Triggers',
      hint: 'What triggers scaling',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Horizontal scaling configuration.
  @SectionId('SCREHO')
  @StandardReferences(
    [
      'IaaS / cloud infrastructure — server provisioning',
      'Twelve-Factor App — cloud-native deployment',
    ],
    'Captures the horizontal-scaling instance bounds, startup time, and session handling.',
  )
  @Form([
    Field(
      'minInstances',
      int,
      'Minimum Instances',
      hint: 'Minimum server count',
    ),
    Field(
      'maxInstances',
      int,
      'Maximum Instances',
      hint: 'Maximum server count',
    ),
    Field(
      'instanceStartupTime',
      String,
      'Instance Startup Time',
      hint: 'Time to add capacity',
    ),
    Field(
      'sessionHandling',
      String,
      'Session Handling',
      hint: 'Sticky, distributed',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? horizontal;

  /// Vertical scaling configuration.
  @SectionId('SCREVE')
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency / resource utilization',
    'IaaS / cloud infrastructure — server provisioning',
  ], 'Captures the vertical-scaling limits for CPU and memory upgrades.')
  @Form([
    Field(
      'canVerticallyScale',
      bool,
      'Can Vertically Scale',
      hint: 'Allow CPU/RAM increases',
    ),
    Field('maxCpuCores', int, 'Max CPU Cores', hint: 'Maximum CPU cores'),
    Field('maxMemoryGb', int, 'Max Memory (GB)', hint: 'Maximum RAM'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? vertical;

  /// Auto-scaling thresholds.
  @SectionId('SRAS')
  @StandardReferences([
    'IaaS / cloud infrastructure — server provisioning',
    'Twelve-Factor App — cloud-native deployment',
  ], 'Captures the auto-scaling thresholds, cooldown, and scale-down policy.')
  @Form([
    Field(
      'cpuThresholdScale',
      String,
      'CPU Scale Threshold',
      hint: 'CPU % to trigger scale',
    ),
    Field(
      'memoryThresholdScale',
      String,
      'Memory Scale Threshold',
      hint: 'Memory % to trigger scale',
    ),
    Field(
      'cooldownPeriod',
      String,
      'Cooldown Period',
      hint: 'Time between scale events',
    ),
    Field(
      'scaleDownPolicy',
      String,
      'Scale Down Policy',
      hint: 'How to scale down',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? autoScaling;

  /// Budget and timing constraints.
  @SectionId('SCRECO')
  @StandardReferences([
    'IaaS / cloud infrastructure — server provisioning',
    'Twelve-Factor App — cloud-native deployment',
  ], 'Captures the budget and timing constraints that bound scaling decisions.')
  @Form([
    Field(
      'budgetConstraint',
      String,
      'Budget Constraint',
      hint: 'Cost limits for scaling',
    ),
    Field(
      'scalingWindow',
      String,
      'Scaling Window',
      hint: 'When scaling is allowed',
    ),
    Field('notes', String, 'Notes', hint: 'Additional scaling notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? constraints;
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
class HighAvailabilityRequirements extends DocSpecsSection {
  @Form([
    Field(
      'availabilityTarget',
      String,
      'Availability Target',
      hint: '99.9%, 99.99%, etc.',
    ),
    Field(
      'downtimeBudgetMonthly',
      String,
      'Monthly Downtime Budget',
      hint: 'Allowed downtime/month',
    ),
    Field(
      'plannedMaintenanceWindow',
      String,
      'Planned Maintenance Window',
      hint: 'When maintenance allowed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Redundancy model.
  @SectionId('HARR')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency / resource utilization',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the redundancy level, scope, and geographic/active-active model for resilience.',
  )
  @Form([
    Field('redundancyLevel', String, 'Redundancy Level', hint: 'N+1, 2N, etc.'),
    Field(
      'redundancyScope',
      String,
      'Redundancy Scope',
      hint: 'Server, rack, datacenter',
    ),
    Field(
      'geographicRedundancy',
      bool,
      'Geographic Redundancy',
      hint: 'Multi-region deployment',
    ),
    Field(
      'activeActiveMode',
      bool,
      'Active-Active Mode',
      hint: 'All sites active',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? redundancy;

  /// Failover behavior.
  @SectionId('HARF')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency / resource utilization',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the failover type, timing, failback procedure, and health-check interval.',
  )
  @Form([
    Field('failoverType', String, 'Failover Type', hint: 'Automatic, manual'),
    Field(
      'failoverTime',
      String,
      'Failover Time',
      hint: 'Maximum failover time',
    ),
    Field(
      'failbackProcedure',
      String,
      'Failback Procedure',
      hint: 'How to restore primary',
    ),
    Field(
      'healthCheckInterval',
      String,
      'Health Check Interval',
      hint: 'How often to check health',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? failover;

  /// Load balancing behavior.
  @SectionId('HARLB')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency / resource utilization',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the load-balancer type, algorithm, and health-check behavior for high availability.',
  )
  @Form([
    Field(
      'loadBalancerType',
      String,
      'Load Balancer Type',
      hint: 'L4, L7, DNS-based',
    ),
    Field(
      'loadBalancingAlgorithm',
      String,
      'Load Balancing Algorithm',
      hint: 'Round-robin, least-conn',
    ),
    Field(
      'healthCheckEndpoint',
      String,
      'Health Check Endpoint',
      hint: 'Endpoint for health checks',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? loadBalancing;

  /// Disaster recovery alignment.
  @SectionId('HARDR')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency / resource utilization',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Captures the disaster-recovery site and replication method that back the high-availability model.',
  )
  @Form([
    Field('drSite', String, 'DR Site', hint: 'Disaster recovery location'),
    Field(
      'drSyncMethod',
      String,
      'DR Sync Method',
      hint: 'Sync or async replication',
    ),
    Field('notes', String, 'Notes', hint: 'Additional HA notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? disasterRecovery;
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
class VirtualizationRequirements extends DocSpecsSection {
  @Form([
    Field(
      'deploymentModel',
      String,
      'Deployment Model',
      hint: 'Bare metal, VM, Container',
    ),
    Field(
      'primaryPlatform',
      String,
      'Primary Platform',
      hint: 'VMware, Docker, Kubernetes',
    ),
    Field(
      'orchestrationPlatform',
      String,
      'Orchestration Platform',
      hint: 'Kubernetes, ECS, etc.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// VM requirements.
  @SectionId('VIREVM')
  @StandardReferences(
    [
      'IaaS / cloud infrastructure — server provisioning',
      'ISO/IEC 25010 — performance efficiency / resource utilization',
    ],
    'Captures the virtual-machine hypervisor, image format, and template requirements.',
  )
  @Form([
    Field(
      'hypervisorType',
      String,
      'Hypervisor Type',
      hint: 'VMware, Hyper-V, KVM',
    ),
    Field('vmImageFormat', String, 'VM Image Format', hint: 'OVA, AMI, VHD'),
    Field(
      'vmTemplateRequired',
      bool,
      'VM Template Required',
      hint: 'Golden image needed',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? vm;

  /// Container requirements.
  @SectionId('VIRECO')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native deployment',
      'IaaS / cloud infrastructure — server provisioning',
    ],
    'Captures the container runtime, base image, registry, and image-scanning requirements.',
  )
  @Form([
    Field(
      'containerRuntime',
      String,
      'Container Runtime',
      hint: 'Docker, containerd, CRI-O',
    ),
    Field('baseImage', String, 'Base Image', hint: 'Base container image'),
    Field('registryUrl', String, 'Registry URL', hint: 'Container registry'),
    Field(
      'imageScanningRequired',
      bool,
      'Image Scanning Required',
      hint: 'Security scanning',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? container;

  /// Kubernetes requirements.
  @SectionId('VIREKU')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native deployment',
      'IaaS / cloud infrastructure — server provisioning',
    ],
    'Captures the Kubernetes version, distribution, namespace strategy, and resource quotas.',
  )
  @Form([
    Field(
      'k8sVersion',
      String,
      'Kubernetes Version',
      hint: 'Required K8s version',
    ),
    Field(
      'k8sDistribution',
      String,
      'Kubernetes Distribution',
      hint: 'EKS, GKE, AKS, OpenShift',
    ),
    Field(
      'namespaceStrategy',
      String,
      'Namespace Strategy',
      hint: 'Per-env, per-service',
    ),
    Field(
      'resourceQuotas',
      String,
      'Resource Quotas',
      hint: 'CPU/memory limits',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? kubernetes;

  /// Networking requirements.
  @SectionId('VIRENE')
  @StandardReferences(
    [
      'ISO/IEC 27033 — network / infrastructure security',
      'C4 model — deployment diagrams',
    ],
    'Captures the virtualization networking layer such as service mesh and ingress control.',
  )
  @Form([
    Field('serviceMesh', String, 'Service Mesh', hint: 'Istio, Linkerd'),
    Field(
      'ingressController',
      String,
      'Ingress Controller',
      hint: 'NGINX, Traefik',
    ),
    Field('notes', String, 'Notes', hint: 'Additional virtualization notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? networking;
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
class CloudProviderRequirements extends DocSpecsSection {
  @Form([
    Field(
      'primaryProvider',
      String,
      'Primary Cloud Provider',
      hint: 'AWS, Azure, GCP, Private',
    ),
    Field(
      'secondaryProvider',
      String,
      'Secondary Provider',
      hint: 'Multi-cloud backup',
    ),
    Field(
      'multiCloudStrategy',
      String,
      'Multi-Cloud Strategy',
      hint: 'Hybrid, Multi-cloud',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Account-structure requirements.
  @SectionId('CPRA')
  @StandardReferences(
    [
      'IaaS / cloud infrastructure — server provisioning',
      'Twelve-Factor App — cloud-native deployment',
    ],
    'Captures the cloud account structure, environment separation, and billing model.',
  )
  @Form([
    Field(
      'accountStructure',
      String,
      'Account Structure',
      hint: 'Org structure',
    ),
    Field(
      'environmentSeparation',
      String,
      'Environment Separation',
      hint: 'By account, VPC, etc.',
    ),
    Field(
      'billingModel',
      String,
      'Billing Model',
      hint: 'Pay-as-you-go, reserved',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? accounts;

  /// Service requirements.
  @SectionId('CPRS')
  @StandardReferences(
    [
      'IaaS / cloud infrastructure — server provisioning',
      'Twelve-Factor App — cloud-native deployment',
    ],
    'Captures the cloud provider services required for compute, storage, database, and networking.',
  )
  @Form([
    Field(
      'computeServices',
      String,
      'Compute Services',
      hint: 'EC2, Lambda, etc.',
    ),
    Field('storageServices', String, 'Storage Services', hint: 'S3, EBS, etc.'),
    Field(
      'databaseServices',
      String,
      'Database Services',
      hint: 'RDS, DynamoDB, etc.',
    ),
    Field(
      'networkingServices',
      String,
      'Networking Services',
      hint: 'VPC, Route 53, etc.',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? services;

  /// Compliance requirements.
  @SectionId('CPRC')
  @StandardReferences(
    [
      'ISO/IEC 27033 — network / infrastructure security',
      'IaaS / cloud infrastructure — server provisioning',
    ],
    'Captures cloud compliance requirements such as data sovereignty, certifications, and encryption.',
  )
  @Form([
    Field(
      'dataSovereigntyRequirements',
      String,
      'Data Sovereignty',
      hint: 'Data residency requirements',
    ),
    Field(
      'cloudCompliance',
      String,
      'Cloud Compliance',
      hint: 'SOC 2, FedRAMP, etc.',
    ),
    Field(
      'encryptionRequirements',
      String,
      'Encryption Requirements',
      hint: 'At-rest, in-transit',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? compliance;

  /// Governance requirements.
  @SectionId('CPRG')
  @StandardReferences(
    [
      'IaaS / cloud infrastructure — server provisioning',
      'Twelve-Factor App — cloud-native deployment',
    ],
    'Captures cloud governance requirements such as resource tagging and cost management.',
  )
  @Form([
    Field(
      'taggingStrategy',
      String,
      'Tagging Strategy',
      hint: 'Resource tagging',
    ),
    Field(
      'costManagement',
      String,
      'Cost Management',
      hint: 'Budget alerts, limits',
    ),
    Field('notes', String, 'Notes', hint: 'Additional cloud provider notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? governance;
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
class ServerOsRequirements extends DocSpecsSection {
  @Form([
    Field(
      'primaryOs',
      String,
      'Primary OS',
      required: true,
      hint: 'Linux, Windows Server',
    ),
    Field(
      'osDistribution',
      String,
      'OS Distribution',
      hint: 'Ubuntu, RHEL, CentOS, Debian',
    ),
    Field('osVersion', String, 'OS Version', hint: 'Specific version'),
    Field('supportLevel', String, 'Support Level', hint: 'LTS, Standard'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Hardening requirements.
  @SectionId('SORH')
  @StandardReferences(
    [
      'ISO/IEC 27033 — network / infrastructure security',
      'ISO/IEC 25010 — performance efficiency / resource utilization',
    ],
    'Captures the server operating-system hardening standard, patching cadence, and update policy.',
  )
  @Form([
    Field(
      'hardeningStandard',
      String,
      'Hardening Standard',
      hint: 'CIS, STIG benchmark',
    ),
    Field(
      'patchingFrequency',
      String,
      'Patching Frequency',
      hint: 'How often patched',
    ),
    Field(
      'autoUpdatePolicy',
      String,
      'Auto-Update Policy',
      hint: 'Automatic or manual',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? hardening;

  /// Security controls.
  @SectionId('SORS')
  @StandardReferences(
    [
      'ISO/IEC 27033 — network / infrastructure security',
      'TIA-942 — data center infrastructure',
    ],
    'Captures the server operating-system security controls such as firewall, mandatory access control, and auditing.',
  )
  @Form([
    Field(
      'firewallConfiguration',
      String,
      'Firewall Configuration',
      hint: 'iptables, firewalld',
    ),
    Field(
      'selinuxMode',
      String,
      'SELinux/AppArmor Mode',
      hint: 'Enforcing, permissive',
    ),
    Field(
      'auditdConfiguration',
      String,
      'Auditd Configuration',
      hint: 'Audit logging requirements',
    ),
    Field(
      'antivirusRequired',
      bool,
      'Antivirus Required',
      hint: 'AV/EDR requirement',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? security;

  /// Monitoring setup.
  @SectionId('SORM')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency / resource utilization',
      'ISO/IEC 27033 — network / infrastructure security',
    ],
    'Captures the server operating-system monitoring, logging, and performance-observability setup.',
  )
  @Form([
    Field(
      'loggingConfiguration',
      String,
      'Logging Configuration',
      hint: 'syslog, journald',
    ),
    Field(
      'monitoringAgent',
      String,
      'Monitoring Agent',
      hint: 'Agent for monitoring',
    ),
    Field(
      'performanceMonitoring',
      String,
      'Performance Monitoring',
      hint: 'Performance tools',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? monitoring;

  /// Licensing details.
  @SectionId('SORL')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency / resource utilization',
      'IaaS / cloud infrastructure — server provisioning',
    ],
    'Captures the operating-system licensing model and license counts for servers.',
  )
  @Form([
    Field(
      'licensingModel',
      String,
      'Licensing Model',
      hint: 'Open source, Enterprise',
    ),
    Field('licenseCount', String, 'License Count', hint: 'Number of licenses'),
    Field('notes', String, 'Notes', hint: 'Additional OS notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? licensing;
}

// =============================================================================
// 8.4.2. Client Requirements
// =============================================================================

/// 8.4.2. Client Requirements.
///
/// Two layers that answer two different questions.
///
/// **Which client applications exist** — [clientApplications], one
/// [ClientApplicationEntry] per client, naming its kind, its entry route and
/// the screens it comprises. This is the enumerable set of clients; a client
/// not listed there does not exist.
///
/// **What a user's machine must provide** — every other subsection: browser,
/// desktop-OS, mobile-device, display, network, hardware, accessibility and
/// security minimums. These are deployment constraints on the *environment*,
/// not clients, which is why a client entry *references* them rather than
/// restating them.
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
class ClientRequirementsSection extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of client requirements strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// The client applications the system consists of (CE-CL).
  @StandardReferences([
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — portability / installability',
  ], 'The client applications the system consists of, each with its kind, platform targets, entry route and the screens it comprises.')
  @SectionId('CLIAPP-CLIE-LST')
  @SectionIdPattern('CLIAPP-CLIE-xxx')
  @ContentHelp(
    'Add one entry per client application of the system. A client that is not '
    'listed here does not exist, however thoroughly the requirement '
    'subsections below describe the machines it would run on.',
  )
  @SerializationOrder(2)
  List<ClientApplicationEntry> clientApplications = [];

  /// Web browser requirements.
  @StandardReferences([
    'WHATWG / W3C — web platform / browser standards',
  ], 'The web browsers the client must support.')
  @SectionId('BRREEN-BROW-LST')
  @SectionIdPattern('BRREEN-BROW-xxx')
  @ContentHelp('Add one entry per supported web browser.')
  @SerializationOrder(3)
  List<BrowserRequirementEntry> browserRequirements = [];

  /// Desktop operating system requirements.
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency / resource utilization',
  ], 'The desktop operating systems the client must support.')
  @SectionId('DORE1-DESK-LST')
  @SectionIdPattern('DORE1-DESK-xxx')
  @ContentHelp('Add one entry per supported desktop operating system.')
  @SerializationOrder(4)
  List<DesktopOsRequirementEntry> desktopOsRequirements = [];

  /// Mobile device requirements.
  @StandardReferences([
    'Android CDD / Apple HIG — mobile device platform requirements',
  ], 'The mobile platforms and devices the client must support.')
  @SectionId('MDRE-MOBI-LST')
  @SectionIdPattern('MDRE-MOBI-xxx')
  @ContentHelp('Add one entry per supported mobile platform.')
  @SerializationOrder(5)
  List<MobileDeviceRequirementEntry> mobileRequirements = [];

  /// Display and screen requirements.
  @SerializationOrder(6)
  DisplayRequirements displayRequirements = DisplayRequirements();

  /// Client network requirements.
  @SerializationOrder(7)
  ClientNetworkRequirements networkRequirements = ClientNetworkRequirements();

  /// Client hardware requirements.
  @SerializationOrder(8)
  ClientHardwareRequirements hardwareRequirements =
      ClientHardwareRequirements();

  /// Accessibility requirements for clients.
  @SerializationOrder(9)
  ClientAccessibilityRequirements accessibilityRequirements =
      ClientAccessibilityRequirements();

  /// Progressive Web App (PWA) requirements.
  @SerializationOrder(10)
  PwaRequirements pwaRequirements = PwaRequirements();

  /// Native app requirements.
  @SerializationOrder(11)
  NativeAppRequirements nativeAppRequirements = NativeAppRequirements();

  /// Client security requirements.
  @SerializationOrder(12)
  ClientSecurityRequirements securityRequirements =
      ClientSecurityRequirements();

  /// Per-machine configuration of a client application (CE-CC).
  @SerializationOrder(13)
  ClientConfiguration clientConfiguration = ClientConfiguration();

  /// User-specific settings of a user-owned device (CE-DS).
  @SerializationOrder(14)
  DeviceSettings deviceSettings = DeviceSettings();

  /// Server-persisted settings that follow the user across devices (CE-UP).
  @SerializationOrder(15)
  UserSettings userSettings = UserSettings();
}

/// The kind of a client application (`codespecs_mapping.md` §4.1).
///
/// The kind decides which other CodeSpecs parts the client may carry — a
/// command-line client has no screen elements — so it is a required, closed
/// choice rather than free text.
enum ClientApplicationKind {
  /// A graphical application with screens, forms and navigation.
  graphicalApplication,

  /// A command-line client driven by arguments and standard streams.
  commandLine,

  /// Another server calling this system as a client.
  server,
}

/// A single client application of the system (CE-CL).
///
/// One client: what kind of application it is, which platforms it targets,
/// where it starts, and which screens it comprises. This is the enumeration
/// [ClientRequirementsSection]'s requirement subsections cannot give — they
/// state what a *machine* must provide, which is a deployment constraint on
/// every client rather than a statement that any particular client exists.
///
/// **Platform targets are referenced, never restated.** A client's platform
/// targets are ids already declared in the browser, desktop-OS and
/// mobile-platform requirement lists of the enclosing section. Naming a
/// platform here that no requirement entry declares is a dangling reference,
/// which is the point: the minimum a platform must meet is stated once.
///
/// **Configuration is not restated either.** Which settings a client carries
/// is declared in [ClientConfiguration] (CE-CC), where each setting names the
/// client that owns it. A client that also listed its settings would be the
/// second source those two would eventually disagree through
/// (`codespecs_mapping.md` §11).
///
/// **Screens, not flows.** A client comprises screens; the flows *between*
/// those screens are the screen flow structure's own subject (D09 XDS) and are
/// reached through the entry route, not listed again per client.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description',
    'ISO/IEC 25010 — portability / installability',
  ],
  'A single client application: its identity, kind, platform targets, entry route and constituent screens.',
)
@SectionId('CLIAPP')
@CodeSpecKind(
  [CodeSpecPart.client],
  note:
      'CE-CL — one client application of the system. Active '
      '(codespecs_mapping.md §4.1): @CsClient, client locus. clientId supplies '
      'the marker\'s first positional argument and clientKind its required '
      'kind; platformTargets, entryRoute and includedScreens become members of '
      'the generated descriptor, the entry route as a CsRouteRef. The client\'s '
      'configuration is not declared here — CE-CC settings name their owning '
      'client (codespecs_mapping.md §11).',
)
class ClientApplicationEntry extends DocSpecsSection {
  @ContentHelp('''
One client application of the system.

**The kind is the constraining choice.** A graphical application has screens,
an entry route and platform targets; a command-line client has none of those
and states its invocation in *Purpose* instead; a server client is another
system calling in, and is listed here so the clients of this system are
enumerable in one place.

**Reference, do not restate.** *Platform Targets* holds ids from the browser,
desktop-OS and mobile-platform requirement lists below; *Entry Route* holds a
route id from the screen route map; *Included Screens* holds screen ids. Every
one of them is declared elsewhere — writing the name of something that is not
declared makes the reference dangle.
''')
  @Form([
    Field(
      'clientId',
      String,
      'Client Id',
      required: true,
      hint: 'The one identifier for this client application (e.g. backoffice) '
          '— cited wherever the client is referenced',
    ),
    Field(
      'clientName',
      String,
      'Client Name',
      required: true,
      hint: 'The name users and operators call this client by',
    ),
    Field(
      'clientKind',
      ClientApplicationKind,
      'Client Kind',
      required: true,
      hint: 'What kind of application this client is — decides which other '
          'parts it can carry (a command-line client has no screens)',
    ),
    Field(
      'purpose',
      String,
      'Purpose',
      required: true,
      hint: 'Who uses this client and what for — the reason it exists '
          'separately from the system\'s other clients',
    ),
    Field(
      'platformTargets',
      String,
      'Platform Targets',
      refersTo: [
        'BROREQENT.browserName',
        'DEOSREEN.osName',
        'MODEREEN.platform',
      ],
      hint: 'The platforms this client runs on, by id from the browser, '
          'desktop-OS and mobile-platform requirement lists below',
    ),
    Field(
      'entryRoute',
      String,
      'Entry Route',
      refersTo: ['SCRTEN.routeId'],
      hint: 'The route this client opens on, by id from the screen route map. '
          'Empty for a client with no routes',
    ),
    Field(
      'includedScreens',
      String,
      'Included Screens',
      refersTo: ['SCREN.screenId'],
      hint: 'The screens this client comprises, by id. Empty for a client '
          'with no screens',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Client configuration — per-machine settings of a client application (CE-CC).
///
/// Distinct from server/system configuration ([SystemConfigurationManagement],
/// CE-CF) and from a user's preferences (CE-UP): this is the configuration a
/// specific *install* of a client app on a *specific machine* carries, keyed by
/// the (client app, machine) pair. Two installs of the same client on two
/// machines have independent client configuration (`codespecs_mapping.md` §11).
@StandardReferences(
  [
    'Twelve-Factor App — config stored in the environment, per deployment',
    'ISO/IEC 25010 — portability / installability',
  ],
  'The per-machine configuration of a client application install — endpoints, device options, and per-install toggles keyed by (client app, machine).',
)
@SectionId('CLICON')
@CodeSpecKind(
  [CodeSpecPart.clientConfiguration],
  note:
      'CE-CC — per-machine client-app settings, keyed by (client app, '
      'machine); distinct from CE-CF server config and CE-UP user settings.',
)
class ClientConfiguration extends DocSpecsSection {
  @ContentHelp('''
Summarise how this client application is configured per install — which
categories of setting exist, which are shipped as defaults in the app's
configuration resources, and which an operator or user may override on a
given machine.

Declare the individual settings in the list below; keep this overview to
the shape and the policy.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// The declared client configuration settings.
  @StandardReferences([
    'Twelve-Factor App — config stored in the environment, per deployment',
    'ISO/IEC 25010 — portability / installability',
  ], 'The client configuration settings declared by the system\'s client applications, one entry per key.')
  @SectionId('CCSET-SETT-LST')
  @SectionIdPattern('CCSET-SETT-xxx')
  @ContentHelp(
    'Add one entry per client configuration setting, naming the client '
    'application that declares it. Declare the setting — '
    'key, value type and default — never its value on a particular machine: '
    'the value comes from the app configuration resources or this install\'s '
    'persisted overrides. Typical keys: api.baseUrl, app.environment, '
    'app.updateChannel, device.options, feature.<name>.',
  )
  @SerializationOrder(1)
  List<ClientConfigurationSettingEntry> settings = [];
}

/// A single declared client configuration setting (CE-CC).
///
/// The declaration only: key, value type, default, and which narrower scopes
/// may shadow the key. The *value* is never authored — it comes from the client
/// app's configuration resources or from this install's persisted overrides
/// (`codespecs_mapping.md` §5.16).
@StandardReferences(
  [
    'Twelve-Factor App — config stored in the environment, per deployment',
    'ISO/IEC 25010 — portability / installability',
  ],
  'Declares one client configuration setting: its key, value type, default, and which narrower scopes may shadow it.',
)
@SectionId('CCSET')
class ClientConfigurationSettingEntry extends DocSpecsSection {
  @Form([
    Field(
      'settingKey',
      String,
      'Setting Key',
      required: true,
      hint: 'The dotted key of the client setting, e.g. api.baseUrl',
    ),
    Field(
      'client',
      String,
      'Client',
      refersTo: ['CLIAPP.clientId'],
      hint: 'The client application that declares this setting, by id. CE-CC '
          'is keyed by (client app, machine), so the owning client is part of '
          'the key. Empty where the system has a single client',
    ),
    Field(
      'valueType',
      String,
      'Value Type',
      hint: 'string / int / double / bool / enum',
    ),
    Field(
      'defaultValue',
      String,
      'Default Value',
      hint:
          'The value used until the app configuration resources or an '
          'install-local override supply one',
    ),
    Field(
      'overridableBy',
      String,
      'Overridable By',
      required: true,
      hint:
          'The narrowest scope permitted to shadow this key — every scope in '
          'between is opened too: none (scope-pinned) / user / device. No '
          'default: pinning a key must be authored, not fallen into',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Device settings — user-specific settings of a user-owned device (CE-DS).
///
/// Distinct from client configuration ([ClientConfiguration], CE-CC — no user
/// identity in the key) and from user settings (CE-UP — server-persisted,
/// follow the user): a device setting is keyed by the (user, device) pair and
/// persisted on the device itself (window layout, last-opened items,
/// machine-local cache preferences). The same user gets independent values on
/// each device; another user on the same device gets their own values
/// (`codespecs_mapping.md` §11).
@StandardReferences(
  [
    'ISO 9241-110 — suitability for individualization (user-tailored settings)',
    'ISO/IEC 25010 — usability / operability',
  ],
  'The user-specific settings of a user-owned device — window layout, last-opened items, and machine-local preferences keyed by (user, device) and persisted on the device.',
)
@SectionId('DEVSET')
@CodeSpecKind(
  [CodeSpecPart.deviceSettings],
  note:
      'CE-DS — user-specific device settings, keyed by (user, device) and '
      'persisted on the device; distinct from CE-CC client configuration '
      '(no user in the key) and CE-UP user settings (follow the user).',
)
class DeviceSettings extends DocSpecsSection {
  @ContentHelp('''
Summarise which settings this system keeps per (user, device) rather than
per user — the ones that describe how *this* machine is set up and would be
wrong to carry to another one.

Declare the individual settings in the list below; keep this overview to the
policy and the reasoning for the device scope.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// The declared device settings.
  @StandardReferences([
    'ISO 9241-110 — suitability for individualization (user-tailored settings)',
    'ISO/IEC 25010 — usability / operability',
  ], 'The device settings declared for this system, one entry per key.')
  @SectionId('DSSET-SETT-LST')
  @SectionIdPattern('DSSET-SETT-xxx')
  @ContentHelp(
    'Add one entry per device setting. Declare the setting — key, value type '
    'and default — never the user\'s chosen value: that lives in the '
    'device-local store. Typical keys: window.layout, editor.fontSize, '
    'recent.files, cache.sizeLimit.',
  )
  @SerializationOrder(1)
  List<DeviceSettingEntry> settings = [];
}

/// A single declared device setting (CE-DS).
///
/// The declaration only: key, value type and default. The value is the user's
/// choice on this device and is never authored (`codespecs_mapping.md` §5.16).
///
/// There is deliberately no shadowing field. §5.16 puts the opt-in on the
/// *wider* scope — a key is shadowable only because its wider-scope declaration
/// says so — and CE-DS is the narrowest scope, so it has nothing below it to
/// open. Declaring the same relation from both ends would be two authored
/// fields that can disagree.
@StandardReferences(
  [
    'ISO 9241-110 — suitability for individualization (user-tailored settings)',
    'ISO/IEC 25010 — usability / operability',
  ],
  'Declares one device setting: its key, value type and default.',
)
@SectionId('DSSET')
class DeviceSettingEntry extends DocSpecsSection {
  @Form([
    Field(
      'settingKey',
      String,
      'Setting Key',
      required: true,
      hint: 'The dotted key of the device setting, e.g. window.layout',
    ),
    Field(
      'valueType',
      String,
      'Value Type',
      hint: 'string / int / double / bool / enum',
    ),
    Field(
      'defaultValue',
      String,
      'Default Value',
      hint: 'The value used until the user changes the setting on this device',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// User settings — server-persisted settings that follow the user (CE-UP).
///
/// Keyed by the user alone: no machine and no device in the key. A user
/// setting is persisted on the server and re-materialised on whichever device
/// the user signs in from, which is what distinguishes it from a device
/// setting ([DeviceSettings], CE-DS — keyed by (user, device), never leaves
/// the device) and from client configuration ([ClientConfiguration], CE-CC —
/// no user identity in the key) (`codespecs_mapping.md` §11).
///
/// The scope is expressed by *which section a setting is declared in*, never
/// by a field on a shared section: there is no persistence discriminator
/// anywhere in the four settings scopes.
@StandardReferences(
  [
    'ISO 9241-110 — suitability for individualization (user-tailored settings)',
    'ISO/IEC 25010 — usability / operability',
  ],
  'The settings that follow a user across devices — theme, language and country, notification preferences and comparable per-user choices, keyed by the user and persisted on the server.',
)
@SectionId('USRSET')
@CodeSpecKind(
  [CodeSpecPart.userSettings],
  note:
      'CE-UP — server-persisted per-user settings, keyed by the user and '
      'restored on any device the user signs into; distinct from CE-DS device '
      'settings (keyed by (user, device), device-local) and CE-CC client '
      'configuration (no user in the key). Realised in both generated client '
      'projects: the client shape in <app>_codespec_client and the persistence '
      'half in <app>_codespec_server (codespecs_mapping.md §4.2/§11).',
)
class UserSettings extends DocSpecsSection {
  @ContentHelp('''
Summarise which settings follow the user rather than the device — the choices
a user expects to find already applied the first time they sign in on a new
machine.

Declare the individual settings in the list below; keep this overview to the
policy, and to how the settings are re-materialised at sign-in.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// The declared user settings.
  @StandardReferences([
    'ISO 9241-110 — suitability for individualization (user-tailored settings)',
    'ISO/IEC 25010 — usability / operability',
  ], 'The user settings declared for this system, one entry per key.')
  @SectionId('USSET-SETT-LST')
  @SectionIdPattern('USSET-SETT-xxx')
  @ContentHelp(
    'Add one entry per user setting. Declare the setting — key, value type '
    'and default — never the user\'s chosen value: that is persisted per user '
    'on the server. Typical keys: ui.theme, ui.language, ui.country, '
    'notifications.<channel>.enabled, list.pageSize.',
  )
  @SerializationOrder(1)
  List<UserSettingEntry> settings = [];
}

/// A single declared user setting (CE-UP).
///
/// The declaration only: key, value type, default, and whether a per-device
/// value may shadow the key. The value is the user's choice and is never
/// authored (`codespecs_mapping.md` §5.16).
@StandardReferences(
  [
    'ISO 9241-110 — suitability for individualization (user-tailored settings)',
    'ISO/IEC 25010 — usability / operability',
  ],
  'Declares one user setting: its key, value type, default, and whether a per-device value may shadow it.',
)
@SectionId('USSET')
class UserSettingEntry extends DocSpecsSection {
  @Form([
    Field(
      'settingKey',
      String,
      'Setting Key',
      required: true,
      hint: 'The dotted key of the user setting, e.g. ui.theme',
    ),
    Field(
      'valueType',
      String,
      'Value Type',
      hint: 'string / int / double / bool / enum',
    ),
    Field(
      'defaultValue',
      String,
      'Default Value',
      hint: 'The value used until the user changes the setting',
    ),
    Field(
      'overridableBy',
      String,
      'Overridable By',
      required: true,
      hint:
          'Whether a per-device value may shadow this key: none (scope-pinned) '
          '/ device. No default: pinning a key must be authored, not fallen '
          'into',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
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
class BrowserRequirementEntry extends DocSpecsSection {
  @Form([
    Field(
      'browserName',
      String,
      'Browser Name',
      required: true,
      hint: 'E.g., Chrome, Firefox, Safari, Edge',
    ),
    Field(
      'browserEngine',
      String,
      'Browser Engine',
      hint: 'Chromium, Gecko, WebKit',
    ),
    Field(
      'minVersion',
      String,
      'Minimum Version',
      required: true,
      hint: 'Minimum supported version',
    ),
    Field(
      'recommendedVersion',
      String,
      'Recommended Version',
      hint: 'Recommended version',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Support level and user share.
  @SectionId('BRES')
  @StandardReferences(
    ['WHATWG / W3C — web platform / browser standards'],
    'Captures the browser support level, priority, and expected user share for the client.',
  )
  @Form([
    Field(
      'supportLevel',
      String,
      'Support Level',
      hint: 'Full, Partial, Best-effort',
    ),
    Field(
      'priority',
      String,
      'Priority',
      hint: 'Primary, Secondary, Edge case',
    ),
    Field(
      'expectedUserShare',
      String,
      'Expected User Share',
      hint: 'Percentage of users',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? support;

  /// Required and optional features.
  @SectionId('BREF')
  @StandardReferences(
    ['WHATWG / W3C — web platform / browser standards'],
    'Captures the required and optional browser platform features such as JS/CSS features, polyfills, and CSS support.',
  )
  @Form([
    Field(
      'requiredFeatures',
      String,
      'Required Features',
      hint: 'JS, CSS features required',
    ),
    Field(
      'optionalFeatures',
      String,
      'Optional Features',
      hint: 'Enhanced features',
    ),
    Field(
      'polyfillsNeeded',
      String,
      'Polyfills Needed',
      hint: 'Required polyfills',
    ),
    Field('cssSupport', String, 'CSS Support', hint: 'CSS features required'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? features;

  /// Testing strategy.
  @SectionId('BRET')
  @StandardReferences(
    [
      'WHATWG / W3C — web platform / browser standards',
      'ISO/IEC 25010 — performance efficiency / resource utilization',
    ],
    'Captures the browser testing strategy such as test platform, automation, and manual testing frequency.',
  )
  @Form([
    Field(
      'testPlatform',
      String,
      'Test Platform',
      hint: 'BrowserStack, Sauce Labs',
    ),
    Field(
      'automatedTesting',
      bool,
      'Automated Testing',
      hint: 'Include in automated tests',
    ),
    Field(
      'manualTestingFrequency',
      String,
      'Manual Testing Frequency',
      hint: 'How often manually tested',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? testing;

  /// Known issues and workarounds.
  @SectionId('BREI')
  @StandardReferences(
    ['WHATWG / W3C — web platform / browser standards'],
    'Captures the browser-specific known limitations and workarounds for the client.',
  )
  @Form([
    Field(
      'knownLimitations',
      String,
      'Known Limitations',
      hint: 'Browser-specific limitations',
    ),
    Field('workarounds', String, 'Workarounds', hint: 'Applied workarounds'),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional browser requirement notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? issues;
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
class DesktopOsRequirementEntry extends DocSpecsSection {
  @Form([
    Field(
      'osName',
      String,
      'Operating System',
      required: true,
      hint: 'E.g., Windows, macOS, Linux',
    ),
    Field('osFamily', String, 'OS Family', hint: 'Windows, macOS, Unix'),
    Field(
      'minVersion',
      String,
      'Minimum Version',
      required: true,
      hint: 'Minimum supported version',
    ),
    Field(
      'recommendedVersion',
      String,
      'Recommended Version',
      hint: 'Recommended version',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Support prioritization.
  @SectionId('DORES')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the desktop OS support prioritization such as support level, priority, and expected user share.',
  )
  @Form([
    Field(
      'supportLevel',
      String,
      'Support Level',
      hint: 'Full, Partial, Best-effort',
    ),
    Field('priority', String, 'Priority', hint: 'Primary, Secondary'),
    Field(
      'expectedUserShare',
      String,
      'Expected User Share',
      hint: 'Percentage of users',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? support;

  /// Hardware and display requirements.
  @SectionId('DORER')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the desktop OS hardware and display requirements such as architecture, RAM, storage, and display driver.',
  )
  @Form([
    Field('architecture', String, 'Architecture', hint: 'x64, ARM64, x86'),
    Field('minRam', String, 'Minimum RAM', hint: 'Minimum RAM required'),
    Field(
      'minStorage',
      String,
      'Minimum Storage',
      hint: 'Free disk space needed',
    ),
    Field(
      'displayDriver',
      String,
      'Display Driver',
      hint: 'Graphics requirements',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? requirements;

  /// Software prerequisites.
  @SectionId('DEOSREENSO')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the desktop OS software prerequisites such as runtime dependencies and additional required software.',
  )
  @Form([
    Field(
      'runtimeDependencies',
      String,
      'Runtime Dependencies',
      hint: 'Required runtimes (.NET, Java)',
    ),
    Field(
      'additionalSoftware',
      String,
      'Additional Software',
      hint: 'Other required software',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? software;

  /// Testing and known issues.
  @SectionId('DORET')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the desktop OS testing environment, automation, and known issues for the client platform.',
  )
  @Form([
    Field(
      'testEnvironment',
      String,
      'Test Environment',
      hint: 'VM, physical, cloud',
    ),
    Field(
      'automatedTesting',
      bool,
      'Automated Testing',
      hint: 'Include in CI/CD',
    ),
    Field('knownIssues', String, 'Known Issues', hint: 'OS-specific issues'),
    Field('notes', String, 'Notes', hint: 'Additional desktop OS notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? testing;
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
class MobileDeviceRequirementEntry extends DocSpecsSection {
  @Form([
    Field(
      'platform',
      String,
      'Platform',
      required: true,
      hint: 'iOS, Android, iPadOS',
    ),
    Field(
      'minOsVersion',
      String,
      'Minimum OS Version',
      required: true,
      hint: 'Minimum OS version',
    ),
    Field(
      'recommendedOsVersion',
      String,
      'Recommended OS Version',
      hint: 'Recommended OS version',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Support prioritization.
  @SectionId('MDRES')
  @StandardReferences(
    ['Android CDD / Apple HIG — mobile device platform requirements'],
    'Captures the mobile device support prioritization such as support level, priority, and expected user share.',
  )
  @Form([
    Field(
      'supportLevel',
      String,
      'Support Level',
      hint: 'Full, Partial, Best-effort',
    ),
    Field('priority', String, 'Priority', hint: 'Primary, Secondary'),
    Field(
      'expectedUserShare',
      String,
      'Expected User Share',
      hint: 'Percentage of users',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? support;

  /// Device coverage.
  @SectionId('MDRED')
  @StandardReferences(
    ['Android CDD / Apple HIG — mobile device platform requirements'],
    'Captures the mobile device coverage such as device types, specific named devices, and supported screen sizes.',
  )
  @Form([
    Field(
      'deviceTypes',
      String,
      'Device Types',
      hint: 'Phone, Tablet, Foldable',
    ),
    Field(
      'specificDevices',
      String,
      'Specific Devices',
      hint: 'Named devices to support',
    ),
    Field(
      'screenSizes',
      String,
      'Screen Sizes',
      hint: 'Supported screen sizes',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? devices;

  /// Hardware expectations.
  @SectionId('MDREH')
  @StandardReferences(
    [
      'Android CDD / Apple HIG — mobile device platform requirements',
      'ISO/IEC 25010 — performance efficiency / resource utilization',
    ],
    'Captures the mobile device hardware expectations such as minimum RAM, storage, required sensors, and hardware acceleration.',
  )
  @Form([
    Field('minRam', String, 'Minimum RAM', hint: 'Minimum device RAM'),
    Field('minStorage', String, 'Minimum Storage', hint: 'Storage for app'),
    Field(
      'requiredSensors',
      String,
      'Required Sensors',
      hint: 'GPS, camera, biometric',
    ),
    Field(
      'hardwareAcceleration',
      bool,
      'Hardware Acceleration',
      hint: 'GPU acceleration needed',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? hardware;

  /// Capability requirements.
  @SectionId('MDREC')
  @StandardReferences(
    ['Android CDD / Apple HIG — mobile device platform requirements'],
    'Captures the mobile device capability requirements such as permissions, background execution, and push notifications.',
  )
  @Form([
    Field(
      'permissionsRequired',
      String,
      'Permissions Required',
      hint: 'Required app permissions',
    ),
    Field(
      'backgroundExecution',
      String,
      'Background Execution',
      hint: 'Background modes needed',
    ),
    Field(
      'pushNotifications',
      bool,
      'Push Notifications',
      hint: 'Push notification support',
    ),
    Field('notes', String, 'Notes', hint: 'Additional mobile device notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? capabilities;
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
class DisplayRequirements extends DocSpecsSection {
  @Form([
    Field(
      'minResolution',
      String,
      'Minimum Resolution',
      hint: '1024x768, 1280x720',
    ),
    Field(
      'recommendedResolution',
      String,
      'Recommended Resolution',
      hint: 'Recommended screen resolution',
    ),
    Field(
      'maxResolution',
      String,
      'Maximum Resolution',
      hint: 'Maximum tested resolution',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Aspect ratio and layout support.
  @SectionId('DIRELA')
  @StandardReferences(
    ['ISO 9241 — ergonomics of human-system interaction'],
    'Captures the client display layout support such as aspect ratios, responsive breakpoints, and fluid layout.',
  )
  @Form([
    Field(
      'supportedAspectRatios',
      String,
      'Supported Aspect Ratios',
      hint: '16:9, 4:3, 21:9',
    ),
    Field(
      'responsiveBreakpoints',
      String,
      'Responsive Breakpoints',
      hint: 'Mobile, tablet, desktop',
    ),
    Field('fluidLayout', bool, 'Fluid Layout', hint: 'Supports fluid layouts'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? layout;

  /// DPI and scaling support.
  @SectionId('DIRESC')
  @StandardReferences(
    ['ISO 9241 — ergonomics of human-system interaction'],
    'Captures the client display DPI and scaling support such as minimum DPI, HiDPI, scaling factors, and vector graphics.',
  )
  @Form([
    Field('minDpi', String, 'Minimum DPI', hint: 'Minimum display DPI'),
    Field('hiDpiSupport', bool, 'HiDPI Support', hint: 'Retina/HiDPI support'),
    Field(
      'scalingFactors',
      String,
      'Scaling Factors',
      hint: '100%, 125%, 150%, 200%',
    ),
    Field(
      'vectorGraphics',
      bool,
      'Vector Graphics',
      hint: 'SVG/vector support',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? scaling;

  /// Color and contrast support.
  @SectionId('DIREC1')
  @StandardReferences(
    [
      'ISO 9241 — ergonomics of human-system interaction',
      'WCAG 2.2 — accessible client experience',
    ],
    'Captures the client display color and contrast support such as color depth, color space, dark mode, and high contrast.',
  )
  @Form([
    Field('colorDepth', String, 'Color Depth', hint: '24-bit, 32-bit'),
    Field(
      'colorSpaceSupport',
      String,
      'Color Space Support',
      hint: 'sRGB, P3, HDR',
    ),
    Field(
      'darkModeSupport',
      bool,
      'Dark Mode Support',
      hint: 'Dark mode theme support',
    ),
    Field(
      'highContrastSupport',
      bool,
      'High Contrast Support',
      hint: 'High contrast mode',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? color;

  /// Multi-display support.
  @SectionId('DRMD')
  @StandardReferences(
    ['ISO 9241 — ergonomics of human-system interaction'],
    'Captures the client multi-display support such as multi-monitor and projector/presentation modes.',
  )
  @Form([
    Field(
      'multiMonitorSupport',
      bool,
      'Multi-Monitor Support',
      hint: 'Multiple display support',
    ),
    Field(
      'projectorMode',
      String,
      'Projector/Presentation Mode',
      hint: 'Presentation display mode',
    ),
    Field('notes', String, 'Notes', hint: 'Additional display notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? multiDisplay;
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
class ClientNetworkRequirements extends DocSpecsSection {
  @Form([
    Field(
      'minDownloadSpeed',
      String,
      'Minimum Download Speed',
      hint: 'Minimum download Mbps',
    ),
    Field(
      'recommendedDownloadSpeed',
      String,
      'Recommended Download Speed',
      hint: 'Recommended download Mbps',
    ),
    Field(
      'minUploadSpeed',
      String,
      'Minimum Upload Speed',
      hint: 'Minimum upload Mbps',
    ),
    Field(
      'peakBandwidthUsage',
      String,
      'Peak Bandwidth Usage',
      hint: 'Maximum bandwidth consumed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Latency requirements.
  @SectionId('CNRL')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the client network latency requirements such as maximum latency, recommended latency, and jitter tolerance.',
  )
  @Form([
    Field(
      'maxLatency',
      String,
      'Maximum Latency',
      hint: 'Maximum acceptable latency',
    ),
    Field(
      'recommendedLatency',
      String,
      'Recommended Latency',
      hint: 'Recommended latency',
    ),
    Field(
      'jitterTolerance',
      String,
      'Jitter Tolerance',
      hint: 'Network jitter tolerance',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? latency;

  /// Connection-type requirements.
  @SectionId('CNRC')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the client connection-type requirements such as supported networks, offline capability, and low-bandwidth mode.',
  )
  @Form([
    Field(
      'connectionTypes',
      String,
      'Connection Types',
      hint: 'WiFi, Ethernet, Cellular',
    ),
    Field(
      'offlineCapability',
      String,
      'Offline Capability',
      hint: 'Offline mode support',
    ),
    Field(
      'lowBandwidthMode',
      String,
      'Low Bandwidth Mode',
      hint: 'Degraded mode for slow connections',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? connection;

  /// Protocol requirements.
  @SectionId('CNRP')
  @StandardReferences(
    [
      'WHATWG / W3C — web platform / browser standards',
      'ISO/IEC 25010 — performance efficiency / resource utilization',
    ],
    'Captures the client network protocol requirements such as HTTP/2, TLS version, and WebRTC support.',
  )
  @Form([
    Field(
      'requiredProtocols',
      String,
      'Required Protocols',
      hint: 'HTTP/2, WebSocket',
    ),
    Field('tlsVersion', String, 'TLS Version', hint: 'Minimum TLS version'),
    Field(
      'webRtcRequired',
      bool,
      'WebRTC Required',
      hint: 'Real-time communication',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? protocols;

  /// Proxy and firewall requirements.
  @SectionId('CLNEREPR')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the client-side proxy and firewall requirements such as proxy support and required outbound ports.',
  )
  @Form([
    Field(
      'proxySupport',
      String,
      'Proxy Support',
      hint: 'HTTP/SOCKS proxy support',
    ),
    Field(
      'firewallPorts',
      String,
      'Firewall Ports',
      hint: 'Required outbound ports',
    ),
    Field('notes', String, 'Notes', hint: 'Additional network notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? proxy;
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
class ClientHardwareRequirements extends DocSpecsSection {
  @Form([
    Field(
      'minCpuCores',
      String,
      'Minimum CPU Cores',
      hint: 'Minimum CPU cores',
    ),
    Field(
      'recommendedCpuCores',
      String,
      'Recommended CPU Cores',
      hint: 'Recommended CPU cores',
    ),
    Field(
      'cpuArchitecture',
      String,
      'CPU Architecture',
      hint: 'x64, ARM, Universal',
    ),
    Field(
      'minCpuSpeed',
      String,
      'Minimum CPU Speed',
      hint: 'Minimum clock speed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Memory requirements.
  @SectionId('CHRM')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the client memory requirements such as minimum RAM, recommended RAM, and app memory usage.',
  )
  @Form([
    Field('minRam', String, 'Minimum RAM', hint: 'Minimum system RAM'),
    Field('recommendedRam', String, 'Recommended RAM', hint: 'Recommended RAM'),
    Field(
      'appMemoryUsage',
      String,
      'App Memory Usage',
      hint: 'Expected memory consumption',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? memory;

  /// Storage requirements.
  @SectionId('CHRS')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the client storage requirements such as free space, install size, cache size, and storage type.',
  )
  @Form([
    Field(
      'minFreeSpace',
      String,
      'Minimum Free Space',
      hint: 'Required free disk space',
    ),
    Field(
      'installSize',
      String,
      'Installation Size',
      hint: 'App installation size',
    ),
    Field('cacheSize', String, 'Cache Size', hint: 'Typical cache size'),
    Field('storageType', String, 'Storage Type', hint: 'SSD recommended'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? storage;

  /// Graphics requirements.
  @SectionId('CHRG')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the client graphics requirements such as GPU need, hardware acceleration, and video decoding.',
  )
  @Form([
    Field('gpuRequired', bool, 'GPU Required', hint: 'Dedicated GPU needed'),
    Field(
      'gpuAcceleration',
      String,
      'GPU Acceleration',
      hint: 'WebGL, hardware acceleration',
    ),
    Field(
      'videoDecoding',
      String,
      'Video Decoding',
      hint: 'Hardware video decode',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? graphics;

  /// Peripheral requirements.
  @SectionId('CHRP')
  @StandardReferences(
    [
      'USB / Bluetooth — peripheral connectivity standards',
      'ISO 9241 — ergonomics of human-system interaction',
    ],
    'Captures the client peripheral requirements such as input devices and audio I/O.',
  )
  @Form([
    Field(
      'inputDevices',
      String,
      'Input Devices',
      hint: 'Keyboard, mouse, touch',
    ),
    Field(
      'audioSupport',
      String,
      'Audio Support',
      hint: 'Audio I/O requirements',
    ),
    Field('notes', String, 'Notes', hint: 'Additional hardware notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? peripherals;
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
class ClientAccessibilityRequirements extends DocSpecsSection {
  @Form([
    Field(
      'screenReaderSupport',
      String,
      'Screen Reader Support',
      hint: 'NVDA, VoiceOver, JAWS',
    ),
    Field(
      'ariaCompliance',
      String,
      'ARIA Compliance',
      hint: 'ARIA landmark/role support',
    ),
    Field(
      'semanticHtml',
      bool,
      'Semantic HTML',
      hint: 'Proper semantic structure',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Visual accessibility support.
  @SectionId('CARV')
  @StandardReferences(
    [
      'WCAG 2.2 — accessible client experience',
      'ISO 9241 — ergonomics of human-system interaction',
    ],
    'Captures the visual accessibility support such as color-blind friendliness, high contrast, zoom, and font scaling in the client.',
  )
  @Form([
    Field(
      'colorBlindSupport',
      bool,
      'Color Blind Support',
      hint: 'Color-blind friendly',
    ),
    Field(
      'highContrastMode',
      bool,
      'High Contrast Mode',
      hint: 'High contrast support',
    ),
    Field('zoomSupport', String, 'Zoom Support', hint: 'Browser zoom support'),
    Field('fontScaling', String, 'Font Scaling', hint: 'Dynamic font scaling'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? visual;

  /// Motor accessibility support.
  @SectionId('CARM')
  @StandardReferences(
    [
      'WCAG 2.2 — accessible client experience',
      'ISO 9241 — ergonomics of human-system interaction',
    ],
    'Captures the motor accessibility support such as keyboard navigation, focus indicators, and touch target sizing in the client.',
  )
  @Form([
    Field(
      'keyboardNavigation',
      bool,
      'Keyboard Navigation',
      hint: 'Full keyboard access',
    ),
    Field(
      'focusIndicators',
      bool,
      'Focus Indicators',
      hint: 'Visible focus indicators',
    ),
    Field(
      'touchTargetSize',
      String,
      'Touch Target Size',
      hint: 'Minimum touch targets',
    ),
    Field('voiceControl', String, 'Voice Control', hint: 'Voice input support'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? motor;

  /// Cognitive accessibility support.
  @SectionId('CARC')
  @StandardReferences(
    [
      'WCAG 2.2 — accessible client experience',
      'ISO 9241 — ergonomics of human-system interaction',
    ],
    'Captures the cognitive accessibility support such as simplified mode, reading level, and reduced motion in the client.',
  )
  @Form([
    Field(
      'simplifiedMode',
      bool,
      'Simplified Mode',
      hint: 'Reduced complexity mode',
    ),
    Field(
      'readingLevel',
      String,
      'Reading Level',
      hint: 'Content reading level',
    ),
    Field(
      'animationControls',
      bool,
      'Animation Controls',
      hint: 'Reduce motion option',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? cognitive;

  /// Standards and notes.
  @SectionId('CARS')
  @StandardReferences(
    ['WCAG 2.2 — accessible client experience'],
    'Captures the accessibility conformance standards such as WCAG level and Section 508 the client targets.',
  )
  @Form([
    Field('wcagLevel', String, 'WCAG Conformance', hint: 'A, AA, or AAA'),
    Field(
      'additionalStandards',
      String,
      'Additional Standards',
      hint: 'Section 508, EN 301 549',
    ),
    Field('notes', String, 'Notes', hint: 'Additional accessibility notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? standards;
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
class PwaRequirements extends DocSpecsSection {
  @Form([
    Field('pwaEnabled', bool, 'PWA Enabled', hint: 'PWA functionality enabled'),
    Field('appName', String, 'App Name', hint: 'PWA display name'),
    Field('shortName', String, 'Short Name', hint: 'PWA short name'),
    Field('themeColor', String, 'Theme Color', hint: 'Theme color hex'),
    Field(
      'backgroundColor',
      String,
      'Background Color',
      hint: 'Splash background color',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Icon requirements.
  @SectionId('PWREIC')
  @StandardReferences(
    ['WHATWG / W3C — web platform / browser standards'],
    'Captures the PWA icon sizes, maskable icons, and splash-screen requirements in the browser client.',
  )
  @Form([
    Field('iconSizes', String, 'Icon Sizes', hint: '192x192, 512x512'),
    Field('maskableIcon', bool, 'Maskable Icon', hint: 'Adaptive icon support'),
    Field(
      'splashScreen',
      String,
      'Splash Screen',
      hint: 'Splash screen config',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? icons;

  /// Installation behavior.
  @SectionId('PWREIN')
  @StandardReferences(
    ['WHATWG / W3C — web platform / browser standards'],
    'Captures the PWA installation prompt and standalone-mode behavior in the browser client.',
  )
  @Form([
    Field(
      'installPrompt',
      String,
      'Install Prompt',
      hint: 'Installation prompt strategy',
    ),
    Field(
      'standaloneMode',
      bool,
      'Standalone Mode',
      hint: 'Standalone display mode',
    ),
    Field('startUrl', String, 'Start URL', hint: 'PWA start URL'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? installation;

  /// Offline support.
  @SectionId('PWREOF')
  @StandardReferences(
    ['WHATWG / W3C — web platform / browser standards'],
    'Captures the PWA offline support via service workers and background sync in the browser client.',
  )
  @Form([
    Field(
      'serviceWorkerStrategy',
      String,
      'Service Worker Strategy',
      hint: 'Cache-first, network-first',
    ),
    Field(
      'offlinePages',
      String,
      'Offline Pages',
      hint: 'Pages available offline',
    ),
    Field(
      'backgroundSync',
      bool,
      'Background Sync',
      hint: 'Background sync support',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? offline;

  /// Update handling.
  @SectionId('PWREUP')
  @StandardReferences(
    ['WHATWG / W3C — web platform / browser standards'],
    'Captures the PWA update and cache-versioning strategy in the browser client.',
  )
  @Form([
    Field(
      'updateStrategy',
      String,
      'Update Strategy',
      hint: 'How updates are handled',
    ),
    Field(
      'cacheVersion',
      String,
      'Cache Versioning',
      hint: 'Cache versioning approach',
    ),
    Field('notes', String, 'Notes', hint: 'Additional PWA notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? updates;
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
class NativeAppRequirements extends DocSpecsSection {
  @Form([
    Field(
      'appStoreDistribution',
      bool,
      'App Store Distribution',
      hint: 'Distributed via app stores',
    ),
    Field(
      'enterpriseDistribution',
      bool,
      'Enterprise Distribution',
      hint: 'MDM/enterprise deployment',
    ),
    Field('sideloading', bool, 'Sideloading', hint: 'Direct installation'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Store presence requirements.
  @SectionId('NARS')
  @StandardReferences(
    ['Android CDD / Apple HIG — mobile device platform requirements'],
    'Captures the app-store presence requirements across Apple, Google, and other native distribution channels.',
  )
  @Form([
    Field(
      'appleAppStore',
      bool,
      'Apple App Store',
      hint: 'iOS App Store listing',
    ),
    Field(
      'googlePlayStore',
      bool,
      'Google Play Store',
      hint: 'Google Play listing',
    ),
    Field('otherStores', String, 'Other Stores', hint: 'Amazon, Samsung, etc.'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? stores;

  /// SDK and version requirements.
  @SectionId('NARV')
  @StandardReferences(
    ['Android CDD / Apple HIG — mobile device platform requirements'],
    'Captures the native app minimum, target, and compile SDK version requirements for the client platform.',
  )
  @Form([
    Field(
      'minSdkVersion',
      String,
      'Minimum SDK Version',
      hint: 'Minimum SDK level',
    ),
    Field(
      'targetSdkVersion',
      String,
      'Target SDK Version',
      hint: 'Target SDK level',
    ),
    Field(
      'compileSdkVersion',
      String,
      'Compile SDK Version',
      hint: 'Compile SDK version',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? versions;

  /// Size and performance requirements.
  @SectionId('NARP')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency / resource utilization',
      'Android CDD / Apple HIG — mobile device platform requirements',
    ],
    'Captures the native app size, startup time, and memory performance targets on the client device.',
  )
  @Form([
    Field('maxAppSize', String, 'Maximum App Size', hint: 'Max download size'),
    Field(
      'startupTime',
      String,
      'Startup Time Target',
      hint: 'Cold start time target',
    ),
    Field('memoryLimit', String, 'Memory Limit', hint: 'Max memory usage'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? performance;

  /// Deep-linking support.
  @SectionId('NARL')
  @StandardReferences(
    ['Android CDD / Apple HIG — mobile device platform requirements'],
    'Captures the native app deep-linking and universal-link support on the client device.',
  )
  @Form([
    Field('deepLinking', bool, 'Deep Linking', hint: 'Deep link support'),
    Field(
      'universalLinks',
      bool,
      'Universal/App Links',
      hint: 'Universal links support',
    ),
    Field('customScheme', String, 'Custom URL Scheme', hint: 'App URL scheme'),
    Field('notes', String, 'Notes', hint: 'Additional native app notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? linking;
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
class ClientSecurityRequirements extends DocSpecsSection {
  @Form([
    Field(
      'localDataEncryption',
      bool,
      'Local Data Encryption',
      hint: 'Encrypt local storage',
    ),
    Field(
      'secureStorage',
      String,
      'Secure Storage',
      hint: 'Keychain, encrypted prefs',
    ),
    Field(
      'cacheClearing',
      String,
      'Cache Clearing',
      hint: 'Sensitive data clearing',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Authentication requirements.
  @SectionId('CSRA')
  @StandardReferences(
    [
      'Android CDD / Apple HIG — mobile device platform requirements',
      'ISO/IEC 25010 — performance efficiency / resource utilization',
    ],
    'Captures the client-side authentication requirements such as biometrics, device passcode, and auto-lock.',
  )
  @Form([
    Field(
      'biometricAuth',
      bool,
      'Biometric Authentication',
      hint: 'FaceID, TouchID, fingerprint',
    ),
    Field(
      'devicePasscode',
      bool,
      'Device Passcode Required',
      hint: 'Require device passcode',
    ),
    Field(
      'rememberCredentials',
      String,
      'Remember Credentials',
      hint: 'Credential storage policy',
    ),
    Field(
      'autoLockTimeout',
      String,
      'Auto-Lock Timeout',
      hint: 'Session timeout',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? authentication;

  /// Device security controls.
  @SectionId('CSRD')
  @StandardReferences(
    [
      'Android CDD / Apple HIG — mobile device platform requirements',
      'ISO/IEC 25010 — performance efficiency / resource utilization',
    ],
    'Captures the device-level security controls such as jailbreak detection and certificate pinning on the client device.',
  )
  @Form([
    Field(
      'jailbreakDetection',
      bool,
      'Jailbreak Detection',
      hint: 'Detect rooted devices',
    ),
    Field('debugDetection', bool, 'Debug Detection', hint: 'Detect debugging'),
    Field(
      'certificatePinning',
      bool,
      'Certificate Pinning',
      hint: 'SSL certificate pinning',
    ),
    Field('vpnDetection', String, 'VPN Detection', hint: 'VPN/proxy detection'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? device;

  /// Network security controls.
  @SectionId('CSRN')
  @StandardReferences(
    [
      'WHATWG / W3C — web platform / browser standards',
      'ISO/IEC 25010 — performance efficiency / resource utilization',
    ],
    'Captures the client-side network security controls such as HTTPS enforcement and TLS versioning.',
  )
  @Form([
    Field('httpsOnly', bool, 'HTTPS Only', hint: 'Require HTTPS'),
    Field(
      'minTlsVersion',
      String,
      'Minimum TLS Version',
      hint: 'TLS 1.2, TLS 1.3',
    ),
    Field(
      'insecureConnectionBlocking',
      bool,
      'Block Insecure Connections',
      hint: 'Block HTTP',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? network;

  /// Code protection controls.
  @SectionId('CSRCP')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency / resource utilization'],
    'Captures the client-side code protection controls such as obfuscation and tamper detection.',
  )
  @Form([
    Field(
      'codeObfuscation',
      bool,
      'Code Obfuscation',
      hint: 'Obfuscate app code',
    ),
    Field(
      'tamperDetection',
      bool,
      'Tamper Detection',
      hint: 'Detect app tampering',
    ),
    Field('notes', String, 'Notes', hint: 'Additional client security notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? codeProtection;
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
class NetworkRequirementsSection extends DocSpecsSection {
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
  @override
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
  @StandardReferences([
    'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
  ], 'The VPN requirements the network must satisfy.')
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
class InternalNetworkRequirements extends DocSpecsSection {
  @Form([
    Field(
      'networkTopology',
      String,
      'Network Topology',
      hint: 'Hub-spoke, mesh, star',
    ),
    Field(
      'vpcStructure',
      String,
      'VPC Structure',
      hint: 'VPC/VLAN organization',
    ),
    Field(
      'subnetConfiguration',
      String,
      'Subnet Configuration',
      hint: 'Subnet layout',
    ),
    Field('cidrRanges', String, 'CIDR Ranges', hint: 'IP address ranges'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Segmentation and isolation.
  @SectionId('INRS')
  @StandardReferences(
    ['ISO/IEC 27033 — network security'],
    'Internal network segmentation and isolation via DMZ, security zones, and trust boundaries.',
  )
  @Form([
    Field(
      'networkSegmentation',
      String,
      'Network Segmentation',
      hint: 'DMZ, tiers, microsegmentation',
    ),
    Field(
      'securityZones',
      String,
      'Security Zones',
      hint: 'Trust zones defined',
    ),
    Field(
      'isolationRequirements',
      String,
      'Isolation Requirements',
      hint: 'Network isolation',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? segmentation;

  /// Routing and service discovery.
  @SectionId('INRR')
  @StandardReferences(
    [
      'TCP/IP — internet protocol suite',
      'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
    ],
    'Internal routing and service discovery covering routing protocols, service discovery, and service mesh.',
  )
  @Form([
    Field(
      'routingProtocol',
      String,
      'Routing Protocol',
      hint: 'BGP, OSPF, static',
    ),
    Field(
      'serviceDiscovery',
      String,
      'Service Discovery',
      hint: 'DNS, Consul, etc.',
    ),
    Field(
      'serviceMesh',
      String,
      'Service Mesh',
      hint: 'Istio, Linkerd if used',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? routing;

  /// Inter-service communication controls.
  @SectionId('INRIS')
  @StandardReferences(
    [
      'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
      'ISO/IEC 27033 — network security',
    ],
    'Inter-service communication controls including protocols, encryption in transit, and certificate management.',
  )
  @Form([
    Field(
      'interServiceCommunication',
      String,
      'Inter-Service Communication',
      hint: 'REST, gRPC, messaging',
    ),
    Field(
      'encryptionInTransit',
      bool,
      'Encryption in Transit',
      hint: 'mTLS, TLS required',
    ),
    Field(
      'certificateManagement',
      String,
      'Certificate Management',
      hint: 'Cert-manager, PKI',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? interService;

  /// Monitoring and notes.
  @SectionId('INRM')
  @StandardReferences(
    ['ISO/IEC 27033 — network security'],
    'Internal network monitoring requirements including tooling and flow logging.',
  )
  @Form([
    Field(
      'networkMonitoring',
      String,
      'Network Monitoring',
      hint: 'Network monitoring tools',
    ),
    Field('flowLogging', bool, 'Flow Logging', hint: 'VPC flow logs'),
    Field('notes', String, 'Notes', hint: 'Additional internal network notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? monitoring;
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
class ExternalNetworkRequirements extends DocSpecsSection {
  @Form([
    Field(
      'internetAccess',
      String,
      'Internet Access',
      hint: 'Direct, NAT gateway, proxy',
    ),
    Field(
      'ispRedundancy',
      String,
      'ISP Redundancy',
      hint: 'Multi-ISP, single ISP',
    ),
    Field(
      'dedicatedLines',
      String,
      'Dedicated Lines',
      hint: 'MPLS, leased lines',
    ),
    Field(
      'peeringRequirements',
      String,
      'Peering Requirements',
      hint: 'Direct peering arrangements',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Public endpoint requirements.
  @SectionId('ENRP')
  @StandardReferences(
    [
      'TCP/IP — internet protocol suite',
      'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
    ],
    'Public endpoint requirements covering public-facing services, static IPs, IPv6, and DNS records.',
  )
  @Form([
    Field(
      'publicEndpoints',
      String,
      'Public Endpoints',
      hint: 'Public-facing services',
    ),
    Field(
      'staticIps',
      String,
      'Static IP Addresses',
      hint: 'Required static IPs',
    ),
    Field('ipv6Support', bool, 'IPv6 Support', hint: 'IPv6 required'),
    Field(
      'dnscname',
      String,
      'DNS/CNAME Requirements',
      hint: 'DNS records needed',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? publicEndpointsConfig;

  /// Third-party connectivity.
  @SectionId('EXNEREPA')
  @StandardReferences(
    [
      'TCP/IP — internet protocol suite',
      'ISO/IEC/IEEE 42010 — architecture description',
    ],
    'Third-party connectivity requirements covering B2B connections, API gateways, and webhooks.',
  )
  @Form([
    Field(
      'partnerConnectivity',
      String,
      'Partner Connectivity',
      hint: 'B2B connections',
    ),
    Field('apiGateway', String, 'API Gateway', hint: 'External API gateway'),
    Field(
      'webhookEndpoints',
      String,
      'Webhook Endpoints',
      hint: 'Inbound webhooks',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? partners;

  /// Cloud connectivity.
  @SectionId('ENRC')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 42010 — architecture description',
      'C4 model — deployment / infrastructure diagrams',
    ],
    'Cloud connectivity requirements such as direct connect and hybrid cloud networking.',
  )
  @Form([
    Field(
      'cloudConnect',
      String,
      'Cloud Direct Connect',
      hint: 'AWS Direct Connect, Azure ExpressRoute',
    ),
    Field(
      'hybridCloud',
      String,
      'Hybrid Cloud',
      hint: 'Hybrid cloud networking',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? cloud;

  /// Security controls.
  @SectionId('ENRS')
  @StandardReferences(
    ['ISO/IEC 27033 — network security'],
    'External network security controls including DDoS protection and web application firewall.',
  )
  @Form([
    Field('ddosProtection', String, 'DDoS Protection', hint: 'DDoS mitigation'),
    Field('waf', String, 'WAF Requirements', hint: 'Web application firewall'),
    Field('notes', String, 'Notes', hint: 'Additional external network notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? security;
}

/// Bandwidth requirements.
@StandardReferences([
  'ISO/IEC 25010 — performance efficiency (network throughput / latency)',
], 'Bandwidth requirements covering total, peak, average, and burst capacity.')
@SectionId('BARE')
class BandwidthRequirements extends DocSpecsSection {
  @Form([
    Field(
      'totalBandwidth',
      String,
      'Total Bandwidth Required',
      hint: 'Total bandwidth capacity',
    ),
    Field(
      'peakBandwidth',
      String,
      'Peak Bandwidth',
      hint: 'Peak bandwidth requirements',
    ),
    Field(
      'averageBandwidth',
      String,
      'Average Bandwidth',
      hint: 'Average bandwidth usage',
    ),
    Field(
      'burstCapacity',
      String,
      'Burst Capacity',
      hint: 'Burst handling capability',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Directional bandwidth requirements.
  @SectionId('BAREDI')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
    'Directional bandwidth requirements for ingress, egress, and east-west traffic.',
  )
  @Form([
    Field(
      'ingressBandwidth',
      String,
      'Ingress Bandwidth',
      hint: 'Inbound bandwidth',
    ),
    Field(
      'egressBandwidth',
      String,
      'Egress Bandwidth',
      hint: 'Outbound bandwidth',
    ),
    Field(
      'eastWestBandwidth',
      String,
      'East-West Bandwidth',
      hint: 'Internal traffic bandwidth',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? direction;

  /// Per-connection bandwidth requirements.
  @SectionId('BARECO')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
    'Per-connection bandwidth requirements including concurrency and connection pooling.',
  )
  @Form([
    Field(
      'perConnectionBandwidth',
      String,
      'Per-Connection Bandwidth',
      hint: 'Bandwidth per connection',
    ),
    Field(
      'concurrentConnections',
      String,
      'Concurrent Connections',
      hint: 'Max concurrent connections',
    ),
    Field(
      'connectionPooling',
      String,
      'Connection Pooling',
      hint: 'Connection pool requirements',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? connection;

  /// Traffic-pattern requirements.
  @SectionId('BARETR')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
    'Bandwidth traffic-pattern requirements including streaming and large file transfers.',
  )
  @Form([
    Field(
      'trafficPatterns',
      String,
      'Traffic Patterns',
      hint: 'Typical traffic patterns',
    ),
    Field(
      'videoStreaming',
      String,
      'Video/Streaming',
      hint: 'Streaming bandwidth',
    ),
    Field(
      'fileTransfers',
      String,
      'File Transfers',
      hint: 'Large file transfer needs',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? traffic;

  /// QoS requirements.
  @SectionId('BAREQO')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
    'Bandwidth quality-of-service requirements and traffic prioritization rules.',
  )
  @Form([
    Field(
      'qosRequirements',
      String,
      'QoS Requirements',
      hint: 'Quality of Service',
    ),
    Field(
      'trafficPrioritization',
      String,
      'Traffic Prioritization',
      hint: 'Traffic priority rules',
    ),
    Field('notes', String, 'Notes', hint: 'Additional bandwidth notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? qos;
}

/// Network latency requirements.
@StandardReferences(
  ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
  'Network latency requirements covering maximum, target, and percentile latency budgets.',
)
@SectionId('NELARE')
class NetworkLatencyRequirements extends DocSpecsSection {
  @Form([
    Field(
      'maxLatency',
      String,
      'Maximum Latency',
      hint: 'Maximum acceptable latency',
    ),
    Field(
      'targetLatency',
      String,
      'Target Latency',
      hint: 'Target p50 latency',
    ),
    Field('p95Latency', String, 'P95 Latency', hint: '95th percentile target'),
    Field('p99Latency', String, 'P99 Latency', hint: '99th percentile target'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Segment-level latency budgets.
  @SectionId('NLRS')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
    'Segment-level latency budgets across client-edge, edge-origin, internal, and database hops.',
  )
  @Form([
    Field(
      'clientToEdge',
      String,
      'Client to Edge Latency',
      hint: 'Client to CDN/edge',
    ),
    Field(
      'edgeToOrigin',
      String,
      'Edge to Origin Latency',
      hint: 'Edge to origin server',
    ),
    Field(
      'internalLatency',
      String,
      'Internal Service Latency',
      hint: 'Service-to-service',
    ),
    Field(
      'databaseLatency',
      String,
      'Database Latency',
      hint: 'DB access latency',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? segments;

  /// Geographic latency budgets.
  @SectionId('NLRG')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
    'Geographic latency budgets across regional, cross-regional, and global scopes.',
  )
  @Form([
    Field(
      'regionalLatency',
      String,
      'Regional Latency',
      hint: 'Same region latency',
    ),
    Field(
      'crossRegionalLatency',
      String,
      'Cross-Regional Latency',
      hint: 'Cross-region latency',
    ),
    Field(
      'globalLatency',
      String,
      'Global Latency',
      hint: 'Worldwide latency targets',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? geographic;

  /// Stability tolerances.
  @SectionId('NELAREST')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
    'Network stability tolerances such as jitter, packet loss, and connection stability.',
  )
  @Form([
    Field(
      'jitterTolerance',
      String,
      'Jitter Tolerance',
      hint: 'Acceptable jitter',
    ),
    Field(
      'packetLoss',
      String,
      'Packet Loss Tolerance',
      hint: 'Acceptable packet loss',
    ),
    Field(
      'connectionStability',
      String,
      'Connection Stability',
      hint: 'Connection stability requirements',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? stability;

  /// Optimization strategies.
  @SectionId('NLRO')
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency (network throughput / latency)',
  ], 'Network latency optimization strategies and related notes.')
  @Form([
    Field(
      'latencyOptimization',
      String,
      'Latency Optimization',
      hint: 'Optimization strategies',
    ),
    Field('notes', String, 'Notes', hint: 'Additional latency notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? optimization;
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
class NetworkAvailabilityRequirements extends DocSpecsSection {
  @Form([
    Field(
      'availabilityTarget',
      String,
      'Availability Target',
      hint: '99.99%, 99.999%',
    ),
    Field(
      'monthlyDowntime',
      String,
      'Monthly Downtime Budget',
      hint: 'Allowed downtime/month',
    ),
    Field(
      'maintenanceWindows',
      String,
      'Maintenance Windows',
      hint: 'Scheduled maintenance',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Redundancy configuration.
  @SectionId('NARR')
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency (network throughput / latency)',
  ], 'Network redundancy configuration across paths, ISPs, links, and devices.')
  @Form([
    Field(
      'pathRedundancy',
      String,
      'Path Redundancy',
      hint: 'Multiple network paths',
    ),
    Field('ispRedundancy', String, 'ISP Redundancy', hint: 'Multiple ISPs'),
    Field('linkRedundancy', String, 'Link Redundancy', hint: 'Redundant links'),
    Field(
      'deviceRedundancy',
      String,
      'Device Redundancy',
      hint: 'Redundant network devices',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? redundancy;

  /// Failover configuration.
  @SectionId('NARF')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
    'Network failover configuration covering mechanism, time, health checks, and rerouting.',
  )
  @Form([
    Field(
      'failoverMechanism',
      String,
      'Failover Mechanism',
      hint: 'Automatic/manual failover',
    ),
    Field(
      'failoverTime',
      String,
      'Failover Time',
      hint: 'Maximum failover time',
    ),
    Field(
      'healthChecks',
      String,
      'Health Checks',
      hint: 'Network health monitoring',
    ),
    Field(
      'automaticRerouting',
      bool,
      'Automatic Rerouting',
      hint: 'Auto path rerouting',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? failover;

  /// Recovery objectives.
  @SectionId('NEAVRERE')
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency (network throughput / latency)',
  ], 'Network recovery objectives such as RPO, RTO, and DR-site connectivity.')
  @Form([
    Field('rpo', String, 'Recovery Point Objective', hint: 'Network state RPO'),
    Field(
      'rto',
      String,
      'Recovery Time Objective',
      hint: 'Network recovery RTO',
    ),
    Field(
      'drSite',
      String,
      'DR Site Connectivity',
      hint: 'DR network connectivity',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? recovery;

  /// Testing and notes.
  @SectionId('NART')
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency (network throughput / latency)',
  ], 'Network availability failover testing frequency and related notes.')
  @Form([
    Field(
      'failoverTesting',
      String,
      'Failover Testing',
      hint: 'Testing frequency',
    ),
    Field('notes', String, 'Notes', hint: 'Additional availability notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? testing;
}

/// VPN requirement entry.
@StandardReferences([
  'ISO/IEC 27033 — network security',
  'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
], 'A single VPN requirement entry covering its name, type, and purpose.')
@SectionId('VRE')
class VpnRequirementEntry extends DocSpecsSection {
  @Form([
    Field(
      'vpnName',
      String,
      'VPN Name',
      required: true,
      hint: 'VPN connection name',
    ),
    Field('vpnType', String, 'VPN Type', hint: 'Site-to-Site, Client, SSL'),
    Field('purpose', String, 'Purpose', hint: 'Purpose of this VPN'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Endpoint configuration.
  @SectionId('VREE')
  @StandardReferences(
    ['IETF RFCs (DNS / TLS / IPsec) — network protocol standards'],
    'VPN endpoint configuration covering local, remote, and reachable networks.',
  )
  @Form([
    Field(
      'localEndpoint',
      String,
      'Local Endpoint',
      hint: 'Local network endpoint',
    ),
    Field(
      'remoteEndpoint',
      String,
      'Remote Endpoint',
      hint: 'Remote network endpoint',
    ),
    Field(
      'remoteNetworks',
      String,
      'Remote Networks',
      hint: 'Networks accessible via VPN',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? endpoints;

  /// Protocol and cryptography.
  @SectionId('VREP')
  @StandardReferences(
    [
      'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
      'ISO/IEC 27033 — network security',
    ],
    'VPN protocol and cryptography settings including protocol, encryption, and authentication.',
  )
  @Form([
    Field('protocol', String, 'Protocol', hint: 'IPSec, OpenVPN, WireGuard'),
    Field(
      'encryptionAlgorithm',
      String,
      'Encryption Algorithm',
      hint: 'AES-256, ChaCha20',
    ),
    Field(
      'authenticationMethod',
      String,
      'Authentication Method',
      hint: 'PSK, certificates, MFA',
    ),
    Field(
      'perfectForwardSecrecy',
      bool,
      'Perfect Forward Secrecy',
      hint: 'PFS enabled',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? protocolDetails;

  /// Performance expectations.
  @SectionId('VPREENPE')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
    'VPN performance expectations such as bandwidth, max connections, and split tunneling.',
  )
  @Form([
    Field('bandwidth', String, 'Bandwidth', hint: 'VPN bandwidth capacity'),
    Field(
      'maxConnections',
      int,
      'Max Connections',
      hint: 'Maximum concurrent connections',
    ),
    Field(
      'splitTunneling',
      bool,
      'Split Tunneling',
      hint: 'Split tunnel allowed',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? performance;

  /// Availability and notes.
  @SectionId('VREA')
  @StandardReferences(
    ['ISO/IEC 27033 — network security'],
    'VPN availability and redundancy expectations for a single VPN requirement.',
  )
  @Form([
    Field(
      'availability',
      String,
      'Availability',
      hint: 'Required availability',
    ),
    Field('redundancy', String, 'Redundancy', hint: 'VPN redundancy'),
    Field('notes', String, 'Notes', hint: 'Additional VPN notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? availabilityDetails;
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
class FirewallRequirements extends DocSpecsSection {
  @Form([
    Field(
      'firewallArchitecture',
      String,
      'Firewall Architecture',
      hint: 'Perimeter, distributed, cloud',
    ),
    Field(
      'firewallVendor',
      String,
      'Firewall Vendor/Product',
      hint: 'Firewall product used',
    ),
    Field(
      'managementModel',
      String,
      'Management Model',
      hint: 'Centralized, distributed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Rule definitions.
  @SectionId('FIRERU')
  @StandardReferences(
    ['ISO/IEC 27033 — network security'],
    'Firewall rule definitions covering default policy and inbound/outbound/internal rules.',
  )
  @Form([
    Field(
      'defaultPolicy',
      String,
      'Default Policy',
      hint: 'Deny-all, allow-all',
    ),
    Field(
      'inboundRules',
      String,
      'Inbound Rules Summary',
      hint: 'Summary of inbound rules',
    ),
    Field(
      'outboundRules',
      String,
      'Outbound Rules Summary',
      hint: 'Summary of outbound rules',
    ),
    Field(
      'internalRules',
      String,
      'Internal Rules Summary',
      hint: 'Inter-zone rules',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? rules;

  /// Port requirements.
  @SectionId('FIREPO')
  @StandardReferences(
    ['ISO/IEC 27033 — network security', 'TCP/IP — internet protocol suite'],
    'Firewall port requirements covering required, blocked, and dynamic port ranges.',
  )
  @Form([
    Field(
      'requiredPorts',
      String,
      'Required Ports',
      hint: 'Ports that must be open',
    ),
    Field(
      'blockedPorts',
      String,
      'Blocked Ports',
      hint: 'Explicitly blocked ports',
    ),
    Field('portRanges', String, 'Port Ranges', hint: 'Dynamic port ranges'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? ports;

  /// Advanced inspection features.
  @SectionId('FIREAD')
  @StandardReferences(
    ['ISO/IEC 27033 — network security'],
    'Advanced firewall inspection features such as IDS/IPS, deep packet inspection, and threat intelligence.',
  )
  @Form([
    Field(
      'intrusionDetection',
      bool,
      'Intrusion Detection',
      hint: 'IDS/IPS enabled',
    ),
    Field(
      'deepPacketInspection',
      bool,
      'Deep Packet Inspection',
      hint: 'DPI enabled',
    ),
    Field(
      'applicationAwareness',
      bool,
      'Application Awareness',
      hint: 'Layer 7 inspection',
    ),
    Field(
      'threatIntelligence',
      String,
      'Threat Intelligence',
      hint: 'Threat feed integration',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? advanced;

  /// Logging and alerts.
  @SectionId('FIRELO')
  @StandardReferences([
    'ISO/IEC 27033 — network security',
  ], 'Firewall logging and alerting requirements including log retention.')
  @Form([
    Field(
      'loggingRequirements',
      String,
      'Logging Requirements',
      hint: 'Firewall log retention',
    ),
    Field('alerting', String, 'Alerting', hint: 'Firewall alerting'),
    Field('notes', String, 'Notes', hint: 'Additional firewall notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? logging;
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
class GeographicDistributionRequirements extends DocSpecsSection {
  @Form([
    Field(
      'primaryRegion',
      String,
      'Primary Region',
      hint: 'Primary deployment region',
    ),
    Field(
      'secondaryRegions',
      String,
      'Secondary Regions',
      hint: 'Secondary/backup regions',
    ),
    Field(
      'edgeLocations',
      String,
      'Edge Locations',
      hint: 'CDN edge locations',
    ),
    Field(
      'regionalCompliance',
      String,
      'Regional Compliance',
      hint: 'Data residency requirements',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// CDN requirements.
  @SectionId('GDRC')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
    'Content delivery network requirements including provider, cached content, and TTL.',
  )
  @Form([
    Field(
      'cdnRequired',
      bool,
      'CDN Required',
      hint: 'Content delivery network',
    ),
    Field(
      'cdnProvider',
      String,
      'CDN Provider',
      hint: 'CloudFront, Cloudflare, etc.',
    ),
    Field(
      'cachedContent',
      String,
      'Cached Content',
      hint: 'What to cache at edge',
    ),
    Field('cacheTtl', String, 'Cache TTL', hint: 'Cache expiration'),
    Field(
      'cacheInvalidation',
      String,
      'Cache Invalidation',
      hint: 'Invalidation strategy',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? cdn;

  /// Traffic routing requirements.
  @SectionId('GDRR')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
    'Geographic traffic routing strategy, failover routing, and traffic steering.',
  )
  @Form([
    Field(
      'routingStrategy',
      String,
      'Routing Strategy',
      hint: 'Latency, geo, weighted',
    ),
    Field(
      'failoverRouting',
      String,
      'Failover Routing',
      hint: 'Geographic failover',
    ),
    Field(
      'trafficSteering',
      String,
      'Traffic Steering',
      hint: 'How traffic is directed',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? routing;

  /// Anycast and global load balancing.
  @SectionId('GDRA')
  @StandardReferences([
    'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
    'TCP/IP — internet protocol suite',
  ], 'Anycast addressing and global server load balancing requirements.')
  @Form([
    Field('anycastIp', bool, 'Anycast IP', hint: 'Anycast addressing'),
    Field(
      'globalLoadBalancing',
      String,
      'Global Load Balancing',
      hint: 'GSLB requirements',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? anycast;

  /// Performance considerations.
  @SectionId('GDRP')
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency (network throughput / latency)',
  ], 'Geographic distribution performance considerations such as edge caching.')
  @Form([
    Field('edgeCaching', String, 'Edge Caching', hint: 'Edge cache strategy'),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional geographic distribution notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? performance;
}

/// DNS requirements.
@StandardReferences([
  'IETF RFCs (DNS / TLS / IPsec) — network protocol standards',
  'TCP/IP — internet protocol suite',
], 'DNS requirements covering provider, hosting model, and DNSSEC.')
@SectionId('DNRE')
class DnsRequirements extends DocSpecsSection {
  @Form([
    Field(
      'dnsProvider',
      String,
      'DNS Provider',
      hint: 'Route 53, Cloudflare, etc.',
    ),
    Field('dnsHosting', String, 'DNS Hosting', hint: 'Managed, self-hosted'),
    Field(
      'dnsSecEnabled',
      bool,
      'DNSSEC Enabled',
      hint: 'DNS security extensions',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Zone requirements.
  @SectionId('DNREZO')
  @StandardReferences(
    ['IETF RFCs (DNS / TLS / IPsec) — network protocol standards'],
    'DNS zone requirements including public, private, and split-horizon zones.',
  )
  @Form([
    Field('publicZones', String, 'Public Zones', hint: 'Public DNS zones'),
    Field('privateZones', String, 'Private Zones', hint: 'Private DNS zones'),
    Field(
      'splitHorizon',
      bool,
      'Split Horizon DNS',
      hint: 'Internal/external split',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? zones;

  /// Record requirements.
  @SectionId('DNRERE')
  @StandardReferences(
    ['IETF RFCs (DNS / TLS / IPsec) — network protocol standards'],
    'DNS record requirements covering record types, TTL policy, and dynamic DNS.',
  )
  @Form([
    Field('recordTypes', String, 'Record Types', hint: 'A, CNAME, TXT, etc.'),
    Field('ttlPolicy', String, 'TTL Policy', hint: 'Default TTL settings'),
    Field('dynamicDns', bool, 'Dynamic DNS', hint: 'Dynamic DNS updates'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? records;

  /// Availability requirements.
  @SectionId('DNREAV')
  @StandardReferences(
    ['IETF RFCs (DNS / TLS / IPsec) — network protocol standards'],
    'DNS availability requirements such as redundancy, resolution SLA, and failover.',
  )
  @Form([
    Field('dnsRedundancy', String, 'DNS Redundancy', hint: 'Secondary DNS'),
    Field('resolutionSla', String, 'Resolution SLA', hint: 'DNS query SLA'),
    Field('failoverDns', String, 'Failover DNS', hint: 'DNS-based failover'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? availability;

  /// Health-check settings.
  @SectionId('DRHC')
  @StandardReferences(
    ['IETF RFCs (DNS / TLS / IPsec) — network protocol standards'],
    'DNS health-check settings including endpoints, checks, and failover actions.',
  )
  @Form([
    Field('healthChecks', bool, 'Health Checks', hint: 'DNS health checking'),
    Field(
      'healthCheckEndpoints',
      String,
      'Health Check Endpoints',
      hint: 'Endpoints to check',
    ),
    Field(
      'failoverAction',
      String,
      'Failover Action',
      hint: 'Action on failure',
    ),
    Field('notes', String, 'Notes', hint: 'Additional DNS notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? healthChecks;
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
class NetworkLoadBalancingRequirements extends DocSpecsSection {
  @Form([
    Field(
      'loadBalancerType',
      String,
      'Load Balancer Type',
      hint: 'L4, L7, DNS-based',
    ),
    Field(
      'loadBalancerProduct',
      String,
      'Load Balancer Product',
      hint: 'ALB, NLB, HAProxy, etc.',
    ),
    Field(
      'deploymentModel',
      String,
      'Deployment Model',
      hint: 'Cloud, on-premises, hybrid',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Routing strategy.
  @SectionId('NLBRR')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
    'Load balancer routing strategy such as algorithm, session persistence, and weighted routing.',
  )
  @Form([
    Field(
      'loadBalancingAlgorithm',
      String,
      'Load Balancing Algorithm',
      hint: 'Round-robin, least-conn',
    ),
    Field(
      'sessionPersistence',
      String,
      'Session Persistence',
      hint: 'Sticky sessions',
    ),
    Field(
      'weightedRouting',
      bool,
      'Weighted Routing',
      hint: 'Weighted distribution',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? routing;

  /// Health-check behavior.
  @SectionId('NLBRHC')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
    'Load balancer health-check behavior including protocol, path, interval, and thresholds.',
  )
  @Form([
    Field(
      'healthCheckProtocol',
      String,
      'Health Check Protocol',
      hint: 'HTTP, TCP, HTTPS',
    ),
    Field(
      'healthCheckPath',
      String,
      'Health Check Path',
      hint: 'Health endpoint path',
    ),
    Field(
      'healthCheckInterval',
      String,
      'Health Check Interval',
      hint: 'Check frequency',
    ),
    Field(
      'unhealthyThreshold',
      int,
      'Unhealthy Threshold',
      hint: 'Failures before unhealthy',
    ),
    Field(
      'healthyThreshold',
      int,
      'Healthy Threshold',
      hint: 'Successes before healthy',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? healthChecks;

  /// TLS settings.
  @SectionId('NLBRT')
  @StandardReferences(
    ['IETF RFCs (DNS / TLS / IPsec) — network protocol standards'],
    'Load balancer TLS settings covering SSL termination, certificates, and HTTP/2 support.',
  )
  @Form([
    Field(
      'sslTermination',
      String,
      'SSL Termination',
      hint: 'At LB, at backend',
    ),
    Field(
      'sslCertificate',
      String,
      'SSL Certificate',
      hint: 'Certificate management',
    ),
    Field('http2Support', bool, 'HTTP/2 Support', hint: 'HTTP/2 enabled'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? tls;

  /// Availability settings.
  @SectionId('NLBRA')
  @StandardReferences(
    ['ISO/IEC 25010 — performance efficiency (network throughput / latency)'],
    'Load balancer high-availability settings such as redundancy and cross-zone balancing.',
  )
  @Form([
    Field('lbRedundancy', String, 'LB Redundancy', hint: 'Load balancer HA'),
    Field(
      'crossZoneBalancing',
      bool,
      'Cross-Zone Balancing',
      hint: 'Cross-AZ distribution',
    ),
    Field('notes', String, 'Notes', hint: 'Additional load balancing notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? availability;
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
class NetworkSecurityRequirements extends DocSpecsSection {
  @Form([
    Field(
      'encryptionInTransit',
      String,
      'Encryption in Transit',
      hint: 'TLS requirements',
    ),
    Field(
      'minTlsVersion',
      String,
      'Minimum TLS Version',
      hint: 'TLS 1.2, TLS 1.3',
    ),
    Field(
      'cipherSuites',
      String,
      'Cipher Suites',
      hint: 'Allowed cipher suites',
    ),
    Field(
      'certificateAuthority',
      String,
      'Certificate Authority',
      hint: 'CA for certificates',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Access-control settings.
  @SectionId('NSRA')
  @StandardReferences([
    'ISO/IEC 27033 — network security',
  ], 'Network access controls: ACLs, security groups, and IP allow/deny lists.')
  @Form([
    Field(
      'networkAcls',
      String,
      'Network ACLs',
      hint: 'Network access control lists',
    ),
    Field('securityGroups', String, 'Security Groups', hint: 'SG strategy'),
    Field(
      'ipWhitelisting',
      String,
      'IP Whitelisting',
      hint: 'Allowed IP ranges',
    ),
    Field(
      'ipBlacklisting',
      String,
      'IP Blacklisting',
      hint: 'Blocked IP ranges',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? access;

  /// Monitoring controls.
  @SectionId('NSRM')
  @StandardReferences(
    ['ISO/IEC 27033 — network security'],
    'Network intrusion detection, traffic analysis, and anomaly detection controls.',
  )
  @Form([
    Field(
      'networkIdp',
      String,
      'Network IDS/IPS',
      hint: 'Intrusion detection/prevention',
    ),
    Field(
      'trafficAnalysis',
      String,
      'Traffic Analysis',
      hint: 'Deep traffic analysis',
    ),
    Field(
      'anomalyDetection',
      bool,
      'Anomaly Detection',
      hint: 'Anomaly-based detection',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? monitoring;

  /// DDoS protection controls.
  @SectionId('NSRD')
  @StandardReferences(
    ['ISO/IEC 27033 — network security'],
    'DDoS mitigation, rate limiting, and geo-blocking controls for the network.',
  )
  @Form([
    Field('ddosProtection', String, 'DDoS Protection', hint: 'DDoS mitigation'),
    Field('rateLimiting', String, 'Rate Limiting', hint: 'Rate limit policies'),
    Field(
      'geoBlocking',
      String,
      'Geo-Blocking',
      hint: 'Geographic restrictions',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? ddos;

  /// Compliance settings.
  @SectionId('NSRC')
  @StandardReferences(
    ['ISO/IEC 27033 — network security'],
    'Network security compliance requirements such as PCI-DSS and audit logging.',
  )
  @Form([
    Field(
      'pciDssCompliance',
      String,
      'PCI-DSS Network Compliance',
      hint: 'PCI network requirements',
    ),
    Field(
      'networkAuditLogs',
      String,
      'Network Audit Logs',
      hint: 'Audit logging',
    ),
    Field('notes', String, 'Notes', hint: 'Additional network security notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? compliance;
}

/// 8.5. Operations Requirements.
@DetailedIn(D06ArchitectureTechnologySpecification)
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
class OperationsRequirements extends DocSpecsSection {
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
  @override
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
class BackupAndRecoverySection extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of backup and recovery strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Data classification for backup purposes.
  @SerializationOrder(2)
  BackupDataClassification dataClassification = BackupDataClassification();

  /// Backup policies by data type.
  @StandardReferences([
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
  ], 'The backup policies the system applies.')
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
  DisasterRecoveryRequirements disasterRecovery =
      DisasterRecoveryRequirements();

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
class BackupDataClassification extends DocSpecsSection {
  @Form([
    Field(
      'criticalData',
      String,
      'Critical Data',
      hint: 'Data requiring highest protection',
    ),
    Field(
      'highPriorityData',
      String,
      'High Priority Data',
      hint: 'Important business data',
    ),
    Field(
      'mediumPriorityData',
      String,
      'Medium Priority Data',
      hint: 'Standard operational data',
    ),
    Field(
      'lowPriorityData',
      String,
      'Low Priority Data',
      hint: 'Non-essential data',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Included data categories.
  @SectionId('BDCC')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ITIL 4 — IT service management',
    ],
    'Lists the data categories, such as databases, files, and configuration, that are backed up.',
  )
  @Form([
    Field(
      'databaseData',
      String,
      'Database Data',
      hint: 'Which databases to back up',
    ),
    Field(
      'fileStorage',
      String,
      'File Storage',
      hint: 'File systems to back up',
    ),
    Field(
      'configurationData',
      String,
      'Configuration Data',
      hint: 'System configurations',
    ),
    Field('logData', String, 'Log Data', hint: 'Logs to archive/backup'),
    Field(
      'applicationState',
      String,
      'Application State',
      hint: 'Stateful application data',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? categories;

  /// Exclusions and regeneration rules.
  @SectionId('BDCE')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ITIL 4 — IT service management',
    ],
    'Identifies data excluded from backup and how ephemeral or cache data is regenerated.',
  )
  @Form([
    Field(
      'excludedData',
      String,
      'Excluded Data',
      hint: 'Data not requiring backup',
    ),
    Field(
      'temporaryData',
      String,
      'Temporary Data',
      hint: 'Ephemeral data handling',
    ),
    Field(
      'cacheData',
      String,
      'Cache Data',
      hint: 'Cache regeneration strategy',
    ),
    Field('notes', String, 'Notes', hint: 'Additional classification notes'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? exclusions;
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
class BackupPolicyEntry extends DocSpecsSection {
  @Form([
    Field(
      'policyName',
      String,
      'Policy Name',
      required: true,
      hint: 'Policy identifier',
    ),
    Field('dataScope', String, 'Data Scope', hint: 'What this policy covers'),
    Field('priority', String, 'Priority', hint: 'Critical, High, Medium, Low'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Backup type configuration.
  @SectionId('BPET')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ITIL 4 — IT service management',
    ],
    'Defines the backup type and the frequency of full, incremental, and differential backups.',
  )
  @Form([
    Field(
      'backupType',
      String,
      'Backup Type',
      hint: 'Full, Incremental, Differential',
    ),
    Field(
      'fullBackupFrequency',
      String,
      'Full Backup Frequency',
      hint: 'Daily, Weekly, Monthly',
    ),
    Field(
      'incrementalFrequency',
      String,
      'Incremental Frequency',
      hint: 'Hourly, Every 6 hours',
    ),
    Field(
      'differentialFrequency',
      String,
      'Differential Frequency',
      hint: 'If using differential',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? backupType;

  /// Schedule settings.
  @SectionId('BPES')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ITIL 4 — IT service management',
    ],
    'Defines the backup window, maximum duration, and timezone for scheduled backups.',
  )
  @Form([
    Field('backupWindow', String, 'Backup Window', hint: 'When backups run'),
    Field(
      'maxDuration',
      String,
      'Max Duration',
      hint: 'Maximum backup duration',
    ),
    Field('timezone', String, 'Timezone', hint: 'Backup schedule timezone'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? schedule;

  /// Retention policies.
  @SectionId('BPER')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ITIL 4 — IT service management',
    ],
    'Defines how long daily, weekly, monthly, and yearly backups are retained.',
  )
  @Form([
    Field(
      'retentionPeriod',
      String,
      'Retention Period',
      hint: 'How long to keep backups',
    ),
    Field(
      'dailyRetention',
      String,
      'Daily Retention',
      hint: 'Daily backup retention',
    ),
    Field(
      'weeklyRetention',
      String,
      'Weekly Retention',
      hint: 'Weekly backup retention',
    ),
    Field(
      'monthlyRetention',
      String,
      'Monthly Retention',
      hint: 'Monthly backup retention',
    ),
    Field(
      'yearlyRetention',
      String,
      'Yearly Retention',
      hint: 'Annual backup retention',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? retention;

  /// Storage configuration.
  @SectionId('BAPOENST')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ITIL 4 — IT service management',
    ],
    'Describes where backups are stored, plus off-site replication, encryption, and compression.',
  )
  @Form([
    Field(
      'storageLocation',
      String,
      'Storage Location',
      hint: 'Where backups are stored',
    ),
    Field(
      'offSiteReplication',
      bool,
      'Off-Site Replication',
      hint: 'Replicate to off-site',
    ),
    Field(
      'encryptionRequired',
      bool,
      'Encryption Required',
      hint: 'Encrypt backups',
    ),
    Field(
      'compressionEnabled',
      bool,
      'Compression Enabled',
      hint: 'Compress backups',
    ),
    Field(
      'verificationRequired',
      bool,
      'Verification Required',
      hint: 'Verify backup integrity',
    ),
    Field('notes', String, 'Notes', hint: 'Additional policy notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? storage;
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
class RpoRtoRequirements extends DocSpecsSection {
  @Form([
    Field(
      'overallRpo',
      String,
      'Overall RPO',
      hint: 'Maximum acceptable data loss',
    ),
    Field(
      'overallRto',
      String,
      'Overall RTO',
      hint: 'Maximum acceptable downtime',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Tier-based targets.
  @SectionId('RRRBT')
  @StandardReferences([
    'ISO 22301 — business continuity management',
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
  ], 'Defines RPO and RTO targets per data-criticality tier.')
  @Form([
    Field(
      'criticalRpo',
      String,
      'Critical Data RPO',
      hint: 'RPO for critical data',
    ),
    Field(
      'criticalRto',
      String,
      'Critical Data RTO',
      hint: 'RTO for critical systems',
    ),
    Field(
      'highRpo',
      String,
      'High Priority RPO',
      hint: 'RPO for high priority data',
    ),
    Field(
      'highRto',
      String,
      'High Priority RTO',
      hint: 'RTO for high priority systems',
    ),
    Field(
      'mediumRpo',
      String,
      'Medium Priority RPO',
      hint: 'RPO for medium priority',
    ),
    Field(
      'mediumRto',
      String,
      'Medium Priority RTO',
      hint: 'RTO for medium priority',
    ),
    Field('lowRpo', String, 'Low Priority RPO', hint: 'RPO for low priority'),
    Field('lowRto', String, 'Low Priority RTO', hint: 'RTO for low priority'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? byTier;

  /// System-specific recovery targets.
  @SectionId('RRRS')
  @StandardReferences([
    'ISO 22301 — business continuity management',
    'ISO/IEC 27031 — ICT business continuity / disaster recovery',
  ], 'Defines per-system RPO and RTO targets for databases and applications.')
  @Form([
    Field('databaseRpo', String, 'Database RPO', hint: 'Database-specific RPO'),
    Field(
      'databaseRto',
      String,
      'Database RTO',
      hint: 'Database recovery time',
    ),
    Field(
      'applicationRpo',
      String,
      'Application RPO',
      hint: 'Application state RPO',
    ),
    Field(
      'applicationRto',
      String,
      'Application RTO',
      hint: 'Application recovery time',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? systems;

  /// Degraded-mode guidance.
  @SectionId('RRRD')
  @StandardReferences(
    [
      'ISO 22301 — business continuity management',
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    ],
    'Describes whether partial restoration and minimal functionality are acceptable during recovery.',
  )
  @Form([
    Field(
      'degradedOperationAllowed',
      bool,
      'Degraded Operation Allowed',
      hint: 'Allow partial restoration',
    ),
    Field(
      'minimalFunctionality',
      String,
      'Minimal Functionality',
      hint: 'Minimum required functions',
    ),
    Field('notes', String, 'Notes', hint: 'Additional RPO/RTO notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? degraded;
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
class BackupInfrastructure extends DocSpecsSection {
  @Form([
    Field(
      'primaryStorage',
      String,
      'Primary Backup Storage',
      hint: 'Primary storage system',
    ),
    Field('storageType', String, 'Storage Type', hint: 'Object, block, tape'),
    Field(
      'storageCapacity',
      String,
      'Storage Capacity',
      hint: 'Required capacity',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Performance and secondary storage.
  @SectionId('BAINST')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ITIL 4 — IT service management',
    ],
    'Describes secondary storage, geographic separation, and cross-region replication for backups.',
  )
  @Form([
    Field(
      'storagePerformance',
      String,
      'Storage Performance',
      hint: 'IOPS, throughput',
    ),
    Field(
      'secondaryStorage',
      String,
      'Secondary Storage',
      hint: 'Secondary storage location',
    ),
    Field(
      'geographicSeparation',
      String,
      'Geographic Separation',
      hint: 'Distance from primary',
    ),
    Field(
      'cloudBackupProvider',
      String,
      'Cloud Backup Provider',
      hint: 'AWS S3, Azure Blob, GCS',
    ),
    Field(
      'crossRegionReplication',
      bool,
      'Cross-Region Replication',
      hint: 'Replicate across regions',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? storage;

  /// Backup software configuration.
  @SectionId('BAINSO')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ITIL 4 — IT service management',
    ],
    'Describes the backup software, agent model, and deduplication configuration.',
  )
  @Form([
    Field(
      'backupSoftware',
      String,
      'Backup Software',
      hint: 'Backup solution used',
    ),
    Field('agentBased', bool, 'Agent-Based', hint: 'Requires backup agents'),
    Field(
      'agentlessBackup',
      bool,
      'Agentless Backup',
      hint: 'Snapshot-based backup',
    ),
    Field('deduplication', bool, 'Deduplication', hint: 'Enable deduplication'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? software;

  /// Network requirements.
  @SectionId('BAINNE')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ITIL 4 — IT service management',
    ],
    'Describes the dedicated network, bandwidth, and in-transit encryption for backup traffic.',
  )
  @Form([
    Field(
      'backupNetwork',
      String,
      'Backup Network',
      hint: 'Dedicated backup network',
    ),
    Field(
      'bandwidthRequired',
      String,
      'Bandwidth Required',
      hint: 'Network bandwidth',
    ),
    Field(
      'encryptionInTransit',
      bool,
      'Encryption in Transit',
      hint: 'Encrypt backup traffic',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? network;

  /// Security controls.
  @SectionId('BAINSE')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Describes access control, encryption, key management, and immutability for backups.',
  )
  @Form([
    Field(
      'accessControl',
      String,
      'Access Control',
      hint: 'Who can access backups',
    ),
    Field(
      'encryptionAlgorithm',
      String,
      'Encryption Algorithm',
      hint: 'AES-256 etc.',
    ),
    Field(
      'keyManagement',
      String,
      'Key Management',
      hint: 'Encryption key handling',
    ),
    Field(
      'immutableBackups',
      bool,
      'Immutable Backups',
      hint: 'WORM compliance',
    ),
    Field('notes', String, 'Notes', hint: 'Additional infrastructure notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? security;
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
class RecoveryProcedures extends DocSpecsSection {
  @Form([
    Field(
      'granularRecovery',
      String,
      'Granular Recovery',
      hint: 'File/item-level recovery',
    ),
    Field(
      'volumeRecovery',
      String,
      'Volume Recovery',
      hint: 'Volume-level recovery',
    ),
    Field(
      'systemRecovery',
      String,
      'Full System Recovery',
      hint: 'Complete system restore',
    ),
    Field(
      'bareMetalRecovery',
      bool,
      'Bare Metal Recovery',
      hint: 'Hardware replacement',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Database recovery behavior.
  @SectionId('REPRDA')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ITIL 4 — IT service management',
    ],
    'Describes database restore, point-in-time, and transaction-log recovery behavior.',
  )
  @Form([
    Field(
      'databaseRecovery',
      String,
      'Database Recovery',
      hint: 'Database restore process',
    ),
    Field(
      'pointInTimeRecovery',
      bool,
      'Point-in-Time Recovery',
      hint: 'Restore to specific time',
    ),
    Field(
      'transactionLogRecovery',
      bool,
      'Transaction Log Recovery',
      hint: 'Log-based recovery',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? database;

  /// Application recovery behavior.
  @SectionId('REPRAP')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ITIL 4 — IT service management',
    ],
    'Describes how application, configuration, and state are restored during recovery.',
  )
  @Form([
    Field(
      'applicationRecovery',
      String,
      'Application Recovery',
      hint: 'App restoration process',
    ),
    Field(
      'configurationRecovery',
      String,
      'Configuration Recovery',
      hint: 'Config restoration',
    ),
    Field(
      'stateRecovery',
      String,
      'State Recovery',
      hint: 'Session/state restoration',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? application;

  /// Recovery automation.
  @SectionId('REPRAU')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'Google SRE — site reliability engineering',
    ],
    'Describes automated recovery, recovery scripts, and where runbooks are stored.',
  )
  @Form([
    Field(
      'automatedRecovery',
      bool,
      'Automated Recovery',
      hint: 'Auto-failover enabled',
    ),
    Field(
      'recoveryScripts',
      String,
      'Recovery Scripts',
      hint: 'Scripted recovery',
    ),
    Field(
      'runbookLocation',
      String,
      'Runbook Location',
      hint: 'Where runbooks are stored',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? automation;

  /// Validation after recovery.
  @SectionId('REPRVA')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'Google SRE — site reliability engineering',
    ],
    'Describes the sanity and service checks that confirm data integrity after a restore.',
  )
  @Form([
    Field(
      'postRecoveryValidation',
      String,
      'Post-Recovery Validation',
      hint: 'Validation procedures',
    ),
    Field(
      'sanityChecks',
      String,
      'Sanity Checks',
      hint: 'Data integrity checks',
    ),
    Field(
      'serviceValidation',
      String,
      'Service Validation',
      hint: 'Service health verification',
    ),
    Field('notes', String, 'Notes', hint: 'Additional recovery notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? validation;
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
class DisasterRecoveryRequirements extends DocSpecsSection {
  @Form([
    Field('drStrategy', String, 'DR Strategy', hint: 'Hot, Warm, Cold standby'),
    Field('drSite', String, 'DR Site Location', hint: 'DR site location'),
    Field('drProvider', String, 'DR Provider', hint: 'DR service provider'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Failover execution.
  @SectionId('DRRF')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ISO 22301 — business continuity management',
    ],
    'Defines the failover type, trigger threshold, and duration for switching to the DR site.',
  )
  @Form([
    Field(
      'failoverType',
      String,
      'Failover Type',
      hint: 'Automatic, Manual, Semi-auto',
    ),
    Field(
      'failoverThreshold',
      String,
      'Failover Threshold',
      hint: 'When to trigger failover',
    ),
    Field(
      'failoverDuration',
      String,
      'Failover Duration',
      hint: 'Time to complete failover',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? failover;

  /// Failback procedure.
  @SectionId('DIREREFA')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ISO 22301 — business continuity management',
    ],
    'Describes returning from the DR site to primary and re-synchronizing data after failback.',
  )
  @Form([
    Field(
      'failbackProcedure',
      String,
      'Failback Procedure',
      hint: 'Return to primary',
    ),
    Field(
      'failbackValidation',
      String,
      'Failback Validation',
      hint: 'Validating failback',
    ),
    Field(
      'dataSync',
      String,
      'Data Synchronization',
      hint: 'Syncing after failback',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? failback;

  /// Replication requirements.
  @SectionId('DRRR')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ISO 22301 — business continuity management',
    ],
    'Specifies the replication method, acceptable lag, and bandwidth for the DR site.',
  )
  @Form([
    Field(
      'replicationMethod',
      String,
      'Replication Method',
      hint: 'Sync, Async replication',
    ),
    Field('replicationLag', String, 'Replication Lag', hint: 'Acceptable lag'),
    Field(
      'replicationBandwidth',
      String,
      'Replication Bandwidth',
      hint: 'Bandwidth for DR',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? replication;

  /// Continuity and coordination.
  @SectionId('DRRC')
  @StandardReferences(
    [
      'ISO 22301 — business continuity management',
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    ],
    'Links disaster recovery to the business continuity plan, communication, and escalation.',
  )
  @Form([
    Field(
      'businessContinuityPlan',
      String,
      'Business Continuity Plan',
      hint: 'BCP reference',
    ),
    Field(
      'communicationPlan',
      String,
      'Communication Plan',
      hint: 'Stakeholder notification',
    ),
    Field('escalationPath', String, 'Escalation Path', hint: 'DR escalation'),
    Field('drTeam', String, 'DR Team', hint: 'DR response team'),
    Field('notes', String, 'Notes', hint: 'Additional DR notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? continuity;
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
class BackupVerification extends DocSpecsSection {
  @Form([
    Field(
      'verificationFrequency',
      String,
      'Verification Frequency',
      hint: 'How often to verify',
    ),
    Field(
      'verificationMethod',
      String,
      'Verification Method',
      hint: 'Checksum, test restore',
    ),
    Field(
      'integrityChecks',
      bool,
      'Integrity Checks',
      hint: 'Automated integrity checks',
    ),
    Field(
      'alertOnFailure',
      bool,
      'Alert on Failure',
      hint: 'Notify on verification failure',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Recovery testing.
  @SectionId('BAVERE')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ISO 22301 — business continuity management',
    ],
    'Defines the schedule and scope of recovery tests and disaster-recovery drills.',
  )
  @Form([
    Field(
      'recoveryTestFrequency',
      String,
      'Recovery Test Frequency',
      hint: 'How often to test recovery',
    ),
    Field(
      'fullRecoveryTest',
      String,
      'Full Recovery Test',
      hint: 'Complete restore test',
    ),
    Field(
      'partialRecoveryTest',
      String,
      'Partial Recovery Test',
      hint: 'Selective restore test',
    ),
    Field('drTest', String, 'DR Test', hint: 'Disaster recovery drill'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? recovery;

  /// Test environment constraints.
  @SectionId('BAVEEN')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'Google SRE — site reliability engineering',
    ],
    'Defines the isolated environment and data handling used for recovery testing.',
  )
  @Form([
    Field(
      'testEnvironment',
      String,
      'Test Environment',
      hint: 'Where tests run',
    ),
    Field(
      'testDataHandling',
      String,
      'Test Data Handling',
      hint: 'Handling test data',
    ),
    Field(
      'productionIsolation',
      bool,
      'Production Isolation',
      hint: 'Isolated from production',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? environment;

  /// Documentation and follow-up.
  @SectionId('BAVEDO')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ITIL 4 — IT service management',
    ],
    'Records how verification test results are documented, signed off, and remediated.',
  )
  @Form([
    Field(
      'testDocumentation',
      String,
      'Test Documentation',
      hint: 'Test result documentation',
    ),
    Field('testSignoff', String, 'Test Sign-off', hint: 'Who approves tests'),
    Field(
      'deficiencyRemediation',
      String,
      'Deficiency Remediation',
      hint: 'Addressing test failures',
    ),
    Field('notes', String, 'Notes', hint: 'Additional verification notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? documentation;
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
class BackupCompliance extends DocSpecsSection {
  @Form([
    Field(
      'regulatoryRequirements',
      String,
      'Regulatory Requirements',
      hint: 'GDPR, HIPAA, SOX etc.',
    ),
    Field(
      'retentionCompliance',
      String,
      'Retention Compliance',
      hint: 'Legal retention requirements',
    ),
    Field(
      'dataResidency',
      String,
      'Data Residency',
      hint: 'Where backups can be stored',
    ),
    Field(
      'crossBorderTransfer',
      bool,
      'Cross-Border Transfer',
      hint: 'International data transfer',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Audit controls.
  @SectionId('BACOAU')
  @StandardReferences(
    [
      'ISO/IEC 20000 — IT service management system',
      'ITIL 4 — IT service management',
    ],
    'Describes audit trails, access logging, and change management for backup operations.',
  )
  @Form([
    Field('auditTrail', bool, 'Audit Trail', hint: 'Backup operation logging'),
    Field('accessLogging', bool, 'Access Logging', hint: 'Log backup access'),
    Field(
      'changeManagement',
      String,
      'Change Management',
      hint: 'Backup policy changes',
    ),
    Field(
      'auditFrequency',
      String,
      'Audit Frequency',
      hint: 'How often audited',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? audit;

  /// Reporting obligations.
  @SectionId('BACOR1')
  @StandardReferences(
    [
      'ISO/IEC 20000 — IT service management system',
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    ],
    'Defines the compliance reporting produced from backup operations and who receives it.',
  )
  @Form([
    Field(
      'complianceReporting',
      String,
      'Compliance Reporting',
      hint: 'Required reports',
    ),
    Field(
      'reportFrequency',
      String,
      'Report Frequency',
      hint: 'How often reported',
    ),
    Field(
      'reportRecipients',
      String,
      'Report Recipients',
      hint: 'Who receives reports',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? reporting;

  /// Legal hold support.
  @SectionId('BCLH')
  @StandardReferences(
    [
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Describes legal hold and eDiscovery support so backups can be preserved for litigation.',
  )
  @Form([
    Field(
      'legalHoldCapability',
      bool,
      'Legal Hold Capability',
      hint: 'Support legal holds',
    ),
    Field(
      'legalHoldProcess',
      String,
      'Legal Hold Process',
      hint: 'How legal holds work',
    ),
    Field(
      'eDiscovery',
      String,
      'eDiscovery Support',
      hint: 'Supporting eDiscovery',
    ),
    Field('notes', String, 'Notes', hint: 'Additional compliance notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? legalHold;
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
class DeploymentStrategySection extends DocSpecsSection {
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
  @override
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
class DeploymentModelRequirements extends DocSpecsSection {
  @Form([
    Field(
      'deploymentModel',
      String,
      'Deployment Model',
      hint: 'Containerized, VM-based, Serverless, Hybrid',
    ),
    Field(
      'containerRuntime',
      String,
      'Container Runtime',
      hint: 'Docker, containerd, CRI-O',
    ),
    Field(
      'orchestrationPlatform',
      String,
      'Orchestration Platform',
      hint: 'Kubernetes, ECS, Nomad',
    ),
    Field(
      'serverlessProvider',
      String,
      'Serverless Provider',
      hint: 'AWS Lambda, Azure Functions, Cloud Run',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Container image policies.
  @SectionId('DMRC')
  @StandardReferences(
    [
      'CI/CD — continuous delivery pipelines',
      'ISO/IEC 27001 — information security controls',
    ],
    'Defines container image policies: registry, security scanning on push, tagging strategy, and approved base images.',
  )
  @Form([
    Field(
      'containerRegistry',
      String,
      'Container Registry',
      hint: 'ECR, ACR, GCR, Docker Hub',
    ),
    Field(
      'imageScanningRequired',
      bool,
      'Image Scanning Required',
      hint: 'Security scanning on push',
    ),
    Field(
      'imageTaggingStrategy',
      String,
      'Image Tagging Strategy',
      hint: 'Semantic versioning, git SHA',
    ),
    Field(
      'baseImagePolicy',
      String,
      'Base Image Policy',
      hint: 'Approved base images',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? container;

  /// Resource allocation.
  @SectionId('DMRR')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering',
      'Twelve-Factor App — cloud-native ops',
    ],
    'Defines CPU/memory resource requirements, scaling configuration, and replica counts for deployed workloads.',
  )
  @Form([
    Field(
      'resourceRequirements',
      String,
      'Resource Requirements',
      hint: 'CPU, memory specifications',
    ),
    Field(
      'scalingConfiguration',
      String,
      'Scaling Configuration',
      hint: 'HPA, VPA, cluster autoscaler',
    ),
    Field(
      'replicaCount',
      String,
      'Replica Count',
      hint: 'Default and min/max replicas',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? resources;

  /// Networking configuration.
  @SectionId('DMRN')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native ops',
      'Google SRE — site reliability engineering',
    ],
    'Defines the deployment networking: service discovery, ingress configuration, and load balancing.',
  )
  @Form([
    Field(
      'serviceDiscovery',
      String,
      'Service Discovery',
      hint: 'DNS, service mesh',
    ),
    Field(
      'ingressConfiguration',
      String,
      'Ingress Configuration',
      hint: 'Ingress controller, routes',
    ),
    Field(
      'loadBalancing',
      String,
      'Load Balancing',
      hint: 'ALB, NLB, internal LB',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? networking;

  /// Storage configuration.
  @SectionId('DMRS')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native ops',
      'Google SRE — site reliability engineering',
    ],
    'Defines persistent-storage requirements and storage classes for deployed workloads.',
  )
  @Form([
    Field(
      'persistentStorage',
      String,
      'Persistent Storage',
      hint: 'PVC, EBS, EFS requirements',
    ),
    Field(
      'storageClass',
      String,
      'Storage Class',
      hint: 'SSD, HDD, performance tier',
    ),
    Field('notes', String, 'Notes', hint: 'Additional deployment model notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? storage;
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
class EnvironmentStrategy extends DocSpecsSection {
  @Form([
    Field(
      'environmentTiers',
      String,
      'Environment Tiers',
      hint: 'Dev, Test, Staging, Prod',
    ),
    Field(
      'environmentParity',
      String,
      'Environment Parity',
      hint: 'How similar envs are to prod',
    ),
    Field(
      'environmentIsolation',
      String,
      'Environment Isolation',
      hint: 'Network, account, cluster isolation',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Development environment setup.
  @SectionId('ENSTDE')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native ops',
      'CI/CD — continuous delivery pipelines',
    ],
    'Defines the development and local environment setup and the strategy for development data.',
  )
  @Form([
    Field(
      'devEnvironment',
      String,
      'Development Environment',
      hint: 'Dev environment setup',
    ),
    Field(
      'localDevelopment',
      String,
      'Local Development',
      hint: 'Local dev environment',
    ),
    Field(
      'devDataStrategy',
      String,
      'Dev Data Strategy',
      hint: 'Synthetic, anonymized, subset',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? development;

  /// Test environment setup.
  @SectionId('ENSTTE')
  @StandardReferences(
    [
      'CI/CD — continuous delivery pipelines',
      'Twelve-Factor App — cloud-native ops',
    ],
    'Defines the test, integration, and performance environments used to validate changes before release.',
  )
  @Form([
    Field(
      'testEnvironment',
      String,
      'Test Environment',
      hint: 'Test/QA environment',
    ),
    Field(
      'integrationEnvironment',
      String,
      'Integration Environment',
      hint: 'Integration testing env',
    ),
    Field(
      'performanceEnvironment',
      String,
      'Performance Environment',
      hint: 'Performance testing env',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? testing;

  /// Staging configuration.
  @SectionId('ENSTST')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native ops',
      'CI/CD — continuous delivery pipelines',
    ],
    'Defines the pre-production staging environment, its parity with production, and how its data is refreshed.',
  )
  @Form([
    Field(
      'stagingEnvironment',
      String,
      'Staging Environment',
      hint: 'Pre-production staging',
    ),
    Field(
      'stagingProdParity',
      bool,
      'Staging-Prod Parity',
      hint: 'Staging mirrors production',
    ),
    Field(
      'stagingDataRefresh',
      String,
      'Staging Data Refresh',
      hint: 'How staging data is refreshed',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? staging;

  /// Production configuration.
  @SectionId('ENSTPR')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering',
      'Twelve-Factor App — cloud-native ops',
    ],
    'Defines the production environment configuration, including multi-region and active-active deployment topology.',
  )
  @Form([
    Field(
      'productionEnvironment',
      String,
      'Production Environment',
      hint: 'Production deployment',
    ),
    Field('multiRegion', bool, 'Multi-Region', hint: 'Multi-region deployment'),
    Field(
      'activeActive',
      bool,
      'Active-Active',
      hint: 'Active-active configuration',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? production;

  /// Ephemeral environment strategy.
  @SectionId('ENSTEP')
  @StandardReferences(
    [
      'CI/CD — continuous delivery pipelines',
      'Twelve-Factor App — cloud-native ops',
    ],
    'Defines ephemeral per-PR or per-feature environments and their auto-cleanup lifecycle.',
  )
  @Form([
    Field(
      'ephemeralEnvironments',
      bool,
      'Ephemeral Environments',
      hint: 'Per-PR/feature environments',
    ),
    Field(
      'environmentLifecycle',
      String,
      'Environment Lifecycle',
      hint: 'Auto-cleanup, retention',
    ),
    Field('notes', String, 'Notes', hint: 'Additional environment notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? ephemeral;
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
class CiCdPipelineRequirements extends DocSpecsSection {
  @Form([
    Field(
      'cicdPlatform',
      String,
      'CI/CD Platform',
      hint: 'GitHub Actions, GitLab CI, Jenkins',
    ),
    Field(
      'pipelineAsCode',
      bool,
      'Pipeline as Code',
      hint: 'Pipeline definition in repo',
    ),
    Field(
      'pipelineLocation',
      String,
      'Pipeline Location',
      hint: 'Where pipeline files are stored',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Build stage settings.
  @SectionId('CCPRB')
  @StandardReferences(
    [
      'CI/CD — continuous delivery pipelines',
      'DORA metrics — DevOps performance',
    ],
    'Defines the build stage: triggers, compile/test/lint/scan steps, dependency caching, and produced artifacts.',
  )
  @Form([
    Field(
      'buildTriggers',
      String,
      'Build Triggers',
      hint: 'Push, PR, tag, schedule',
    ),
    Field(
      'buildSteps',
      String,
      'Build Steps',
      hint: 'Compile, test, lint, scan',
    ),
    Field(
      'buildCaching',
      String,
      'Build Caching',
      hint: 'Dependency caching strategy',
    ),
    Field(
      'buildArtifacts',
      String,
      'Build Artifacts',
      hint: 'What artifacts are produced',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? build;

  /// Quality gate settings.
  @SectionId('CCPRQ')
  @StandardReferences(
    [
      'CI/CD — continuous delivery pipelines',
      'ISO/IEC 27001 — information security controls',
    ],
    'Defines pipeline quality gates: code-quality checks, test-coverage thresholds, security scans, and manual approval gates.',
  )
  @Form([
    Field(
      'codeQualityGates',
      String,
      'Code Quality Gates',
      hint: 'Linting, static analysis',
    ),
    Field(
      'testCoverageThreshold',
      String,
      'Test Coverage Threshold',
      hint: 'Minimum coverage required',
    ),
    Field(
      'securityScanRequired',
      bool,
      'Security Scan Required',
      hint: 'SAST, SCA in pipeline',
    ),
    Field(
      'approvalRequired',
      bool,
      'Approval Required',
      hint: 'Manual approval gates',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? quality;

  /// Deployment stage settings.
  @SectionId('CCPRD')
  @StandardReferences(
    [
      'CI/CD — continuous delivery pipelines',
      'DORA metrics — DevOps performance',
    ],
    'Defines the ordered deployment stages, auto-deploy behavior per environment, and the production deployment gate.',
  )
  @Form([
    Field(
      'deploymentStages',
      String,
      'Deployment Stages',
      hint: 'Ordered deployment stages',
    ),
    Field(
      'autoDeployDev',
      bool,
      'Auto-Deploy to Dev',
      hint: 'Auto-deploy on merge',
    ),
    Field(
      'autoDeployStaging',
      bool,
      'Auto-Deploy to Staging',
      hint: 'Auto-deploy to staging',
    ),
    Field(
      'productionGate',
      String,
      'Production Gate',
      hint: 'Prod deployment gate',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? deployment;

  /// Notification and escalation settings.
  @SectionId('CCPRN')
  @StandardReferences(
    [
      'CI/CD — continuous delivery pipelines',
      'Google SRE — site reliability engineering',
    ],
    'Defines pipeline notifications and the escalation path when a build or deployment fails.',
  )
  @Form([
    Field(
      'pipelineNotifications',
      String,
      'Pipeline Notifications',
      hint: 'Slack, email, Teams alerts',
    ),
    Field(
      'failureEscalation',
      String,
      'Failure Escalation',
      hint: 'Build failure response',
    ),
    Field('notes', String, 'Notes', hint: 'Additional CI/CD notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? notifications;
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
class ReleaseStrategy extends DocSpecsSection {
  @Form([
    Field(
      'releaseMethodology',
      String,
      'Release Methodology',
      hint: 'Blue-green, Canary, Rolling, A/B',
    ),
    Field(
      'releaseFrequency',
      String,
      'Release Frequency',
      hint: 'Daily, Weekly, Bi-weekly',
    ),
    Field(
      'releaseSchedule',
      String,
      'Release Schedule',
      hint: 'When releases occur',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Blue-green deployment configuration.
  @SectionId('RSBG')
  @StandardReferences(
    [
      'CI/CD — continuous delivery pipelines',
      'Google SRE — site reliability engineering',
    ],
    'Defines blue-green deployment: traffic switching, warmup period, and retention of the old (green) version for fast switch-back.',
  )
  @Form([
    Field(
      'releaseWindow',
      String,
      'Release Window',
      hint: 'Allowed deployment times',
    ),
    Field(
      'blueGreenEnabled',
      bool,
      'Blue-Green Enabled',
      hint: 'Uses blue-green deployment',
    ),
    Field(
      'trafficSwitching',
      String,
      'Traffic Switching',
      hint: 'How traffic is switched',
    ),
    Field(
      'warmupPeriod',
      String,
      'Warmup Period',
      hint: 'New version warmup time',
    ),
    Field(
      'greenRetention',
      String,
      'Green Retention',
      hint: 'How long to keep old version',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? blueGreen;

  /// Canary deployment configuration.
  @SectionId('RESTCA')
  @StandardReferences(
    [
      'CI/CD — continuous delivery pipelines',
      'Google SRE — site reliability engineering',
    ],
    'Defines canary deployment: initial traffic percentage, ramp-up steps, health metrics, and auto-rollback criteria.',
  )
  @Form([
    Field(
      'canaryEnabled',
      bool,
      'Canary Enabled',
      hint: 'Uses canary deployment',
    ),
    Field(
      'canaryPercentage',
      String,
      'Canary Percentage',
      hint: 'Initial canary traffic %',
    ),
    Field(
      'canaryRampUpSteps',
      String,
      'Canary Ramp-Up Steps',
      hint: 'Percentage ramp-up steps',
    ),
    Field(
      'canaryMetrics',
      String,
      'Canary Metrics',
      hint: 'Metrics for canary health',
    ),
    Field(
      'canaryDuration',
      String,
      'Canary Duration',
      hint: 'Time at each step',
    ),
    Field(
      'autoRollbackCriteria',
      String,
      'Auto-Rollback Criteria',
      hint: 'When to auto-rollback canary',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? canary;

  /// Feature flags configuration.
  @SectionId('RSFF')
  @StandardReferences(
    [
      'CI/CD — continuous delivery pipelines',
      'Twelve-Factor App — cloud-native ops',
    ],
    'Defines feature-flag usage for decoupling deploy from release, including provider and flag-management strategy.',
  )
  @Form([
    Field(
      'featureFlagsEnabled',
      bool,
      'Feature Flags Enabled',
      hint: 'Uses feature flags',
    ),
    Field(
      'featureFlagProvider',
      String,
      'Feature Flag Provider',
      hint: 'LaunchDarkly, Flagsmith, custom',
    ),
    Field(
      'flagStrategy',
      String,
      'Flag Strategy',
      hint: 'How flags are managed',
    ),
  ])
  @CodeSpecKind(
    [CodeSpecPart.serverConfiguration],
    note:
        'CE-CF — feature flags are config toggles authored as server '
        'configuration values; authorization-derived feature grants are '
        'server-level entitlements (mapping doc codespecs_mapping.md §5.26). The '
        'deploy-from-release flag itself is deployment tooling.',
  )
  @SerializationOrder(3)
  DocSpecsSection? featureFlags;

  /// Release management.
  @SectionId('RESTMA')
  @StandardReferences(
    ['ITIL 4 — IT service management', 'CI/CD — continuous delivery pipelines'],
    'Defines release management practices: release notes, changelog generation, and release approval.',
  )
  @Form([
    Field(
      'releaseNotes',
      String,
      'Release Notes',
      hint: 'Release notes process',
    ),
    Field(
      'changelogGeneration',
      String,
      'Changelog Generation',
      hint: 'Auto or manual changelog',
    ),
    Field(
      'releaseApproval',
      String,
      'Release Approval',
      hint: 'Who approves releases',
    ),
    Field('notes', String, 'Notes', hint: 'Additional release notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? management;
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
class RollbackStrategy extends DocSpecsSection {
  @Form([
    Field(
      'rollbackMethod',
      String,
      'Rollback Method',
      hint: 'Redeploy, traffic switch, restore',
    ),
    Field(
      'autoRollbackEnabled',
      bool,
      'Auto-Rollback Enabled',
      hint: 'Automatic rollback on failure',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Trigger and timing conditions.
  @SectionId('ROSTTR')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering',
      'DORA metrics — DevOps performance',
    ],
    'Defines what triggers a rollback and the target time to complete it (time-to-restore).',
  )
  @Form([
    Field(
      'rollbackTriggers',
      String,
      'Rollback Triggers',
      hint: 'What triggers rollback',
    ),
    Field(
      'rollbackTimeTarget',
      String,
      'Rollback Time Target',
      hint: 'Max time to complete rollback',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? triggers;

  /// Health-based rollback thresholds.
  @SectionId('ROSTHE')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering',
      'DORA metrics — DevOps performance',
    ],
    'Defines health signal thresholds — error rate, latency, and health-check failures — that trigger an automatic rollback.',
  )
  @Form([
    Field(
      'healthCheckFailures',
      String,
      'Health Check Failures',
      hint: 'Failures before rollback',
    ),
    Field(
      'errorRateThreshold',
      String,
      'Error Rate Threshold',
      hint: 'Error rate triggering rollback',
    ),
    Field(
      'latencyThreshold',
      String,
      'Latency Threshold',
      hint: 'Latency triggering rollback',
    ),
    Field(
      'customMetricThresholds',
      String,
      'Custom Metric Thresholds',
      hint: 'Business metrics for rollback',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? health;

  /// Rollback target and artifact retention.
  @SectionId('ROSTTA')
  @StandardReferences(
    [
      'CI/CD — continuous delivery pipelines',
      'Google SRE — site reliability engineering',
    ],
    'Defines which version a rollback targets and how many prior artifacts are retained for rollback.',
  )
  @Form([
    Field(
      'rollbackTarget',
      String,
      'Rollback Target',
      hint: 'Previous version, specific version',
    ),
    Field(
      'versionRetention',
      String,
      'Version Retention',
      hint: 'How many versions kept',
    ),
    Field(
      'artifactStorage',
      String,
      'Artifact Storage',
      hint: 'Where rollback artifacts stored',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? targets;

  /// Data rollback safeguards.
  @SectionId('ROSTDA')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering',
      'CI/CD — continuous delivery pipelines',
    ],
    'Defines safeguards for rolling back data and database migrations while preserving backward compatibility.',
  )
  @Form([
    Field(
      'dataRollbackStrategy',
      String,
      'Data Rollback Strategy',
      hint: 'How to handle data on rollback',
    ),
    Field(
      'migrationRollback',
      String,
      'Migration Rollback',
      hint: 'Database migration rollback',
    ),
    Field(
      'backwardCompatibility',
      String,
      'Backward Compatibility',
      hint: 'Data format compatibility',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? data;

  /// Manual procedure and follow-up.
  @SectionId('ROSTOP')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering',
      'ITIL 4 — IT service management',
    ],
    'Defines the manual rollback procedure, validation of a successful rollback, and post-rollback follow-up actions.',
  )
  @Form([
    Field(
      'manualRollbackProcedure',
      String,
      'Manual Rollback Procedure',
      hint: 'Steps for manual rollback',
    ),
    Field(
      'rollbackValidation',
      String,
      'Rollback Validation',
      hint: 'Validating successful rollback',
    ),
    Field(
      'postRollbackActions',
      String,
      'Post-Rollback Actions',
      hint: 'Actions after rollback',
    ),
    Field('notes', String, 'Notes', hint: 'Additional rollback notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? operations;
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
@CodeSpecKind(
  [CodeSpecPart.serverConfiguration],
  note:
      'Server-side application configuration and secrets stored/versioned '
      'across environments (CsServerConfig, codespecs_mapping.md §5.5).',
)
class ConfigurationManagement extends DocSpecsSection {
  @Form([
    Field(
      'configStorage',
      String,
      'Configuration Storage',
      hint: 'ConfigMaps, SSM, Consul',
    ),
    Field(
      'secretsManagement',
      String,
      'Secrets Management',
      hint: 'Vault, AWS Secrets, Azure KV',
    ),
    Field(
      'configVersioning',
      bool,
      'Config Versioning',
      hint: 'Version controlled config',
    ),
    Field('configAudit', bool, 'Config Audit', hint: 'Audit config changes'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Environment-configuration rules.
  @SectionId('COMAEN')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native ops',
      'CI/CD — continuous delivery pipelines',
    ],
    'Defines how configuration differs per environment through inheritance and override patterns, with validation.',
  )
  @Form([
    Field(
      'envSpecificConfig',
      String,
      'Environment-Specific Config',
      hint: 'How env config differs',
    ),
    Field(
      'configInheritance',
      String,
      'Config Inheritance',
      hint: 'Base + override pattern',
    ),
    Field(
      'configValidation',
      String,
      'Config Validation',
      hint: 'Config validation process',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? environment;

  /// Configuration injection rules.
  @SectionId('COMAIN')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native ops',
      'Google SRE — site reliability engineering',
    ],
    'Defines how configuration is injected into running apps and how they reload it dynamically at runtime.',
  )
  @Form([
    Field(
      'configInjectionMethod',
      String,
      'Config Injection Method',
      hint: 'Env vars, mounted files',
    ),
    Field(
      'dynamicConfig',
      bool,
      'Dynamic Config',
      hint: 'Runtime config updates',
    ),
    Field(
      'configReload',
      String,
      'Config Reload',
      hint: 'How apps reload config',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? injection;

  /// Feature-configuration rules.
  @SectionId('COMAFE')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native ops',
      'CI/CD — continuous delivery pipelines',
    ],
    'Defines feature-toggle, experiment, and per-tenant configuration rules that vary runtime behavior.',
  )
  @Form([
    Field(
      'featureToggles',
      String,
      'Feature Toggles',
      hint: 'Feature toggle management',
    ),
    Field(
      'experimentsConfig',
      String,
      'Experiments Config',
      hint: 'A/B test configuration',
    ),
    Field(
      'tenantConfig',
      String,
      'Tenant Configuration',
      hint: 'Per-tenant configuration',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? features;

  /// Security controls.
  @SectionId('COMASE')
  @StandardReferences(
    [
      'ISO/IEC 27001 — information security controls',
      'Twelve-Factor App — cloud-native ops',
    ],
    'Defines security controls over configuration, including secret rotation and access control for who may manage config.',
  )
  @Form([
    Field(
      'secretRotation',
      String,
      'Secret Rotation',
      hint: 'Secret rotation policy',
    ),
    Field(
      'accessControl',
      String,
      'Access Control',
      hint: 'Who can manage config',
    ),
    Field('notes', String, 'Notes', hint: 'Additional config notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? security;
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
class InfrastructureAsCode extends DocSpecsSection {
  @Form([
    Field(
      'iacTool',
      String,
      'IaC Tool',
      hint: 'Terraform, Pulumi, CloudFormation',
    ),
    Field(
      'iacRepository',
      String,
      'IaC Repository',
      hint: 'Where IaC code lives',
    ),
    Field(
      'iacModules',
      String,
      'IaC Modules',
      hint: 'Reusable modules strategy',
    ),
    Field(
      'iacRegistry',
      String,
      'IaC Registry',
      hint: 'Private module registry',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// State management.
  @SectionId('IACS')
  @StandardReferences(
    [
      'Twelve-Factor App — cloud-native ops',
      'Google SRE — site reliability engineering',
    ],
    'Defines how infrastructure state is stored, locked against concurrent changes, and separated per environment.',
  )
  @Form([
    Field('stateStorage', String, 'State Storage', hint: 'S3, GCS, Azure Blob'),
    Field(
      'stateLocking',
      bool,
      'State Locking',
      hint: 'Prevent concurrent changes',
    ),
    Field(
      'stateEnvironmentSeparation',
      String,
      'State Separation',
      hint: 'Per-environment state files',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? state;

  /// Execution governance.
  @SectionId('IACE')
  @StandardReferences(
    ['ITIL 4 — IT service management', 'CI/CD — continuous delivery pipelines'],
    'Governs how infrastructure plans are reviewed, approved, and applied through the CI/CD pipeline.',
  )
  @Form([
    Field('planReview', String, 'Plan Review', hint: 'Who reviews IaC plans'),
    Field(
      'applyApproval',
      String,
      'Apply Approval',
      hint: 'Approval for applying changes',
    ),
    Field(
      'pipelineIntegration',
      String,
      'Pipeline Integration',
      hint: 'IaC in CI/CD pipeline',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? execution;

  /// Drift detection settings.
  @SectionId('IACD')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering',
      'Twelve-Factor App — cloud-native ops',
    ],
    'Defines how manual drift from the desired infrastructure state is detected, remediated, and reconciled on a schedule.',
  )
  @Form([
    Field(
      'driftDetection',
      bool,
      'Drift Detection',
      hint: 'Detect manual changes',
    ),
    Field(
      'driftRemediation',
      String,
      'Drift Remediation',
      hint: 'How to handle drift',
    ),
    Field(
      'reconciliationSchedule',
      String,
      'Reconciliation Schedule',
      hint: 'When to check for drift',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? drift;

  /// Security and policy controls.
  @SectionId('INASCOSE')
  @StandardReferences(
    [
      'ISO/IEC 27001 — information security controls',
      'Twelve-Factor App — cloud-native ops',
    ],
    'Defines security and policy-as-code controls for infrastructure code, including sensitive-value handling and compliance checks.',
  )
  @Form([
    Field(
      'sensitiveValueHandling',
      String,
      'Sensitive Value Handling',
      hint: 'Handling secrets in IaC',
    ),
    Field(
      'policyAsCode',
      String,
      'Policy as Code',
      hint: 'OPA, Sentinel policies',
    ),
    Field(
      'complianceChecks',
      String,
      'Compliance Checks',
      hint: 'Compliance validation',
    ),
    Field('notes', String, 'Notes', hint: 'Additional IaC notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? security;
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
class DeploymentSecurity extends DocSpecsSection {
  @Form([
    Field(
      'pipelineSecrets',
      String,
      'Pipeline Secrets',
      hint: 'How secrets are injected',
    ),
    Field(
      'serviceAccounts',
      String,
      'Service Accounts',
      hint: 'Deployment service accounts',
    ),
    Field('roleBindings', String, 'Role Bindings', hint: 'Kubernetes RBAC'),
    Field(
      'leastPrivilege',
      bool,
      'Least Privilege',
      hint: 'Minimum required permissions',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Supply-chain security.
  @SectionId('DSSC')
  @StandardReferences(
    [
      'CI/CD — continuous delivery pipelines',
      'ISO/IEC 27001 — information security controls',
    ],
    'Covers supply-chain integrity for the delivery pipeline: signed artifacts, image signatures, SBOM generation, and provenance attestation.',
  )
  @Form([
    Field(
      'signedArtifacts',
      bool,
      'Signed Artifacts',
      hint: 'Artifact signing required',
    ),
    Field('imageSignature', String, 'Image Signature', hint: 'Cosign, Notary'),
    Field(
      'sbomGeneration',
      bool,
      'SBOM Generation',
      hint: 'Software bill of materials',
    ),
    Field(
      'supplyChainAttestation',
      String,
      'Supply Chain Attestation',
      hint: 'Provenance verification',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? supplyChain;

  /// Runtime security.
  @SectionId('DESERU')
  @StandardReferences(
    [
      'ISO/IEC 27001 — information security controls',
      'Google SRE — site reliability engineering',
    ],
    'Defines runtime security hardening for deployed workloads such as pod security policies, network policies, and immutable containers.',
  )
  @Form([
    Field(
      'podSecurityPolicy',
      String,
      'Pod Security Policy',
      hint: 'PSP/PSA configuration',
    ),
    Field(
      'networkPolicies',
      String,
      'Network Policies',
      hint: 'Network segmentation',
    ),
    Field(
      'seccompProfile',
      String,
      'Seccomp Profile',
      hint: 'Syscall restrictions',
    ),
    Field(
      'readOnlyRootFilesystem',
      bool,
      'Read-Only Root Filesystem',
      hint: 'Immutable containers',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? runtime;

  /// Access control and audit.
  @SectionId('DESEAC')
  @StandardReferences(
    [
      'ITIL 4 — IT service management',
      'ISO/IEC 27001 — information security controls',
    ],
    'Governs who may approve deployments, break-glass emergency access, and audit logging of all deployments.',
  )
  @Form([
    Field(
      'deploymentApprovers',
      String,
      'Deployment Approvers',
      hint: 'Who can approve deployments',
    ),
    Field(
      'emergencyAccess',
      String,
      'Emergency Access',
      hint: 'Break-glass procedures',
    ),
    Field('auditLogging', bool, 'Audit Logging', hint: 'Log all deployments'),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional deployment security notes',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? access;
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
class MonitoringAndAlertingSection extends DocSpecsSection {
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
  @override
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
  @StandardReferences([
    'Prometheus / Grafana — metrics & alerting',
  ], 'The alert definitions the system applies.')
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
class MonitoringInfrastructure extends DocSpecsSection {
  @Form([
    Field(
      'monitoringPlatform',
      String,
      'Monitoring Platform',
      hint: 'Datadog, Prometheus, CloudWatch',
    ),
    Field(
      'metricsBackend',
      String,
      'Metrics Backend',
      hint: 'Prometheus, InfluxDB, Graphite',
    ),
    Field(
      'loggingBackend',
      String,
      'Logging Backend',
      hint: 'ELK, Splunk, CloudWatch Logs',
    ),
    Field(
      'tracingBackend',
      String,
      'Tracing Backend',
      hint: 'Jaeger, Zipkin, X-Ray',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Deployment model.
  @SectionId('MOINDE')
  @StandardReferences(
    [
      'Prometheus / Grafana — metrics & alerting',
      'OpenTelemetry — observability / metrics / tracing',
    ],
    'Describes the monitoring deployment model including hosting, data retention, and HA.',
  )
  @Form([
    Field(
      'monitoringDeployment',
      String,
      'Monitoring Deployment',
      hint: 'SaaS, self-hosted, hybrid',
    ),
    Field(
      'dataRetention',
      String,
      'Data Retention',
      hint: 'Metrics/logs retention period',
    ),
    Field(
      'storageRequirements',
      String,
      'Storage Requirements',
      hint: 'Estimated storage needs',
    ),
    Field(
      'highAvailability',
      bool,
      'High Availability',
      hint: 'Monitoring HA required',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? deployment;

  /// Collection model.
  @SectionId('MOINCO')
  @StandardReferences(
    [
      'OpenTelemetry — observability / metrics / tracing',
      'Prometheus / Grafana — metrics & alerting',
    ],
    'Describes the metrics collection model including frequency and agent-based versus agentless collection.',
  )
  @Form([
    Field(
      'collectionFrequency',
      String,
      'Collection Frequency',
      hint: 'Metrics scrape interval',
    ),
    Field(
      'agentBased',
      bool,
      'Agent-Based Collection',
      hint: 'Requires monitoring agents',
    ),
    Field(
      'agentlessCollection',
      bool,
      'Agentless Collection',
      hint: 'Push-based metrics',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? collection;

  /// Access and privacy controls.
  @SectionId('MOINAC')
  @StandardReferences(
    [
      'OpenTelemetry — observability / metrics / tracing',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Describes access control, data privacy, and multi-tenant isolation for monitoring.',
  )
  @Form([
    Field(
      'accessControl',
      String,
      'Access Control',
      hint: 'Who can access monitoring',
    ),
    Field(
      'dataPrivacy',
      String,
      'Data Privacy',
      hint: 'Sensitive data handling',
    ),
    Field(
      'multiTenant',
      bool,
      'Multi-Tenant',
      hint: 'Tenant isolation in monitoring',
    ),
    Field('notes', String, 'Notes', hint: 'Additional infrastructure notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? access;
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
class MetricsCollectionRequirements extends DocSpecsSection {
  @Form([
    Field('cpuMetrics', bool, 'CPU Metrics', hint: 'CPU utilization, load'),
    Field('memoryMetrics', bool, 'Memory Metrics', hint: 'Memory usage, swap'),
    Field('diskMetrics', bool, 'Disk Metrics', hint: 'Disk I/O, space'),
    Field(
      'networkMetrics',
      bool,
      'Network Metrics',
      hint: 'Network I/O, connections',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Container and cluster metrics.
  @SectionId('MCRC')
  @StandardReferences([
    'OpenTelemetry — observability / metrics / tracing',
    'Prometheus / Grafana — metrics & alerting',
  ], 'Describes container, pod, node, and cluster-level metrics to collect.')
  @Form([
    Field(
      'containerMetrics',
      bool,
      'Container Metrics',
      hint: 'Container resource usage',
    ),
    Field('podMetrics', bool, 'Pod Metrics', hint: 'Pod status, restarts'),
    Field('nodeMetrics', bool, 'Node Metrics', hint: 'Kubernetes node metrics'),
    Field(
      'clusterMetrics',
      bool,
      'Cluster Metrics',
      hint: 'Cluster-level metrics',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? container;

  /// Application metrics.
  @SectionId('MCRA')
  @StandardReferences(
    [
      'OpenTelemetry — observability / metrics / tracing',
      'Google SRE — site reliability engineering',
    ],
    'Describes application metrics such as request rate, error rate, and saturation.',
  )
  @Form([
    Field(
      'requestMetrics',
      bool,
      'Request Metrics',
      hint: 'Request rate, latency',
    ),
    Field('errorMetrics', bool, 'Error Metrics', hint: 'Error rates, types'),
    Field(
      'saturationMetrics',
      bool,
      'Saturation Metrics',
      hint: 'Queue depth, utilization',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? application;

  /// Business metrics.
  @SectionId('MCRB')
  @StandardReferences(
    [
      'OpenTelemetry — observability / metrics / tracing',
      'DORA metrics — DevOps performance',
    ],
    'Describes business metrics such as KPIs, user activity, and transaction volume.',
  )
  @Form([
    Field(
      'businessMetrics',
      String,
      'Business Metrics',
      hint: 'Custom business KPIs',
    ),
    Field(
      'userMetrics',
      String,
      'User Metrics',
      hint: 'Active users, sessions',
    ),
    Field(
      'transactionMetrics',
      String,
      'Transaction Metrics',
      hint: 'Transaction volume, value',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? business;

  /// Custom metrics settings.
  @SectionId('MECORECU')
  @StandardReferences(
    [
      'OpenTelemetry — observability / metrics / tracing',
      'Prometheus / Grafana — metrics & alerting',
    ],
    'Describes custom application-specific metrics and their naming conventions.',
  )
  @Form([
    Field(
      'customMetricsRequired',
      bool,
      'Custom Metrics Required',
      hint: 'Application-specific metrics',
    ),
    Field(
      'metricNamingConvention',
      String,
      'Metric Naming Convention',
      hint: 'Naming standard for metrics',
    ),
    Field('notes', String, 'Notes', hint: 'Additional metrics notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? custom;
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
class ApplicationPerformanceMonitoring extends DocSpecsSection {
  @Form([
    Field(
      'apmPlatform',
      String,
      'APM Platform',
      hint: 'Datadog APM, New Relic, Dynatrace',
    ),
    Field(
      'instrumentationMethod',
      String,
      'Instrumentation Method',
      hint: 'Auto, manual, hybrid',
    ),
    Field(
      'samplingRate',
      String,
      'Sampling Rate',
      hint: 'Trace sampling percentage',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Tracing settings.
  @SectionId('APMT')
  @StandardReferences(
    [
      'OpenTelemetry — observability / metrics / tracing',
      'Prometheus / Grafana — metrics & alerting',
    ],
    'Describes distributed tracing settings including trace context, span collection, and retention.',
  )
  @Form([
    Field(
      'distributedTracing',
      bool,
      'Distributed Tracing',
      hint: 'End-to-end tracing',
    ),
    Field('traceContext', String, 'Trace Context', hint: 'W3C, B3, custom'),
    Field(
      'spanCollection',
      String,
      'Span Collection',
      hint: 'What spans to collect',
    ),
    Field(
      'traceRetention',
      String,
      'Trace Retention',
      hint: 'Trace data retention',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? tracing;

  /// Profiling settings.
  @SectionId('APMP')
  @StandardReferences(
    [
      'OpenTelemetry — observability / metrics / tracing',
      'Google SRE — site reliability engineering',
    ],
    'Describes continuous CPU and memory profiling settings and acceptable overhead.',
  )
  @Form([
    Field(
      'continuousProfiling',
      bool,
      'Continuous Profiling',
      hint: 'Production profiling',
    ),
    Field(
      'cpuProfiling',
      bool,
      'CPU Profiling',
      hint: 'CPU profile collection',
    ),
    Field(
      'memoryProfiling',
      bool,
      'Memory Profiling',
      hint: 'Memory profile collection',
    ),
    Field(
      'profilingOverhead',
      String,
      'Profiling Overhead',
      hint: 'Acceptable overhead',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? profiling;

  /// Error tracking settings.
  @SectionId('APME')
  @StandardReferences(
    [
      'OpenTelemetry — observability / metrics / tracing',
      'Prometheus / Grafana — metrics & alerting',
    ],
    'Describes error tracking settings such as grouping, source mapping, and error context.',
  )
  @Form([
    Field(
      'errorTracking',
      bool,
      'Error Tracking',
      hint: 'Exception collection',
    ),
    Field(
      'errorGrouping',
      String,
      'Error Grouping',
      hint: 'How errors are grouped',
    ),
    Field('sourceMapping', bool, 'Source Mapping', hint: 'Stack trace mapping'),
    Field(
      'errorContext',
      String,
      'Error Context',
      hint: 'Context data with errors',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? errors;

  /// User and synthetic monitoring settings.
  @SectionId('APMUS')
  @StandardReferences([
    'OpenTelemetry — observability / metrics / tracing',
    'Google SRE — site reliability engineering',
  ], 'Describes real-user monitoring and synthetic monitoring settings.')
  @Form([
    Field(
      'realUserMonitoring',
      bool,
      'Real User Monitoring',
      hint: 'Client-side monitoring',
    ),
    Field(
      'syntheticMonitoring',
      bool,
      'Synthetic Monitoring',
      hint: 'Synthetic transactions',
    ),
    Field('notes', String, 'Notes', hint: 'Additional APM notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? userSignals;
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
class LogManagementRequirements extends DocSpecsSection {
  @Form([
    Field(
      'logSources',
      String,
      'Log Sources',
      hint: 'Application, system, container',
    ),
    Field(
      'logFormat',
      String,
      'Log Format',
      hint: 'JSON, structured, unstructured',
    ),
    Field('logLevels', String, 'Log Levels', hint: 'Debug, Info, Warn, Error'),
    Field(
      'logFields',
      String,
      'Required Log Fields',
      hint: 'timestamp, correlation_id',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Collection method.
  @SectionId('LMRC')
  @StandardReferences(
    [
      'OpenTelemetry — observability / metrics / tracing',
      'Prometheus / Grafana — metrics & alerting',
    ],
    'Describes the log collection method, shipping pipeline, and buffering strategy.',
  )
  @Form([
    Field(
      'collectionMethod',
      String,
      'Collection Method',
      hint: 'Sidecar, agent, stdout',
    ),
    Field(
      'logShipping',
      String,
      'Log Shipping',
      hint: 'Fluentd, Filebeat, Vector',
    ),
    Field(
      'bufferingStrategy',
      String,
      'Buffering Strategy',
      hint: 'Memory, disk buffering',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? collection;

  /// Storage settings.
  @SectionId('LMRS')
  @StandardReferences(
    [
      'OpenTelemetry — observability / metrics / tracing',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Describes log storage settings including retention, cold storage, and compression.',
  )
  @Form([
    Field(
      'logRetention',
      String,
      'Log Retention',
      hint: 'Retention period by type',
    ),
    Field('coldStorage', String, 'Cold Storage', hint: 'Archive strategy'),
    Field(
      'compressionEnabled',
      bool,
      'Compression Enabled',
      hint: 'Log compression',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? storage;

  /// Search and analysis.
  @SectionId('LMRA')
  @StandardReferences([
    'OpenTelemetry — observability / metrics / tracing',
    'Prometheus / Grafana — metrics & alerting',
  ], 'Describes log search, analytics, and anomaly detection capabilities.')
  @Form([
    Field(
      'fullTextSearch',
      bool,
      'Full-Text Search',
      hint: 'Log search capability',
    ),
    Field(
      'logAnalytics',
      String,
      'Log Analytics',
      hint: 'Analysis capabilities',
    ),
    Field(
      'anomalyDetection',
      bool,
      'Anomaly Detection',
      hint: 'ML-based detection',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? analysis;

  /// Compliance settings.
  @SectionId('LOMARECO')
  @StandardReferences(
    [
      'ISO/IEC 20000 — IT service management system',
      'OpenTelemetry — observability / metrics / tracing',
    ],
    'Describes logging compliance controls such as PII handling, audit logs, and immutability.',
  )
  @Form([
    Field(
      'piiHandling',
      String,
      'PII Handling',
      hint: 'Sensitive data masking',
    ),
    Field('auditLogs', bool, 'Audit Logs', hint: 'Separate audit logging'),
    Field(
      'logImmutability',
      bool,
      'Log Immutability',
      hint: 'Tamper-proof logs',
    ),
    Field('notes', String, 'Notes', hint: 'Additional logging notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? compliance;
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
class AlertingRequirements extends DocSpecsSection {
  @Form([
    Field(
      'alertChannels',
      String,
      'Alert Channels',
      hint: 'Email, Slack, PagerDuty',
    ),
    Field(
      'primaryChannel',
      String,
      'Primary Channel',
      hint: 'Primary alert channel',
    ),
    Field(
      'secondaryChannel',
      String,
      'Secondary Channel',
      hint: 'Fallback channel',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Routing rules.
  @SectionId('ALRERO')
  @StandardReferences([
    'Prometheus / Grafana — metrics & alerting',
    'ITIL 4 — IT service management',
  ], 'Describes how alerts are routed by team, service, and severity.')
  @Form([
    Field(
      'routingRules',
      String,
      'Routing Rules',
      hint: 'How alerts are routed',
    ),
    Field('teamRouting', String, 'Team Routing', hint: 'Team-based routing'),
    Field(
      'serviceRouting',
      String,
      'Service Routing',
      hint: 'Service-based routing',
    ),
    Field(
      'severityRouting',
      String,
      'Severity Routing',
      hint: 'Severity-based routing',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? routing;

  /// De-duplication behavior.
  @SectionId('ALREDE')
  @StandardReferences(
    [
      'Prometheus / Grafana — metrics & alerting',
      'Google SRE — site reliability engineering',
    ],
    'Describes alert de-duplication, grouping, and flapping detection to reduce noise.',
  )
  @Form([
    Field(
      'alertDeduplication',
      String,
      'Alert De-duplication',
      hint: 'De-dup strategy',
    ),
    Field(
      'alertGrouping',
      String,
      'Alert Grouping',
      hint: 'Related alert grouping',
    ),
    Field(
      'flappingDetection',
      bool,
      'Flapping Detection',
      hint: 'Detect flapping alerts',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? deduplication;

  /// Suppression rules.
  @SectionId('ALRESU')
  @StandardReferences(
    [
      'Prometheus / Grafana — metrics & alerting',
      'ITIL 4 — IT service management',
    ],
    'Describes alert suppression via maintenance windows, dependency-based rules, and manual overrides.',
  )
  @Form([
    Field(
      'maintenanceWindows',
      String,
      'Maintenance Windows',
      hint: 'Scheduled suppression',
    ),
    Field(
      'dependencyAlerts',
      String,
      'Dependency Alerts',
      hint: 'Dependency-based suppression',
    ),
    Field(
      'manualSuppression',
      bool,
      'Manual Suppression',
      hint: 'Allow manual suppression',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? suppression;

  /// Response automation.
  @SectionId('ALRERE')
  @StandardReferences(
    [
      'Prometheus / Grafana — metrics & alerting',
      'Google SRE — site reliability engineering',
    ],
    'Describes alert response automation such as auto-remediation, runbook links, and acknowledgment.',
  )
  @Form([
    Field(
      'autoRemediation',
      bool,
      'Auto-Remediation',
      hint: 'Automatic remediation',
    ),
    Field(
      'runbookLinks',
      bool,
      'Runbook Links',
      hint: 'Link alerts to runbooks',
    ),
    Field(
      'acknowledgeRequired',
      bool,
      'Acknowledge Required',
      hint: 'Require acknowledgment',
    ),
    Field('notes', String, 'Notes', hint: 'Additional alerting notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? response;
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
class AlertDefinitionEntry extends DocSpecsSection {
  @Form([
    Field(
      'alertName',
      String,
      'Alert Name',
      required: true,
      hint: 'Alert identifier',
    ),
    Field(
      'alertDescription',
      String,
      'Alert Description',
      hint: 'What this alert means',
    ),
    Field('severity', String, 'Severity', hint: 'Critical, Warning, Info'),
    Field('priority', String, 'Priority', hint: 'P1, P2, P3, P4, P5'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Trigger conditions.
  @SectionId('ADEC')
  @StandardReferences(
    [
      'Prometheus / Grafana — metrics & alerting',
      'OpenTelemetry — observability / metrics / tracing',
    ],
    'Describes alert trigger conditions: metric, comparison, threshold, and evaluation window.',
  )
  @Form([
    Field('metricName', String, 'Metric Name', hint: 'Metric to monitor'),
    Field('condition', String, 'Condition', hint: '>, <, ==, etc.'),
    Field('threshold', String, 'Threshold', hint: 'Alert threshold value'),
    Field('duration', String, 'Duration', hint: 'How long before alerting'),
    Field(
      'evaluationPeriod',
      String,
      'Evaluation Period',
      hint: 'Evaluation window',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? condition;

  /// Recovery conditions.
  @SectionId('ADER')
  @StandardReferences(
    [
      'Prometheus / Grafana — metrics & alerting',
      'OpenTelemetry — observability / metrics / tracing',
    ],
    'Describes recovery thresholds, recovery duration, and auto-resolve behavior for alerts.',
  )
  @Form([
    Field(
      'recoveryThreshold',
      String,
      'Recovery Threshold',
      hint: 'When alert resolves',
    ),
    Field(
      'recoveryDuration',
      String,
      'Recovery Duration',
      hint: 'Time before resolving',
    ),
    Field('autoResolve', bool, 'Auto-Resolve', hint: 'Auto-resolve enabled'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? recovery;

  /// Notification details.
  @SectionId('ADEN')
  @StandardReferences(
    [
      'Prometheus / Grafana — metrics & alerting',
      'ITIL 4 — IT service management',
    ],
    'Describes alert notification channel, escalation policy, and runbook linkage.',
  )
  @Form([
    Field(
      'notificationChannel',
      String,
      'Notification Channel',
      hint: 'Where to send alert',
    ),
    Field(
      'escalationPolicy',
      String,
      'Escalation Policy',
      hint: 'Escalation if not acked',
    ),
    Field('runbookUrl', String, 'Runbook URL', hint: 'Link to runbook'),
    Field('notes', String, 'Notes', hint: 'Additional alert notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? notification;
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
class DashboardRequirements extends DocSpecsSection {
  @Form([
    Field(
      'dashboardPlatform',
      String,
      'Dashboard Platform',
      hint: 'Grafana, Datadog, custom',
    ),
    Field(
      'dashboardAsCode',
      bool,
      'Dashboards as Code',
      hint: 'Version-controlled dashboards',
    ),
    Field(
      'dashboardLocation',
      String,
      'Dashboard Location',
      hint: 'Where dashboards are stored',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Standard dashboards.
  @SectionId('DAREST')
  @StandardReferences(
    [
      'Prometheus / Grafana — metrics & alerting',
      'OpenTelemetry — observability / metrics / tracing',
    ],
    'Describes the standard set of dashboards for system, service, infrastructure, and business views.',
  )
  @Form([
    Field(
      'systemOverview',
      bool,
      'System Overview Dashboard',
      hint: 'High-level system health',
    ),
    Field(
      'serviceDashboards',
      bool,
      'Service Dashboards',
      hint: 'Per-service dashboards',
    ),
    Field(
      'infrastructureDashboard',
      bool,
      'Infrastructure Dashboard',
      hint: 'Infra-level dashboard',
    ),
    Field(
      'businessDashboard',
      bool,
      'Business Dashboard',
      hint: 'Business metrics dashboard',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? standard;

  /// Access controls.
  @SectionId('DAREAC')
  @StandardReferences(
    [
      'Prometheus / Grafana — metrics & alerting',
      'ITIL 4 — IT service management',
    ],
    'Describes access controls for public, internal, and edit permissions on dashboards.',
  )
  @Form([
    Field(
      'publicDashboards',
      String,
      'Public Dashboards',
      hint: 'Status page dashboards',
    ),
    Field(
      'internalDashboards',
      String,
      'Internal Dashboards',
      hint: 'Internal-only dashboards',
    ),
    Field(
      'accessControl',
      String,
      'Dashboard Access Control',
      hint: 'Who can view/edit',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? access;

  /// Feature requirements.
  @SectionId('DAREFE')
  @StandardReferences(
    [
      'Prometheus / Grafana — metrics & alerting',
      'OpenTelemetry — observability / metrics / tracing',
    ],
    'Describes dashboard features such as drill-down, annotations, templating, and alert integration.',
  )
  @Form([
    Field(
      'drillDown',
      bool,
      'Drill-Down Capability',
      hint: 'Navigate to details',
    ),
    Field('annotations', bool, 'Annotations', hint: 'Deployment markers'),
    Field('templating', bool, 'Templating', hint: 'Variable-based filtering'),
    Field(
      'alertIntegration',
      bool,
      'Alert Integration',
      hint: 'Show alerts on dashboard',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? features;

  /// Mobile support and notes.
  @SectionId('DAREMO')
  @StandardReferences([
    'Prometheus / Grafana — metrics & alerting',
    'OpenTelemetry — observability / metrics / tracing',
  ], 'Describes mobile access to dashboards and additional dashboard notes.')
  @Form([
    Field(
      'mobileAccess',
      bool,
      'Mobile Access',
      hint: 'Mobile-friendly dashboards',
    ),
    Field('notes', String, 'Notes', hint: 'Additional dashboard notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? mobile;
}

/// On-call procedures.
@StandardReferences([
  'Prometheus / Grafana — metrics & alerting',
  'ITIL 4 — IT service management',
  'Google SRE — site reliability engineering',
], 'Describes on-call tooling, rotation, coverage, and escalation procedures.')
@SectionId('ONCAPR')
class OnCallProcedures extends DocSpecsSection {
  @Form([
    Field(
      'onCallTool',
      String,
      'On-Call Tool',
      hint: 'PagerDuty, OpsGenie, VictorOps',
    ),
    Field(
      'rotationSchedule',
      String,
      'Rotation Schedule',
      hint: 'Weekly, daily rotation',
    ),
    Field(
      'coverageHours',
      String,
      'Coverage Hours',
      hint: '24/7, business hours',
    ),
    Field(
      'primarySecondary',
      bool,
      'Primary/Secondary',
      hint: 'Primary and backup on-call',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Team coverage.
  @SectionId('OCPT')
  @StandardReferences(
    [
      'ITIL 4 — IT service management',
      'Google SRE — site reliability engineering',
    ],
    'Describes which teams participate in on-call and how escalation flows between them.',
  )
  @Form([
    Field(
      'onCallTeams',
      String,
      'On-Call Teams',
      hint: 'Which teams participate',
    ),
    Field(
      'crossTeamEscalation',
      String,
      'Cross-Team Escalation',
      hint: 'Escalation between teams',
    ),
    Field(
      'managementEscalation',
      String,
      'Management Escalation',
      hint: 'When to involve management',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? teams;

  /// Response SLAs.
  @SectionId('OCPS')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering',
      'ITIL 4 — IT service management',
    ],
    'Describes on-call response SLAs for acknowledgment, response, and resolution.',
  )
  @Form([
    Field('ackSla', String, 'Acknowledgment SLA', hint: 'Time to acknowledge'),
    Field(
      'responseSla',
      String,
      'Response SLA',
      hint: 'Time to start response',
    ),
    Field('resolutionSla', String, 'Resolution SLA', hint: 'Time to resolve'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? slas;

  /// Escalation rules.
  @SectionId('OCPE')
  @StandardReferences(
    [
      'Prometheus / Grafana — metrics & alerting',
      'ITIL 4 — IT service management',
    ],
    'Describes on-call escalation timeouts, escalation path, and executive escalation.',
  )
  @Form([
    Field(
      'escalationTimeout',
      String,
      'Escalation Timeout',
      hint: 'When to escalate',
    ),
    Field(
      'escalationPath',
      String,
      'Escalation Path',
      hint: 'Escalation chain',
    ),
    Field(
      'executiveEscalation',
      String,
      'Executive Escalation',
      hint: 'When to involve executives',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? escalation;

  /// Documentation requirements.
  @SectionId('OCPD')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering',
      'ITIL 4 — IT service management',
    ],
    'Describes on-call documentation such as runbooks, incident and communication templates.',
  )
  @Form([
    Field('runbooks', String, 'Runbooks', hint: 'Where runbooks are stored'),
    Field(
      'incidentTemplates',
      String,
      'Incident Templates',
      hint: 'Incident response templates',
    ),
    Field(
      'communicationTemplates',
      String,
      'Communication Templates',
      hint: 'Stakeholder comm templates',
    ),
    Field('notes', String, 'Notes', hint: 'Additional on-call notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? documentation;
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
class IncidentManagementRequirements extends DocSpecsSection {
  @Form([
    Field(
      'incidentProcess',
      String,
      'Incident Process',
      hint: 'Incident management process',
    ),
    Field(
      'severityDefinitions',
      String,
      'Severity Definitions',
      hint: 'SEV1, SEV2, SEV3 definitions',
    ),
    Field(
      'incidentCommander',
      String,
      'Incident Commander',
      hint: 'IC role and selection',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Communication requirements.
  @SectionId('IMRC')
  @StandardReferences(
    [
      'ITIL 4 — IT service management',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Describes internal, external, and status-page communication during incidents.',
  )
  @Form([
    Field(
      'internalComms',
      String,
      'Internal Communications',
      hint: 'Internal status updates',
    ),
    Field(
      'externalComms',
      String,
      'External Communications',
      hint: 'Customer communication',
    ),
    Field(
      'statusPageUpdates',
      String,
      'Status Page Updates',
      hint: 'Status page process',
    ),
    Field(
      'stakeholderNotification',
      String,
      'Stakeholder Notification',
      hint: 'Who gets notified',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? communication;

  /// War room setup.
  @SectionId('IMRWR')
  @StandardReferences([
    'ITIL 4 — IT service management',
    'Google SRE — site reliability engineering',
  ], 'Describes the incident war room, bridge call, and chat channel setup.')
  @Form([
    Field('warRoomSetup', String, 'War Room Setup', hint: 'Incident war room'),
    Field('bridgeCall', String, 'Bridge Call', hint: 'Conference bridge'),
    Field('chatChannel', String, 'Chat Channel', hint: 'Incident chat channel'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? warRoom;

  /// Post-incident expectations.
  @SectionId('IMRPI')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering',
      'ITIL 4 — IT service management',
    ],
    'Describes post-incident expectations including blameless post-mortems and action item tracking.',
  )
  @Form([
    Field(
      'postMortemRequired',
      bool,
      'Post-Mortem Required',
      hint: 'Require post-mortems',
    ),
    Field(
      'postMortemTimeline',
      String,
      'Post-Mortem Timeline',
      hint: 'When post-mortem due',
    ),
    Field(
      'blamelessCulture',
      bool,
      'Blameless Culture',
      hint: 'Blameless post-mortems',
    ),
    Field(
      'actionItemTracking',
      String,
      'Action Item Tracking',
      hint: 'Track remediation items',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? postIncident;

  /// Metrics and notes.
  @SectionId('IMRM')
  @StandardReferences([
    'Google SRE — site reliability engineering',
    'DORA metrics — DevOps performance',
  ], 'Describes incident metrics such as MTTR and MTBF targets.')
  @Form([
    Field('mttr', String, 'MTTR Target', hint: 'Mean time to repair target'),
    Field('mtbf', String, 'MTBF Target', hint: 'Mean time between failures'),
    Field('notes', String, 'Notes', hint: 'Additional incident notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? metrics;
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
class SlaMonitoringRequirements extends DocSpecsSection {
  @Form([
    Field('availabilitySla', String, 'Availability SLA', hint: '99.9%, 99.99%'),
    Field('performanceSla', String, 'Performance SLA', hint: 'Latency SLA'),
    Field('errorRateSla', String, 'Error Rate SLA', hint: 'Maximum error rate'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Monitoring mechanics.
  @SectionId('SLMOREMO')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering',
      'Prometheus / Grafana — metrics & alerting',
    ],
    'Describes how SLAs are tracked, reported, and how breaches and burn rate are alerted.',
  )
  @Form([
    Field('slaTracking', String, 'SLA Tracking', hint: 'How SLAs are tracked'),
    Field(
      'slaReporting',
      String,
      'SLA Reporting',
      hint: 'SLA report frequency',
    ),
    Field(
      'slaBreachAlerts',
      bool,
      'SLA Breach Alerts',
      hint: 'Alert on SLA breach',
    ),
    Field(
      'slaBurnRate',
      bool,
      'SLA Burn Rate',
      hint: 'Track error budget burn',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? monitoring;

  /// Error-budget policy.
  @SectionId('SMREB')
  @StandardReferences([
    'Google SRE — site reliability engineering',
    'DORA metrics — DevOps performance',
  ], 'Describes the error-budget policy, exhaustion action, and reset period.')
  @Form([
    Field(
      'errorBudgetPolicy',
      String,
      'Error Budget Policy',
      hint: 'Error budget handling',
    ),
    Field(
      'budgetExhaustionAction',
      String,
      'Budget Exhaustion Action',
      hint: 'Action when budget spent',
    ),
    Field(
      'budgetResetPeriod',
      String,
      'Budget Reset Period',
      hint: 'Monthly, quarterly reset',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? errorBudget;

  /// Customer-specific SLA rules.
  @SectionId('SLMORECU')
  @StandardReferences([
    'ITIL 4 — IT service management',
    'ISO/IEC 20000 — IT service management system',
  ], 'Describes customer-specific SLA tiers, exclusions, and credit policy.')
  @Form([
    Field(
      'customerSlaTiers',
      String,
      'Customer SLA Tiers',
      hint: 'Different SLA tiers',
    ),
    Field('slaExclusions', String, 'SLA Exclusions', hint: 'What is excluded'),
    Field(
      'slaCredits',
      String,
      'SLA Credits',
      hint: 'Credit policy for misses',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? customer;

  /// Reporting and review.
  @SectionId('SLMORERE')
  @StandardReferences([
    'Google SRE — site reliability engineering',
    'ITIL 4 — IT service management',
  ], 'Describes SLA reporting recipients, review cadence, and related notes.')
  @Form([
    Field(
      'slaReportRecipients',
      String,
      'SLA Report Recipients',
      hint: 'Who receives reports',
    ),
    Field(
      'slaReviewMeetings',
      String,
      'SLA Review Meetings',
      hint: 'SLA review cadence',
    ),
    Field('notes', String, 'Notes', hint: 'Additional SLA notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? reporting;
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
class MaintenanceWindowsSection extends DocSpecsSection {
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
  @override
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
  @StandardReferences([
    'ITIL 4 — change management',
  ], 'The maintenance windows the system schedules.')
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
  MaintenanceChangeManagement changeManagement = MaintenanceChangeManagement();

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
class ScheduledMaintenancePolicy extends DocSpecsSection {
  @Form([
    Field(
      'maintenancePolicy',
      String,
      'Maintenance Policy',
      hint: 'Overall maintenance approach',
    ),
    Field(
      'zeroDowntimeGoal',
      bool,
      'Zero-Downtime Goal',
      hint: 'Strive for zero downtime',
    ),
    Field(
      'maintenanceAgreement',
      String,
      'Maintenance Agreement',
      hint: 'SLA for maintenance windows',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Scheduling preferences.
  @SectionId('SMPS')
  @StandardReferences(
    [
      'ITIL 4 — change management',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Defines the preferred days, times, frequency, and blackout periods for scheduled maintenance.',
  )
  @Form([
    Field(
      'preferredDay',
      String,
      'Preferred Day',
      hint: 'Preferred day of week',
    ),
    Field(
      'preferredTime',
      String,
      'Preferred Time',
      hint: 'Preferred start time',
    ),
    Field('timezone', String, 'Timezone', hint: 'Maintenance timezone'),
    Field(
      'maxFrequency',
      String,
      'Maximum Frequency',
      hint: 'Max maintenance per month',
    ),
    Field(
      'blackoutPeriods',
      String,
      'Blackout Periods',
      hint: 'When maintenance is forbidden',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? scheduling;

  /// Duration constraints.
  @SectionId('SMPD')
  @StandardReferences(
    [
      'ITIL 4 — change management',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Defines the maximum and typical duration constraints for scheduled maintenance windows.',
  )
  @Form([
    Field(
      'maxDuration',
      String,
      'Maximum Duration',
      hint: 'Max window duration',
    ),
    Field(
      'typicalDuration',
      String,
      'Typical Duration',
      hint: 'Typical window length',
    ),
    Field(
      'extensionPolicy',
      String,
      'Extension Policy',
      hint: 'How to extend if needed',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? duration;

  /// Notice requirements.
  @SectionId('SMPN')
  @StandardReferences(
    [
      'ITIL 4 — IT service management',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Defines the advance notice periods and channels for scheduled maintenance.',
  )
  @Form([
    Field(
      'standardNotice',
      String,
      'Standard Notice Period',
      hint: 'Days advance notice',
    ),
    Field(
      'minimumNotice',
      String,
      'Minimum Notice Period',
      hint: 'Minimum advance notice',
    ),
    Field(
      'noticeChannels',
      String,
      'Notice Channels',
      hint: 'How users are notified',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? notice;

  /// Approval requirements.
  @SectionId('SMPA')
  @StandardReferences(
    [
      'ITIL 4 — change management',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Defines who must approve scheduled maintenance and the approval requirements.',
  )
  @Form([
    Field(
      'approvalRequired',
      bool,
      'Approval Required',
      hint: 'Requires approval',
    ),
    Field(
      'approvalAuthority',
      String,
      'Approval Authority',
      hint: 'Who approves maintenance',
    ),
    Field('notes', String, 'Notes', hint: 'Additional policy notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? approval;
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
class MaintenanceWindowEntry extends DocSpecsSection {
  @Form([
    Field(
      'windowName',
      String,
      'Window Name',
      required: true,
      hint: 'Maintenance window name',
    ),
    Field(
      'windowType',
      String,
      'Window Type',
      hint: 'Routine, Patch, Upgrade, Migration',
    ),
    Field('priority', String, 'Priority', hint: 'Critical, Standard, Low'),
    Field(
      'description',
      String,
      'Description',
      hint: 'What maintenance is performed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Schedule details.
  @SectionId('MWES')
  @StandardReferences([
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ], 'Describes the frequency, timing, and duration of a maintenance window.')
  @Form([
    Field('frequency', String, 'Frequency', hint: 'Weekly, Monthly, Quarterly'),
    Field('dayOfWeek', String, 'Day of Week', hint: 'When this window occurs'),
    Field('startTime', String, 'Start Time', hint: 'Window start time'),
    Field('endTime', String, 'End Time', hint: 'Window end time'),
    Field('duration', String, 'Duration', hint: 'Expected duration'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? schedule;

  /// Scope details.
  @SectionId('MAWIENSC')
  @StandardReferences(
    [
      'ITIL 4 — change management',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Describes the systems, services, and regions in scope for a maintenance window.',
  )
  @Form([
    Field(
      'affectedSystems',
      String,
      'Affected Systems',
      hint: 'Which systems are affected',
    ),
    Field(
      'affectedServices',
      String,
      'Affected Services',
      hint: 'Which services impacted',
    ),
    Field(
      'affectedRegions',
      String,
      'Affected Regions',
      hint: 'Geographic scope',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? scope;

  /// Impact details.
  @SectionId('MWEI')
  @StandardReferences([
    'ITIL 4 — IT service management',
    'ISO/IEC 20000 — IT service management system',
  ], 'Describes the user and service impact of a maintenance window.')
  @Form([
    Field('userImpact', String, 'User Impact', hint: 'How users are affected'),
    Field(
      'serviceAvailability',
      String,
      'Service Availability',
      hint: 'Fully down, degraded, partial',
    ),
    Field(
      'dataAvailability',
      String,
      'Data Availability',
      hint: 'Data access during window',
    ),
    Field(
      'workarounds',
      String,
      'Workarounds',
      hint: 'Workarounds during maintenance',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? impact;

  /// Rollback details.
  @SectionId('MWER')
  @StandardReferences([
    'Google SRE — site reliability engineering',
    'ITIL 4 — change management',
  ], 'Describes the rollback plan and decision point for a maintenance window.')
  @Form([
    Field(
      'rollbackPlan',
      String,
      'Rollback Plan',
      hint: 'How to roll back if needed',
    ),
    Field(
      'rollbackDecisionPoint',
      String,
      'Rollback Decision Point',
      hint: 'When to decide on rollback',
    ),
    Field('notes', String, 'Notes', hint: 'Additional window notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? rollback;
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
class EmergencyMaintenanceProcedures extends DocSpecsSection {
  @Form([
    Field(
      'emergencyTriggers',
      String,
      'Emergency Triggers',
      hint: 'What triggers emergency maintenance',
    ),
    Field(
      'securityPatchPolicy',
      String,
      'Security Patch Policy',
      hint: 'Critical security patch handling',
    ),
    Field(
      'severityThresholds',
      String,
      'Severity Thresholds',
      hint: 'What severity warrants emergency',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Approval and documentation workflow.
  @SectionId('EMPG')
  @StandardReferences(
    [
      'ITIL 4 — change management',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Defines the approval and documentation workflow for emergency maintenance work.',
  )
  @Form([
    Field(
      'emergencyApproval',
      String,
      'Emergency Approval',
      hint: 'Who approves emergency work',
    ),
    Field(
      'delegationOfAuthority',
      String,
      'Delegation of Authority',
      hint: 'Backup approvers',
    ),
    Field(
      'documentationRequired',
      String,
      'Documentation Required',
      hint: 'Post-hoc documentation',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? governance;

  /// Notification and stakeholder handling.
  @SectionId('EMPC')
  @StandardReferences(
    [
      'ITIL 4 — IT service management',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Describes how stakeholders are notified when emergency maintenance is required.',
  )
  @Form([
    Field(
      'emergencyNotice',
      String,
      'Emergency Notice',
      hint: 'Minimum notice for emergency',
    ),
    Field(
      'notificationChannels',
      String,
      'Notification Channels',
      hint: 'Emergency notification channels',
    ),
    Field(
      'stakeholderEscalation',
      String,
      'Stakeholder Escalation',
      hint: 'How stakeholders are informed',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? communication;

  /// Execution and follow-up details.
  @SectionId('EMPE')
  @StandardReferences([
    'Google SRE — site reliability engineering',
    'ITIL 4 — change management',
  ], 'Describes how emergency maintenance is executed and reviewed afterward.')
  @Form([
    Field(
      'teamAssembly',
      String,
      'Team Assembly',
      hint: 'How response team assembles',
    ),
    Field(
      'maxEmergencyDuration',
      String,
      'Max Emergency Duration',
      hint: 'Maximum emergency window',
    ),
    Field(
      'postEmergencyReview',
      bool,
      'Post-Emergency Review',
      hint: 'Mandatory review after',
    ),
    Field('notes', String, 'Notes', hint: 'Additional emergency notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? execution;
}

/// Change management for maintenance.
@StandardReferences([
  'ITIL 4 — change management',
  'ISO/IEC 20000 — IT service management system',
], 'Defines the change management process governing maintenance changes.')
@SectionId('MACHMA')
class MaintenanceChangeManagement extends DocSpecsSection {
  @Form([
    // Change process
    Field(
      'changeProcess',
      String,
      'Change Process',
      hint: 'ITIL, custom change process',
    ),
    Field(
      'changeCategories',
      String,
      'Change Categories',
      hint: 'Standard, Normal, Emergency',
    ),
    Field(
      'changeBoard',
      String,
      'Change Advisory Board',
      hint: 'CAB composition',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// CAB cadence and documentation prerequisites.
  @SectionId('MCMG')
  @StandardReferences(
    [
      'ITIL 4 — change management',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Defines the change advisory board cadence and governance prerequisites for maintenance changes.',
  )
  @Form([
    Field(
      'changeBoardSchedule',
      String,
      'CAB Schedule',
      hint: 'When CAB meets',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? governance;

  /// Required assessments and rollback planning.
  @SectionId('MCMD')
  @StandardReferences(
    [
      'ITIL 4 — change management',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Defines the impact/risk assessments and rollback plans required to document a maintenance change.',
  )
  @Form([
    Field(
      'changeRequestRequired',
      bool,
      'Change Request Required',
      hint: 'CR needed for maintenance',
    ),
    Field(
      'impactAssessment',
      bool,
      'Impact Assessment Required',
      hint: 'Assess impact before change',
    ),
    Field(
      'riskAssessment',
      bool,
      'Risk Assessment Required',
      hint: 'Assess risk before change',
    ),
    Field(
      'rollbackPlanRequired',
      bool,
      'Rollback Plan Required',
      hint: 'Rollback plan mandatory',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? documentation;

  /// Testing and sign-off requirements.
  @SectionId('MCMT')
  @StandardReferences(
    [
      'ITIL 4 — change management',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Defines the testing and sign-off required before a maintenance change proceeds.',
  )
  @Form([
    Field(
      'preProdTesting',
      bool,
      'Pre-Production Testing',
      hint: 'Test in staging first',
    ),
    Field(
      'testPlanRequired',
      bool,
      'Test Plan Required',
      hint: 'Test plan mandatory',
    ),
    Field(
      'signOffRequired',
      bool,
      'Sign-Off Required',
      hint: 'Post-test sign-off',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? testing;

  /// Logging and audit trail expectations.
  @SectionId('MCMA')
  @StandardReferences([
    'ITIL 4 — change management',
    'ISO/IEC 20000 — IT service management system',
  ], 'Defines the change logging and audit trail kept for maintenance changes.')
  @Form([
    Field('changeLogging', bool, 'Change Logging', hint: 'Log all changes'),
    Field(
      'changeHistory',
      String,
      'Change History',
      hint: 'Where changes are tracked',
    ),
    Field('notes', String, 'Notes', hint: 'Additional change management notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? audit;
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
class MaintenanceUserImpact extends DocSpecsSection {
  @Form([
    Field(
      'advanceNotification',
      String,
      'Advance Notification',
      hint: 'How users are notified in advance',
    ),
    Field(
      'inAppNotification',
      bool,
      'In-App Notification',
      hint: 'Banner or popup in app',
    ),
    Field(
      'emailNotification',
      bool,
      'Email Notification',
      hint: 'Email users before maintenance',
    ),
    Field(
      'statusPageUpdate',
      bool,
      'Status Page Update',
      hint: 'Update status page',
    ),
    Field(
      'socialMediaNotice',
      bool,
      'Social Media Notice',
      hint: 'Post on social media',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Communication during maintenance.
  @SectionId('MUID')
  @StandardReferences(
    [
      'ITIL 4 — IT service management',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Describes what users are shown and told while maintenance is in progress.',
  )
  @Form([
    Field(
      'maintenancePage',
      String,
      'Maintenance Page',
      hint: 'What user sees during downtime',
    ),
    Field(
      'maintenanceMessage',
      String,
      'Maintenance Message',
      hint: 'Default maintenance text',
    ),
    Field(
      'estimatedCompletion',
      bool,
      'Estimated Completion',
      hint: 'Show estimated completion',
    ),
    Field(
      'progressUpdates',
      bool,
      'Progress Updates',
      hint: 'Periodic progress updates',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? during;

  /// Graceful-degradation strategy.
  @SectionId('MUIGD')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering',
      'ISO/IEC 27031 — ICT business continuity / disaster recovery',
    ],
    'Defines how partial service is preserved during maintenance to reduce user impact.',
  )
  @Form([
    Field(
      'gracefulDegradation',
      String,
      'Graceful Degradation',
      hint: 'Partial service availability',
    ),
    Field(
      'readOnlyMode',
      bool,
      'Read-Only Mode',
      hint: 'Allow read-only access',
    ),
    Field(
      'queuedOperations',
      bool,
      'Queued Operations',
      hint: 'Queue writes during maintenance',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? gracefulDegradation;

  /// Post-maintenance communication.
  @SectionId('MUIP')
  @StandardReferences(
    [
      'ITIL 4 — IT service management',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Describes how completion of maintenance is communicated to users afterward.',
  )
  @Form([
    Field(
      'completionNotice',
      bool,
      'Completion Notice',
      hint: 'Notify when complete',
    ),
    Field(
      'changelogPublished',
      bool,
      'Changelog Published',
      hint: 'Publish changes made',
    ),
    Field(
      'feedbackCollection',
      bool,
      'Feedback Collection',
      hint: 'Collect user feedback',
    ),
    Field('notes', String, 'Notes', hint: 'Additional user impact notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? post;
}

/// Post-maintenance validation.
@StandardReferences(
  ['Google SRE — site reliability engineering', 'ITIL 4 — change management'],
  'Defines the validation performed after maintenance to confirm the system is fully functional.',
)
@SectionId('POMAVA')
class PostMaintenanceValidation extends DocSpecsSection {
  @Form([
    Field('smokeTests', bool, 'Smoke Tests', hint: 'Run smoke tests after'),
    Field(
      'functionalTests',
      bool,
      'Functional Tests',
      hint: 'Run functional test suite',
    ),
    Field(
      'performanceTests',
      bool,
      'Performance Tests',
      hint: 'Run performance checks',
    ),
    Field(
      'healthChecks',
      bool,
      'Health Checks',
      hint: 'Verify all health checks',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Monitoring requirements after maintenance.
  @SectionId('PMVM')
  @StandardReferences(
    ['Google SRE — site reliability engineering', 'ITIL 4 — change management'],
    'Describes the heightened monitoring required after a maintenance window to confirm system health.',
  )
  @Form([
    Field(
      'enhancedMonitoring',
      String,
      'Enhanced Monitoring',
      hint: 'Heightened monitoring period',
    ),
    Field(
      'monitoringDuration',
      String,
      'Monitoring Duration',
      hint: 'How long to watch after',
    ),
    Field(
      'keyMetrics',
      String,
      'Key Metrics',
      hint: 'Metrics to watch closely',
    ),
    Field(
      'baselineComparison',
      bool,
      'Baseline Comparison',
      hint: 'Compare to pre-maintenance',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? monitoring;

  /// Sign-off and reporting expectations.
  @SectionId('PMVC')
  @StandardReferences(
    [
      'ITIL 4 — change management',
      'ISO/IEC 20000 — IT service management system',
    ],
    'Captures the sign-off and reporting expectations that close out a maintenance window.',
  )
  @Form([
    Field(
      'validateSignoff',
      String,
      'Validation Sign-Off',
      hint: 'Who signs off validation',
    ),
    Field(
      'maintenanceReport',
      bool,
      'Maintenance Report',
      hint: 'Generate maintenance report',
    ),
    Field(
      'lessonsLearned',
      bool,
      'Lessons Learned',
      hint: 'Document lessons learned',
    ),
    Field('notes', String, 'Notes', hint: 'Additional validation notes'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? closure;
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
class CommunicationRequirements extends DocSpecsSection {
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
  @override
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
class ProtocolsAndStandardsSection extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of communication protocols and standards.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Protocol catalog — contains 0+× Protocol.
  @StandardReferences([
    'IETF RFC 9110 — HTTP semantics',
  ], 'The communication protocols the system supports.')
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
  ['IETF RFC 9110 — HTTP semantics', 'ISO/IEC 7498 — OSI reference model'],
  'Describes a single communication protocol entry with its version and transport layer.',
)
@SectionId('PE')
class ProtocolEntry extends DocSpecsSection {
  @Form([
    Field(
      'protocolName',
      String,
      'Protocol Name',
      required: true,
      hint: 'HTTP/2, WebSocket, gRPC, MQTT, AMQP',
    ),
    Field(
      'protocolType',
      String,
      'Protocol Type',
      hint: 'Request-response, streaming, pub-sub, event-driven',
    ),
    Field(
      'protocolVersion',
      String,
      'Protocol Version',
      hint: 'HTTP/2, MQTT 5.0, gRPC 1.x',
    ),
    Field('transportLayer', String, 'Transport Layer', hint: 'TCP, UDP, QUIC'),
    Field(
      'directionality',
      String,
      'Directionality',
      hint: 'Client-to-server, bidirectional, server-push',
    ),
    Field('notes', String, 'Notes', hint: 'Additional protocol notes'),
  ])
  @override
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
class ProtocolAuthSerialization extends DocSpecsSection {
  @Form([
    Field(
      'authenticationMethod',
      String,
      'Authentication Method',
      hint: 'API key, OAuth 2.0, mTLS, JWT',
    ),
    Field(
      'authorizationScheme',
      String,
      'Authorization Scheme',
      hint: 'Bearer token, Basic, custom',
    ),
    Field(
      'messageFormat',
      String,
      'Message Format',
      hint: 'JSON, Protocol Buffers, XML, Avro',
    ),
    Field('encoding', String, 'Encoding', hint: 'UTF-8, Base64, binary'),
    Field(
      'compressionSupport',
      String,
      'Compression Support',
      hint: 'gzip, brotli, none',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Performance settings.
@StandardReferences(
  ['IETF RFC 9110 — HTTP semantics', 'ISO/IEC 7498 — OSI reference model'],
  'Defines protocol performance settings such as message size, pooling, and timeouts.',
)
@SectionId('PRPE')
class ProtocolPerformance extends DocSpecsSection {
  @Form([
    Field(
      'maxMessageSize',
      String,
      'Max Message Size',
      hint: 'Maximum payload size',
    ),
    Field(
      'connectionPooling',
      bool,
      'Connection Pooling',
      hint: 'Connection reuse strategy',
    ),
    Field(
      'keepAliveInterval',
      String,
      'Keep-Alive Interval',
      hint: 'Heartbeat/keep-alive timing',
    ),
    Field(
      'connectionTimeout',
      String,
      'Connection Timeout',
      hint: 'Connection establishment timeout',
    ),
    Field(
      'requestTimeout',
      String,
      'Request Timeout',
      hint: 'Individual request timeout',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Reliability and delivery.
@StandardReferences(
  ['IETF RFC 9110 — HTTP semantics', 'ISO/IEC 7498 — OSI reference model'],
  'Defines retry policy, idempotency, and delivery guarantees for the protocol.',
)
@SectionId('PRRE')
class ProtocolReliability extends DocSpecsSection {
  @Form([
    Field(
      'retryPolicy',
      String,
      'Retry Policy',
      hint: 'Exponential backoff, fixed interval',
    ),
    Field(
      'idempotencySupport',
      bool,
      'Idempotency Support',
      hint: 'Support for idempotent operations',
    ),
    Field(
      'deliveryGuarantee',
      String,
      'Delivery Guarantee',
      hint: 'At-most-once, at-least-once, exactly-once',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Usage and notes.
@StandardReferences([
  'IETF RFC 9110 — HTTP semantics',
], 'Describes which components use the protocol and its directionality.')
@SectionId('PRUS')
class ProtocolUsage extends DocSpecsSection {
  @Form([
    Field(
      'usedBy',
      String,
      'Used By',
      hint: 'Components or services using this protocol',
    ),
    Field(
      'directionality',
      String,
      'Directionality',
      hint: 'Client-to-server, bidirectional, server-push',
    ),
    Field('notes', String, 'Notes', hint: 'Additional protocol notes'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// TLS/SSL requirements.
@StandardReferences(
  ['IETF RFC 8446 — TLS 1.3', 'IETF RFC 5280 — X.509 PKI certificates'],
  'Defines the minimum, preferred, and disabled TLS versions for transport security.',
)
@SectionId('TLRE')
class TlsRequirements extends DocSpecsSection {
  @Form([
    Field(
      'minimumTlsVersion',
      String,
      'Minimum TLS Version',
      required: true,
      hint: 'TLS 1.2, TLS 1.3',
    ),
    Field(
      'preferredTlsVersion',
      String,
      'Preferred TLS Version',
      hint: 'TLS 1.3',
    ),
    Field(
      'disabledProtocols',
      String,
      'Disabled Protocols',
      hint: 'SSLv3, TLS 1.0, TLS 1.1',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Cipher suite policy.
  @SectionId('TRCS')
  @StandardReferences([
    'IETF RFC 8446 — TLS 1.3',
  ], 'Defines allowed and disabled cipher suites and key-exchange algorithms.')
  @Form([
    Field(
      'allowedCipherSuites',
      String,
      'Allowed Cipher Suites',
      hint: 'AES-256-GCM, ChaCha20-Poly1305',
    ),
    Field(
      'disabledCipherSuites',
      String,
      'Disabled Cipher Suites',
      hint: 'RC4, DES, 3DES, MD5-based',
    ),
    Field(
      'keyExchangeAlgorithms',
      String,
      'Key Exchange Algorithms',
      hint: 'ECDHE, DHE, X25519',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? cipherSuites;

  /// Certificate validation rules.
  @SectionId('TRCV')
  @StandardReferences(
    ['IETF RFC 5280 — X.509 PKI certificates', 'IETF RFC 8446 — TLS 1.3'],
    'Defines certificate pinning, OCSP stapling, and mutual-TLS validation rules.',
  )
  @Form([
    Field(
      'certificatePinning',
      bool,
      'Certificate Pinning',
      hint: 'Enable HPKP or app-level pinning',
    ),
    Field(
      'ocspStapling',
      bool,
      'OCSP Stapling',
      hint: 'Online certificate status protocol',
    ),
    Field(
      'mutualTls',
      bool,
      'Mutual TLS (mTLS)',
      hint: 'Client certificate authentication',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? certificateValidation;

  /// Termination and internal encryption.
  @SectionId('TLRETE')
  @StandardReferences(
    ['IETF RFC 8446 — TLS 1.3'],
    'Defines where TLS is terminated and whether internal service-to-service traffic is encrypted.',
  )
  @Form([
    Field(
      'tlsTermination',
      String,
      'TLS Termination',
      hint: 'Load balancer, reverse proxy, application',
    ),
    Field(
      'internalTls',
      bool,
      'Internal TLS',
      hint: 'Encrypt service-to-service traffic',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? termination;

  /// Compliance and HSTS settings.
  @SectionId('TLRECO')
  @StandardReferences([
    'IETF RFC 8446 — TLS 1.3',
    'IETF RFC 9110 — HTTP semantics',
  ], 'Defines TLS compliance targets and HSTS enforcement settings.')
  @Form([
    Field(
      'sslLabsTargetGrade',
      String,
      'SSL Labs Target Grade',
      hint: 'A+, A, B minimum rating',
    ),
    Field(
      'hstsEnabled',
      bool,
      'HSTS Enabled',
      hint: 'HTTP Strict Transport Security',
    ),
    Field(
      'hstsMaxAge',
      String,
      'HSTS Max-Age',
      hint: 'HSTS header max-age value',
    ),
    Field(
      'hstsIncludeSubdomains',
      bool,
      'HSTS Include Subdomains',
      hint: 'Apply HSTS to all subdomains',
    ),
    Field('notes', String, 'Notes', hint: 'Additional TLS requirements'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? compliance;
}

/// Certificate management.
@StandardReferences(
  ['IETF RFC 5280 — X.509 PKI certificates', 'IETF RFC 8446 — TLS 1.3'],
  'Defines the certificate authority, type, and overall certificate management approach.',
)
@SectionId('CEMA')
class CertificateManagement extends DocSpecsSection {
  @Form([
    Field(
      'certificateAuthority',
      String,
      'Certificate Authority',
      hint: 'Public CA, private PKI, Let\'s Encrypt',
    ),
    Field(
      'certificateType',
      String,
      'Certificate Type',
      hint: 'DV, OV, EV, Wildcard',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Key specifications.
  @SectionId('CEMAKE')
  @StandardReferences(
    ['IETF RFC 5280 — X.509 PKI certificates'],
    'Defines the key algorithm, length, and signature algorithm for certificates.',
  )
  @Form([
    Field('keyAlgorithm', String, 'Key Algorithm', hint: 'RSA, ECDSA, Ed25519'),
    Field(
      'keyLength',
      String,
      'Key Length',
      hint: 'RSA 2048/4096, ECDSA P-256/P-384',
    ),
    Field(
      'signatureAlgorithm',
      String,
      'Signature Algorithm',
      hint: 'SHA-256, SHA-384',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? keys;

  /// Lifecycle management.
  @SectionId('CEMALI')
  @StandardReferences(
    ['IETF RFC 5280 — X.509 PKI certificates'],
    'Defines certificate validity, renewal, rotation, and revocation lifecycle.',
  )
  @Form([
    Field(
      'validityPeriod',
      String,
      'Validity Period',
      hint: 'Certificate lifetime (e.g. 90 days, 1 year)',
    ),
    Field(
      'renewalWindow',
      String,
      'Renewal Window',
      hint: 'Days before expiry to renew',
    ),
    Field(
      'automaticRenewal',
      bool,
      'Automatic Renewal',
      hint: 'Auto-renew via ACME/cert-manager',
    ),
    Field(
      'rotationPolicy',
      String,
      'Rotation Policy',
      hint: 'Scheduled rotation cadence',
    ),
    Field(
      'revocationProcess',
      String,
      'Revocation Process',
      hint: 'CRL, OCSP procedures',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? lifecycle;

  /// Storage and access controls.
  @SectionId('CEMAST')
  @StandardReferences(
    ['IETF RFC 5280 — X.509 PKI certificates'],
    'Defines how certificates and private keys are stored, protected, and access-controlled.',
  )
  @Form([
    Field(
      'storageMethod',
      String,
      'Storage Method',
      hint: 'HSM, vault, Kubernetes secrets',
    ),
    Field(
      'privateKeyProtection',
      String,
      'Private Key Protection',
      hint: 'Hardware-backed, encrypted at rest',
    ),
    Field(
      'accessControl',
      String,
      'Access Control',
      hint: 'Who can access certificates/keys',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? storage;

  /// Monitoring rules.
  @SectionId('CEMAMO')
  @StandardReferences([
    'IETF RFC 5280 — X.509 PKI certificates',
  ], 'Defines certificate expiry monitoring and alert thresholds.')
  @Form([
    Field(
      'expiryMonitoring',
      bool,
      'Expiry Monitoring',
      hint: 'Automated certificate expiry alerts',
    ),
    Field(
      'expiryAlertThreshold',
      String,
      'Expiry Alert Threshold',
      hint: 'Days before expiry to alert (e.g. 30, 14, 7)',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional certificate management notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? monitoring;
}

/// API versioning strategy.
@StandardReferences([
  'SemVer — semantic versioning',
  'OpenAPI Specification — REST API description',
], 'Defines the overall API versioning scheme, format, and current version.')
@SectionId('APVEST')
class ApiVersioningStrategy extends DocSpecsSection {
  @Form([
    // Scheme
    Field(
      'versioningScheme',
      String,
      'Versioning Scheme',
      required: true,
      hint: 'URL path, header, query parameter',
    ),
    Field(
      'versionFormat',
      String,
      'Version Format',
      hint: 'v1, v2.0, semver, date-based',
    ),
    Field(
      'currentVersion',
      String,
      'Current Version',
      hint: 'Current active API version',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Supported versions and deprecation commitments.
  @SectionId('AVSS')
  @StandardReferences(
    ['SemVer — semantic versioning', 'IETF RFC 9110 — HTTP semantics'],
    'Defines supported API versions and their deprecation and sunset commitments.',
  )
  @Form([
    Field(
      'supportedVersions',
      String,
      'Supported Versions',
      hint: 'List of all currently supported versions',
    ),
    Field(
      'deprecationPolicy',
      String,
      'Deprecation Policy',
      hint: 'Sunset timeline, notice period',
    ),
    Field(
      'deprecationNoticeMethod',
      String,
      'Deprecation Notice Method',
      hint: 'HTTP Sunset header, changelog, email',
    ),
    Field(
      'minimumSupportPeriod',
      String,
      'Minimum Support Period',
      hint: 'Minimum time a version stays supported',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? support;

  /// Compatibility guarantees and migration expectations.
  @SectionId('AVSC')
  @StandardReferences(
    [
      'SemVer — semantic versioning',
      'OpenAPI Specification — REST API description',
    ],
    'Defines backward-compatibility guarantees, breaking-change policy, and migration guidance.',
  )
  @Form([
    Field(
      'backwardCompatibility',
      String,
      'Backward Compatibility',
      hint: 'Guaranteed compatibility rules',
    ),
    Field(
      'breakingChangePolicy',
      String,
      'Breaking Change Policy',
      hint: 'When and how breaking changes are allowed',
    ),
    Field(
      'migrationGuidance',
      bool,
      'Migration Guidance',
      hint: 'Provide migration guides between versions',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? compatibility;

  /// Documentation and client generation practices.
  @SectionId('AVSD')
  @StandardReferences([
    'OpenAPI Specification — REST API description',
    'AsyncAPI — event-driven API description',
  ], 'Defines API documentation formats and client SDK generation practices.')
  @Form([
    Field(
      'apiDocumentationFormat',
      String,
      'API Documentation Format',
      hint: 'OpenAPI/Swagger, AsyncAPI, GraphQL SDL',
    ),
    Field(
      'changelogFormat',
      String,
      'Changelog Format',
      hint: 'Keep a Changelog, custom',
    ),
    Field(
      'clientSdkGeneration',
      bool,
      'Client SDK Generation',
      hint: 'Auto-generate client libraries',
    ),
    Field('notes', String, 'Notes', hint: 'Additional versioning notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? documentation;
}

/// Message format standards.
@StandardReferences([
  'JSON / IETF RFC 8259 — data interchange format',
  'Protocol Buffers — binary serialization',
], 'Defines the message serialization formats the system uses on the wire.')
@SectionId('MEFOST')
class MessageFormatStandards extends DocSpecsSection {
  @Form([
    Field(
      'primaryFormat',
      String,
      'Primary Format',
      required: true,
      hint: 'JSON, Protocol Buffers, XML',
    ),
    Field(
      'secondaryFormats',
      String,
      'Secondary Formats',
      hint: 'Additional supported formats',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Schema standards.
  @SectionId('MFSS')
  @StandardReferences(
    [
      'JSON / IETF RFC 8259 — data interchange format',
      'Protocol Buffers — binary serialization',
    ],
    'Defines schema definition, registry, evolution, and validation standards.',
  )
  @Form([
    Field(
      'schemaDefinition',
      String,
      'Schema Definition',
      hint: 'JSON Schema, Protobuf definitions, XSD',
    ),
    Field(
      'schemaRegistry',
      String,
      'Schema Registry',
      hint: 'Confluent, Apicurio, custom',
    ),
    Field(
      'schemaEvolution',
      String,
      'Schema Evolution',
      hint: 'Forward, backward, full compatibility',
    ),
    Field(
      'schemaValidation',
      String,
      'Schema Validation',
      hint: 'Request/response validation strategy',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? schema;

  /// Field conventions.
  @SectionId('MFSC')
  @StandardReferences(
    ['JSON / IETF RFC 8259 — data interchange format'],
    'Defines field-level conventions for dates, encoding, nulls, enums, and naming.',
  )
  @Form([
    Field(
      'dateTimeFormat',
      String,
      'Date/Time Format',
      hint: 'ISO 8601, Unix timestamp',
    ),
    Field(
      'characterEncoding',
      String,
      'Character Encoding',
      hint: 'UTF-8, ASCII',
    ),
    Field(
      'nullHandling',
      String,
      'Null Handling',
      hint: 'Omit, explicit null, empty string',
    ),
    Field(
      'enumRepresentation',
      String,
      'Enum Representation',
      hint: 'String, integer, UPPER_CASE',
    ),
    Field(
      'namingConvention',
      String,
      'Naming Convention',
      hint: 'camelCase, snake_case for field names',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? conventions;

  /// Pagination and error envelopes.
  @SectionId('MFSR')
  @StandardReferences(
    [
      'JSON / IETF RFC 8259 — data interchange format',
      'IETF RFC 9110 — HTTP semantics',
    ],
    'Defines pagination formats and standardized error and response envelopes.',
  )
  @Form([
    Field(
      'paginationFormat',
      String,
      'Pagination Format',
      hint: 'Cursor, offset, page-number',
    ),
    Field(
      'errorResponseFormat',
      String,
      'Error Response Format',
      hint: 'RFC 7807 Problem Details, custom envelope',
    ),
    Field(
      'envelopeFormat',
      String,
      'Envelope Format',
      hint: 'Flat, wrapped with metadata',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? responses;

  /// Compression and negotiation.
  @SectionId('MFST')
  @StandardReferences([
    'IETF RFC 9110 — HTTP semantics',
    'JSON / IETF RFC 8259 — data interchange format',
  ], 'Defines message compression algorithms and content negotiation behavior.')
  @Form([
    Field(
      'compressionAlgorithm',
      String,
      'Compression Algorithm',
      hint: 'gzip, brotli, zstd, none',
    ),
    Field(
      'contentNegotiation',
      bool,
      'Content Negotiation',
      hint: 'Support Accept/Content-Type headers',
    ),
    Field('notes', String, 'Notes', hint: 'Additional message format notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? transport;
}

/// Rate limiting and throttling.
@StandardReferences([
  'IETF RFC 9110 — HTTP semantics',
], 'Defines the rate limiting and throttling policy for API traffic.')
@SectionId('RALIPO')
class RateLimitingPolicy extends DocSpecsSection {
  @Form([
    Field(
      'rateLimitingStrategy',
      String,
      'Rate Limiting Strategy',
      required: true,
      hint: 'Token bucket, sliding window, fixed window',
    ),
    Field(
      'rateLimitScope',
      String,
      'Rate Limit Scope',
      hint: 'Global, per-client, per-endpoint, per-tenant',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Rate-limit ceilings and burst handling.
  @SectionId('RLPL')
  @StandardReferences([
    'IETF RFC 9110 — HTTP semantics',
  ], 'Defines rate-limit ceilings, per-scope limits, and burst allowances.')
  @Form([
    Field(
      'globalRateLimit',
      String,
      'Global Rate Limit',
      hint: 'Requests per second/minute overall',
    ),
    Field(
      'perClientLimit',
      String,
      'Per-Client Limit',
      hint: 'Rate limit per API key/client',
    ),
    Field(
      'perEndpointLimit',
      String,
      'Per-Endpoint Limit',
      hint: 'Rate limit per API endpoint',
    ),
    Field(
      'burstAllowance',
      String,
      'Burst Allowance',
      hint: 'Short burst above steady-state limit',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? limits;

  /// Runtime response behavior when limits are exceeded.
  @SectionId('RLPB')
  @StandardReferences(
    ['IETF RFC 9110 — HTTP semantics'],
    'Defines runtime throttling behavior and rate-limit response headers when limits are exceeded.',
  )
  @Form([
    Field(
      'throttlingBehavior',
      String,
      'Throttling Behavior',
      hint: 'HTTP 429, queue, graceful degrade',
    ),
    Field(
      'retryAfterHeader',
      bool,
      'Retry-After Header',
      hint: 'Include Retry-After in 429 responses',
    ),
    Field(
      'rateLimitHeaders',
      bool,
      'Rate Limit Headers',
      hint: 'X-RateLimit-* response headers',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? behavior;

  /// Quota management and exceptions.
  @SectionId('RLPQ')
  @StandardReferences(
    ['IETF RFC 9110 — HTTP semantics'],
    'Defines quota management, reset cadence, and exemptions from rate limits.',
  )
  @Form([
    Field(
      'quotaManagement',
      String,
      'Quota Management',
      hint: 'Daily/monthly quotas per subscription tier',
    ),
    Field(
      'quotaResetPolicy',
      String,
      'Quota Reset Policy',
      hint: 'Calendar-based, rolling window',
    ),
    Field(
      'exemptions',
      String,
      'Exemptions',
      hint: 'Services or clients exempt from limits',
    ),
    Field('notes', String, 'Notes', hint: 'Additional rate limiting notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? quotas;
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
class ProtocolComplianceRequirements extends DocSpecsSection {
  @Form([
    Field(
      'corsPolicy',
      String,
      'CORS Policy',
      hint: 'Allowed origins, methods, headers',
    ),
    Field(
      'contentSecurityPolicy',
      String,
      'Content Security Policy',
      hint: 'CSP header directives',
    ),
    Field(
      'httpSecurityHeaders',
      String,
      'HTTP Security Headers',
      hint: 'X-Frame-Options, X-Content-Type-Options',
    ),
    Field(
      'cookiePolicy',
      String,
      'Cookie Policy',
      hint: 'SameSite, Secure, HttpOnly attributes',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Caching requirements.
  @SectionId('PCRC')
  @StandardReferences([
    'IETF RFC 9110 — HTTP semantics',
  ], 'Defines HTTP caching and CDN integration requirements.')
  @Form([
    Field(
      'cachingPolicy',
      String,
      'Caching Policy',
      hint: 'Cache-Control, ETag, If-Modified-Since',
    ),
    Field(
      'cdnIntegration',
      String,
      'CDN Integration',
      hint: 'CDN caching strategy and invalidation',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? caching;

  /// Request logging and trace propagation rules.
  @SectionId('PCRO')
  @StandardReferences([
    'IETF RFC 9110 — HTTP semantics',
  ], 'Defines request logging and distributed trace-context propagation rules.')
  @Form([
    Field(
      'requestLogging',
      String,
      'Request Logging',
      hint: 'Request/response logging, PII redaction',
    ),
    Field(
      'distributedTracing',
      String,
      'Distributed Tracing',
      hint: 'Correlation IDs, W3C Trace Context, OpenTelemetry',
    ),
    Field(
      'tracePropagation',
      String,
      'Trace Propagation',
      hint: 'Header format for trace context propagation',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? observability;

  /// Webhook, event, and health endpoint standards.
  @SectionId('PCRE')
  @StandardReferences(
    [
      'AsyncAPI — event-driven API description',
      'IETF RFC 9110 — HTTP semantics',
    ],
    'Defines standards for webhooks, event streams, and health-check endpoints.',
  )
  @Form([
    Field(
      'webhookStandards',
      String,
      'Webhook Standards',
      hint: 'Signature verification, retry policy',
    ),
    Field(
      'eventStreamStandards',
      String,
      'Event Stream Standards',
      hint: 'SSE, CloudEvents format',
    ),
    Field(
      'healthEndpointStandard',
      String,
      'Health Endpoint Standard',
      hint: '/health, /ready, /live conventions',
    ),
    Field('notes', String, 'Notes', hint: 'Additional compliance notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? events;
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
class ExternalConnectivitySection extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of external connectivity requirements.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// External partner connections — contains 0+× ExternalPartnerConnection.
  @StandardReferences([
    'Enterprise Integration Patterns — messaging & integration',
  ], 'The external partner connections the system integrates with.')
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
@StandardReferences([
  'Enterprise Integration Patterns — messaging & integration',
  'OAuth 2.0 / IETF RFC 6749 — authorization framework',
  'OpenAPI Specification — REST API description',
], 'Describes a single external partner integration the system connects to.')
@SectionId('EXPACOEN')
class ExternalPartnerConnectionEntry extends DocSpecsSection {
  @Form([
    Field(
      'partnerName',
      String,
      'Partner Name',
      required: true,
      hint: 'Name of the external partner or system',
    ),
    Field(
      'partnerType',
      String,
      'Partner Type',
      hint: 'Vendor, customer, regulatory body, payment provider',
    ),
    Field(
      'connectionPurpose',
      String,
      'Connection Purpose',
      hint: 'Business purpose of this integration',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Protocol and endpoint.
  @SectionId('EXPAPR')
  @StandardReferences(
    [
      'OpenAPI Specification — REST API description',
      'IETF RFC 9110 — HTTP semantics',
    ],
    'Describes the protocol, endpoint, and data format for the partner connection.',
  )
  @Form([
    Field('protocol', String, 'Protocol', hint: 'REST, SOAP, SFTP, AS2, EDI'),
    Field('endpointUrl', String, 'Endpoint URL', hint: 'Base URL or hostname'),
    Field(
      'dataDirection',
      String,
      'Data Direction',
      hint: 'Inbound, outbound, bidirectional',
    ),
    Field(
      'dataFormat',
      String,
      'Data Format',
      hint: 'JSON, XML, CSV, EDI X12, EDIFACT',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? protocol;

  /// Authentication settings.
  @SectionId('EXPAAU')
  @StandardReferences(
    [
      'OAuth 2.0 / IETF RFC 6749 — authorization framework',
      'ISO/IEC 27001 — information security controls',
    ],
    'Specifies the authentication method and credential management for the partner connection.',
  )
  @Form([
    Field(
      'authenticationMethod',
      String,
      'Authentication Method',
      hint: 'API key, OAuth 2.0, client certificate, SAML',
    ),
    Field(
      'credentialStorage',
      String,
      'Credential Storage',
      hint: 'Vault, secrets manager, environment variable',
    ),
    Field(
      'credentialRotation',
      String,
      'Credential Rotation',
      hint: 'Rotation frequency and process',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? authentication;

  /// Network configuration.
  @SectionId('EXPANE')
  @StandardReferences(
    ['ISO/IEC 27001 — information security controls'],
    'Describes network routing, IP whitelisting, and firewall rules for the partner connection.',
  )
  @Form([
    Field(
      'networkRoute',
      String,
      'Network Route',
      hint: 'Public internet, VPN, private link, dedicated line',
    ),
    Field(
      'ipWhitelisting',
      bool,
      'IP Whitelisting',
      hint: 'Restrict by IP address',
    ),
    Field(
      'whitelistedIps',
      String,
      'Whitelisted IPs',
      hint: 'Allowed IP ranges',
    ),
    Field(
      'firewallRules',
      String,
      'Firewall Rules',
      hint: 'Required firewall rule changes',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? network;

  /// Reliability and SLA.
  @SectionId('EXPARE')
  @StandardReferences(
    [
      'Circuit Breaker / Resilience patterns — fault tolerance',
      'Enterprise Integration Patterns — messaging & integration',
    ],
    'Captures SLA, latency, timeout, and retry expectations for the partner connection.',
  )
  @Form([
    Field('sla', String, 'SLA', hint: 'Partner system availability SLA'),
    Field(
      'expectedLatency',
      String,
      'Expected Latency',
      hint: 'Round-trip time expectations',
    ),
    Field(
      'expectedThroughput',
      String,
      'Expected Throughput',
      hint: 'Requests per second or data volume',
    ),
    Field(
      'timeoutPolicy',
      String,
      'Timeout Policy',
      hint: 'Connection and read timeout',
    ),
    Field(
      'retryStrategy',
      String,
      'Retry Strategy',
      hint: 'Retry count, backoff policy',
    ),
    Field(
      'circuitBreakerEnabled',
      bool,
      'Circuit Breaker',
      hint: 'Circuit breaker for partner failures',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? reliability;

  /// Data handling.
  @SectionId('EPDH')
  @StandardReferences(
    [
      'ISO/IEC 27001 — information security controls',
      'IETF RFC 8446 — TLS 1.3',
    ],
    'Specifies data classification, encryption, and retention for partner data exchange.',
  )
  @Form([
    Field(
      'dataClassification',
      String,
      'Data Classification',
      hint: 'Confidentiality level of exchanged data',
    ),
    Field(
      'encryptionRequirements',
      String,
      'Encryption Requirements',
      hint: 'Encryption in transit and at rest',
    ),
    Field(
      'dataRetention',
      String,
      'Data Retention',
      hint: 'Retention of exchanged data',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? dataHandling;

  /// Operations and contacts.
  @StandardReferences([
    'Enterprise Integration Patterns — messaging & integration',
  ], 'The operational contacts and procedures for the partner connection.')
  @SectionId('EXPAOP-OPER-LST')
  @SectionIdPattern('EXPAOP-OPER-xxx')
  @ContentHelp('Add one entry per operational contact.')
  @SerializationOrder(6)
  List<ExternalPartnerOperations> operations = [];
}

/// Operations and contacts.
@StandardReferences(
  ['Enterprise Integration Patterns — messaging & integration'],
  'Captures operational contacts and escalation processes for the partner integration.',
)
@SectionId('EXPAOP')
class ExternalPartnerOperations extends DocSpecsSection {
  @Form([
    Field(
      'contactPerson',
      String,
      'Contact Person',
      hint: 'Technical contact at partner',
    ),
    Field(
      'escalationProcess',
      String,
      'Escalation Process',
      hint: 'Issue escalation path',
    ),
    Field(
      'maintenanceNotification',
      String,
      'Maintenance Notification',
      hint: 'How partner communicates downtimes',
    ),
    Field('notes', String, 'Notes', hint: 'Additional connection notes'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// Cloud service integrations.
@StandardReferences([
  'OpenAPI Specification — REST API description',
  'ISO/IEC 27001 — information security controls',
], 'Describes the cloud provider services the system integrates with.')
@SectionId('CLSEIN')
class CloudServiceIntegrations extends DocSpecsSection {
  @Form([
    Field(
      'primaryCloudProvider',
      String,
      'Primary Cloud Provider',
      hint: 'AWS, Azure, GCP, multi-cloud',
    ),
    Field(
      'secondaryProviders',
      String,
      'Secondary Providers',
      hint: 'Additional cloud providers',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Managed services catalog.
  @SectionId('CSIS')
  @StandardReferences(
    [
      'OpenAPI Specification — REST API description',
      'ISO/IEC 27001 — information security controls',
    ],
    'Catalogs the managed cloud services the system depends on, such as storage and identity.',
  )
  @Form([
    Field(
      'managedServices',
      String,
      'Managed Services',
      hint: 'Databases, queues, caches, storage',
    ),
    Field(
      'identityProvider',
      String,
      'Identity Provider',
      hint: 'Cognito, Azure AD, Auth0, Keycloak',
    ),
    Field(
      'emailService',
      String,
      'Email Service',
      hint: 'SES, SendGrid, Mailgun',
    ),
    Field(
      'notificationService',
      String,
      'Notification Service',
      hint: 'Push notifications, SMS gateway',
    ),
    Field(
      'storageService',
      String,
      'Storage Service',
      hint: 'S3, Blob Storage, GCS',
    ),
    Field(
      'cdnService',
      String,
      'CDN Service',
      hint: 'CloudFront, Azure CDN, Cloudflare',
    ),
    Field(
      'searchService',
      String,
      'Search Service',
      hint: 'Elasticsearch, OpenSearch, Algolia',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? services;

  /// Network connectivity.
  @SectionId('CSIN')
  @StandardReferences(
    ['ISO/IEC 27001 — information security controls'],
    'Describes VPC peering, private endpoints, and transit routing for cloud connectivity.',
  )
  @Form([
    Field(
      'vpcPeering',
      String,
      'VPC Peering',
      hint: 'VPC/VNet peering requirements',
    ),
    Field(
      'privateEndpoints',
      String,
      'Private Endpoints',
      hint: 'Private link, service endpoints',
    ),
    Field(
      'transitGateway',
      String,
      'Transit Gateway',
      hint: 'Cross-VPC or cross-region routing',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? networking;

  /// Compliance and notes.
  @SectionId('CSIC')
  @StandardReferences(
    ['ISO/IEC 27001 — information security controls'],
    'Specifies data residency and compliance certifications for cloud service integrations.',
  )
  @Form([
    Field(
      'dataResidency',
      String,
      'Data Residency',
      hint: 'Region restrictions for data storage',
    ),
    Field(
      'complianceCertifications',
      String,
      'Compliance Certifications',
      hint: 'SOC 2, ISO 27001, HIPAA',
    ),
    Field('notes', String, 'Notes', hint: 'Additional cloud integration notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? compliance;
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
class ThirdPartyApiIntegrations extends DocSpecsSection {
  @Form([
    Field(
      'paymentGateways',
      String,
      'Payment Gateways',
      hint: 'Stripe, PayPal, Adyen',
    ),
    Field(
      'paymentCompliance',
      String,
      'Payment Compliance',
      hint: 'PCI DSS level, tokenization',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Analytics and monitoring providers.
  @SectionId('TPAIA')
  @StandardReferences(
    [
      'OpenAPI Specification — REST API description',
      'OAuth 2.0 / IETF RFC 6749 — authorization framework',
    ],
    'Describes third-party analytics and error-tracking service providers the system consumes.',
  )
  @Form([
    Field(
      'analyticsServices',
      String,
      'Analytics Services',
      hint: 'Google Analytics, Mixpanel, Amplitude',
    ),
    Field(
      'errorTrackingServices',
      String,
      'Error Tracking Services',
      hint: 'Sentry, Bugsnag, Datadog APM',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? analytics;

  /// Communication providers.
  @SectionId('TPAIC')
  @StandardReferences(
    [
      'OpenAPI Specification — REST API description',
      'Webhooks — HTTP callback delivery',
    ],
    'Describes third-party SMS, chat, and video conferencing communication providers.',
  )
  @Form([
    Field(
      'smsProviders',
      String,
      'SMS Providers',
      hint: 'Twilio, MessageBird, Vonage',
    ),
    Field(
      'chatIntegrations',
      String,
      'Chat Integrations',
      hint: 'Slack, Teams, Telegram bots',
    ),
    Field(
      'videoConferencing',
      String,
      'Video Conferencing',
      hint: 'Zoom, Teams, Jitsi APIs',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? communication;

  /// Mapping and location providers.
  @SectionId('TPAIL')
  @StandardReferences(
    [
      'OpenAPI Specification — REST API description',
      'OAuth 2.0 / IETF RFC 6749 — authorization framework',
    ],
    'Describes third-party mapping and geocoding service providers the system consumes.',
  )
  @Form([
    Field(
      'mappingServices',
      String,
      'Mapping Services',
      hint: 'Google Maps, Mapbox, HERE',
    ),
    Field(
      'geocodingServices',
      String,
      'Geocoding Services',
      hint: 'Address validation and geocoding',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? location;

  /// Document and media providers.
  @SectionId('TPAIM')
  @StandardReferences(
    [
      'OpenAPI Specification — REST API description',
      'OAuth 2.0 / IETF RFC 6749 — authorization framework',
    ],
    'Describes third-party document generation, media processing, and OCR providers.',
  )
  @Form([
    Field(
      'documentGeneration',
      String,
      'Document Generation',
      hint: 'PDF generation, document signing',
    ),
    Field(
      'mediaProcessing',
      String,
      'Media Processing',
      hint: 'Image resizing, video transcoding',
    ),
    Field(
      'ocrServices',
      String,
      'OCR Services',
      hint: 'Document scanning and text extraction',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? media;

  /// AI and translation providers.
  @SectionId('THPAAPINAI')
  @StandardReferences(
    [
      'OpenAPI Specification — REST API description',
      'OAuth 2.0 / IETF RFC 6749 — authorization framework',
    ],
    'Describes third-party AI/ML and translation service providers the system consumes.',
  )
  @Form([
    Field(
      'aiServices',
      String,
      'AI/ML Services',
      hint: 'OpenAI, Claude, Bedrock, Vertex AI',
    ),
    Field(
      'translationServices',
      String,
      'Translation Services',
      hint: 'Google Translate, DeepL',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? ai;

  /// Compliance and fallback controls.
  @SectionId('TPAIO')
  @StandardReferences(
    [
      'Circuit Breaker / Resilience patterns — fault tolerance',
      'OAuth 2.0 / IETF RFC 6749 — authorization framework',
    ],
    'Defines API key management, usage monitoring, and fallback strategy for third-party APIs.',
  )
  @Form([
    Field(
      'apiKeyManagement',
      String,
      'API Key Management',
      hint: 'Storage, rotation, access control',
    ),
    Field(
      'usageMonitoring',
      String,
      'Usage Monitoring',
      hint: 'Cost tracking per API',
    ),
    Field(
      'fallbackStrategy',
      String,
      'Fallback Strategy',
      hint: 'Alternative when primary is unavailable',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional third-party integration notes',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? operations;
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
class NetworkSecurityPolicy extends DocSpecsSection {
  @Form([
    Field(
      'firewallType',
      String,
      'Firewall Type',
      hint: 'WAF, network firewall, host-based',
    ),
    Field(
      'wafProvider',
      String,
      'WAF Provider',
      hint: 'AWS WAF, Cloudflare, Azure Front Door',
    ),
    Field(
      'defaultDenyPolicy',
      bool,
      'Default Deny Policy',
      hint: 'Deny all except explicit allow',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Firewall rule details.
  @SectionId('NSPF')
  @StandardReferences([
    'ISO/IEC 27001 — information security controls',
  ], 'Specifies ingress and egress firewall rules governing external traffic.')
  @Form([
    Field(
      'ingressRules',
      String,
      'Ingress Rules',
      hint: 'Allowed inbound traffic rules',
    ),
    Field(
      'egressRules',
      String,
      'Egress Rules',
      hint: 'Allowed outbound traffic rules',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? firewall;

  /// IP management controls.
  @SectionId('NSPIM')
  @StandardReferences(
    ['ISO/IEC 27001 — information security controls'],
    'Defines IP allow-listing, deny-listing, and geo-blocking access controls.',
  )
  @Form([
    Field(
      'staticIpRequired',
      bool,
      'Static IP Required',
      hint: 'Fixed outbound IP addresses',
    ),
    Field(
      'ipAllowListing',
      String,
      'IP Allow-Listing',
      hint: 'Inbound IP restrictions',
    ),
    Field(
      'ipDenyListing',
      String,
      'IP Deny-Listing',
      hint: 'Blocked IP ranges',
    ),
    Field(
      'geoBlocking',
      String,
      'Geo-Blocking',
      hint: 'Country or region-based access control',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? ipManagement;

  /// VPN configuration.
  @SectionId('NSPV')
  @StandardReferences(
    [
      'ISO/IEC 27001 — information security controls',
      'IETF RFC 8446 — TLS 1.3',
    ],
    'Specifies VPN type, topology, and availability for secure external connectivity.',
  )
  @Form([
    Field(
      'vpnRequired',
      bool,
      'VPN Required',
      hint: 'Site-to-site or client VPN',
    ),
    Field(
      'vpnType',
      String,
      'VPN Type',
      hint: 'IPSec, WireGuard, OpenVPN, AWS Client VPN',
    ),
    Field(
      'vpnTopology',
      String,
      'VPN Topology',
      hint: 'Hub-spoke, mesh, point-to-point',
    ),
    Field(
      'vpnHighAvailability',
      bool,
      'VPN High Availability',
      hint: 'Redundant VPN tunnels',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? vpn;

  /// DDoS protections.
  @SectionId('NSPD')
  @StandardReferences(
    [
      'ISO/IEC 27001 — information security controls',
      'API Gateway pattern — edge routing & policy enforcement',
    ],
    'Describes DDoS protection and edge rate limiting for external connectivity.',
  )
  @Form([
    Field(
      'ddosProtection',
      String,
      'DDoS Protection',
      hint: 'AWS Shield, Cloudflare, Azure DDoS',
    ),
    Field(
      'rateLimitingAtEdge',
      String,
      'Rate Limiting at Edge',
      hint: 'Edge-level request throttling',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? ddos;

  /// DNS controls and notes.
  @SectionId('NESEPODN')
  @StandardReferences(
    ['ISO/IEC 27001 — information security controls'],
    'Specifies DNS provider, DNSSEC, and private DNS controls for connectivity.',
  )
  @Form([
    Field(
      'dnsProvider',
      String,
      'DNS Provider',
      hint: 'Route 53, Cloudflare DNS, Azure DNS',
    ),
    Field(
      'dnssecEnabled',
      bool,
      'DNSSEC Enabled',
      hint: 'DNS Security Extensions',
    ),
    Field('privateDns', String, 'Private DNS', hint: 'Internal DNS zones'),
    Field('notes', String, 'Notes', hint: 'Additional network security notes'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? dns;
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
class ServiceMeshAndGateway extends DocSpecsSection {
  @Form([
    Field(
      'apiGateway',
      String,
      'API Gateway',
      hint: 'Kong, AWS API Gateway, Apigee, Azure APIM',
    ),
    Field(
      'gatewayFeatures',
      String,
      'Gateway Features',
      hint: 'Auth, throttling, transformation, caching',
    ),
    Field(
      'gatewayHighAvailability',
      bool,
      'Gateway High Availability',
      hint: 'Multi-region or multi-zone gateway',
    ),
    Field(
      'apiKeyManagement',
      String,
      'API Key Management',
      hint: 'Developer portal, key provisioning',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Service mesh configuration.
  @SectionId('SMAGM')
  @StandardReferences(
    [
      'Service Mesh (Istio / Envoy) — service-to-service traffic management',
      'IETF RFC 8446 — TLS 1.3',
    ],
    'Describes the service mesh, sidecar proxy, traffic policy, and mTLS configuration.',
  )
  @Form([
    Field(
      'serviceMesh',
      String,
      'Service Mesh',
      hint: 'Istio, Linkerd, Consul Connect',
    ),
    Field(
      'sidecarProxy',
      String,
      'Sidecar Proxy',
      hint: 'Envoy, HAProxy, custom',
    ),
    Field(
      'trafficPolicy',
      String,
      'Traffic Policy',
      hint: 'Retries, timeouts, circuit breaking',
    ),
    Field(
      'mtlsEnabled',
      bool,
      'mTLS Enabled',
      hint: 'Mutual TLS for internal traffic',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? mesh;

  /// Load balancing and termination rules.
  @SectionId('SMAGLB')
  @StandardReferences(
    [
      'Service Mesh (Istio / Envoy) — service-to-service traffic management',
      'IETF RFC 8446 — TLS 1.3',
    ],
    'Specifies load balancing algorithms and SSL termination rules for traffic distribution.',
  )
  @Form([
    Field(
      'loadBalancerType',
      String,
      'Load Balancer Type',
      hint: 'Application LB, Network LB, internal',
    ),
    Field(
      'loadBalancingAlgorithm',
      String,
      'Load Balancing Algorithm',
      hint: 'Round-robin, least-connections, weighted',
    ),
    Field(
      'healthCheckEndpoint',
      String,
      'Health Check Endpoint',
      hint: 'LB health check path and interval',
    ),
    Field(
      'sslTermination',
      String,
      'SSL Termination',
      hint: 'At load balancer, gateway, or application',
    ),
    Field('notes', String, 'Notes', hint: 'Additional gateway/mesh notes'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? loadBalancing;
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
class ConnectivityResilience extends DocSpecsSection {
  @Form([
    Field(
      'failoverStrategy',
      String,
      'Failover Strategy',
      hint: 'Active-passive, active-active, DNS failover',
    ),
    Field(
      'redundantConnections',
      bool,
      'Redundant Connections',
      hint: 'Multiple ISP or network paths',
    ),
    Field(
      'geographicRedundancy',
      String,
      'Geographic Redundancy',
      hint: 'Multi-region connectivity',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Circuit breaking and isolation strategy.
  @SectionId('COREP1')
  @StandardReferences(
    ['Circuit Breaker / Resilience patterns — fault tolerance'],
    'Defines circuit breaking, bulkhead isolation, and fallback behavior for downstream failures.',
  )
  @Form([
    Field(
      'circuitBreakerPattern',
      String,
      'Circuit Breaker Pattern',
      hint: 'Threshold, timeout, half-open criteria',
    ),
    Field(
      'bulkheadIsolation',
      String,
      'Bulkhead Isolation',
      hint: 'Connection pool isolation per downstream',
    ),
    Field(
      'fallbackBehavior',
      String,
      'Fallback Behavior',
      hint: 'Cached response, degraded mode, error page',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? protection;

  /// Offline and reconnection behavior.
  @SectionId('COREOF')
  @StandardReferences(
    [
      'Circuit Breaker / Resilience patterns — fault tolerance',
      'Enterprise Integration Patterns — messaging & integration',
    ],
    'Describes offline capability and reconnection behavior when connectivity is lost.',
  )
  @Form([
    Field(
      'offlineCapability',
      String,
      'Offline Capability',
      hint: 'Client-side caching and sync strategy',
    ),
    Field(
      'reconnectionStrategy',
      String,
      'Reconnection Strategy',
      hint: 'Automatic reconnect with backoff',
    ),
    Field(
      'queuedOperations',
      bool,
      'Queued Operations',
      hint: 'Queue requests when connectivity lost',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? offline;

  /// Monitoring and alerting expectations.
  @SectionId('COREOP')
  @StandardReferences(
    [
      'Circuit Breaker / Resilience patterns — fault tolerance',
      'ISO/IEC 27001 — information security controls',
    ],
    'Defines monitoring and alerting expectations for external connectivity health.',
  )
  @Form([
    Field(
      'connectivityMonitoring',
      String,
      'Connectivity Monitoring',
      hint: 'Uptime monitoring, latency checks',
    ),
    Field(
      'connectivityAlerts',
      String,
      'Connectivity Alerts',
      hint: 'Alert on degradation or outage',
    ),
    Field('notes', String, 'Notes', hint: 'Additional resilience notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? operations;
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
class SystemOperationAndMonitoring extends DocSpecsSection {
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
  @override
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
class SystemOperation extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// 8.7.1.1. Administration Requirements.
  @SerializationOrder(1)
  AdministrationRequirementsSection administrationRequirements =
      AdministrationRequirementsSection();

  /// Maintenance Procedures.
  @StandardReferences([
    'ITIL 4 — change enablement and maintenance windows',
  ], 'The catalog of scheduled maintenance procedures the system requires.')
  @SectionId('MAINT-MAIN-LST')
  @SectionIdPattern('MAINT-MAIN-xxx')
  @ContentHelp('Add one entry per maintenance procedure.')
  @SerializationOrder(2)
  List<DocSpecsSection> maintenanceProcedures = [];
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
class AdministrationRequirementsSection extends DocSpecsSection {
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
  @override
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
  @SectionId('ADENMA')
  @StandardReferences(
    [
      'ITIL 4 — service configuration management practice',
      'AWS Well-Architected — operational excellence (runbooks, playbooks)',
    ],
    'Administration environment management governs how environments are provisioned, seeded, and accessed.',
  )
  @Form([
    // Environments
    Field(
      'environmentCatalog',
      String,
      'Environment Catalog',
      hint: 'List of managed environments',
    ),
    Field(
      'environmentProvisioning',
      String,
      'Environment Provisioning',
      hint: 'Automated, on-demand, scheduled',
    ),
    Field(
      'environmentCloning',
      bool,
      'Environment Cloning',
      hint: 'Clone environment for testing',
    ),

    // Data management
    Field(
      'dataSeeding',
      String,
      'Data Seeding',
      hint: 'Seed data for non-production envs',
    ),
    Field(
      'dataAnonymization',
      bool,
      'Data Anonymization',
      hint: 'Anonymize production data for dev/test',
    ),
    Field(
      'dataSyncBetweenEnvs',
      String,
      'Data Sync Between Envs',
      hint: 'Selective data promotion',
    ),

    // Access
    Field(
      'environmentAccessControl',
      String,
      'Environment Access Control',
      hint: 'Who can access which environment',
    ),
    Field(
      'productionAccessPolicy',
      String,
      'Production Access Policy',
      hint: 'Break-glass, approval workflow',
    ),
    Field(
      'environmentVariableManagement',
      String,
      'Env Variable Management',
      hint: 'Per-env variable sets',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional environment management notes',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? environmentManagement;

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
class AdminInterfaceRequirements extends DocSpecsSection {
  @Form([
    Field(
      'adminPortalType',
      String,
      'Admin Portal Type',
      required: true,
      hint: 'Web dashboard, CLI, API, mobile',
    ),
    Field(
      'adminPortalUrl',
      String,
      'Admin Portal URL',
      hint: 'Dedicated admin subdomain or path',
    ),
    Field(
      'accessRestriction',
      String,
      'Access Restriction',
      hint: 'VPN-only, IP-restricted, MFA-required',
    ),
    Field(
      'authenticationMethod',
      String,
      'Authentication Method',
      hint: 'SSO, LDAP, local credentials',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Dashboard widget requirements.
  @SectionId('AIRD')
  @StandardReferences(
    [
      'AWS Well-Architected — operational excellence (runbooks, playbooks)',
      'Google SRE — eliminating toil and operational procedures',
    ],
    'Dashboard widget requirements define the at-a-glance status widgets on the admin landing page.',
  )
  @Form([
    Field(
      'dashboardOverview',
      String,
      'Dashboard Overview',
      hint: 'Key metrics displayed on landing page',
    ),
    Field(
      'systemHealthWidget',
      bool,
      'System Health Widget',
      hint: 'Real-time system status indicator',
    ),
    Field(
      'activeUsersWidget',
      bool,
      'Active Users Widget',
      hint: 'Current active user count',
    ),
    Field(
      'alertsSummaryWidget',
      bool,
      'Alerts Summary Widget',
      hint: 'Recent alerts and warnings',
    ),
    Field(
      'resourceUsageWidget',
      bool,
      'Resource Usage Widget',
      hint: 'CPU, memory, storage gauges',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? dashboard;

  /// Data management tooling.
  @SectionId('ADINREDA')
  @StandardReferences(
    [
      'CIS Controls — secure configuration and administration',
      'ISO/IEC 27001 — operations security (A.12)',
    ],
    'Data management tooling provides import, export, search, and audit-log viewing for administrators.',
  )
  @Form([
    Field(
      'dataExport',
      String,
      'Data Export',
      hint: 'Export formats (CSV, JSON, PDF)',
    ),
    Field(
      'dataImport',
      String,
      'Data Import',
      hint: 'Bulk import capabilities',
    ),
    Field(
      'searchAndFiltering',
      String,
      'Search and Filtering',
      hint: 'Global search, advanced filters',
    ),
    Field(
      'auditLogViewer',
      bool,
      'Audit Log Viewer',
      hint: 'View admin action audit trail',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? data;

  /// Operational controls.
  @SectionId('AIRO')
  @StandardReferences(
    [
      'AWS Well-Architected — operational excellence (runbooks, playbooks)',
      'Google SRE — eliminating toil and operational procedures',
    ],
    'Operational controls let administrators toggle maintenance mode, feature flags, and caches.',
  )
  @Form([
    Field(
      'maintenanceModeToggle',
      bool,
      'Maintenance Mode Toggle',
      hint: 'Enable/disable maintenance mode',
    ),
    Field(
      'featureFlagManagement',
      bool,
      'Feature Flag Management',
      hint: 'Toggle feature flags from admin',
    ),
    Field(
      'cacheManagement',
      bool,
      'Cache Management',
      hint: 'Clear or invalidate caches',
    ),
    Field('notes', String, 'Notes', hint: 'Additional admin interface notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? operations;
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
@CodeSpecKind(
  [CodeSpecPart.serverConfiguration],
  note:
      'CE-CF — server / system configuration only (narrowed csm2r5); '
      'never carries user or client-machine settings.',
)
class SystemConfigurationManagement extends DocSpecsSection {
  @Form([
    // Configuration sources
    Field(
      'configurationSource',
      String,
      'Configuration Source',
      required: true,
      hint: 'Environment variables, config files, vault',
    ),
    Field(
      'configurationFormat',
      String,
      'Configuration Format',
      hint: 'YAML, JSON, TOML, properties',
    ),
    Field(
      'centralConfigService',
      String,
      'Central Config Service',
      hint: 'Consul, Spring Cloud Config, AWS AppConfig',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Dynamic configuration and rollback behavior.
  @SectionId('SCMD')
  @StandardReferences(
    [
      'ISO/IEC 20000 — configuration and change management',
      'ITIL 4 — change enablement and maintenance windows',
    ],
    'Dynamic configuration and rollback behavior describe how config changes are applied live and reverted.',
  )
  @Form([
    Field(
      'dynamicConfiguration',
      bool,
      'Dynamic Configuration',
      hint: 'Change config without restart',
    ),
    Field(
      'hotReloadSupport',
      bool,
      'Hot Reload Support',
      hint: 'Apply config changes live',
    ),
    Field(
      'configVersioning',
      bool,
      'Config Versioning',
      hint: 'Track configuration history',
    ),
    Field(
      'configRollback',
      bool,
      'Config Rollback',
      hint: 'Revert to previous configuration',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? dynamic;

  /// Environment overrides and secrets handling.
  @SectionId('SCME')
  @StandardReferences(
    [
      'CIS Controls — secure configuration and administration',
      'ISO/IEC 27001 — operations security (A.12)',
    ],
    'Environment overrides and secrets handling govern per-environment configuration and credential storage.',
  )
  @Form([
    Field(
      'environmentOverrides',
      String,
      'Environment Overrides',
      hint: 'Per-environment config layering',
    ),
    Field(
      'secretsManagement',
      String,
      'Secrets Management',
      hint: 'Vault, AWS Secrets Manager, Azure Key Vault',
    ),
    Field(
      'secretRotation',
      bool,
      'Secret Rotation',
      hint: 'Automated secret rotation',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? environment;

  /// Validation, diffing, and audit controls.
  @SectionId('SCMG')
  @StandardReferences(
    [
      'ISO/IEC 20000 — configuration and change management',
      'ITIL 4 — service configuration management practice',
    ],
    'Validation, diffing, and audit controls ensure configuration changes are checked and traceable.',
  )
  @Form([
    Field(
      'configValidation',
      String,
      'Config Validation',
      hint: 'Schema validation before deploy',
    ),
    Field(
      'configDiffing',
      bool,
      'Config Diffing',
      hint: 'Compare configurations across envs',
    ),
    Field(
      'configAuditTrail',
      bool,
      'Config Audit Trail',
      hint: 'Log who changed what and when',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional configuration management notes',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;

  /// The declared server configuration settings.
  @StandardReferences([
    'Twelve-Factor App — config stored in the environment',
    'CIS Controls — secure configuration and administration',
  ], 'The server / system configuration settings declared for this system, one entry per key.')
  @SectionId('SCSET-SETT-LST')
  @SectionIdPattern('SCSET-SETT-xxx')
  @ContentHelp(
    'Add one entry per server configuration setting. Declare the setting — '
    'key, value type, default, the source key it is read from, whether it '
    'carries a secret, and whether narrower scopes may shadow it. Never write '
    'the value: it is supplied per deployment, and a secret-bearing setting '
    'declares only its presence and shape, never its content. Typical keys: '
    'server.host, server.port, server.isolateCount, log.level, '
    'database.migrationsDirectory, tls.privateKey, jwt.rsaPrivateKey.',
  )
  @SerializationOrder(4)
  List<ServerConfigurationSettingEntry> settings = [];
}

/// A single declared server / system configuration setting (CE-CF).
///
/// The declaration only: key, value type, default, the environment variable and
/// command-line option it may also be read from, whether it carries a secret,
/// and which narrower scopes may shadow it. The *value* is supplied per
/// deployment through the configuration
/// tree, the OS environment, a `.env` file or the command line (in that
/// precedence, command line winning) and is never authored. A secret-bearing
/// setting declares its presence and shape so deployment tooling can supply
/// the content out of band (`codespecs_mapping.md` §5.16).
///
/// Security and infrastructure configuration is scope-pinned: it stays
/// server-side unless the declaration explicitly opens it to a narrower scope.
@StandardReferences(
  [
    'Twelve-Factor App — config stored in the environment',
    'CIS Controls — secure configuration and administration',
    'OWASP ASVS — secrets management',
  ],
  'Declares one server configuration setting: its key, value type, default, deployment source aliases, secret marking, and which narrower scopes may shadow it.',
)
@SectionId('SCSET')
class ServerConfigurationSettingEntry extends DocSpecsSection {
  @Form([
    Field(
      'settingKey',
      String,
      'Setting Key',
      required: true,
      hint: 'The dotted key of the server setting, e.g. server.isolateCount',
    ),
    Field(
      'valueType',
      String,
      'Value Type',
      hint: 'string / int / double / bool / enum',
    ),
    Field(
      'defaultValue',
      String,
      'Default Value',
      hint:
          'The value used when no deployment source supplies one; leave empty '
          'for a setting that must be supplied per deployment',
    ),
    Field(
      'environmentVariable',
      String,
      'Environment Variable',
      hint:
          'The environment variable this setting may also be read from, e.g. '
          'SERVER_ISOLATE_COUNT; leave empty if it is not readable that way',
    ),
    Field(
      'commandLineOption',
      String,
      'Command-Line Option',
      hint:
          'The command-line option this setting may also be read from, e.g. '
          '--isolates; the command line wins over every other source',
    ),
    Field(
      'secret',
      bool,
      'Carries a Secret',
      hint:
          'Whether the value is a secret (certificate, private key, shared '
          'secret) — declared here, supplied out of band, never written down',
    ),
    Field(
      'overridableBy',
      String,
      'Overridable By',
      required: true,
      hint:
          'The narrowest scope permitted to shadow this key — every scope in '
          'between is opened too: none (scope-pinned, and the only correct '
          'answer for security and infrastructure settings) / client / user / '
          'device. No default: pinning a key must be authored, not fallen into',
    ),
  ])
  @override
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
class UserProvisioningTools extends DocSpecsSection {
  @Form([
    Field(
      'provisioningMethod',
      String,
      'Provisioning Method',
      required: true,
      hint: 'Manual, SCIM, LDAP sync, JIT provisioning',
    ),
    Field(
      'bulkProvisioning',
      bool,
      'Bulk Provisioning',
      hint: 'Import users via CSV/file upload',
    ),
    Field(
      'selfServiceRegistration',
      bool,
      'Self-Service Registration',
      hint: 'Users can create own accounts',
    ),
    Field(
      'invitationWorkflow',
      bool,
      'Invitation Workflow',
      hint: 'Invite users via email',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Account lifecycle management.
  @SectionId('UPTL')
  @StandardReferences(
    [
      'CIS Controls — secure configuration and administration',
      'ISO/IEC 27001 — operations security (A.12)',
    ],
    'Account lifecycle management defines how user accounts are activated, suspended, and offboarded.',
  )
  @Form([
    Field(
      'accountActivation',
      String,
      'Account Activation',
      hint: 'Email verification, admin approval',
    ),
    Field(
      'accountDeactivation',
      String,
      'Account Deactivation',
      hint: 'Soft delete, hard delete, disable',
    ),
    Field(
      'accountSuspension',
      bool,
      'Account Suspension',
      hint: 'Temporary account suspension',
    ),
    Field(
      'inactivityPolicy',
      String,
      'Inactivity Policy',
      hint: 'Auto-disable after N days of inactivity',
    ),
    Field(
      'offboardingProcess',
      String,
      'Offboarding Process',
      hint: 'Data transfer, access revocation',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? lifecycle;

  /// Role management and reviews.
  @SectionId('UPTRM')
  @StandardReferences(
    [
      'CIS Controls — secure configuration and administration',
      'ISO/IEC 27001 — operations security (A.12)',
    ],
    'Role management and reviews control how roles are assigned and periodically recertified.',
  )
  @Form([
    Field(
      'roleAssignment',
      String,
      'Role Assignment',
      hint: 'Manual, rule-based, request-approval',
    ),
    Field(
      'delegatedAdministration',
      bool,
      'Delegated Administration',
      hint: 'Department admins manage own users',
    ),
    Field(
      'accessReviewProcess',
      String,
      'Access Review Process',
      hint: 'Periodic access recertification',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? roleManagement;

  /// Directory integration settings.
  @SectionId('UPTDI')
  @StandardReferences(
    [
      'CIS Controls — secure configuration and administration',
      'ISO/IEC 27001 — operations security (A.12)',
    ],
    'Directory integration settings govern how user accounts synchronize with an external directory.',
  )
  @Form([
    Field(
      'directoryIntegration',
      String,
      'Directory Integration',
      hint: 'Active Directory, Azure AD, LDAP',
    ),
    Field(
      'syncFrequency',
      String,
      'Sync Frequency',
      hint: 'Real-time, hourly, daily',
    ),
    Field(
      'conflictResolution',
      String,
      'Conflict Resolution',
      hint: 'Source of truth for conflicts',
    ),
    Field('notes', String, 'Notes', hint: 'Additional user provisioning notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? directoryIntegration;
}

/// Batch job management — the scheduled jobs and the policy they run under.
///
/// Two layers, deliberately separated. This section and its policy subsections
/// author what is true of *every* job — the time-zone basis, the execution
/// controls, the monitoring surface. [scheduledJobs] authors the jobs
/// themselves, one entry each. A specification that has only the policy layer
/// can say how jobs are run in general but cannot name a single one, which is
/// exactly what the job list exists to fix.
///
/// The policy is the **default layer**: an execution control stated here applies
/// to every job that does not override it, and an entry that does override it
/// says so in its own failure-policy subsection.
@StandardReferences(
  [
    'Google SRE — eliminating toil and operational procedures',
    'AWS Well-Architected — operational excellence (runbooks, playbooks)',
  ],
  'Batch job management specifies how scheduled and background jobs are defined and operated.',
)
@SectionId('BAJOMA')
class BatchJobManagement extends DocSpecsSection {
  @ContentHelp('''
Describe the ground rules every scheduled job runs under.

**The scheduling substrate is fixed, so there is no engine decision to record
here.** Jobs are run by the framework's own scheduler; this section says under
what rules they run, never with what.

**Time zone is a system-wide choice, not a per-job one.** Every schedule is
interpreted in the scheduler's own clock zone, so state that zone once here
rather than per job.

The jobs themselves are declared one by one in Scheduled Jobs (SCJOB); the
subsections below carry the defaults those declarations inherit.
''')
  @Form([
    Field(
      'timeZoneHandling',
      String,
      'Time Zone Handling',
      required: true,
      hint: 'The clock zone every schedule is interpreted in — UTC or the '
          "server's local zone",
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Workload shape — orientation above the job list, deliberately narrative.
  ///
  /// What kind of batch surface this system has, in prose: mostly a nightly
  /// financial rollup with a small maintenance tail, or a continuous
  /// integration-sync load, or a report factory. It is the paragraph a reader
  /// wants *before* thirty [scheduledJobs] entries, for the same reason an
  /// architecture overview sits above a component list.
  ///
  /// **It is narrative and not a form, on purpose.** This section used to carry
  /// five fixed category slots — data processing, report generation,
  /// notification, maintenance, integration sync. A form of five slots each
  /// labelled "… Jobs" *is* an inventory grouped by category, whatever the help
  /// text says, so it became a second place to state which jobs exist and could
  /// disagree with [scheduledJobs] — which is authoritative and is what the
  /// CodeSpecs generator reads. The fixed five were also a closed taxonomy with
  /// no basis: a system whose batch work is model retraining or index rebuilding
  /// had no slot. One prose field can describe any workload and cannot be
  /// mistaken for the inventory.
  ///
  /// [scheduledJobs] remains the only place a job comes into existence. A shape
  /// described here that no entry there realises is a workload the specification
  /// has not actually declared.
  @SectionId('BJMJT')
  @StandardReferences(
    [
      'Google SRE — eliminating toil and operational procedures',
      'ITIL 4 — change enablement and maintenance windows',
    ],
    'The shape of the scheduled workload — what kind of batch surface the system has, as orientation above the job list.',
  )
  @ContentHelp('Describe the shape of the scheduled workload in a short '
      'paragraph: what the batch surface of this system is mostly made of, and '
      'why it exists. This is orientation, not the job inventory — every job is '
      'declared individually in Scheduled Jobs (SCJOB). Do not list jobs here; '
      'a list in two places is a list that can disagree with itself.')
  @SerializationOrder(1)
  DocSpecsSection? workloadShape;

  /// Execution controls — the **default layer** for every job.
  ///
  /// Retry, timeout and idempotency stated here apply to every job that does
  /// not say otherwise. A job that needs different numbers overrides them in
  /// its own failure-policy subsection, so this section is the rule and the
  /// entry is the exception — never the other way round.
  @SectionId('BJME')
  @StandardReferences(
    [
      'Google SRE — eliminating toil and operational procedures',
      'AWS Well-Architected — operational excellence (runbooks, playbooks)',
    ],
    'Execution controls define how batch jobs run, retry, and enforce timeouts.',
  )
  @ContentHelp('State the controls that apply to every job. A job that needs '
      'different retry, backoff or timeout numbers overrides them in its own '
      'entry (SCJOB); what is stated here is what every other job inherits.')
  @Form([
    Field(
      'concurrencyControl',
      String,
      'Concurrency Control',
      hint: 'Max parallel jobs, queue depth',
    ),
    Field(
      'priorityLevels',
      String,
      'Priority Levels',
      hint: 'Job priority classification',
    ),
    Field(
      'retryPolicy',
      String,
      'Default Retry Policy',
      hint: 'The retry count and backoff a job inherits unless it overrides '
          'them, plus what happens after the last attempt',
    ),
    Field(
      'idempotency',
      bool,
      'Idempotency',
      hint: 'Whether jobs are required to be safe to re-run after a failure',
    ),
    Field(
      'timeout',
      String,
      'Default Timeout',
      hint: 'The maximum run time a job inherits unless it overrides it',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? execution;

  /// Monitoring and manual controls.
  @SectionId('BJMM')
  @StandardReferences(
    [
      'AWS Well-Architected — operational excellence (runbooks, playbooks)',
      'Google SRE — eliminating toil and operational procedures',
    ],
    'Monitoring and manual controls track batch job health and allow operators to intervene.',
  )
  @Form([
    Field(
      'jobDashboard',
      bool,
      'Job Dashboard',
      hint: 'Visual job status overview',
    ),
    Field(
      'executionHistory',
      bool,
      'Execution History',
      hint: 'Job run history and logs',
    ),
    Field(
      'failureAlerts',
      String,
      'Default Failure Alerting',
      hint: 'What is raised when a job fails, for jobs that do not name their '
          'own alert message. The destination the alert is delivered to is a '
          'deployment setting, not authored here.',
    ),
    Field(
      'slaMonitoring',
      String,
      'SLA Monitoring',
      hint: 'Alert if job exceeds expected duration',
    ),
    Field(
      'manualTrigger',
      bool,
      'Manual Trigger',
      hint: 'Admin can trigger jobs on demand',
    ),
    Field('notes', String, 'Notes', hint: 'Additional batch job notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? monitoring;

  /// Scheduled jobs — one entry per job the system runs.
  ///
  /// The declaration layer. Everything above is policy that applies to all
  /// jobs; this is where a job actually comes into existence.
  @StandardReferences([
    'Google SRE — eliminating toil and operational procedures',
    'ISO/IEC 11179 — metadata registries / data element definitions',
  ], 'The declared background jobs: each with its trigger, the work it performs, the data it acts on, its failure policy and the environments it runs in.')
  @SectionId('SCJOB-JOB-LST')
  @SectionIdPattern('SCJOB-JOB-xxx')
  @ContentHelp('Add one entry per job the system runs off the request thread. '
      'A job that is not listed here does not exist, however thoroughly the '
      'policy sections above describe how jobs are run.')
  @SerializationOrder(4)
  List<ScheduledJobEntry> scheduledJobs = [];
}

/// A single scheduled job (form + trigger case + work definition + failure
/// policy).
///
/// One background job: what starts it, what it does, which data it acts on,
/// what happens when it fails, and where it is deployed. Work that runs *off*
/// the request thread is what separates a job from a server operation — the
/// trigger is that axis, which is why it is a required, closed choice rather
/// than free text.
///
/// **Where the specification stops and the code begins.** This entry carries
/// the job's *intent* — what it does, over which data, in what order. It does
/// **not** carry the work body: the body is written in the CodeSpec as
/// compilable pseudo-code over a later-injected service (`codespecs_mapping.md`
/// §5.29 scope part 2), and pseudo-code in a specification is code in the wrong
/// place. State the intent well enough that the body can be written from it,
/// then stop.
///
/// **Ownership is derived, not declared.** The service unit that owns a job
/// follows from the entity it primarily writes, exactly as it does for a server
/// operation (`codespecs_mapping.md` §5.17) — so [ScheduledJobEntry] names the
/// entity and never the unit. Two places to state one fact is how they come to
/// disagree.
///
/// **A scheduled report is not declared twice.** A report definition that names
/// a schedule is *realised as* a job (`codespecs_mapping.md` §5.28); that job
/// comes from the report, not from an entry here. List a job here only when the
/// work is not already the schedule of a report.
@StandardReferences(
  [
    'Google SRE — eliminating toil and operational procedures',
    'ISO/IEC 11179 — metadata registries / data element definitions',
  ],
  'A single background job: its identity, trigger, work definition, target data, failure policy and deployment envelope.',
)
@SectionId('SCJOB')
@CodeSpecKind(
  [CodeSpecPart.backgroundJob],
  note:
      'CE-JB — one declared background job, distinct from request-driven '
      'serverApi by the fact that it runs off the request thread. Active '
      '(codespecs_mapping.md §4.1): @CsJob, server locus. triggerKind and its '
      'case subsection supply the trigger and its per-kind slot; the '
      'failure-policy subsection supplies maxRetries / backoff / timeout / '
      'failureAlert; enabled, environments and the target set ride the '
      'TomJobDeclaration envelope; the owning service unit is derived from '
      'primaryDataEntity. The work body is compilable pseudo-code over a '
      'later-injected abstract service and is written in the CodeSpec, not '
      'here (codespecs_mapping.md §5.29).',
)
@OneOf(
  discriminator: 'triggerKind',
  note: 'Job trigger closed choice: the kind selects its promoted trigger '
      'subsection — a recurring clock expression, a calendar date rule, or a '
      'named system event. Each kind is started by a different thing and '
      'states a different rule, so every kind binds a case.',
)
class ScheduledJobEntry extends DocSpecsSection {
  @ContentHelp('''
One job the system runs off the request thread.

**Deployment is opt-out.** A declared job is meant to run: leave *Enabled* set
unless the job is deliberately dormant. Leave *Environments* empty to run it
everywhere; naming environments restricts it to those, and is how a job that
must never run in production is kept out of it.

**Failure policy is an exception, not a restatement.** Fill in the failure
subsection only where this job needs different numbers from the Execution
Controls (BJME). An entry that repeats the default is a second copy of it.
''')
  @Form([
    Field(
      'jobName',
      String,
      'Job Name',
      required: true,
      hint: 'The one identifier for this job (e.g. nightlyInvoiceRollup) — '
          'cited wherever the job is referenced',
    ),
    Field(
      'purpose',
      String,
      'Purpose',
      required: true,
      hint: 'Why this job exists — the operational or business reason it runs '
          'on its own rather than as part of a request',
    ),
    Field(
      'triggerKind',
      ScheduledJobTrigger,
      'Trigger Kind',
      required: true,
      hint: 'What starts the job — selects the trigger subsection below',
    ),
    Field(
      'primaryDataEntity',
      String,
      'Primary Data Entity',
      required: true,
      refersTo: ['DAENT.entityName'],
      hint: 'The Data Model entity this job primarily writes. This determines '
          'which service unit owns the job — never state ownership by hand.',
    ),
    Field(
      'enabled',
      bool,
      'Enabled',
      hint: 'Whether the job is deployed to run. A declared job is meant to '
          'run, so clear this only for a deliberately dormant job.',
    ),
    Field(
      'environments',
      String,
      'Environments',
      hint: 'Comma-separated deployment environments this job runs in, or '
          'empty to run in every environment',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Cron trigger — a promoted `@OneOf` case.
  ///
  /// Present only for the `cron` kind: a recurring clock expression, taken
  /// verbatim. It is a single field because that is exactly what the trigger
  /// is — the zone it is read in is the system-wide one stated on
  /// [BatchJobManagement], and catch-up behaviour after a missed window is a
  /// scheduler setting rather than a specification statement.
  @SectionId('SCJOB-CRON')
  @StandardReferences(
    [
      'POSIX crontab — the recurring-schedule expression convention',
      'Google SRE — eliminating toil and operational procedures',
    ],
    'The recurring clock expression that starts this job.',
  )
  @Case(ScheduledJobTrigger.cron)
  @Form([
    Field(
      'cronExpression',
      String,
      'Recurrence Expression',
      required: true,
      hint: 'The recurrence expression, verbatim (e.g. 0 2 * * * for daily at '
          '02:00)',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? cronTrigger;

  /// Calendar trigger — a promoted `@OneOf` case.
  ///
  /// Present only for the `calendar` kind: a date rule a clock expression
  /// cannot state — the last day of the month, the third Monday of a quarter.
  @SectionId('SCJOB-CAL')
  @StandardReferences(
    [
      'ISO 8601 — date and time representation',
      'Google SRE — eliminating toil and operational procedures',
    ],
    'The calendar date rule that starts this job.',
  )
  @Case(ScheduledJobTrigger.calendar)
  @Form([
    Field(
      'calendarRule',
      String,
      'Calendar Rule',
      required: true,
      hint: 'The date rule and time of day (e.g. last day of each month at '
          '02:00; third Monday of each quarter at 06:00)',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? calendarTrigger;

  /// Event trigger — a promoted `@OneOf` case.
  ///
  /// Present only for the `event` kind. An event-triggered job does not fire on
  /// time at all, so it has no schedule; what it has instead — and what neither
  /// other arm has — is an occurrence carrying data the work reads.
  @SectionId('SCJOB-EVNT')
  @StandardReferences(
    [
      'Enterprise Integration Patterns — event-driven consumer',
      'Google SRE — eliminating toil and operational procedures',
    ],
    'The system event that starts this job and the data that event carries.',
  )
  @Case(ScheduledJobTrigger.event)
  @Form([
    Field(
      'eventName',
      String,
      'Event Name',
      required: true,
      hint: 'The system occurrence that starts the job (e.g. '
          'order.payment.settled)',
    ),
    Field(
      'eventPayload',
      String,
      'Event Payload',
      hint: 'What each occurrence carries that the work reads — typically the '
          'identity of the record the event is about',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? eventTrigger;

  /// What the job does and which data it acts on.
  ///
  /// The intent half of the work definition. The body that realises it is
  /// written in the CodeSpec (`codespecs_mapping.md` §5.29 scope part 2); this
  /// section says what that body must achieve and over which data, in enough
  /// detail that it can be written from here without a second conversation.
  @SectionId('SCJOB-WORK')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148:2018 — requirements specification',
      'DAMA-DMBOK2 — data management body of knowledge',
    ],
    'What the job does and which entities and reports it acts on.',
  )
  @ContentHelp('Describe what the job does, in order, as prose an implementer '
      'can work from. Do not write code here — the work body is written in the '
      'CodeSpec; what this section owes it is a complete statement of intent '
      'and of the data the work touches.')
  @Form([
    Field(
      'workSummary',
      String,
      'Work Summary',
      required: true,
      hint: 'What the job does, step by step, in prose — the intent the work '
          'body must realise',
    ),
    Field(
      'readEntities',
      String,
      'Read Entities',
      refersTo: ['DAENT.entityName'],
      hint: 'The Data Model entities the job reads',
    ),
    Field(
      'writtenEntities',
      String,
      'Written Entities',
      refersTo: ['DAENT.entityName'],
      hint: 'The Data Model entities the job writes, including the primary one',
    ),
    Field(
      'targetReports',
      String,
      'Target Reports',
      refersTo: ['REPENT.reportId'],
      hint: 'The reports this job produces, where the work is a report run',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? workDefinition;

  /// This job's departures from the system-wide execution policy.
  ///
  /// Every field is an override. Left empty, the job inherits the Execution
  /// Controls (BJME) default; the policy stays the rule and the entry is the
  /// exception.
  @SectionId('SCJOB-FAIL')
  @StandardReferences(
    [
      'Google SRE — handling overload, retries and cascading failure',
      'AWS Well-Architected — reliability (failure management)',
    ],
    'This job\'s retry, backoff, timeout and alerting overrides of the system-wide execution policy.',
  )
  @ContentHelp('Fill in only what differs from the Execution Controls (BJME) '
      'default. An empty field means the job inherits the default, which is '
      'the normal case.')
  @Form([
    Field(
      'maxRetries',
      int,
      'Maximum Retries',
      hint: 'How many times a failed run is retried, if not the default',
    ),
    Field(
      'retryBackoff',
      String,
      'Retry Backoff',
      hint: 'The delay before the first retry and how it grows, if not the '
          'default',
    ),
    Field(
      'timeout',
      String,
      'Timeout',
      hint: 'How long a single run may take before it is abandoned, if not '
          'the default',
    ),
    Field(
      'failureAlertMessage',
      String,
      'Failure Alert Message',
      refersTo: ['MSGKE.key'],
      hint: 'The message raised when this job fails permanently. The job names '
          'the message; the deployment names where it is delivered.',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? failurePolicy;
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
class SystemDiagnosticTools extends DocSpecsSection {
  @Form([
    Field(
      'remoteDebugging',
      bool,
      'Remote Debugging',
      hint: 'Attach debugger to running service',
    ),
    Field(
      'profiling',
      String,
      'Profiling',
      hint: 'CPU, memory, I/O profiling tools',
    ),
    Field(
      'threadDumpCapability',
      bool,
      'Thread Dump Capability',
      hint: 'Capture thread/goroutine dumps',
    ),
    Field(
      'heapDumpCapability',
      bool,
      'Heap Dump Capability',
      hint: 'Capture memory heap dumps',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Trace and dependency inspection tools.
  @SectionId('SDTT')
  @StandardReferences(
    [
      'AWS Well-Architected — operational excellence (runbooks, playbooks)',
      'Google SRE — eliminating toil and operational procedures',
    ],
    'Trace and dependency inspection tools reveal how requests flow across services.',
  )
  @Form([
    Field(
      'requestTracing',
      String,
      'Request Tracing',
      hint: 'End-to-end request trace viewer',
    ),
    Field(
      'slowQueryAnalysis',
      bool,
      'Slow Query Analysis',
      hint: 'Identify slow database queries',
    ),
    Field(
      'dependencyMapping',
      bool,
      'Dependency Mapping',
      hint: 'Visualize service dependencies',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? tracing;

  /// Log analysis capabilities.
  @SectionId('SDTL')
  @StandardReferences(
    [
      'ISO/IEC 27001 — operations security (A.12)',
      'AWS Well-Architected — operational excellence (runbooks, playbooks)',
    ],
    'Log analysis capabilities let operators search and correlate log data during diagnosis.',
  )
  @Form([
    Field(
      'logAggregation',
      String,
      'Log Aggregation',
      hint: 'ELK, Loki, CloudWatch Logs',
    ),
    Field(
      'logSearchCapability',
      String,
      'Log Search',
      hint: 'Full-text search across logs',
    ),
    Field(
      'correlatedLogView',
      bool,
      'Correlated Log View',
      hint: 'View logs across services by trace ID',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? logs;

  /// Self-service diagnostic entry points.
  @SectionId('SDTSS')
  @StandardReferences(
    [
      'AWS Well-Architected — operational excellence (runbooks, playbooks)',
      'Google SRE — eliminating toil and operational procedures',
    ],
    'Self-service diagnostic entry points let operators inspect the system without escalation.',
  )
  @Form([
    Field(
      'adminDiagnosticEndpoints',
      String,
      'Diagnostic Endpoints',
      hint: '/info, /env, /metrics endpoints',
    ),
    Field(
      'databaseQueryConsole',
      bool,
      'Database Query Console',
      hint: 'Read-only query interface for admins',
    ),
    Field('notes', String, 'Notes', hint: 'Additional diagnostic tool notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? selfService;
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
class Monitoring extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Monitoring Overview
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('MONITO-MONI')
  @Form([
    // Strategy
    Field(
      'monitoringStrategy',
      String,
      'Monitoring Strategy',
      hint: 'Proactive, reactive, hybrid approach',
    ),
    Field(
      'observabilityMaturity',
      String,
      'Observability Maturity',
      hint: 'Current maturity level (L1-L4)',
    ),
    Field(
      'monitoringScope',
      String,
      'Monitoring Scope',
      hint: 'Infrastructure, application, business metrics',
    ),
    // Tools
    Field(
      'primaryMonitoringPlatform',
      String,
      'Primary Monitoring Platform',
      hint: 'Datadog, New Relic, Prometheus, CloudWatch',
    ),
    Field(
      'metricsStore',
      String,
      'Metrics Store',
      hint: 'InfluxDB, Prometheus, CloudWatch Metrics',
    ),
    Field(
      'tracingPlatform',
      String,
      'Tracing Platform',
      hint: 'Jaeger, Zipkin, AWS X-Ray, Datadog APM',
    ),
    Field(
      'loggingPlatform',
      String,
      'Logging Platform',
      hint: 'ELK Stack, Loki, CloudWatch Logs',
    ),
    // Coverage
    Field(
      'coverageRequirement',
      String,
      'Coverage Requirement',
      hint: 'Which services must be monitored',
    ),
    Field(
      'dataRetention',
      String,
      'Data Retention',
      hint: 'Metrics: 15d, traces: 7d, logs: 30d',
    ),
    Field(
      'costBudget',
      String,
      'Cost Budget',
      hint: 'Monthly monitoring cost budget',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? monitoringOverview;

  /// Monitoring strategy narrative.
  @ContentHelp(
    'Executive summary of monitoring philosophy, tool '
    'selection rationale, and observability goals.',
  )
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
@StandardReferences([
  'Google SRE — monitoring and alerting (the four golden signals)',
  'Prometheus — Alertmanager (routing, grouping, silencing)',
  'Google SRE — being on-call and incident response',
], 'The full alerting configuration covering rules, channels, and escalation.')
@SectionId('ALCO')
class AlertingConfiguration extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Alerting Overview
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('ALCO-ALER')
  @Form([
    // Philosophy
    Field(
      'alertingPhilosophy',
      String,
      'Alerting Philosophy',
      hint: 'Page on symptoms, not causes; reduce noise',
    ),
    Field(
      'alertSeverityLevels',
      String,
      'Alert Severity Levels',
      hint: 'Critical, Warning, Info',
    ),
    Field(
      'onCallModel',
      String,
      'On-Call Model',
      hint: 'Follow-the-sun, regional, single team',
    ),
    // Response expectations
    Field(
      'criticalResponseTime',
      String,
      'Critical Response Time',
      hint: 'Max time to acknowledge critical alerts',
    ),
    Field(
      'warningResponseTime',
      String,
      'Warning Response Time',
      hint: 'Max time to acknowledge warnings',
    ),
    Field(
      'infoResponseTime',
      String,
      'Info Response Time',
      hint: 'Expected review time for info alerts',
    ),
    // Alert hygiene
    Field(
      'alertReviewCadence',
      String,
      'Alert Review Cadence',
      hint: 'How often alert rules are reviewed',
    ),
    Field(
      'noisyAlertPolicy',
      String,
      'Noisy Alert Policy',
      hint: 'Process for tuning noisy alerts',
    ),
    Field(
      'staleAlertCleanup',
      String,
      'Stale Alert Cleanup',
      hint: 'Removing outdated alert rules',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? alertingOverview;

  /// Alerting overview narrative.
  @SerializationOrder(1)
  TextSection overviewNarrative = TextSection();

  /// Notification channels.
  @SerializationOrder(2)
  AlertNotificationChannels notificationChannels = AlertNotificationChannels();

  /// Alert rules catalog.
  @StandardReferences([
    'Prometheus — Alertmanager (routing, grouping, silencing)',
  ], 'The catalog of alert rules the system evaluates.')
  @SectionId('ALRUEN-ALER-LST')
  @SectionIdPattern('ALRUEN-ALER-xxx')
  @ContentHelp('Add one entry per alert rule.')
  @SerializationOrder(3)
  List<AlertRuleEntry> alertRules = [];

  /// Escalation policies.
  @SerializationOrder(4)
  AlertEscalationPolicies escalationPolicies = AlertEscalationPolicies();

  /// Alert suppression and maintenance windows.
  @StandardReferences([
    'Prometheus — Alertmanager (routing, grouping, silencing)',
  ], 'The catalog of alert suppression and maintenance window rules.')
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
@StandardReferences([
  'Prometheus — Alertmanager (routing, grouping, silencing)',
  'Google SRE — being on-call and incident response',
], 'The channels through which alerts reach responders.')
@SectionId('ALNOCH')
class AlertNotificationChannels extends DocSpecsSection {
  @Form([
    // Primary channels
    Field(
      'pagingService',
      String,
      'Paging Service',
      hint: 'PagerDuty, Opsgenie, VictorOps',
    ),
    Field(
      'slackIntegration',
      String,
      'Slack Integration',
      hint: 'Channel for alerts (#alerts, #incidents)',
    ),
    Field(
      'teamsIntegration',
      String,
      'Teams Integration',
      hint: 'Microsoft Teams channel integration',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Secondary and escalation delivery methods.
  @SectionId('ANCD')
  @StandardReferences([
    'PagerDuty / on-call — escalation policy design',
    'Google SRE — being on-call and incident response',
  ], 'The secondary email, SMS, and voice delivery methods for alerts.')
  @Form([
    Field(
      'emailNotification',
      String,
      'Email Notification',
      hint: 'Email distribution lists for alerts',
    ),
    Field(
      'smsNotification',
      String,
      'SMS Notification',
      hint: 'SMS/text for critical alerts',
    ),
    Field(
      'phoneCallEscalation',
      String,
      'Phone Call Escalation',
      hint: 'Voice call for unacknowledged criticals',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? delivery;

  /// Severity-based channel routing.
  @SectionId('ANCR')
  @StandardReferences([
    'Prometheus — Alertmanager (routing, grouping, silencing)',
    'ITIL 4 — monitoring and event management practice',
  ], 'How alerts route to channels based on their severity level.')
  @Form([
    Field(
      'criticalAlertChannels',
      String,
      'Critical Alert Channels',
      hint: 'Where critical alerts are sent',
    ),
    Field(
      'warningAlertChannels',
      String,
      'Warning Alert Channels',
      hint: 'Where warning alerts are sent',
    ),
    Field(
      'infoAlertChannels',
      String,
      'Info Alert Channels',
      hint: 'Where info alerts are sent',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? routing;

  /// Message templates, enrichment, and grouping rules.
  @SectionId('ANCF')
  @StandardReferences([
    'Prometheus — Alertmanager (routing, grouping, silencing)',
    'Google SRE — monitoring and alerting (the four golden signals)',
  ], 'How alert messages are formatted, enriched, deduplicated, and grouped.')
  @Form([
    Field(
      'alertMessageFormat',
      String,
      'Alert Message Format',
      hint: 'Template for alert notification content',
    ),
    Field(
      'enrichmentData',
      String,
      'Enrichment Data',
      hint: 'Runbook links, dashboard links, context',
    ),
    Field(
      'deduplication',
      String,
      'Deduplication',
      hint: 'How duplicate alerts are suppressed',
    ),
    Field(
      'groupingRules',
      String,
      'Grouping Rules',
      hint: 'How related alerts are grouped',
    ),
    Field('notes', String, 'Notes', hint: 'Additional formatting notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? formatting;
}

/// An alert rule entry.
@StandardReferences([
  'Google SRE — monitoring and alerting (the four golden signals)',
  'Prometheus — Alertmanager (routing, grouping, silencing)',
], 'A single alert rule defining when and how the system pages responders.')
@SectionId('ALERULENT')
class AlertRuleEntry extends DocSpecsSection {
  @Form([
    Field(
      'alertId',
      String,
      'Alert ID',
      required: true,
      hint: 'Unique identifier for this alert rule',
    ),
    Field(
      'alertName',
      String,
      'Alert Name',
      required: true,
      hint: 'Human-readable name for this alert',
    ),
    Field(
      'alertDescription',
      String,
      'Alert Description',
      hint: 'What this alert detects and why it matters',
    ),
    Field('severity', String, 'Severity', hint: 'Critical, Warning, Info'),
    Field(
      'category',
      String,
      'Category',
      hint: 'Infrastructure, Application, Business, Security',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Trigger conditions.
  @SectionId('ARET')
  @StandardReferences([
    'Google SRE — monitoring and alerting (the four golden signals)',
    'Prometheus — Alertmanager (routing, grouping, silencing)',
  ], 'The metric, threshold, and window conditions that trigger this alert.')
  @Form([
    Field(
      'metricOrCondition',
      String,
      'Metric/Condition',
      hint: 'What triggers this alert',
    ),
    Field(
      'threshold',
      String,
      'Threshold',
      hint: 'Threshold value(s) for triggering',
    ),
    Field(
      'evaluationWindow',
      String,
      'Evaluation Window',
      hint: 'Time window for condition evaluation',
    ),
    Field(
      'requiredOccurrences',
      String,
      'Required Occurrences',
      hint: 'N of M before alerting',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? trigger;

  /// Response actions.
  @SectionId('ARER')
  @StandardReferences(
    [
      'Google SRE — being on-call and incident response',
      'Prometheus — Alertmanager (routing, grouping, silencing)',
    ],
    'The notification, runbook, and remediation actions taken when the alert fires.',
  )
  @Form([
    Field(
      'notificationChannels',
      String,
      'Notification Channels',
      hint: 'Where alert is sent',
    ),
    Field(
      'runbookLink',
      String,
      'Runbook Link',
      hint: 'Link to troubleshooting runbook',
    ),
    Field(
      'escalationPolicy',
      String,
      'Escalation Policy',
      hint: 'Which escalation policy applies',
    ),
    Field(
      'autoRemediation',
      String,
      'Auto-Remediation',
      hint: 'Automatic remediation action if any',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? response;

  /// Ownership details.
  @SectionId('AREO')
  @StandardReferences([
    'Google SRE — being on-call and incident response',
    'ITIL 4 — monitoring and event management practice',
  ], 'Which team and contact own responses to this alert rule.')
  @Form([
    Field(
      'ownerTeam',
      String,
      'Owner Team',
      hint: 'Team that owns this alert rule',
    ),
    Field(
      'primaryContact',
      String,
      'Primary Contact',
      hint: 'Primary contact for this alert',
    ),
    Field('notes', String, 'Notes', hint: 'Additional ownership notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? ownership;
}

/// Alert escalation policies.
@StandardReferences([
  'PagerDuty / on-call — escalation policy design',
  'Google SRE — being on-call and incident response',
], 'How unacknowledged alerts escalate through responder levels.')
@SectionId('ALESPO')
class AlertEscalationPolicies extends DocSpecsSection {
  @Form([
    // Escalation levels
    Field(
      'level1Responder',
      String,
      'Level 1 Responder',
      hint: 'Primary on-call, response time',
    ),
    Field(
      'level2Responder',
      String,
      'Level 2 Responder',
      hint: 'Escalation if L1 no response',
    ),
    Field(
      'level3Responder',
      String,
      'Level 3 Responder',
      hint: 'Senior engineer/architect escalation',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Management escalation path and timing thresholds.
  @SectionId('AEPT')
  @StandardReferences([
    'PagerDuty / on-call — escalation policy design',
    'ISO/IEC 20000 — incident and service request management',
  ], 'The timing thresholds that govern when alerts escalate between levels.')
  @Form([
    Field(
      'managementEscalation',
      String,
      'Management Escalation',
      hint: 'When to escalate to management',
    ),
    Field(
      'level1ToLevel2Time',
      String,
      'L1 to L2 Time',
      hint: 'Time before escalating to L2',
    ),
    Field(
      'level2ToLevel3Time',
      String,
      'L2 to L3 Time',
      hint: 'Time before escalating to L3',
    ),
    Field(
      'level3ToManagementTime',
      String,
      'L3 to Management Time',
      hint: 'Time before management notification',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? timing;

  /// Escalation control behavior.
  @SectionId('AEPB')
  @StandardReferences([
    'PagerDuty / on-call — escalation policy design',
    'ITIL 4 — monitoring and event management practice',
  ], 'How acknowledgment and resolution control the escalation flow.')
  @Form([
    Field(
      'acknowledgeStopsEscalation',
      bool,
      'Acknowledge Stops Escalation',
      hint: 'Whether acknowledgment pauses escalation',
    ),
    Field(
      'resolveStopsEscalation',
      bool,
      'Resolve Stops Escalation',
      hint: 'Whether resolution cancels escalation',
    ),
    Field(
      'repeatNotification',
      String,
      'Repeat Notification',
      hint: 'Re-notify if unresolved after N minutes',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? behavior;

  /// Schedule-specific policy variants.
  @SectionId('AEPS')
  @StandardReferences([
    'PagerDuty / on-call — escalation policy design',
    'Google SRE — being on-call and incident response',
  ], 'How escalation policies differ across business hours and off hours.')
  @Form([
    Field(
      'businessHoursPolicy',
      String,
      'Business Hours Policy',
      hint: 'Escalation during business hours',
    ),
    Field(
      'afterHoursPolicy',
      String,
      'After-Hours Policy',
      hint: 'Escalation outside business hours',
    ),
    Field(
      'weekendHolidayPolicy',
      String,
      'Weekend/Holiday Policy',
      hint: 'Escalation on weekends/holidays',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional escalation schedule notes',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? schedules;
}

/// Alert suppression and maintenance windows.
@StandardReferences([
  'Prometheus — Alertmanager (routing, grouping, silencing)',
  'Google SRE — monitoring and alerting (the four golden signals)',
], 'How alerts are silenced or inhibited during maintenance windows.')
@SectionId('ALSURU')
class AlertSuppressionRules extends DocSpecsSection {
  @Form([
    // Maintenance windows
    Field(
      'scheduledMaintenanceWindows',
      String,
      'Scheduled Maintenance Windows',
      hint: 'Recurring maintenance window times',
    ),
    Field(
      'adHocMaintenanceProcess',
      String,
      'Ad-Hoc Maintenance Process',
      hint: 'How to create one-time maintenance windows',
    ),
    Field(
      'maintenanceNotification',
      String,
      'Maintenance Notification',
      hint: 'How stakeholders are informed',
    ),
    // Suppression rules
    Field(
      'dependentAlertSuppression',
      bool,
      'Dependent Alert Suppression',
      hint: 'Suppress downstream alerts',
    ),
    Field(
      'flappingDetection',
      bool,
      'Flapping Detection',
      hint: 'Detect and suppress flapping alerts',
    ),
    Field(
      'silenceRules',
      String,
      'Silence Rules',
      hint: 'Temporary silence for known issues',
    ),
    Field(
      'inhibitRules',
      String,
      'Inhibit Rules',
      hint: 'Rules to inhibit lower-severity alerts',
    ),
    // Audit
    Field(
      'suppressionAuditLog',
      bool,
      'Suppression Audit Log',
      hint: 'Log all suppression/silence actions',
    ),
    Field(
      'suppressionReview',
      String,
      'Suppression Review',
      hint: 'Periodic review of active suppressions',
    ),
    Field('notes', String, 'Notes', hint: 'Additional suppression notes'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// On-call schedule configuration.
@StandardReferences([
  'Google SRE — being on-call and incident response',
  'PagerDuty / on-call — escalation policy design',
], 'How on-call rotations and duties are configured for the team.')
@SectionId('OCSC')
class OnCallScheduleConfig extends DocSpecsSection {
  @Form([
    Field(
      'rotationSchedule',
      String,
      'Rotation Schedule',
      hint: 'Weekly, bi-weekly, custom rotation',
    ),
    Field(
      'scheduleTimezone',
      String,
      'Schedule Timezone',
      hint: 'UTC, local, follow-the-sun',
    ),
    Field(
      'primaryOnCallDuties',
      String,
      'Primary On-Call Duties',
      hint: 'Responsibilities during on-call',
    ),
    Field(
      'secondaryOnCallDuties',
      String,
      'Secondary On-Call Duties',
      hint: 'Backup on-call responsibilities',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Override and coverage handling.
  @SectionId('OCSCC')
  @StandardReferences([
    'PagerDuty / on-call — escalation policy design',
    'Google SRE — being on-call and incident response',
  ], 'How on-call shift overrides and holiday coverage are managed.')
  @Form([
    Field(
      'scheduleOverrideProcess',
      String,
      'Schedule Override Process',
      hint: 'How to swap on-call shifts',
    ),
    Field(
      'holidayCoverage',
      String,
      'Holiday Coverage',
      hint: 'Coverage during holidays',
    ),
    Field(
      'vacationCoverage',
      String,
      'Vacation Coverage',
      hint: 'How vacation affects on-call',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? coverage;

  /// Compensation and tooling support.
  @SectionId('OCSCO')
  @StandardReferences([
    'PagerDuty / on-call — escalation policy design',
    'Google SRE — being on-call and incident response',
  ], 'How on-call compensation and scheduling tooling are handled.')
  @Form([
    Field(
      'onCallCompensation',
      String,
      'On-Call Compensation',
      hint: 'Comp for being on-call',
    ),
    Field(
      'incidentResponseCompensation',
      String,
      'Incident Response Compensation',
      hint: 'Additional comp for incidents',
    ),
    Field(
      'scheduleManagementTool',
      String,
      'Schedule Management Tool',
      hint: 'PagerDuty, Opsgenie schedule',
    ),
    Field(
      'handoffProcess',
      String,
      'Handoff Process',
      hint: 'On-call handoff procedure',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional on-call operations notes',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? operations;
}

// ---------------------------------------------------------------------------
// 8.7.2.3 Metrics and Observability
// ---------------------------------------------------------------------------

/// 8.7.2.3. Metrics and Observability.
///
/// Comprehensive metrics collection, distributed tracing, and observability
/// requirements.
@StandardReferences([
  'OpenTelemetry — metrics, traces, and logs',
  'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
  'The Twelve-Factor App — logs as event streams',
], 'The overall metrics, tracing, and observability strategy for the system.')
@SectionId('MEANOB')
class MetricsAndObservability extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Metrics Overview
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('MEANOB-METR')
  @Form([
    // Pillars
    Field(
      'metricsEnabled',
      bool,
      'Metrics Enabled',
      hint: 'Whether metrics collection is enabled',
    ),
    Field(
      'logsEnabled',
      bool,
      'Logs Enabled',
      hint: 'Whether log collection is enabled',
    ),
    Field(
      'tracesEnabled',
      bool,
      'Traces Enabled',
      hint: 'Whether distributed tracing is enabled',
    ),
    Field(
      'profilesEnabled',
      bool,
      'Profiles Enabled',
      hint: 'Continuous profiling',
    ),
    // Standards
    Field(
      'metricsFormat',
      String,
      'Metrics Format',
      hint: 'Prometheus, OpenMetrics, StatsD',
    ),
    Field('logsFormat', String, 'Logs Format', hint: 'Structured JSON, syslog'),
    Field(
      'tracingStandard',
      String,
      'Tracing Standard',
      hint: 'OpenTelemetry, OpenTracing, W3C Trace Context',
    ),
    // Collection
    Field(
      'collectionMethod',
      String,
      'Collection Method',
      hint: 'Pull (Prometheus), push (agent), sidecar',
    ),
    Field(
      'scrapeInterval',
      String,
      'Scrape Interval',
      hint: 'Metrics collection frequency',
    ),
    Field(
      'samplingRate',
      String,
      'Sampling Rate',
      hint: 'Trace sampling percentage',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? metricsOverview;

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
  @StandardReferences([
    'Prometheus — metric types and exposition format',
  ], 'The catalog of custom application metrics the system emits.')
  @SectionId('CUMEEN-CUST-LST')
  @SectionIdPattern('CUMEEN-CUST-xxx')
  @ContentHelp('Add one entry per custom metric.')
  @SerializationOrder(6)
  List<CustomMetricEntry> customMetrics = [];
}

/// Application metrics specification.
@StandardReferences([
  'RED method — rate, errors, duration (service metrics)',
  'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
], 'Metrics that describe application request rate, errors, and duration.')
@SectionId('APMESP')
class ApplicationMetricsSpec extends DocSpecsSection {
  @Form([
    Field('requestRate', bool, 'Request Rate', hint: 'Requests per second'),
    Field('errorRate', bool, 'Error Rate', hint: 'Error percentage'),
    Field(
      'requestDuration',
      bool,
      'Request Duration',
      hint: 'Latency histograms (p50, p95, p99)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// USE metrics.
  @SectionId('AMSR')
  @StandardReferences([
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
    'RED method — rate, errors, duration (service metrics)',
  ], 'Utilization, saturation, and error metrics for service resources.')
  @Form([
    Field(
      'resourceUtilization',
      bool,
      'Resource Utilization',
      hint: 'CPU, memory per service',
    ),
    Field(
      'resourceSaturation',
      bool,
      'Resource Saturation',
      hint: 'Queue depths, connection pool usage',
    ),
    Field(
      'resourceErrors',
      bool,
      'Resource Errors',
      hint: 'Timeouts, failures',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? resources;

  /// Application-specific metrics.
  @SectionId('AMSA')
  @StandardReferences(
    [
      'RED method — rate, errors, duration (service metrics)',
      'Prometheus — metric types and exposition format',
    ],
    'Application-level metrics for caches, databases, clients, and message queues.',
  )
  @Form([
    Field(
      'cacheMetrics',
      bool,
      'Cache Metrics',
      hint: 'Hit rate, miss rate, evictions',
    ),
    Field(
      'databaseMetrics',
      bool,
      'Database Metrics',
      hint: 'Query count, latency, connection count',
    ),
    Field(
      'httpClientMetrics',
      bool,
      'HTTP Client Metrics',
      hint: 'Outbound request metrics',
    ),
    Field('grpcMetrics', bool, 'gRPC Metrics', hint: 'gRPC-specific metrics'),
    Field(
      'messageQueueMetrics',
      bool,
      'Message Queue Metrics',
      hint: 'Publish/consume rates, lag',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? application;

  /// Labeling guidance.
  @SectionId('AMSL')
  @StandardReferences(
    [
      'Prometheus — metric types and exposition format',
      'OpenTelemetry — metrics, traces, and logs',
    ],
    'Guidance on standard and custom labels applied to metrics and their cardinality.',
  )
  @Form([
    Field(
      'standardLabels',
      String,
      'Standard Labels',
      hint: 'service, environment, version, instance',
    ),
    Field(
      'customLabels',
      String,
      'Custom Labels',
      hint: 'Business-specific labels',
    ),
    Field(
      'labelCardinality',
      String,
      'Label Cardinality',
      hint: 'Max cardinality guidelines',
    ),
    Field('notes', String, 'Notes', hint: 'Additional labeling notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? labels;
}

/// Infrastructure metrics specification.
@StandardReferences([
  'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
  'Prometheus — metric types and exposition format',
], 'Metrics for compute, memory, disk, and network infrastructure resources.')
@SectionId('INMESP')
class InfrastructureMetricsSpec extends DocSpecsSection {
  @Form([
    // Compute
    Field(
      'cpuMetrics',
      bool,
      'CPU Metrics',
      hint: 'User, system, iowait, idle',
    ),
    Field(
      'memoryMetrics',
      bool,
      'Memory Metrics',
      hint: 'Used, available, cached, buffered',
    ),
    Field(
      'diskMetrics',
      bool,
      'Disk Metrics',
      hint: 'Usage, IOPS, throughput, latency',
    ),
    Field(
      'networkMetrics',
      bool,
      'Network Metrics',
      hint: 'Bytes in/out, packets, errors',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Container and orchestration metrics.
  @SectionId('IMSK')
  @StandardReferences([
    'Prometheus — metric types and exposition format',
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
  ], 'Metrics for containers, pods, nodes, and deployments in the orchestrator.')
  @Form([
    Field(
      'containerMetrics',
      bool,
      'Container Metrics',
      hint: 'Container CPU, memory, restarts',
    ),
    Field(
      'podMetrics',
      bool,
      'Pod Metrics',
      hint: 'Pod status, readiness, age',
    ),
    Field(
      'nodeMetrics',
      bool,
      'Node Metrics',
      hint: 'Node capacity, allocatable, conditions',
    ),
    Field(
      'deploymentMetrics',
      bool,
      'Deployment Metrics',
      hint: 'Replica count, rollout status',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? kubernetes;

  /// Cloud-managed services and edge metrics.
  @SectionId('IMSC')
  @StandardReferences([
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
    'Prometheus — metric types and exposition format',
  ], 'Metrics from cloud provider managed services and edge infrastructure.')
  @Form([
    Field(
      'cloudProviderMetrics',
      bool,
      'Cloud Provider Metrics',
      hint: 'Native cloud metrics integration',
    ),
    Field(
      'managedServiceMetrics',
      bool,
      'Managed Service Metrics',
      hint: 'RDS, ElastiCache, SQS metrics',
    ),
    Field(
      'loadBalancerMetrics',
      bool,
      'Load Balancer Metrics',
      hint: 'Connection count, healthy hosts',
    ),
    Field(
      'cdnMetrics',
      bool,
      'CDN Metrics',
      hint: 'Cache hit ratio, bandwidth, latency',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? cloud;

  /// Cost attribution and notes.
  @SectionId('INMESPCO')
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency',
    'Prometheus — metric types and exposition format',
  ], 'How infrastructure cost is attributed and tracked as a metric.')
  @Form([
    Field(
      'costMetrics',
      bool,
      'Cost Metrics',
      hint: 'Resource cost attribution',
    ),
    Field('notes', String, 'Notes', hint: 'Additional cost attribution notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? cost;
}

/// Business metrics specification.
@StandardReferences([
  'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
  'ISO/IEC 25010 — performance efficiency',
], 'Metrics that measure business outcomes such as user activity and revenue.')
@SectionId('BUMESP')
class BusinessMetricsSpec extends DocSpecsSection {
  @Form([
    // User activity
    Field('activeUsers', bool, 'Active Users', hint: 'DAU, WAU, MAU'),
    Field(
      'sessionMetrics',
      bool,
      'Session Metrics',
      hint: 'Session count, duration, depth',
    ),
    Field(
      'userJourneyMetrics',
      bool,
      'User Journey Metrics',
      hint: 'Funnel completion, drop-off',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Transaction and revenue metrics.
  @SectionId('BMST')
  @StandardReferences([
    'RED method — rate, errors, duration (service metrics)',
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
  ], 'Volume, value, and success rates of business transactions.')
  @Form([
    Field(
      'transactionVolume',
      bool,
      'Transaction Volume',
      hint: 'Orders, payments, conversions',
    ),
    Field(
      'transactionValue',
      bool,
      'Transaction Value',
      hint: 'Revenue, GMV, average order value',
    ),
    Field(
      'transactionSuccess',
      bool,
      'Transaction Success',
      hint: 'Success/failure rates',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? transactions;

  /// Feature adoption and engagement metrics.
  @SectionId('BMSFU')
  @StandardReferences([
    'RED method — rate, errors, duration (service metrics)',
    'ISO/IEC 25010 — performance efficiency',
  ], 'How widely and deeply product features are adopted and used.')
  @Form([
    Field(
      'featureAdoption',
      bool,
      'Feature Adoption',
      hint: 'Feature usage rates',
    ),
    Field(
      'featureEngagement',
      bool,
      'Feature Engagement',
      hint: 'Depth of feature usage',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? featureUsage;

  /// KPI and customer outcome metrics.
  @SectionId('BMSK')
  @StandardReferences([
    'ISO/IEC 25010 — performance efficiency',
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
  ], 'Key performance indicators that track customer outcomes and satisfaction.')
  @Form([
    Field(
      'conversionRate',
      bool,
      'Conversion Rate',
      hint: 'Percentage of users who convert',
    ),
    Field(
      'churnRate',
      bool,
      'Churn Rate',
      hint: 'Percentage of customers lost over time',
    ),
    Field(
      'customerSatisfaction',
      bool,
      'Customer Satisfaction',
      hint: 'NPS, CSAT from feedback',
    ),
    Field(
      'slaCompliance',
      bool,
      'SLA Compliance',
      hint: 'SLA adherence metrics',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? kpis;

  /// Real-time dashboard and notes.
  @SectionId('BMSO')
  @StandardReferences([
    'Google SRE — the four golden signals (latency, traffic, errors, saturation)',
    'RED method — rate, errors, duration (service metrics)',
  ], 'Real-time operational dashboards that surface live business metrics.')
  @Form([
    Field(
      'realTimeBusinessDashboard',
      bool,
      'Real-Time Business Dashboard',
      hint: 'Live business metrics display',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional business operations notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? operations;
}

/// Distributed tracing specification.
@StandardReferences([
  'W3C Trace Context — distributed trace propagation',
  'OpenTelemetry — metrics, traces, and logs',
], 'How requests are traced end to end across distributed services.')
@SectionId('DITRSP')
class DistributedTracingSpec extends DocSpecsSection {
  @Form([
    Field(
      'tracingBackend',
      String,
      'Tracing Backend',
      hint: 'Jaeger, Zipkin, Tempo, X-Ray',
    ),
    Field(
      'tracingProtocol',
      String,
      'Tracing Protocol',
      hint: 'OTLP, Jaeger Thrift, Zipkin JSON',
    ),
    Field(
      'traceIdFormat',
      String,
      'Trace ID Format',
      hint: 'W3C Trace Context, B3, custom',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Sampling strategy.
  @SectionId('DTSS')
  @StandardReferences(
    [
      'OpenTelemetry — metrics, traces, and logs',
      'W3C Trace Context — distributed trace propagation',
    ],
    'How the volume of collected traces is reduced through head and tail sampling.',
  )
  @Form([
    Field(
      'headSamplingRate',
      String,
      'Head Sampling Rate',
      hint: 'Percentage of traces sampled at start',
    ),
    Field(
      'tailSamplingRules',
      String,
      'Tail Sampling Rules',
      hint: 'Rules for sampling after trace completes',
    ),
    Field(
      'errorSampling',
      String,
      'Error Sampling',
      hint: 'Always sample error traces',
    ),
    Field(
      'latencySampling',
      String,
      'Latency Sampling',
      hint: 'Sample slow traces',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? sampling;

  /// Span metadata.
  @SectionId('DITRSPSP')
  @StandardReferences([
    'OpenTelemetry — metrics, traces, and logs',
    'W3C Trace Context — distributed trace propagation',
  ], 'The attributes and naming conventions applied to trace spans.')
  @Form([
    Field(
      'defaultSpanAttributes',
      String,
      'Default Span Attributes',
      hint: 'Attributes added to all spans',
    ),
    Field(
      'spanNameConvention',
      String,
      'Span Name Convention',
      hint: 'Naming convention for spans',
    ),
    Field(
      'resourceAttributes',
      String,
      'Resource Attributes',
      hint: 'Service name, version, environment',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? spans;

  /// Correlation and retention.
  @SectionId('DTSO')
  @StandardReferences(
    [
      'W3C Trace Context — distributed trace propagation',
      'OpenTelemetry — metrics, traces, and logs',
    ],
    'How traces are correlated with logs and metrics and how long they are kept.',
  )
  @Form([
    Field(
      'logTraceCorrelation',
      bool,
      'Log-Trace Correlation',
      hint: 'Inject trace ID into logs',
    ),
    Field(
      'metricsTraceCorrelation',
      bool,
      'Metrics-Trace Correlation',
      hint: 'Link metrics to exemplar traces',
    ),
    Field(
      'baggagePropagation',
      String,
      'Baggage Propagation',
      hint: 'Custom context propagated across services',
    ),
    Field(
      'traceRetention',
      String,
      'Trace Retention',
      hint: 'How long traces are stored',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional tracing correlation notes',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? operations;
}

/// A custom metric entry.
@StandardReferences([
  'Prometheus — metric types and exposition format',
  'OpenTelemetry — metrics, traces, and logs',
], 'A single custom application metric with its type, unit, and labels.')
@SectionId('CUSMETENT')
class CustomMetricEntry extends DocSpecsSection {
  @Form([
    Field(
      'metricName',
      String,
      'Metric Name',
      required: true,
      hint: 'Full metric name (e.g., app_orders_total)',
    ),
    Field(
      'metricType',
      String,
      'Metric Type',
      hint: 'Counter, gauge, histogram, summary',
    ),
    Field(
      'metricDescription',
      String,
      'Metric Description',
      hint: 'What this metric measures',
    ),
    Field('unit', String, 'Unit', hint: 'seconds, bytes, requests, count'),
    Field('labels', String, 'Labels', hint: 'Labels attached to this metric'),
    Field('source', String, 'Source', hint: 'Where this metric is emitted'),
    Field(
      'alertOnMetric',
      bool,
      'Alert On Metric',
      hint: 'Whether alerts are based on this metric',
    ),
    Field(
      'dashboardInclusion',
      String,
      'Dashboard Inclusion',
      hint: 'Which dashboards include this metric',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional notes for this custom metric',
    ),
  ])
  @override
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
class MonitoringDashboards extends DocSpecsSection {
  @SectionId('MODA-DASH')
  @Form([
    // Platform
    Field(
      'dashboardPlatform',
      String,
      'Dashboard Platform',
      hint: 'Grafana, Datadog, CloudWatch, custom',
    ),
    Field(
      'dashboardAccessControl',
      String,
      'Dashboard Access Control',
      hint: 'Who can view, edit dashboards',
    ),
    Field(
      'dashboardVersioning',
      bool,
      'Dashboard Versioning',
      hint: 'Version control for dashboards',
    ),
    // Standards
    Field(
      'dashboardNamingConvention',
      String,
      'Dashboard Naming Convention',
      hint: 'Naming standards for dashboards',
    ),
    Field(
      'standardLayout',
      String,
      'Standard Layout',
      hint: 'Common layout patterns',
    ),
    Field(
      'colorCodingStandards',
      String,
      'Color Coding Standards',
      hint: 'Red=bad, green=good conventions',
    ),
    // Categories
    Field(
      'executiveDashboards',
      bool,
      'Executive Dashboards',
      hint: 'High-level business KPIs',
    ),
    Field(
      'operationalDashboards',
      bool,
      'Operational Dashboards',
      hint: 'Real-time ops dashboards',
    ),
    Field(
      'serviceDashboards',
      bool,
      'Service Dashboards',
      hint: 'Per-service detail dashboards',
    ),
    Field(
      'infrastructureDashboards',
      bool,
      'Infrastructure Dashboards',
      hint: 'Infra-level dashboards',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? dashboardOverview;

  /// Dashboard overview narrative.
  @SerializationOrder(1)
  TextSection overviewNarrative = TextSection();

  /// Dashboard catalog.
  @StandardReferences([
    'Grafana — dashboard and panel design',
  ], 'The catalog of monitoring dashboards the system provides.')
  @SectionId('DAEN-DASH-LST')
  @SectionIdPattern('DAEN-DASH-xxx')
  @ContentHelp('Add one entry per dashboard.')
  @SerializationOrder(2)
  List<DashboardEntry> dashboards = [];

  /// Dashboard template specifications.
  @StandardReferences([
    'Grafana — dashboard and panel design',
  ], 'The catalog of reusable dashboard templates the system provides.')
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
class DashboardEntry extends DocSpecsSection {
  @Form([
    Field(
      'dashboardId',
      String,
      'Dashboard ID',
      required: true,
      hint: 'Unique dashboard identifier',
    ),
    Field(
      'dashboardName',
      String,
      'Dashboard Name',
      required: true,
      hint: 'Human-readable dashboard name',
    ),
    Field(
      'dashboardCategory',
      String,
      'Dashboard Category',
      hint: 'Executive, operational, service, infrastructure',
    ),
    Field(
      'targetAudience',
      String,
      'Target Audience',
      hint: 'Who uses this dashboard',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Refresh and data composition details.
  @SectionId('DAENCO')
  @StandardReferences(
    [
      'Grafana — dashboard and panel design',
      'OpenTelemetry — observability signals',
    ],
    'Refresh cadence, time range and data source configuration for a monitoring dashboard.',
  )
  @Form([
    Field(
      'refreshInterval',
      String,
      'Refresh Interval',
      hint: 'How often the dashboard refreshes',
    ),
    Field(
      'timeRangeDefault',
      String,
      'Time Range Default',
      hint: 'Default time window',
    ),
    Field(
      'keyPanels',
      String,
      'Key Panels',
      hint: 'Main visualizations on dashboard',
    ),
    Field(
      'dataSource',
      String,
      'Data Source',
      hint: 'Data source for dashboard',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? configuration;

  /// Alert ownership and notes.
  @SectionId('DAENOP')
  @StandardReferences(
    [
      'Google SRE — monitoring and dashboards (the four golden signals)',
      'ISO/IEC 20000 — service reporting',
    ],
    'Ownership, alert integration and operational notes for a monitoring dashboard.',
  )
  @Form([
    Field(
      'alertIntegration',
      String,
      'Alert Integration',
      hint: 'Alerts displayed on dashboard',
    ),
    Field(
      'ownerTeam',
      String,
      'Owner Team',
      hint: 'Team that owns this dashboard',
    ),
    Field('notes', String, 'Notes', hint: 'Additional operational notes'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? operations;
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
class DashboardTemplates extends DocSpecsSection {
  @Form([
    // Service template
    Field(
      'serviceTemplateLayout',
      String,
      'Service Template Layout',
      hint: 'Standard panels for service dashboards',
    ),
    Field(
      'serviceTemplateVariables',
      String,
      'Service Template Variables',
      hint: 'Configurable variables',
    ),
    // Infrastructure template
    Field(
      'infraTemplateLayout',
      String,
      'Infra Template Layout',
      hint: 'Standard panels for infra dashboards',
    ),
    // K8s template
    Field(
      'k8sTemplateLayout',
      String,
      'K8s Template Layout',
      hint: 'Kubernetes-specific dashboard layout',
    ),
    // Database template
    Field(
      'databaseTemplateLayout',
      String,
      'Database Template Layout',
      hint: 'Database monitoring panels',
    ),
    // Custom templates
    Field(
      'customTemplateProcess',
      String,
      'Custom Template Process',
      hint: 'How to create new templates',
    ),
    Field(
      'templateVersioning',
      String,
      'Template Versioning',
      hint: 'How templates are versioned',
    ),
    Field('notes', String, 'Notes', hint: 'Additional template notes'),
  ])
  @override
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
class SlaAndSloMonitoring extends DocSpecsSection {
  @SectionId('SASM-SLAO')
  @Form([
    // SLI/SLO framework
    Field('sloFramework', String, 'SLO Framework', hint: 'Google SRE, custom'),
    Field(
      'errorBudgetPolicy',
      String,
      'Error Budget Policy',
      hint: 'How error budget is managed',
    ),
    Field(
      'errorBudgetExhaustionPolicy',
      String,
      'Error Budget Exhaustion Policy',
      hint: 'Actions when budget exhausted',
    ),
    // Reporting
    Field(
      'slaReportingCadence',
      String,
      'SLA Reporting Cadence',
      hint: 'Weekly, monthly SLA reports',
    ),
    Field(
      'slaReportingAudience',
      String,
      'SLA Reporting Audience',
      hint: 'Who receives SLA reports',
    ),
    Field(
      'slaBreachProcess',
      String,
      'SLA Breach Process',
      hint: 'Process when SLA is breached',
    ),
    // External SLAs
    Field(
      'customerFacingSLAs',
      bool,
      'Customer-Facing SLAs',
      hint: 'SLAs published to customers',
    ),
    Field(
      'slaCredits',
      String,
      'SLA Credits',
      hint: 'Credit/refund policy for breaches',
    ),
    Field(
      'slaExclusions',
      String,
      'SLA Exclusions',
      hint: 'Maintenance windows, force majeure',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? slaOverview;

  /// SLA/SLO overview narrative.
  @SerializationOrder(1)
  TextSection overviewNarrative = TextSection();

  /// Service Level Indicators.
  @SerializationOrder(2)
  ServiceLevelIndicators slis = ServiceLevelIndicators();

  /// SLO catalog.
  @StandardReferences([
    'Google SRE — service level objectives (SLOs and SLIs)',
  ], 'The catalog of service level objectives the system commits to.')
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
class ServiceLevelIndicators extends DocSpecsSection {
  @Form([
    Field(
      'availabilitySli',
      String,
      'Availability SLI',
      hint: 'How availability is measured',
    ),
    Field(
      'availabilityExclusions',
      String,
      'Availability Exclusions',
      hint: 'What is excluded from availability',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Latency and throughput indicators.
  @SectionId('SLIP')
  @StandardReferences([
    'Google SRE — service level objectives (SLOs and SLIs)',
    'ISO/IEC 25010 — reliability (availability, maturity)',
  ], 'Service level indicators covering latency and throughput.')
  @Form([
    Field(
      'latencySli',
      String,
      'Latency SLI',
      hint: 'How latency is measured (p50, p95, p99)',
    ),
    Field(
      'latencyThresholds',
      String,
      'Latency Thresholds',
      hint: 'Good latency vs bad latency',
    ),
    Field(
      'throughputSli',
      String,
      'Throughput SLI',
      hint: 'How throughput is measured',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? performance;

  /// Error, correctness, and freshness indicators.
  @SectionId('SLIQ')
  @StandardReferences(
    [
      'Google SRE — service level objectives (SLOs and SLIs)',
      'ISO/IEC 25010 — reliability (availability, maturity)',
    ],
    'Service level indicators covering error rate, correctness, and data freshness.',
  )
  @Form([
    Field(
      'errorRateSli',
      String,
      'Error Rate SLI',
      hint: 'How errors are counted',
    ),
    Field(
      'errorCategories',
      String,
      'Error Categories',
      hint: 'Which errors count against SLI',
    ),
    Field(
      'correctnessSli',
      String,
      'Correctness SLI',
      hint: 'Data correctness measurement',
    ),
    Field(
      'freshnessSli',
      String,
      'Freshness SLI',
      hint: 'Data freshness measurement',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? quality;

  /// Measurement method and location.
  @SectionId('SLIM')
  @StandardReferences([
    'Google SRE — service level objectives (SLOs and SLIs)',
    'Google SRE — site reliability engineering practices',
  ], 'Describes how and where service level indicators are measured.')
  @Form([
    Field(
      'measurementMethod',
      String,
      'Measurement Method',
      hint: 'Synthetic, real user, logs',
    ),
    Field(
      'measurementLocation',
      String,
      'Measurement Location',
      hint: 'Server-side, client-side, edge',
    ),
    Field('notes', String, 'Notes', hint: 'Free-form measurement notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? measurement;
}

/// An SLO entry.
@StandardReferences([
  'Google SRE — service level objectives (SLOs and SLIs)',
], 'A single service level objective the system commits to meeting.')
@SectionId('SE')
class SloEntry extends DocSpecsSection {
  @Form([
    Field(
      'sloId',
      String,
      'SLO ID',
      required: true,
      hint: 'Unique SLO identifier',
    ),
    Field(
      'sloName',
      String,
      'SLO Name',
      required: true,
      hint: 'Human-readable SLO name',
    ),
    Field(
      'sloDescription',
      String,
      'SLO Description',
      hint: 'What this SLO covers',
    ),
    Field(
      'serviceName',
      String,
      'Service Name',
      hint: 'Service the SLO applies to',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Objective target and budget definition.
  @SectionId('SLENTA')
  @StandardReferences(
    [
      'Google SRE — service level objectives (SLOs and SLIs)',
      'Google SRE — error budgets',
    ],
    'Defines the target and derived error budget for a single service level objective.',
  )
  @Form([
    Field(
      'sliType',
      String,
      'SLI Type',
      hint: 'Availability, latency, error rate',
    ),
    Field('sloTarget', String, 'SLO Target', hint: 'e.g., 99.9%, p99 < 200ms'),
    Field(
      'sloWindow',
      String,
      'SLO Window',
      hint: 'Rolling 28-day, calendar month',
    ),
    Field('errorBudget', String, 'Error Budget', hint: 'Derived error budget'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? target;

  /// Alerting and ownership rules.
  @SectionId('SLENOP')
  @StandardReferences(
    [
      'Google SRE — service level objectives (SLOs and SLIs)',
      'ITIL 4 — service level management practice',
    ],
    'Alerting thresholds and ownership assigned to a single service level objective.',
  )
  @Form([
    Field(
      'alertThreshold',
      String,
      'Alert Threshold',
      hint: 'When to alert on burn rate',
    ),
    Field(
      'burnRateAlert',
      String,
      'Burn Rate Alert',
      hint: 'Fast-burn, slow-burn alerts',
    ),
    Field('ownerTeam', String, 'Owner Team', hint: 'Team owning this SLO'),
    Field('notes', String, 'Notes', hint: 'Free-form operational notes'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? operations;
}

/// Error budget tracking.
@StandardReferences([
  'Google SRE — error budgets',
  'Google SRE — service level objectives (SLOs and SLIs)',
], 'Tracks the error budget derived from the service level objectives.')
@SectionId('ERBUTR')
class ErrorBudgetTracking extends DocSpecsSection {
  @Form([
    // Budget calculation
    Field(
      'budgetCalculationMethod',
      String,
      'Budget Calculation Method',
      hint: 'How error budget is calculated',
    ),
    Field(
      'budgetWindow',
      String,
      'Budget Window',
      hint: 'Rolling or calendar window',
    ),
    Field(
      'budgetResetPolicy',
      String,
      'Budget Reset Policy',
      hint: 'When budget resets',
    ),
    // Monitoring
    Field(
      'budgetBurnRateDashboard',
      bool,
      'Budget Burn Rate Dashboard',
      hint: 'Dashboard showing burn rate',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Burn-rate monitoring thresholds.
  @SectionId('EBTM')
  @StandardReferences([
    'Google SRE — error budgets',
    'Google SRE — service level objectives (SLOs and SLIs)',
  ], 'Thresholds that watch how quickly the error budget burns down.')
  @Form([
    Field(
      'budgetAlertThresholds',
      String,
      'Budget Alert Thresholds',
      hint: 'Warn at 50%, critical at 80%',
    ),
    Field(
      'burnRateTimePeriods',
      String,
      'Burn Rate Time Periods',
      hint: '1h, 6h, 24h, 7d burn rates',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? monitoring;

  /// Recovery policy and attribution rules.
  @SectionId('EBTG')
  @StandardReferences([
    'Google SRE — error budgets',
    'ITIL 4 — service level management practice',
  ], 'Recovery and attribution rules applied when the error budget is spent.')
  @Form([
    Field(
      'budgetExhaustionActions',
      String,
      'Budget Exhaustion Actions',
      hint: 'Feature freeze, deployment freeze',
    ),
    Field(
      'budgetRecoveryProcess',
      String,
      'Budget Recovery Process',
      hint: 'Steps to recover budget',
    ),
    Field(
      'budgetReviewMeeting',
      String,
      'Budget Review Meeting',
      hint: 'Regular error budget review',
    ),
    Field(
      'budgetAttribution',
      String,
      'Budget Attribution',
      hint: 'Attribute budget spend to incidents',
    ),
    Field('notes', String, 'Notes', hint: 'Free-form governance notes'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? governance;
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
class HealthChecksAndDiagnosticsSection extends DocSpecsSection {
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
  @override
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
class HealthCheckEndpoints extends DocSpecsSection {
  @Form([
    Field(
      'livenessEndpoint',
      String,
      'Liveness Endpoint',
      required: true,
      hint: '/health/live — is the process running',
    ),
    Field(
      'readinessEndpoint',
      String,
      'Readiness Endpoint',
      required: true,
      hint: '/health/ready — can it serve traffic',
    ),
    Field(
      'startupEndpoint',
      String,
      'Startup Endpoint',
      hint: '/health/startup — has initialization completed',
    ),
    Field(
      'deepHealthEndpoint',
      String,
      'Deep Health Endpoint',
      hint: '/health/deep — checks all dependencies',
    ),
    Field('healthCheckProtocol', String, 'Protocol', hint: 'HTTP, gRPC, TCP'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Response configuration.
  @SectionId('HCEC')
  @StandardReferences(
    [
      'Kubernetes — liveness, readiness, and startup probes',
      'Google SRE — health checking and monitoring',
    ],
    'Specifies the health check port, response format, and success/failure status codes returned by the endpoints.',
  )
  @Form([
    Field('healthCheckPort', int, 'Port', hint: 'Dedicated health check port'),
    Field(
      'responseFormat',
      String,
      'Response Format',
      hint: 'JSON, plain text, RFC Health Check format',
    ),
    Field(
      'successStatusCode',
      int,
      'Success Status Code',
      hint: 'HTTP 200 for healthy',
    ),
    Field(
      'failureStatusCode',
      int,
      'Failure Status Code',
      hint: 'HTTP 503 for unhealthy',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? configuration;

  /// Timing thresholds.
  @SectionId('HCET')
  @StandardReferences(
    [
      'Kubernetes — liveness, readiness, and startup probes',
      'Google SRE — health checking and monitoring',
    ],
    'Defines the check interval, timeout, and failure/success thresholds that govern how probes decide a service is healthy or unhealthy.',
  )
  @Form([
    Field(
      'checkInterval',
      String,
      'Check Interval',
      hint: 'How often health is checked (e.g. 10s, 30s)',
    ),
    Field(
      'checkTimeout',
      String,
      'Check Timeout',
      hint: 'Max time for a health check response',
    ),
    Field(
      'failureThreshold',
      int,
      'Failure Threshold',
      hint: 'Consecutive failures before unhealthy',
    ),
    Field(
      'successThreshold',
      int,
      'Success Threshold',
      hint: 'Consecutive successes to become healthy',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? timing;

  /// Response content settings.
  @SectionId('HECHENCO')
  @StandardReferences(
    [
      'Kubernetes — liveness, readiness, and startup probes',
      'Google SRE — health checking and monitoring',
    ],
    'Specifies what detail a health check response includes such as component status, version, uptime, and redaction of sensitive data.',
  )
  @Form([
    Field(
      'includeComponentStatus',
      bool,
      'Include Component Status',
      hint: 'Show status of individual components',
    ),
    Field(
      'includeVersion',
      bool,
      'Include Version',
      hint: 'Include app version in response',
    ),
    Field(
      'includeUptime',
      bool,
      'Include Uptime',
      hint: 'Include process uptime',
    ),
    Field(
      'includeMetrics',
      bool,
      'Include Metrics',
      hint: 'Include basic metrics in response',
    ),
    Field(
      'sensitiveDataRedaction',
      bool,
      'Sensitive Data Redaction',
      hint: 'Redact secrets from health output',
    ),
    Field('notes', String, 'Notes', hint: 'Additional health endpoint notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? contentSettings;
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
class ApplicationDiagnostics extends DocSpecsSection {
  @Form([
    // Runtime information
    Field(
      'infoEndpoint',
      String,
      'Info Endpoint',
      hint: '/info — build version, git commit, environment',
    ),
    Field(
      'metricsEndpoint',
      String,
      'Metrics Endpoint',
      hint: '/metrics — Prometheus, OpenMetrics format',
    ),
    Field(
      'environmentEndpoint',
      String,
      'Environment Endpoint',
      hint: '/env — configuration (redacted)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// On-demand profiling and slow-request tracing.
  @SectionId('APDIPE')
  @StandardReferences(
    [
      'OpenTelemetry — observability signals',
      'Google SRE — site reliability engineering practices',
    ],
    'Specifies on-demand CPU and memory profiling and per-request tracing used to diagnose slow or resource-heavy requests.',
  )
  @Form([
    Field(
      'cpuProfiling',
      bool,
      'CPU Profiling',
      hint: 'On-demand CPU profiling',
    ),
    Field(
      'memoryProfiling',
      bool,
      'Memory Profiling',
      hint: 'Heap analysis and leak detection',
    ),
    Field(
      'requestTracing',
      bool,
      'Request Tracing',
      hint: 'Per-request timing breakdown',
    ),
    Field(
      'slowRequestDetection',
      String,
      'Slow Request Detection',
      hint: 'Threshold and alerting for slow requests',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? performance;

  /// Runtime queue and pool inspection.
  @SectionId('APDIRU')
  @StandardReferences(
    [
      'OpenTelemetry — observability signals',
      'Google SRE — health checking and monitoring',
    ],
    'Provides runtime inspection of connection pools, thread pools, and queue depth for diagnosing resource contention.',
  )
  @Form([
    Field(
      'connectionPoolStatus',
      bool,
      'Connection Pool Status',
      hint: 'Database and HTTP pool monitoring',
    ),
    Field(
      'threadPoolStatus',
      bool,
      'Thread Pool Status',
      hint: 'Worker thread/isolate pool status',
    ),
    Field(
      'queueDepthMonitoring',
      bool,
      'Queue Depth Monitoring',
      hint: 'Message queue backlog tracking',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? runtime;

  /// Feature and resilience status indicators.
  @SectionId('ADFS')
  @StandardReferences(
    [
      'OpenTelemetry — observability signals',
      'Google SRE — health checking and monitoring',
    ],
    'Exposes feature-flag, circuit-breaker, and cache-hit-ratio status indicators for runtime resilience visibility.',
  )
  @Form([
    Field(
      'featureFlagStatus',
      bool,
      'Feature Flag Status',
      hint: 'Active feature flags visibility',
    ),
    Field(
      'circuitBreakerStatus',
      bool,
      'Circuit Breaker Status',
      hint: 'State of circuit breakers',
    ),
    Field(
      'cacheHitRatio',
      bool,
      'Cache Hit Ratio',
      hint: 'Cache effectiveness monitoring',
    ),
    Field('notes', String, 'Notes', hint: 'Additional diagnostics notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? featureStatus;
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
class LogAggregationRequirements extends DocSpecsSection {
  @Form([
    Field(
      'logPlatform',
      String,
      'Log Platform',
      required: true,
      hint: 'ELK Stack, Loki/Grafana, CloudWatch, Datadog',
    ),
    Field(
      'logFormat',
      String,
      'Log Format',
      hint: 'Structured JSON, plain text, syslog',
    ),
    Field(
      'logLevels',
      String,
      'Log Levels',
      hint: 'TRACE, DEBUG, INFO, WARN, ERROR, FATAL',
    ),
    Field(
      'defaultLogLevel',
      String,
      'Default Log Level',
      hint: 'Production default level (e.g. INFO)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Dynamic configuration and collection settings.
  @SectionId('LARC')
  @StandardReferences(
    [
      'OpenTelemetry — observability signals',
      'The Twelve-Factor App — disposability (fast startup, graceful shutdown)',
    ],
    'Specifies dynamic log-level changes and the collection, shipping, buffering, and sampling settings for log ingestion.',
  )
  @Form([
    Field(
      'dynamicLogLevelChange',
      bool,
      'Dynamic Log Level Change',
      hint: 'Change log level without restart',
    ),
    Field(
      'logCollectionMethod',
      String,
      'Log Collection Method',
      hint: 'Sidecar, agent, direct push, stdout',
    ),
    Field(
      'logShippingProtocol',
      String,
      'Log Shipping Protocol',
      hint: 'Fluentd, Logstash, OTLP',
    ),
    Field(
      'logBuffering',
      String,
      'Log Buffering',
      hint: 'Buffer size, flush interval',
    ),
    Field(
      'logSampling',
      String,
      'Log Sampling',
      hint: 'Sample rate for high-volume logs',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? collection;

  /// Retention and archival settings.
  @SectionId('LARR')
  @StandardReferences(
    [
      'ISO/IEC 20000 — service availability management',
      'OpenTelemetry — observability signals',
    ],
    'Defines log retention periods, archival policy, and regulatory-compliance retention for aggregated logs.',
  )
  @Form([
    Field(
      'retentionPeriod',
      String,
      'Retention Period',
      hint: 'Hot: 7d, warm: 30d, cold: 1y',
    ),
    Field(
      'archivalPolicy',
      String,
      'Archival Policy',
      hint: 'S3 Glacier, cold storage',
    ),
    Field(
      'complianceRetention',
      String,
      'Compliance Retention',
      hint: 'Regulatory retention requirements',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? retention;

  /// Search and analysis capabilities.
  @SectionId('LARA')
  @StandardReferences(
    [
      'OpenTelemetry — observability signals',
      'Google SRE — health checking and monitoring',
    ],
    'Specifies log search, trace-correlation, saved queries, and log-based alerting used to analyze aggregated logs.',
  )
  @Form([
    Field(
      'fullTextSearch',
      bool,
      'Full-Text Search',
      hint: 'Search across all log streams',
    ),
    Field(
      'correlationByTraceId',
      bool,
      'Correlation by Trace ID',
      hint: 'Cross-service log correlation',
    ),
    Field(
      'savedQueries',
      bool,
      'Saved Queries',
      hint: 'Reusable log search queries',
    ),
    Field(
      'logBasedAlerts',
      bool,
      'Log-Based Alerts',
      hint: 'Alert on log patterns or frequencies',
    ),
    Field(
      'piiRedaction',
      bool,
      'PII Redaction',
      hint: 'Automatic PII masking in logs',
    ),
    Field('notes', String, 'Notes', hint: 'Additional log aggregation notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? analysis;
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
class TroubleshootingCapabilities extends DocSpecsSection {
  @Form([
    Field(
      'debugMode',
      String,
      'Debug Mode',
      hint: 'How to enable verbose diagnostics',
    ),
    Field(
      'diagnosticDump',
      bool,
      'Diagnostic Dump',
      hint: 'Generate full diagnostic report on demand',
    ),
    Field(
      'replayCapability',
      bool,
      'Replay Capability',
      hint: 'Replay failed requests for analysis',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Runbook and remediation support.
  @SectionId('TRCARU')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering practices',
      'AWS Well-Architected — reliability pillar (health checks)',
    ],
    'Defines runbook integration and automated remediation that link alerts to known-issue fixes and correlated incident timelines.',
  )
  @Form([
    Field(
      'runbookIntegration',
      bool,
      'Runbook Integration',
      hint: 'Link alerts to troubleshooting runbooks',
    ),
    Field(
      'automatedRemediation',
      String,
      'Automated Remediation',
      hint: 'Auto-fix for known issues (restart, scale)',
    ),
    Field(
      'incidentTimeline',
      bool,
      'Incident Timeline',
      hint: 'Correlated event timeline for incidents',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? runbooks;

  /// Break-glass and diagnostic access controls.
  @SectionId('TRCAAC')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering practices',
      'ISO/IEC 20000 — service availability management',
    ],
    'Specifies audited break-glass access and diagnostic tooling used to investigate incidents in production.',
  )
  @Form([
    Field(
      'productionShellAccess',
      String,
      'Production Shell Access',
      hint: 'Break-glass SSH/exec with audit',
    ),
    Field(
      'databaseReadAccess',
      String,
      'Database Read Access',
      hint: 'Read-only query for production DB',
    ),
    Field(
      'networkDiagnostics',
      bool,
      'Network Diagnostics',
      hint: 'Ping, traceroute, DNS lookup tools',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? access;

  /// Incident communication and retrospective support.
  @SectionId('TRCACO')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering practices',
      'ISO/IEC 20000 — service availability management',
    ],
    'Defines incident communication tooling and the blameless-postmortem process that supports retrospective analysis.',
  )
  @Form([
    Field(
      'statusPageIntegration',
      String,
      'Status Page Integration',
      hint: 'Statuspage.io, Instatus, custom',
    ),
    Field(
      'warRoomTools',
      String,
      'War Room Tools',
      hint: 'Incident collaboration (Slack channel, Zoom)',
    ),
    Field(
      'postmortemProcess',
      String,
      'Postmortem Process',
      hint: 'Blameless postmortem template and workflow',
    ),
    Field('notes', String, 'Notes', hint: 'Additional troubleshooting notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? communication;
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
class DependencyHealthMonitoring extends DocSpecsSection {
  @Form([
    // Database
    Field(
      'databaseHealthCheck',
      String,
      'Database Health Check',
      hint: 'Connection test, query test, replication lag',
    ),
    Field(
      'databaseLatencyThreshold',
      String,
      'DB Latency Threshold',
      hint: 'Alert threshold for slow queries',
    ),
    Field(
      'databaseConnectionPoolHealth',
      bool,
      'DB Pool Health',
      hint: 'Monitor pool exhaustion',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Cache subsystem checks.
  @SectionId('DHMC')
  @StandardReferences(
    [
      'Google SRE — health checking and monitoring',
      'OpenTelemetry — observability signals',
    ],
    'Specifies health checks for the cache subsystem including ping, memory, and eviction-rate monitoring.',
  )
  @Form([
    Field(
      'cacheHealthCheck',
      String,
      'Cache Health Check',
      hint: 'Redis/Memcached ping and memory',
    ),
    Field(
      'cacheEvictionMonitoring',
      bool,
      'Cache Eviction Monitoring',
      hint: 'Alert on high eviction rates',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? cache;

  /// Queue and dead-letter monitoring.
  @SectionId('DHMQ')
  @StandardReferences(
    [
      'Google SRE — health checking and monitoring',
      'OpenTelemetry — observability signals',
    ],
    'Defines health monitoring of message queues including queue depth, consumer lag, and dead-letter-queue accumulation.',
  )
  @Form([
    Field(
      'messageQueueHealth',
      String,
      'Message Queue Health',
      hint: 'Queue depth, consumer lag',
    ),
    Field(
      'dlqMonitoring',
      bool,
      'Dead Letter Queue Monitoring',
      hint: 'Alert on DLQ message accumulation',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? queue;

  /// External service and certificate checks.
  @SectionId('DHME')
  @StandardReferences(
    [
      'Google SRE — health checking and monitoring',
      'ISO/IEC 20000 — service availability management',
    ],
    'Specifies connectivity, certificate-expiry, and DNS-resolution checks for the external service dependencies of the system.',
  )
  @Form([
    Field(
      'externalServicePing',
      bool,
      'External Service Ping',
      hint: 'Periodic connectivity tests',
    ),
    Field(
      'certificateExpiryCheck',
      bool,
      'Certificate Expiry Check',
      hint: 'Monitor TLS certificate expiration',
    ),
    Field(
      'dnsResolutionCheck',
      bool,
      'DNS Resolution Check',
      hint: 'Verify DNS resolution for dependencies',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? external;

  /// Thresholds and cascade protection settings.
  @SectionId('DHMT')
  @StandardReferences(
    [
      'Google SRE — health checking and monitoring',
      'AWS Well-Architected — reliability pillar (health checks)',
    ],
    'Defines the thresholds that mark a dependency degraded or unavailable and the cascade-protection settings that prevent one failure from spreading.',
  )
  @Form([
    Field(
      'degradedThreshold',
      String,
      'Degraded Threshold',
      hint: 'When to mark dependency as degraded',
    ),
    Field(
      'unavailableThreshold',
      String,
      'Unavailable Threshold',
      hint: 'When to mark dependency as down',
    ),
    Field(
      'cascadeProtection',
      String,
      'Cascade Protection',
      hint: 'Prevent cascading failures',
    ),
    Field('notes', String, 'Notes', hint: 'Additional dependency health notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? thresholds;
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
class CapacityPlanningSection extends DocSpecsSection {
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
  @override
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
  ScalingTriggersAndThresholds scalingTriggers = ScalingTriggersAndThresholds();

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
class UserGrowthProjections extends DocSpecsSection {
  @Form([
    // Current state
    Field(
      'currentActiveUsers',
      int,
      'Current Active Users',
      required: true,
      hint: 'Current monthly active user count',
    ),
    Field(
      'currentRegisteredUsers',
      int,
      'Current Registered Users',
      hint: 'Total registered user accounts',
    ),
    Field(
      'currentConcurrentUsers',
      int,
      'Current Concurrent Users',
      hint: 'Peak concurrent user count',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Growth-rate assumptions and time-based projections.
  @SectionId('UGPF')
  @StandardReferences(
    [
      'Google SRE — capacity planning and demand forecasting',
      'ISO/IEC 20000 — capacity management process',
    ],
    'Projects active user counts at 6 to 36 months from a stated growth rate to drive capacity forecasts.',
  )
  @Form([
    Field(
      'projectedGrowthRate',
      String,
      'Projected Growth Rate',
      required: true,
      hint: 'Monthly/yearly user growth percentage',
    ),
    Field(
      'users6Months',
      int,
      'Users at 6 Months',
      hint: 'Expected active users in 6 months',
    ),
    Field(
      'users12Months',
      int,
      'Users at 12 Months',
      hint: 'Expected active users in 12 months',
    ),
    Field(
      'users24Months',
      int,
      'Users at 24 Months',
      hint: 'Expected active users in 24 months',
    ),
    Field(
      'users36Months',
      int,
      'Users at 36 Months',
      hint: 'Expected active users in 36 months',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? forecast;

  /// User segmentation and geographic patterns.
  @SectionId('UGPS')
  @StandardReferences(
    [
      'Google SRE — capacity planning and demand forecasting',
      'ISO/IEC 20000 — capacity management process',
    ],
    'Captures user segments, geographic distribution, and seasonal patterns that shape demand forecasts.',
  )
  @Form([
    Field(
      'userSegments',
      String,
      'User Segments',
      hint: 'Growth per user category (free, premium, enterprise)',
    ),
    Field(
      'geographicDistribution',
      String,
      'Geographic Distribution',
      hint: 'Expected user distribution across regions',
    ),
    Field(
      'seasonalPatterns',
      String,
      'Seasonal Patterns',
      hint: 'Monthly/quarterly user volume patterns',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? segmentation;

  /// Capacity thresholds and planning notes.
  @SectionId('UGPT')
  @StandardReferences(
    [
      'Google SRE — capacity planning and demand forecasting',
      'ISO/IEC 20000 — capacity management process',
    ],
    'Defines soft and hard user-capacity limits that trigger system review and scaling actions.',
  )
  @Form([
    Field(
      'softCapacityLimit',
      int,
      'Soft Capacity Limit',
      hint: 'User count requiring system review',
    ),
    Field(
      'hardCapacityLimit',
      int,
      'Hard Capacity Limit',
      hint: 'Maximum supportable users before scaling',
    ),
    Field('notes', String, 'Notes', hint: 'Additional user growth notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? thresholds;
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
class DataGrowthProjections extends DocSpecsSection {
  @Form([
    Field(
      'currentDataVolume',
      String,
      'Current Data Volume',
      required: true,
      hint: 'Total data size (e.g. 500 GB)',
    ),
    Field(
      'currentDatabaseSize',
      String,
      'Current Database Size',
      hint: 'Primary database storage usage',
    ),
    Field(
      'currentFileStorageSize',
      String,
      'Current File Storage Size',
      hint: 'File/blob storage usage',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Growth-rate assumptions.
  @SectionId('DGPG')
  @StandardReferences(
    [
      'Google SRE — capacity planning and demand forecasting',
      'ISO/IEC 20000 — capacity management process',
    ],
    'Captures data growth rate, volume per user, and transaction growth assumptions driving capacity forecasts.',
  )
  @Form([
    Field(
      'dataGrowthRate',
      String,
      'Data Growth Rate',
      required: true,
      hint: 'Monthly data volume increase',
    ),
    Field(
      'dataVolumePerUser',
      String,
      'Data Volume per User',
      hint: 'Average storage per active user',
    ),
    Field(
      'transactionVolumeGrowth',
      String,
      'Transaction Volume Growth',
      hint: 'Growth in daily/monthly transactions',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? growth;

  /// Volume projections.
  @SectionId('DGPP')
  @StandardReferences(
    [
      'Google SRE — capacity planning and demand forecasting',
      'ISO/IEC 20000 — capacity management process',
    ],
    'Projects total data volume at 6, 12, and 24 months to inform storage capacity planning.',
  )
  @Form([
    Field(
      'projectedVolume6Months',
      String,
      'Projected Volume at 6 Months',
      hint: 'Expected total data at 6 months',
    ),
    Field(
      'projectedVolume12Months',
      String,
      'Projected Volume at 12 Months',
      hint: 'Expected total data at 12 months',
    ),
    Field(
      'projectedVolume24Months',
      String,
      'Projected Volume at 24 Months',
      hint: 'Expected total data at 24 months',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? projections;

  /// Data lifecycle strategy.
  @SectionId('DGPL')
  @StandardReferences(
    [
      'ISO/IEC 20000 — capacity management process',
      'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
    ],
    'Defines retention, archival, cleanup, and compression policies that manage data-storage capacity over time.',
  )
  @Form([
    Field(
      'dataRetentionPolicy',
      String,
      'Data Retention Policy',
      hint: 'Hot/warm/cold storage tiers',
    ),
    Field(
      'archivalStrategy',
      String,
      'Archival Strategy',
      hint: 'When and how data moves to archive',
    ),
    Field(
      'dataCleanupPolicy',
      String,
      'Data Cleanup Policy',
      hint: 'Automatic deletion rules',
    ),
    Field(
      'compressionStrategy',
      String,
      'Compression Strategy',
      hint: 'Data compression for storage efficiency',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? lifecycle;

  /// Thresholds and notes.
  @SectionId('DGPT')
  @StandardReferences(
    [
      'ISO/IEC 20000 — capacity management process',
      'Google SRE — capacity planning and demand forecasting',
    ],
    'Defines storage alert thresholds and partitioning strategy that govern data-growth capacity limits.',
  )
  @Form([
    Field(
      'storageAlertThreshold',
      String,
      'Storage Alert Threshold',
      hint: 'Percentage triggering storage alert (e.g. 80%)',
    ),
    Field(
      'partitioningStrategy',
      String,
      'Partitioning Strategy',
      hint: 'Table/index partitioning approach',
    ),
    Field('notes', String, 'Notes', hint: 'Additional data growth notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? thresholds;
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
class PeakLoadPatterns extends DocSpecsSection {
  @Form([
    Field(
      'dailyPeakHours',
      String,
      'Daily Peak Hours',
      required: true,
      hint: 'Hours of highest daily traffic',
    ),
    Field(
      'weeklyPeakDays',
      String,
      'Weekly Peak Days',
      hint: 'Highest traffic days of the week',
    ),
    Field(
      'monthlyPeakPeriods',
      String,
      'Monthly Peak Periods',
      hint: 'Month-end processing, billing cycles',
    ),
    Field(
      'yearlyPeakEvents',
      String,
      'Yearly Peak Events',
      hint: 'Black Friday, tax season, renewals',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Peak metrics.
  @SectionId('PLPM')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
      'Google SRE — capacity planning and demand forecasting',
    ],
    'Captures peak RPS, concurrent sessions, and response-time targets that define the workload capacity envelope.',
  )
  @Form([
    Field(
      'peakRequestsPerSecond',
      int,
      'Peak Requests/Second',
      hint: 'Maximum expected RPS during peak',
    ),
    Field(
      'peakConcurrentSessions',
      int,
      'Peak Concurrent Sessions',
      hint: 'Maximum simultaneous user sessions',
    ),
    Field(
      'averageResponseTimeTarget',
      String,
      'Avg Response Time Target',
      hint: 'Target p50 response time during peak',
    ),
    Field(
      'p99ResponseTimeTarget',
      String,
      'P99 Response Time Target',
      hint: 'Target p99 response time during peak',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? metrics;

  /// Load multipliers.
  @SectionId('PLPC')
  @StandardReferences(
    [
      'Google SRE — capacity planning and demand forecasting',
      'AWS Well-Architected — reliability pillar (workload scaling)',
    ],
    'Captures peak-to-average ratios, burst capacity, and graceful-degradation plans for extreme load.',
  )
  @Form([
    Field(
      'peakToAverageRatio',
      String,
      'Peak-to-Average Ratio',
      hint: 'Ratio of peak to normal load (e.g. 3:1)',
    ),
    Field(
      'burstCapacityRequired',
      String,
      'Burst Capacity Required',
      hint: 'Short-duration spike handling',
    ),
    Field(
      'gracefulDegradationPlan',
      String,
      'Graceful Degradation Plan',
      hint: 'What degrades first under extreme load',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? capacity;

  /// Testing regime.
  @SectionId('PLPT')
  @StandardReferences(
    [
      'Google SRE — site reliability engineering practices',
      'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
    ],
    'Defines the load-testing cadence, tools, and benchmark baselines used to validate peak capacity.',
  )
  @Form([
    Field(
      'loadTestingFrequency',
      String,
      'Load Testing Frequency',
      hint: 'How often load tests are run',
    ),
    Field(
      'loadTestingTools',
      String,
      'Load Testing Tools',
      hint: 'k6, JMeter, Gatling, Locust',
    ),
    Field(
      'benchmarkBaseline',
      String,
      'Benchmark Baseline',
      hint: 'Current performance baseline metrics',
    ),
    Field('notes', String, 'Notes', hint: 'Additional peak load notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? testing;
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
class ScalingTriggersAndThresholds extends DocSpecsSection {
  @Form([
    Field(
      'cpuScaleUpThreshold',
      String,
      'CPU Scale-Up Threshold',
      required: true,
      hint: 'CPU % triggering scale-up (e.g. 70%)',
    ),
    Field(
      'cpuScaleDownThreshold',
      String,
      'CPU Scale-Down Threshold',
      hint: 'CPU % triggering scale-down (e.g. 30%)',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Memory-based thresholds.
  @SectionId('STATM')
  @StandardReferences(
    [
      'AWS Well-Architected — reliability pillar (workload scaling)',
      'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
    ],
    'Defines the memory-utilization thresholds that trigger scale-up and scale-down of the workload.',
  )
  @Form([
    Field(
      'memoryScaleUpThreshold',
      String,
      'Memory Scale-Up Threshold',
      hint: 'Memory % triggering scale-up',
    ),
    Field(
      'memoryScaleDownThreshold',
      String,
      'Memory Scale-Down Threshold',
      hint: 'Memory % triggering scale-down',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? memory;

  /// Request-based thresholds.
  @SectionId('STATR')
  @StandardReferences(
    [
      'AWS Well-Architected — reliability pillar (workload scaling)',
      'Google SRE — site reliability engineering practices',
    ],
    'Defines request-rate, latency, and queue-depth thresholds that trigger scaling of the workload.',
  )
  @Form([
    Field(
      'requestRateScaleUpThreshold',
      String,
      'Request Rate Scale-Up',
      hint: 'RPS threshold for scaling up',
    ),
    Field(
      'responseTimeScaleUpThreshold',
      String,
      'Response Time Scale-Up',
      hint: 'Latency threshold triggering scale-up',
    ),
    Field(
      'queueDepthScaleUpThreshold',
      String,
      'Queue Depth Scale-Up',
      hint: 'Message queue depth triggering scale-up',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? request;

  /// Scaling behavior.
  @SectionId('STATB')
  @StandardReferences(
    [
      'AWS Well-Architected — reliability pillar (workload scaling)',
      'Google SRE — site reliability engineering practices',
    ],
    'Defines scaling cooldowns, min/max instance bounds, and step size that govern how the system scales.',
  )
  @Form([
    Field(
      'scalingCooldownPeriod',
      String,
      'Scaling Cooldown Period',
      hint: 'Minimum time between scaling events',
    ),
    Field(
      'minInstances',
      int,
      'Minimum Instances',
      hint: 'Minimum number of running instances',
    ),
    Field(
      'maxInstances',
      int,
      'Maximum Instances',
      hint: 'Maximum number of running instances',
    ),
    Field(
      'scalingStepSize',
      String,
      'Scaling Step Size',
      hint: 'Instances added per scale-up event',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? behavior;

  /// Scaling types and providers.
  @SectionId('STATT')
  @StandardReferences(
    [
      'The Twelve-Factor App — concurrency (scale out via the process model)',
      'AWS Well-Architected — reliability pillar (workload scaling)',
    ],
    'Selects horizontal versus vertical scaling, the auto-scaling provider, and scheduled scaling for known peaks.',
  )
  @Form([
    Field(
      'horizontalScaling',
      bool,
      'Horizontal Scaling',
      hint: 'Add more instances',
    ),
    Field(
      'verticalScaling',
      bool,
      'Vertical Scaling',
      hint: 'Increase instance resources',
    ),
    Field(
      'autoScalingProvider',
      String,
      'Auto-Scaling Provider',
      hint: 'Kubernetes HPA, AWS Auto Scaling, Azure VMSS',
    ),
    Field(
      'scheduledScaling',
      String,
      'Scheduled Scaling',
      hint: 'Pre-scale for known peak events',
    ),
    Field('notes', String, 'Notes', hint: 'Additional scaling trigger notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? type;
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
class ResourceCapacityBaselines extends DocSpecsSection {
  @Form([
    // Compute
    Field(
      'cpuBaseline',
      String,
      'CPU Baseline',
      required: true,
      hint: 'Normal CPU utilization per service',
    ),
    Field(
      'memoryBaseline',
      String,
      'Memory Baseline',
      hint: 'Normal memory usage per service',
    ),
    Field(
      'instanceCountBaseline',
      String,
      'Instance Count Baseline',
      hint: 'Normal number of running instances',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Storage baselines.
  @SectionId('RCBS')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
      'ISO/IEC 20000 — capacity management process',
    ],
    'Records normal storage IOPS and throughput as capacity baselines for the workload.',
  )
  @Form([
    Field(
      'storageIOPSBaseline',
      String,
      'Storage IOPS Baseline',
      hint: 'Normal storage I/O operations per second',
    ),
    Field(
      'storageThroughputBaseline',
      String,
      'Storage Throughput Baseline',
      hint: 'Normal storage throughput (MB/s)',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? storage;

  /// Network baselines.
  @SectionId('RCBN')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
      'ISO/IEC 20000 — capacity management process',
    ],
    'Records normal network bandwidth and active connection counts as capacity baselines.',
  )
  @Form([
    Field(
      'networkBandwidthBaseline',
      String,
      'Network Bandwidth Baseline',
      hint: 'Normal network usage (Mbps)',
    ),
    Field(
      'connectionCountBaseline',
      String,
      'Connection Count Baseline',
      hint: 'Normal active connection count',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? network;

  /// Database baselines.
  @SectionId('RCBD')
  @StandardReferences(
    [
      'ISO/IEC 25010 — performance efficiency (capacity, resource utilization)',
      'ISO/IEC 20000 — capacity management process',
    ],
    'Records normal database connection-pool usage, query volume, and on-disk size as capacity baselines.',
  )
  @Form([
    Field(
      'databaseConnectionPoolBaseline',
      String,
      'DB Connection Pool Baseline',
      hint: 'Normal active DB connections',
    ),
    Field(
      'queryVolumeBaseline',
      String,
      'Query Volume Baseline',
      hint: 'Normal queries per second',
    ),
    Field(
      'databaseSizeBaseline',
      String,
      'Database Size Baseline',
      hint: 'Current database on-disk size',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? database;

  /// Cost baselines and notes.
  @SectionId('RCBC')
  @StandardReferences(
    [
      'AWS Well-Architected — reliability pillar (workload scaling)',
      'Google SRE — capacity planning and demand forecasting',
    ],
    'Establishes baseline infrastructure cost, cost per user, and projected cost at target scale.',
  )
  @Form([
    Field(
      'currentMonthlyCost',
      String,
      'Current Monthly Cost',
      hint: 'Baseline monthly infrastructure cost',
    ),
    Field(
      'costPerUser',
      String,
      'Cost Per User',
      hint: 'Infrastructure cost per active user',
    ),
    Field(
      'projectedCostAtScale',
      String,
      'Projected Cost at Scale',
      hint: 'Estimated cost at target user count',
    ),
    Field('notes', String, 'Notes', hint: 'Additional resource baseline notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? cost;
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
class CapacityReviewProcess extends DocSpecsSection {
  @Form([
    Field(
      'reviewFrequency',
      String,
      'Review Frequency',
      required: true,
      hint: 'Monthly, quarterly, on-demand',
    ),
    Field(
      'reviewParticipants',
      String,
      'Review Participants',
      hint: 'Engineering, ops, finance stakeholders',
    ),
    Field(
      'reviewChecklist',
      String,
      'Review Checklist',
      hint: 'Standard items reviewed each cycle',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Monitoring and forecasting inputs.
  @SectionId('CAREPRMO')
  @StandardReferences(
    [
      'Google SRE — capacity planning and demand forecasting',
      'ISO/IEC 20000 — capacity management process',
    ],
    'Captures the dashboards, trend analysis, and forecasting models that feed capacity review decisions.',
  )
  @Form([
    Field(
      'capacityDashboard',
      bool,
      'Capacity Dashboard',
      hint: 'Dedicated capacity monitoring dashboard',
    ),
    Field(
      'trendAnalysis',
      bool,
      'Trend Analysis',
      hint: 'Automated growth trend detection',
    ),
    Field(
      'forecastingModel',
      String,
      'Forecasting Model',
      hint: 'Linear, exponential, ML-based forecasting',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? monitoring;

  /// Escalation and emergency scaling decisions.
  @SectionId('CRPE')
  @StandardReferences(
    [
      'ITIL 4 — capacity and performance management',
      'Google SRE — site reliability engineering practices',
    ],
    'Defines capacity alert thresholds, escalation procedures, and emergency scaling steps for the capacity review process.',
  )
  @Form([
    Field(
      'capacityAlertThresholds',
      String,
      'Capacity Alert Thresholds',
      hint: 'Warning: 70%, critical: 85%, emergency: 95%',
    ),
    Field(
      'escalationProcedure',
      String,
      'Escalation Procedure',
      hint: 'Who to notify at each threshold level',
    ),
    Field(
      'emergencyScalingProcedure',
      String,
      'Emergency Scaling Procedure',
      hint: 'Steps for urgent capacity increase',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? escalation;

  /// Budgeting and rightsizing planning.
  @SectionId('CRPP')
  @StandardReferences(
    [
      'ISO/IEC 20000 — capacity management process',
      'Google SRE — capacity planning and demand forecasting',
    ],
    'Captures budget integration, procurement lead time, and rightsizing decisions produced by the capacity review.',
  )
  @Form([
    Field(
      'budgetPlanningIntegration',
      bool,
      'Budget Planning Integration',
      hint: 'Capacity forecasts feed into budget cycles',
    ),
    Field(
      'procurementLeadTime',
      String,
      'Procurement Lead Time',
      hint: 'Time to provision new resources',
    ),
    Field(
      'rightsizingReview',
      bool,
      'Rightsizing Review',
      hint: 'Periodic over-provisioning review',
    ),
    Field('notes', String, 'Notes', hint: 'Additional capacity review notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? planning;
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
class TechnicalSecurityRequirements extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// 8.8.1. IT Security Standards.
  @SerializationOrder(1)
  ItSecurityStandardsSection itSecurityStandards = ItSecurityStandardsSection();

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
class ItSecurityStandardsSection extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of IT security standards strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Security standards and frameworks — contains 0+× SecurityStandard.
  @StandardReferences([
    'ISO/IEC 27001 — information security management system',
  ], 'The catalog of security standards and frameworks the system conforms to.')
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
class SecurityStandardEntry extends DocSpecsSection {
  @Form([
    Field(
      'standardName',
      String,
      'Standard Name',
      required: true,
      hint: 'E.g., OWASP Top 10, ISO 27001, SOC 2, NIST CSF',
    ),
    Field(
      'standardVersion',
      String,
      'Standard Version',
      hint: 'Version or year of the standard',
    ),
    Field(
      'standardType',
      String,
      'Standard Type',
      hint: 'Framework, Certification, Guideline, Benchmark',
    ),
    Field(
      'issuingBody',
      String,
      'Issuing Body',
      hint: 'Organization that publishes the standard',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Applicability and regulatory scope.
  @SectionId('SESTENSC')
  @StandardReferences(
    [
      'ISO/IEC 27001 — information security management system',
      'NIST SP 800-53 — security and privacy controls',
    ],
    'The applicability scope and regulatory drivers that make a security standard relevant.',
  )
  @Form([
    Field(
      'applicabilityScope',
      String,
      'Applicability Scope',
      hint: 'Which systems, services, or data this applies to',
    ),
    Field(
      'mandatoryOrVoluntary',
      String,
      'Mandatory / Voluntary',
      hint: 'Regulatory requirement or best-practice adoption',
    ),
    Field(
      'regulatoryDriver',
      String,
      'Regulatory Driver',
      hint: 'Regulation requiring this standard (e.g. GDPR, PCI-DSS)',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? scope;

  /// Implementation status and planning.
  @SectionId('SSEI')
  @StandardReferences(
    [
      'ISO/IEC 27001 — information security management system',
      'ISO/IEC 27002 — information security controls',
    ],
    'The implementation status, target compliance date, and gap analysis for a security standard.',
  )
  @Form([
    Field(
      'implementationStatus',
      String,
      'Implementation Status',
      hint: 'Planned, In Progress, Implemented, Certified',
    ),
    Field(
      'targetComplianceDate',
      String,
      'Target Compliance Date',
      hint: 'Date by which compliance must be achieved',
    ),
    Field(
      'controlsRequired',
      String,
      'Controls Required',
      hint: 'Key control areas to implement',
    ),
    Field(
      'gapAnalysis',
      String,
      'Gap Analysis',
      hint: 'Summary of current gaps against the standard',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? implementation;

  /// Verification and ownership.
  @SectionId('SSEV')
  @StandardReferences(
    [
      'ISO/IEC 27001 — information security management system',
      'NIST Cybersecurity Framework — identify, protect, detect, respond, recover',
    ],
    'The certification, assessment, and evidence requirements verifying conformance to a standard.',
  )
  @Form([
    Field(
      'certificationRequired',
      bool,
      'Certification Required',
      hint: 'Whether formal certification is needed',
    ),
    Field(
      'assessmentFrequency',
      String,
      'Assessment Frequency',
      hint: 'How often compliance is assessed',
    ),
    Field(
      'evidenceRequirements',
      String,
      'Evidence Requirements',
      hint: 'Documentation and artifacts to maintain',
    ),
    Field(
      'responsibleTeam',
      String,
      'Responsible Team',
      hint: 'Team/role accountable for compliance',
    ),
    Field('notes', String, 'Notes', hint: 'Additional security standard notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? verification;
}

/// Application security requirements (OWASP-based).
@StandardReferences([
  'OWASP Top 10 — web application security risks',
  'OWASP ASVS — application security verification standard',
], 'The application-level security requirements derived from OWASP standards.')
@SectionId('APSERE')
class ApplicationSecurityRequirements extends DocSpecsSection {
  @Form([
    Field(
      'owaspTop10Compliance',
      String,
      'OWASP Top 10 Compliance',
      required: true,
      hint: 'Current OWASP Top 10 version addressed',
    ),
    Field(
      'injectionPrevention',
      String,
      'Injection Prevention',
      hint: 'SQL injection, XSS, command injection measures',
    ),
    Field(
      'authenticationControls',
      String,
      'Authentication Controls',
      hint: 'Broken authentication prevention',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Core protection controls.
  @SectionId('ASRC')
  @StandardReferences(
    [
      'OWASP Top 10 — web application security risks',
      'OWASP ASVS — application security verification standard',
    ],
    'Core protections against sensitive data exposure, misconfiguration, CSRF, and SSRF, with the access-control model specified in SBP.12.',
  )
  @Form([
    Field(
      'sensitiveDataExposure',
      String,
      'Sensitive Data Exposure',
      hint: 'Encryption, masking, tokenization',
    ),
    Field(
      'accessControlEnforcement',
      String,
      'Access Control Enforcement',
      hint: 'Broken access control prevention',
    ),
    Field(
      'securityMisconfiguration',
      String,
      'Security Misconfiguration',
      hint: 'Default credentials, open ports, debug mode',
    ),
    Field(
      'csrfProtection',
      String,
      'CSRF Protection',
      hint: 'Cross-site request forgery prevention',
    ),
    Field(
      'ssrfProtection',
      String,
      'SSRF Protection',
      hint: 'Server-side request forgery prevention',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? controls;

  /// Input and output validation.
  @SectionId('ASRV')
  @StandardReferences(
    [
      'OWASP Top 10 — web application security risks',
      'OWASP ASVS — application security verification standard',
    ],
    'Input validation, output encoding, and file upload security controls for the application.',
  )
  @Form([
    Field(
      'inputValidationStrategy',
      String,
      'Input Validation Strategy',
      hint: 'Whitelist, sanitization, encoding',
    ),
    Field(
      'outputEncoding',
      String,
      'Output Encoding',
      hint: 'HTML, URL, JavaScript encoding',
    ),
    Field(
      'fileUploadSecurity',
      String,
      'File Upload Security',
      hint: 'File type, size, malware scanning',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? validation;

  /// API and browser-facing protections.
  @SectionId('ASRA')
  @StandardReferences(
    [
      'OWASP Top 10 — web application security risks',
      'OWASP ASVS — application security verification standard',
    ],
    'Protections for APIs and browsers including API security standards, rate limiting, and content security policy.',
  )
  @Form([
    Field(
      'apiSecurityStandard',
      String,
      'API Security Standard',
      hint: 'OWASP API Security Top 10 measures',
    ),
    Field(
      'rateLimiting',
      String,
      'Rate Limiting',
      hint: 'API rate limiting and throttling',
    ),
    Field(
      'contentSecurityPolicy',
      String,
      'Content Security Policy',
      hint: 'CSP headers and directives',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional application security notes',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? api;
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
class InfrastructureSecurityHardening extends DocSpecsSection {
  @Form([
    Field(
      'osHardeningBaseline',
      String,
      'OS Hardening Baseline',
      required: true,
      hint: 'CIS Benchmark, DISA STIG, custom baseline',
    ),
    Field(
      'patchManagementPolicy',
      String,
      'Patch Management Policy',
      hint: 'Patching cadence, critical patch SLA',
    ),
    Field(
      'minimumInstallation',
      bool,
      'Minimum Installation',
      hint: 'Remove unnecessary packages and services',
    ),
    Field(
      'firewallRules',
      String,
      'Firewall Rules',
      hint: 'Default deny, explicit allow rules',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Container security.
  @SectionId('ISHC')
  @StandardReferences(
    [
      'CIS Benchmarks — secure configuration and hardening',
      'NIST SP 800-53 — security and privacy controls',
    ],
    'Container and orchestration hardening covering base images, scanning, and runtime security.',
  )
  @Form([
    Field(
      'containerBaseImages',
      String,
      'Container Base Images',
      hint: 'Approved base images, distroless, Alpine',
    ),
    Field(
      'containerScanning',
      String,
      'Container Scanning',
      hint: 'Image vulnerability scanning tool',
    ),
    Field(
      'containerRuntimeSecurity',
      String,
      'Container Runtime Security',
      hint: 'Read-only filesystems, non-root, capabilities',
    ),
    Field(
      'containerOrchestrationSecurity',
      String,
      'Orchestration Security',
      hint: 'K8s RBAC, network policies, pod security',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? container;

  /// Network hardening.
  @SectionId('ISHN')
  @StandardReferences(
    [
      'CIS Benchmarks — secure configuration and hardening',
      'NIST SP 800-53 — security and privacy controls',
    ],
    'Network-level hardening through segmentation, internal TLS, and DNS security policy.',
  )
  @Form([
    Field(
      'networkSegmentation',
      String,
      'Network Segmentation',
      hint: 'VPC, subnet, security group strategy',
    ),
    Field(
      'internalTlsCommunication',
      bool,
      'Internal TLS Communication',
      hint: 'Service-to-service mTLS',
    ),
    Field(
      'dnsSecurityPolicy',
      String,
      'DNS Security Policy',
      hint: 'DNSSEC, private DNS zones',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? network;

  /// Access hardening.
  @SectionId('ISHA')
  @StandardReferences(
    [
      'CIS Benchmarks — secure configuration and hardening',
      'NIST SP 800-53 — security and privacy controls',
    ],
    'Hardening of infrastructure access through SSH policy, privileged access management, and service accounts, with the access-control model specified in SBP.12.',
  )
  @Form([
    Field(
      'sshAccessPolicy',
      String,
      'SSH Access Policy',
      hint: 'Key-only auth, bastion hosts, session recording',
    ),
    Field(
      'privilegedAccessManagement',
      String,
      'Privileged Access Management',
      hint: 'PAM tool, just-in-time access',
    ),
    Field(
      'serviceAccountPolicy',
      String,
      'Service Account Policy',
      hint: 'Least privilege, rotation, naming',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional infrastructure security notes',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? access;
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
class SecurityDevelopmentLifecycle extends DocSpecsSection {
  @Form([
    Field(
      'threatModeling',
      String,
      'Threat Modeling',
      required: true,
      hint: 'STRIDE, PASTA, Attack Trees methodology',
    ),
    Field(
      'threatModelingFrequency',
      String,
      'Threat Modeling Frequency',
      hint: 'Per feature, per release, quarterly',
    ),
    Field(
      'securityDesignReview',
      bool,
      'Security Design Review',
      hint: 'Mandatory security review of architecture',
    ),
    Field(
      'securityRequirementsProcess',
      String,
      'Security Requirements Process',
      hint: 'How security requirements are gathered',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Development-phase controls.
  @SectionId('SDLD')
  @StandardReferences(
    [
      'OWASP SAMM — software assurance maturity model (secure SDLC)',
      'OWASP ASVS — application security verification standard',
    ],
    'The secure coding, static analysis, and dependency scanning controls applied during development.',
  )
  @Form([
    Field(
      'secureCodeTraining',
      String,
      'Secure Code Training',
      hint: 'Developer security training frequency',
    ),
    Field(
      'staticAnalysis',
      String,
      'Static Analysis (SAST)',
      hint: 'SAST tool and integration point',
    ),
    Field(
      'secretDetection',
      String,
      'Secret Detection',
      hint: 'Pre-commit hooks, CI scanning for secrets',
    ),
    Field(
      'dependencyScanning',
      String,
      'Dependency Scanning (SCA)',
      hint: 'SCA tool for known vulnerabilities',
    ),
    Field(
      'licenseScannerPolicy',
      String,
      'License Compliance Scanning',
      hint: 'OSS license compatibility checking',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? development;

  /// Testing-phase controls.
  @SectionId('SDLT')
  @StandardReferences(
    [
      'OWASP SAMM — software assurance maturity model (secure SDLC)',
      'OWASP ASVS — application security verification standard',
    ],
    'The dynamic, interactive, and manual security testing performed during the testing phase.',
  )
  @Form([
    Field(
      'dynamicAnalysis',
      String,
      'Dynamic Analysis (DAST)',
      hint: 'DAST tool and test frequency',
    ),
    Field(
      'interactiveAnalysis',
      String,
      'Interactive Analysis (IAST)',
      hint: 'IAST tool for runtime detection',
    ),
    Field(
      'securityTestingInCi',
      bool,
      'Security Testing in CI',
      hint: 'Automated security tests in pipeline',
    ),
    Field(
      'manualCodeReview',
      String,
      'Manual Code Review',
      hint: 'Security-focused code review process',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? testing;

  /// Release-phase controls.
  @SectionId('SDLR')
  @StandardReferences(
    [
      'OWASP SAMM — software assurance maturity model (secure SDLC)',
      'NIST SP 800-53 — security and privacy controls',
    ],
    'The security gates and change tracking applied before releasing software to production.',
  )
  @Form([
    Field(
      'preReleaseSecurityGate',
      bool,
      'Pre-Release Security Gate',
      hint: 'Security sign-off before production deploy',
    ),
    Field(
      'securityChangeLog',
      bool,
      'Security Change Log',
      hint: 'Track security-relevant changes',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional security dev lifecycle notes',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? release;
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
class VulnerabilityManagementPolicy extends DocSpecsSection {
  @Form([
    Field(
      'vulnerabilityScanningTool',
      String,
      'Vulnerability Scanning Tool',
      required: true,
      hint: 'Nessus, Qualys, Tenable, Trivy',
    ),
    Field(
      'scanFrequency',
      String,
      'Scan Frequency',
      hint: 'Daily, weekly, on each deployment',
    ),
    Field(
      'scanScope',
      String,
      'Scan Scope',
      hint: 'Infrastructure, applications, containers, dependencies',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Severity classification.
  @SectionId('VMPC')
  @StandardReferences(
    [
      'NIST SP 800-40 — enterprise patch and vulnerability management',
      'CIS Controls — critical security controls',
    ],
    'The CVSS-based severity classification and patch SLA targets for each vulnerability level.',
  )
  @Form([
    Field(
      'severityClassification',
      String,
      'Severity Classification',
      hint: 'CVSS-based: Critical, High, Medium, Low',
    ),
    Field(
      'criticalVulnSla',
      String,
      'Critical Vulnerability SLA',
      hint: 'Max time to patch critical (e.g. 24h)',
    ),
    Field(
      'highVulnSla',
      String,
      'High Vulnerability SLA',
      hint: 'Max time to patch high (e.g. 7d)',
    ),
    Field(
      'mediumVulnSla',
      String,
      'Medium Vulnerability SLA',
      hint: 'Max time to patch medium (e.g. 30d)',
    ),
    Field(
      'lowVulnSla',
      String,
      'Low Vulnerability SLA',
      hint: 'Max time to patch low (e.g. 90d)',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? classification;

  /// Remediation process.
  @SectionId('VMPP')
  @StandardReferences(
    [
      'NIST SP 800-40 — enterprise patch and vulnerability management',
      'NIST SP 800-53 — security and privacy controls',
    ],
    'The remediation, risk-acceptance, and zero-day response workflow for tracked vulnerabilities.',
  )
  @Form([
    Field(
      'vulnerabilityTracking',
      String,
      'Vulnerability Tracking',
      hint: 'Jira, dedicated vulnerability tool',
    ),
    Field(
      'riskAcceptanceProcess',
      String,
      'Risk Acceptance Process',
      hint: 'When and how to accept residual risk',
    ),
    Field(
      'exceptionProcess',
      String,
      'Exception Process',
      hint: 'Temporary exception workflow and approvals',
    ),
    Field(
      'zeroDayResponsePlan',
      String,
      'Zero-Day Response Plan',
      hint: 'Emergency response for zero-day exploits',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? process;

  /// Reporting and disclosure.
  @SectionId('VMPR')
  @StandardReferences(
    [
      'NIST SP 800-40 — enterprise patch and vulnerability management',
      'OWASP SAMM — software assurance maturity model (secure SDLC)',
    ],
    'How vulnerability findings are reported and how responsible disclosure is handled.',
  )
  @Form([
    Field(
      'vulnerabilityReporting',
      String,
      'Vulnerability Reporting',
      hint: 'Dashboard, weekly report, executive summary',
    ),
    Field(
      'responsibleDisclosure',
      String,
      'Responsible Disclosure',
      hint: 'Bug bounty, security.txt, disclosure policy',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional vulnerability management notes',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? reporting;
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
class IncidentResponsePlan extends DocSpecsSection {
  @Form([
    Field(
      'incidentSeverityLevels',
      String,
      'Incident Severity Levels',
      required: true,
      hint: 'SEV1-SEV4 definitions for security incidents',
    ),
    Field(
      'incidentCategories',
      String,
      'Incident Categories',
      hint: 'Data breach, unauthorized access, malware, DDoS',
    ),
    Field(
      'detectionMechanisms',
      String,
      'Detection Mechanisms',
      hint: 'SIEM, IDS/IPS, anomaly detection, user reports',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Response process.
  @SectionId('IRPP')
  @StandardReferences(
    [
      'NIST Cybersecurity Framework — identify, protect, detect, respond, recover',
      'NIST SP 800-53 — security and privacy controls',
    ],
    'The containment, eradication, and recovery procedures followed when responding to an incident.',
  )
  @Form([
    Field(
      'initialResponseSla',
      String,
      'Initial Response SLA',
      hint: 'Time to acknowledge and begin triage',
    ),
    Field(
      'containmentProcedure',
      String,
      'Containment Procedure',
      hint: 'Steps to isolate affected systems',
    ),
    Field(
      'eradicationProcedure',
      String,
      'Eradication Procedure',
      hint: 'Steps to remove threat from systems',
    ),
    Field(
      'recoveryProcedure',
      String,
      'Recovery Procedure',
      hint: 'Steps to restore normal operations',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? process;

  /// Communication requirements.
  @SectionId('IRPC')
  @StandardReferences(
    [
      'NIST Cybersecurity Framework — identify, protect, detect, respond, recover',
      'ISO/IEC 27001 — information security management system',
    ],
    'Notification, escalation, and external communication requirements during a security incident.',
  )
  @Form([
    Field(
      'notificationRequirements',
      String,
      'Notification Requirements',
      hint: 'Regulatory breach notification timelines',
    ),
    Field(
      'internalEscalation',
      String,
      'Internal Escalation',
      hint: 'Escalation paths and contacts',
    ),
    Field(
      'externalCommunication',
      String,
      'External Communication',
      hint: 'Customer notification, press, regulators',
    ),
    Field(
      'legalCounselEngagement',
      String,
      'Legal Counsel Engagement',
      hint: 'When to engage legal team',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? communication;

  /// Post-incident activities.
  @SectionId('IRPPI')
  @StandardReferences(
    [
      'NIST Cybersecurity Framework — identify, protect, detect, respond, recover',
      'ISO/IEC 27001 — information security management system',
    ],
    'Post-incident review and lessons-learned activities that feed findings back into prevention.',
  )
  @Form([
    Field(
      'postIncidentReview',
      String,
      'Post-Incident Review',
      hint: 'Blameless retrospective process',
    ),
    Field(
      'lessonsLearnedProcess',
      String,
      'Lessons Learned Process',
      hint: 'How findings are fed back into prevention',
    ),
    Field(
      'incidentDocumentation',
      String,
      'Incident Documentation',
      hint: 'What to document and retention period',
    ),
    Field('notes', String, 'Notes', hint: 'Additional incident response notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? postIncident;
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
class DataProtectionAndPrivacySection extends DocSpecsSection {
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
  @override
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
  DataSubjectRightsManagement dataSubjectRights = DataSubjectRightsManagement();

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
class PrivacyRegulationCompliance extends DocSpecsSection {
  @Form([
    Field(
      'applicableRegulations',
      String,
      'Applicable Regulations',
      required: true,
      hint: 'GDPR, CCPA/CPRA, LGPD, PIPA, PIPEDA, PDPA, etc.',
    ),
    Field(
      'primaryJurisdiction',
      String,
      'Primary Jurisdiction',
      required: true,
      hint: 'Main legal jurisdiction for data processing',
    ),
    Field(
      'additionalJurisdictions',
      String,
      'Additional Jurisdictions',
      hint: 'Other jurisdictions where data subjects reside',
    ),
    Field(
      'regulatoryAuthority',
      String,
      'Supervisory Authority',
      hint: 'Lead data protection authority for GDPR purposes',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// GDPR-specific requirements.
  @SectionId('PRCG')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'ISO/IEC 27701 — privacy information management system',
    ],
    'Lawful basis, controller or processor role, and supervisory authority under GDPR.',
  )
  @Form([
    Field(
      'gdprLawfulBasis',
      String,
      'GDPR Lawful Basis',
      hint:
          'Consent, contract, legal obligation, vital interests, public task, legitimate interests',
    ),
    Field(
      'gdprDataControllerRole',
      String,
      'Data Controller Role',
      required: true,
      hint: 'Whether organization acts as controller or processor',
    ),
    Field(
      'gdprRepresentative',
      String,
      'EU Representative',
      hint: 'EU-based representative if organization is outside EU',
    ),
    Field(
      'gdprLeadSupervisoryAuthority',
      String,
      'Lead Supervisory Authority',
      hint: 'Lead supervisory authority for cross-border processing',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? gdpr;

  /// Data Protection Officer details.
  @SectionId('PRCD')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'ISO/IEC 27701 — privacy information management system',
    ],
    'Whether a Data Protection Officer is required and their contact and responsibilities.',
  )
  @Form([
    Field(
      'dpoRequired',
      String,
      'DPO Required',
      hint: 'Whether a Data Protection Officer is required',
    ),
    Field(
      'dpoContactDetails',
      String,
      'DPO Contact Details',
      hint: 'Name, email, and reporting line of DPO',
    ),
    Field(
      'dpoResponsibilities',
      String,
      'DPO Responsibilities',
      hint: 'Monitoring compliance, advising on DPIA, liaison with authority',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? dpo;

  /// Records and documentation.
  @SectionId('PRCR')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'ISO/IEC 27701 — privacy information management system',
    ],
    'Records of processing activities, transparency notices, and staff training.',
  )
  @Form([
    Field(
      'recordsOfProcessing',
      String,
      'Records of Processing Activities',
      required: true,
      hint: 'ROPA maintenance process — Article 30 GDPR',
    ),
    Field(
      'privacyPolicyRequirements',
      String,
      'Privacy Policy Requirements',
      hint: 'Transparency notices, layered privacy policies',
    ),
    Field(
      'dataProtectionTraining',
      String,
      'Data Protection Training',
      hint: 'Staff training frequency, content, and certification',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? records;

  /// Cross-border transfer controls.
  @SectionId('PRCT')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'ISO/IEC 27701 — privacy information management system',
    ],
    'Cross-border transfer mechanisms and impact assessments for third-country processing.',
  )
  @Form([
    Field(
      'crossBorderTransferMechanism',
      String,
      'Transfer Mechanism',
      hint:
          'Standard contractual clauses, adequacy decisions, binding corporate rules',
    ),
    Field(
      'transferImpactAssessment',
      String,
      'Transfer Impact Assessment',
      hint: 'Assessment of third-country legal framework, Schrems II',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional regulation compliance notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? transfers;
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
class DataResidencyRequirements extends DocSpecsSection {
  @Form([
    // Storage location
    Field(
      'primaryDataRegion',
      String,
      'Primary Data Region',
      required: true,
      hint: 'Geographic region for primary data storage',
    ),
    Field(
      'allowedDataRegions',
      String,
      'Allowed Data Regions',
      hint: 'All permitted regions for data storage and processing',
    ),
    Field(
      'prohibitedDataRegions',
      String,
      'Prohibited Data Regions',
      hint: 'Regions where data must never be stored or processed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Governing regulation and sovereignty constraints.
  @SectionId('DRRS')
  @StandardReferences(
    [
      'ISO/IEC 27018 — protection of PII in public clouds',
      'GDPR — data protection by design and by default (Article 25)',
    ],
    'Sovereignty laws, key location, and sovereign cloud provider constraints.',
  )
  @Form([
    Field(
      'dataResidencyRegulation',
      String,
      'Residency Regulation',
      hint: 'Specific laws mandating data residency (e.g. Russia, China)',
    ),
    Field(
      'dataSovereigntyRequirements',
      String,
      'Sovereignty Requirements',
      hint: 'Government access restrictions, national security considerations',
    ),
    Field(
      'encryptionKeyLocation',
      String,
      'Encryption Key Location',
      required: true,
      hint: 'Where encryption keys are stored and managed geographically',
    ),
    Field(
      'cloudProviderRequirements',
      String,
      'Cloud Provider Requirements',
      hint: 'Sovereign cloud requirements, government-certified providers',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? sovereignty;

  /// Backup, replication, and CDN placement rules.
  @SectionId('DARERERE')
  @StandardReferences(
    [
      'ISO/IEC 27018 — protection of PII in public clouds',
      'GDPR — storage limitation and data minimisation (Article 5)',
    ],
    'Geographic constraints on backups, cross-region replication, and CDN caching.',
  )
  @Form([
    Field(
      'backupDataResidency',
      String,
      'Backup Data Residency',
      hint: 'Geographic constraints for backup and disaster recovery data',
    ),
    Field(
      'replicationConstraints',
      String,
      'Replication Constraints',
      hint: 'Cross-region replication limitations and rules',
    ),
    Field(
      'cdnDataConstraints',
      String,
      'CDN Data Constraints',
      hint: 'Content delivery network caching location restrictions',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? replication;

  /// Verification and transparency requirements.
  @SectionId('DRRV')
  @StandardReferences(
    [
      'ISO/IEC 27018 — protection of PII in public clouds',
      'GDPR — data protection by design and by default (Article 25)',
    ],
    'Verification, provider certifications, and transparency about where data is stored.',
  )
  @Form([
    Field(
      'residencyVerification',
      String,
      'Residency Verification',
      hint: 'How data residency compliance is verified and audited',
    ),
    Field(
      'providerCertifications',
      String,
      'Provider Certifications',
      hint: 'Cloud provider certifications (ISO 27001, SOC 2, C5, ENS)',
    ),
    Field(
      'dataLocationTransparency',
      String,
      'Data Location Transparency',
      hint: 'How data subjects are informed about storage locations',
    ),
    Field('notes', String, 'Notes', hint: 'Additional data residency notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? verification;
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
class ConsentManagementRequirements extends DocSpecsSection {
  @Form([
    Field(
      'consentCollectionMethod',
      String,
      'Collection Method',
      required: true,
      hint:
          'How consent is obtained: opt-in checkboxes, cookie banners, in-app dialogs',
    ),
    Field(
      'consentGranularity',
      String,
      'Consent Granularity',
      required: true,
      hint: 'Per-purpose consent, bundled consent, tiered consent model',
    ),
    Field(
      'consentRecordStorage',
      String,
      'Consent Record Storage',
      required: true,
      hint: 'How consent records are stored with timestamp and version',
    ),
    Field(
      'consentWithdrawalProcess',
      String,
      'Withdrawal Process',
      required: true,
      hint: 'How users can withdraw consent — must be as easy as giving it',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Collection requirements.
  @SectionId('CMRC')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'ISO/IEC 29100 — privacy framework',
    ],
    'Plain-language, double opt-in, and age-verification requirements for collecting consent.',
  )
  @Form([
    Field(
      'consentLanguage',
      String,
      'Consent Language',
      hint:
          'Plain language requirements, multi-language support, reading level',
    ),
    Field(
      'doubleOptIn',
      String,
      'Double Opt-In',
      hint: 'Whether double opt-in is required (e.g. email verification)',
    ),
    Field(
      'ageVerification',
      String,
      'Age Verification',
      hint:
          'Minimum age requirements, parental consent for minors (COPPA, GDPR Art. 8)',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? collection;

  /// Consent record storage rules.
  @SectionId('COMAREST')
  @StandardReferences([
    'GDPR — storage limitation and data minimisation (Article 5)',
    'ISO/IEC 27701 — privacy information management system',
  ], 'Versioning and retention of consent proof records after withdrawal.')
  @Form([
    Field(
      'consentVersioning',
      String,
      'Consent Versioning',
      hint: 'Tracking consent policy versions and re-consent triggers',
    ),
    Field(
      'consentProofRetention',
      String,
      'Consent Proof Retention',
      hint: 'How long consent proof is retained after withdrawal',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? storage;

  /// Preference management workflow.
  @SectionId('CMRM')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'ISO/IEC 27701 — privacy information management system',
    ],
    'Self-service preference management and propagation of consent changes to downstream systems.',
  )
  @Form([
    Field(
      'consentPreferenceCenter',
      String,
      'Preference Center',
      hint: 'Self-service UI for managing consent preferences',
    ),
    Field(
      'consentPropagation',
      String,
      'Consent Propagation',
      hint:
          'How consent changes propagate to downstream systems and processors',
    ),
    Field(
      'consentSynchronization',
      String,
      'Cross-Platform Sync',
      hint: 'Synchronizing consent across web, mobile, and third parties',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? management;

  /// Cookie and tracking rules.
  @SectionId('CMRT')
  @StandardReferences([
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'CCPA/CPRA — consumer privacy rights',
  ], 'Consent rules for cookies, tracking pixels, and third-party sharing.')
  @Form([
    Field(
      'cookieConsentRequirements',
      String,
      'Cookie Consent',
      hint: 'Cookie categories (essential, functional, analytics, marketing)',
    ),
    Field(
      'trackingConsentRequirements',
      String,
      'Tracking Consent',
      hint:
          'Analytics, advertising pixels, fingerprinting consent requirements',
    ),
    Field(
      'thirdPartyConsentSharing',
      String,
      'Third-Party Consent Sharing',
      hint: 'How consent status is communicated to third-party integrations',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? tracking;

  /// Compliance evidence and reporting.
  @SectionId('COMARECO')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'ISO/IEC 27701 — privacy information management system',
    ],
    'Audit trails and reporting that evidence consent compliance for regulators.',
  )
  @Form([
    Field(
      'consentAuditTrail',
      String,
      'Consent Audit Trail',
      hint: 'Audit logging of all consent events for regulatory evidence',
    ),
    Field(
      'consentComplianceReporting',
      String,
      'Compliance Reporting',
      hint: 'Consent metrics, dashboards, and regulatory reports',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional consent management notes',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? compliance;
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
class DataSubjectRightsManagement extends DocSpecsSection {
  @Form([
    Field(
      'rightOfAccessProcess',
      String,
      'Right of Access Process',
      required: true,
      hint: 'How data subjects request and receive copies of their data',
    ),
    Field(
      'accessRequestTimeline',
      String,
      'Access Request Timeline',
      required: true,
      hint: 'Response timeline — GDPR requires within 1 month',
    ),
    Field(
      'identityVerification',
      String,
      'Identity Verification',
      required: true,
      hint: 'How requester identity is verified before disclosure',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Access and rectification handling.
  @SectionId('DSRMA')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'CCPA/CPRA — consumer privacy rights',
    ],
    'Defines access data format, rectification process, and propagation of corrections.',
  )
  @Form([
    Field(
      'accessDataFormat',
      String,
      'Access Data Format',
      hint: 'Format for providing data (structured, machine-readable, PDF)',
    ),
    Field(
      'rectificationProcess',
      String,
      'Rectification Process',
      hint: 'How data subjects request correction of inaccurate personal data',
    ),
    Field(
      'rectificationPropagation',
      String,
      'Rectification Propagation',
      hint: 'How corrections propagate to recipients of the data',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? access;

  /// Erasure handling.
  @SectionId('DSRME')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'CCPA/CPRA — consumer privacy rights',
    ],
    'Defines erasure process, scope, exceptions, and verification across systems.',
  )
  @Form([
    Field(
      'erasureProcess',
      String,
      'Right to Erasure Process',
      required: true,
      hint: 'How erasure requests are processed — "right to be forgotten"',
    ),
    Field(
      'erasureScope',
      String,
      'Erasure Scope',
      hint: 'What data is erased: active records, backups, logs, analytics',
    ),
    Field(
      'erasureExceptions',
      String,
      'Erasure Exceptions',
      hint: 'Legal retention obligations that override erasure (tax, fraud)',
    ),
    Field(
      'erasureVerification',
      String,
      'Erasure Verification',
      hint: 'How complete erasure is verified across all systems',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? erasure;

  /// Portability handling.
  @SectionId('DSRMP')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'CCPA/CPRA — consumer privacy rights',
    ],
    'Defines structured, machine-readable data export and direct-transfer support.',
  )
  @Form([
    Field(
      'portabilityProcess',
      String,
      'Data Portability Process',
      required: true,
      hint: 'How data is exported in structured, machine-readable format',
    ),
    Field(
      'portabilityFormat',
      String,
      'Portability Format',
      hint: 'Export formats: JSON, CSV, XML, API-based transfer',
    ),
    Field(
      'portabilityDirectTransfer',
      String,
      'Direct Transfer',
      hint: 'Whether direct controller-to-controller transfer is supported',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? portability;

  /// Restriction and objection handling.
  @SectionId('DSRMR')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'CCPA/CPRA — consumer privacy rights',
    ],
    'Defines how processing restriction and objections to processing are handled.',
  )
  @Form([
    Field(
      'restrictionProcess',
      String,
      'Restriction of Processing',
      hint: 'How processing restriction is applied while disputes are resolved',
    ),
    Field(
      'objectionProcess',
      String,
      'Right to Object',
      hint:
          'How objections to processing are handled (direct marketing, profiling)',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? restriction;

  /// Automated decision safeguards.
  @SectionId('DASURIMAAU')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'NIST Privacy Framework — govern, control, communicate, protect',
    ],
    'Defines safeguards and human review for automated decisions with significant effects.',
  )
  @Form([
    Field(
      'automatedDecisionMaking',
      String,
      'Automated Decision-Making',
      hint:
          'Safeguards for automated decisions with legal or significant effects',
    ),
    Field(
      'humanReviewProcess',
      String,
      'Human Review Process',
      hint: 'Process for requesting human review of automated decisions',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? automation;

  /// Operational workflow and tracking.
  @SectionId('DSRMO')
  @StandardReferences([
    'GDPR — data subject rights and lawful processing (EU 2016/679)',
    'CCPA/CPRA — consumer privacy rights',
  ], 'Defines the end-to-end DSAR workflow, tracking, and completion metrics.')
  @Form([
    Field(
      'dsarWorkflow',
      String,
      'DSAR Workflow',
      hint: 'Data Subject Access Request end-to-end workflow and tooling',
    ),
    Field(
      'dsarTracking',
      String,
      'DSAR Tracking',
      hint: 'Tracking system for requests, SLAs, and completion metrics',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional data subject rights notes',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? operations;
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
class PrivacyImpactAssessmentProcess extends DocSpecsSection {
  @Form([
    Field(
      'dpiaThreshold',
      String,
      'DPIA Threshold',
      required: true,
      hint:
          'Criteria triggering a DPIA: new processing, high risk, large-scale profiling',
    ),
    Field(
      'dpiaScreeningProcess',
      String,
      'Screening Process',
      hint: 'Initial screening to determine if full DPIA is needed',
    ),
    Field(
      'mandatoryDpiaScenarios',
      String,
      'Mandatory DPIA Scenarios',
      hint:
          'Systematic monitoring, sensitive data at scale, automated decisions',
    ),
    Field(
      'dpiaMethodology',
      String,
      'DPIA Methodology',
      required: true,
      hint: 'Framework used: ICO template, CNIL PIA tool, NIST privacy',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Assessment process inputs.
  @SectionId('PIAPA')
  @StandardReferences(
    [
      'GDPR — data protection by design and by default (Article 25)',
      'NIST Privacy Framework — govern, control, communicate, protect',
    ],
    'Defines DPIA stakeholders, data flow mapping, and risk assessment criteria.',
  )
  @Form([
    Field(
      'dpiaStakeholders',
      String,
      'DPIA Stakeholders',
      hint:
          'Who participates: DPO, engineering, legal, business, external advisor',
    ),
    Field(
      'dataFlowMapping',
      String,
      'Data Flow Mapping',
      hint:
          'Documenting data flows, storage, access, and sharing for each processing activity',
    ),
    Field(
      'riskAssessmentCriteria',
      String,
      'Risk Assessment Criteria',
      hint: 'Likelihood and severity matrix, residual risk thresholds',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? assessment;

  /// Mitigation measures.
  @SectionId('PIAPM')
  @StandardReferences(
    [
      'GDPR — data protection by design and by default (Article 25)',
      'ISO/IEC 29100 — privacy framework',
      'NIST Privacy Framework — govern, control, communicate, protect',
    ],
    'Defines privacy-by-design, minimization, and de-identification measures that reduce risk.',
  )
  @Form([
    Field(
      'mitigationMeasures',
      String,
      'Mitigation Measures',
      hint: 'Technical and organizational measures to reduce identified risks',
    ),
    Field(
      'privacyByDesign',
      String,
      'Privacy by Design',
      required: true,
      hint:
          'How privacy is embedded in system design from inception (Art. 25 GDPR)',
    ),
    Field(
      'privacyByDefault',
      String,
      'Privacy by Default',
      hint:
          'Default settings protect privacy — minimal data, shortest retention',
    ),
    Field(
      'dataMinimization',
      String,
      'Data Minimization',
      hint:
          'Limiting collection to what is necessary for the specified purpose',
    ),
    Field(
      'pseudonymization',
      String,
      'Pseudonymization',
      hint: 'Techniques applied: tokenization, hashing, key-coded data',
    ),
    Field(
      'anonymization',
      String,
      'Anonymization',
      hint:
          'Techniques for irreversible de-identification: k-anonymity, differential privacy',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? mitigation;

  /// Review and approval workflow.
  @SectionId('PIAPR')
  @StandardReferences(
    [
      'GDPR — data protection by design and by default (Article 25)',
      'NIST Privacy Framework — govern, control, communicate, protect',
    ],
    'Defines DPIA approval, supervisory consultation, and periodic review cadence.',
  )
  @Form([
    Field(
      'dpiaApprovalProcess',
      String,
      'Approval Process',
      hint: 'Who reviews and approves the DPIA before processing begins',
    ),
    Field(
      'supervisoryConsultation',
      String,
      'Supervisory Consultation',
      hint:
          'When prior consultation with the supervisory authority is required',
    ),
    Field(
      'dpiaReviewFrequency',
      String,
      'Review Frequency',
      hint: 'How often existing DPIAs are reviewed and updated',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional privacy impact assessment notes',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? review;
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
class DataProcessingAgreementRequirements extends DocSpecsSection {
  @Form([
    Field(
      'dpaTemplate',
      String,
      'DPA Template',
      required: true,
      hint: 'Standard data processing agreement template used',
    ),
    Field(
      'processorObligations',
      String,
      'Processor Obligations',
      required: true,
      hint:
          'Article 28 GDPR: security measures, sub-processing, audits, deletion',
    ),
    Field(
      'processingPurposeLimitation',
      String,
      'Purpose Limitation',
      required: true,
      hint: 'Ensuring data is processed only for specified purposes',
    ),
    Field(
      'auditRights',
      String,
      'Audit Rights',
      required: true,
      hint: 'Controller right to audit processor premises and practices',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Agreement-management details.
  @SectionId('DPARM')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'ISO/IEC 27701 — privacy information management system',
    ],
    'Defines how sub-processors are approved, monitored, and communicated to controllers.',
  )
  @Form([
    Field(
      'subProcessorManagement',
      String,
      'Sub-Processor Management',
      hint: 'How sub-processors are approved, listed, and monitored',
    ),
    Field(
      'subProcessorNotification',
      String,
      'Sub-Processor Notification',
      hint: 'Process for notifying controllers of sub-processor changes',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? management;

  /// Data-handling details.
  @SectionId('DPARH')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'ISO/IEC 27701 — privacy information management system',
    ],
    'Defines retention, return on termination, and confidentiality obligations for processors.',
  )
  @Form([
    Field(
      'dataRetentionInDpa',
      String,
      'Retention in DPA',
      hint: 'Retention periods and deletion/return obligations',
    ),
    Field(
      'dataReturnOnTermination',
      String,
      'Data Return on Termination',
      hint: 'Data return or certified destruction on contract end',
    ),
    Field(
      'confidentialityObligations',
      String,
      'Confidentiality Obligations',
      hint: 'Staff confidentiality commitments and access restrictions',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? handling;

  /// Security and audit details.
  @SectionId('DPARS')
  @StandardReferences(
    [
      'GDPR — data breach notification (Articles 33-34)',
      'ISO/IEC 27701 — privacy information management system',
    ],
    'Defines processor security measures, breach notification, and compliance certification.',
  )
  @Form([
    Field(
      'securityMeasuresInDpa',
      String,
      'Security Measures',
      hint: 'Technical and organizational measures required from processors',
    ),
    Field(
      'breachNotificationInDpa',
      String,
      'Breach Notification',
      hint:
          'Processor obligation to notify controller of breaches without undue delay',
    ),
    Field(
      'complianceCertification',
      String,
      'Compliance Certification',
      hint: 'Processor certifications accepted as audit evidence',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? security;

  /// International-transfer details.
  @SectionId('DPART')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'ISO/IEC 27018 — protection of PII in public clouds',
    ],
    'Defines contractual clauses and mechanisms for international personal data transfers.',
  )
  @Form([
    Field(
      'internationalTransferClauses',
      String,
      'International Transfer Clauses',
      hint: 'Standard contractual clauses or other mechanisms in the DPA',
    ),
    Field(
      'governingLaw',
      String,
      'Governing Law',
      hint: 'Applicable law and jurisdiction for DPA disputes',
    ),
    Field(
      'liabilityAndIndemnification',
      String,
      'Liability',
      hint: 'Liability allocation and indemnification provisions',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional data processing agreement notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? transfers;
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
class DataProtectionClassification extends DocSpecsSection {
  @Form([
    Field(
      'classificationLevels',
      String,
      'Classification Levels',
      required: true,
      hint: 'Public, Internal, Confidential, Restricted, Top Secret',
    ),
    Field(
      'personalDataCategories',
      String,
      'Personal Data Categories',
      required: true,
      hint: 'Basic identity, contact, financial, health, biometric, genetic',
    ),
    Field(
      'sensitiveDataCategories',
      String,
      'Sensitive Data Categories',
      hint:
          'Special categories Art. 9 GDPR: race, religion, health, sexual orientation, political opinion',
    ),
    Field(
      'classificationResponsibility',
      String,
      'Classification Responsibility',
      hint: 'Who is responsible for classifying data',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Handling rules.
  @SectionId('DPCH')
  @StandardReferences(
    [
      'ISO/IEC 27018 — protection of PII in public clouds',
      'ISO/IEC 27701 — privacy information management system',
    ],
    'Defines encryption, access control, and logging requirements per classification level.',
  )
  @Form([
    Field(
      'encryptionAtRest',
      String,
      'Encryption at Rest',
      required: true,
      hint: 'Encryption requirements per classification level (AES-256)',
    ),
    Field(
      'encryptionInTransit',
      String,
      'Encryption in Transit',
      required: true,
      hint: 'TLS 1.2+, mTLS, certificate requirements',
    ),
    Field(
      'accessControlByClassification',
      String,
      'Access Control',
      hint: 'Access restrictions mapped to classification levels',
    ),
    Field(
      'loggingByClassification',
      String,
      'Logging Requirements',
      hint: 'Audit logging requirements per classification level',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? handling;

  /// Retention and disposal rules.
  @SectionId('DPCR')
  @StandardReferences(
    [
      'GDPR — data subject rights and lawful processing (EU 2016/679)',
      'ISO/IEC 27701 — privacy information management system',
    ],
    'Defines retention periods, secure disposal, and exceptions per data category.',
  )
  @Form([
    Field(
      'retentionPolicyByCategory',
      String,
      'Retention Policy',
      required: true,
      hint: 'Retention periods per data category and legal basis',
    ),
    Field(
      'disposalProcedure',
      String,
      'Disposal Procedure',
      hint: 'Secure deletion, shredding, crypto-erasure per classification',
    ),
    Field(
      'retentionExceptions',
      String,
      'Retention Exceptions',
      hint: 'Legal holds, regulatory overrides, litigation preservation',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? retention;

  /// Masking and de-identification rules.
  @SectionId('DPCM')
  @StandardReferences(
    [
      'ISO/IEC 27018 — protection of PII in public clouds',
      'GDPR — data protection by design and by default (Article 25)',
    ],
    'Defines masking, tokenization, and de-identification standards for personal data.',
  )
  @Form([
    Field(
      'dataMaskingRules',
      String,
      'Data Masking Rules',
      hint: 'Masking rules for non-production environments, logs, and reports',
    ),
    Field(
      'tokenizationRequirements',
      String,
      'Tokenization Requirements',
      hint: 'Payment card, PII tokenization approach (PCI DSS)',
    ),
    Field(
      'deIdentificationStandards',
      String,
      'De-Identification Standards',
      hint: 'HIPAA Safe Harbor, Expert Determination, k-anonymity',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? masking;

  /// Incident handling.
  @SectionId('DPCI')
  @StandardReferences(
    [
      'GDPR — data breach notification (Articles 33-34)',
      'ISO/IEC 27701 — privacy information management system',
    ],
    'Maps data classification to breach severity and defines exfiltration-prevention controls.',
  )
  @Form([
    Field(
      'breachClassificationMatrix',
      String,
      'Breach Classification',
      hint: 'Mapping data classification to breach severity and response',
    ),
    Field(
      'dataLossPreventionControls',
      String,
      'DLP Controls',
      hint: 'Technical controls to prevent unauthorized data exfiltration',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional data protection classification notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? incident;
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
class SecurityAuditRequirementsSection extends DocSpecsSection {
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
  @override
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
class PenetrationTestingRequirements extends DocSpecsSection {
  @Form([
    Field(
      'pentestScope',
      String,
      'Penetration Test Scope',
      required: true,
      hint:
          'External network, internal network, web application, mobile app, API',
    ),
    Field(
      'pentestMethodology',
      String,
      'Testing Methodology',
      required: true,
      hint: 'OWASP WSTG, PTES, OSSTMM, NIST SP 800-115',
    ),
    Field(
      'pentestApproach',
      String,
      'Testing Approach',
      hint: 'Black box, grey box, white box, or combination',
    ),
    Field(
      'pentestProvider',
      String,
      'Testing Provider',
      hint: 'Internal red team, external firm, or both',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Frequency and scheduling.
  @SectionId('PTRS')
  @StandardReferences(
    [
      'PCI DSS — logging, monitoring, and regular security testing',
      'OWASP WSTG — web security testing guide (penetration testing)',
    ],
    'Frequency, retesting, and trigger-based scheduling for penetration testing.',
  )
  @Form([
    Field(
      'pentestFrequency',
      String,
      'Testing Frequency',
      required: true,
      hint: 'Annual, semi-annual, quarterly, after major releases',
    ),
    Field(
      'retestRequirements',
      String,
      'Retest Requirements',
      hint: 'When retesting is required after remediation',
    ),
    Field(
      'triggerBasedTesting',
      String,
      'Trigger-Based Testing',
      hint:
          'Events triggering unscheduled tests: major changes, incidents, new integrations',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? scheduling;

  /// Execution rules.
  @SectionId('PTRE')
  @StandardReferences(
    [
      'OWASP WSTG — web security testing guide (penetration testing)',
      'OWASP ASVS — verification and security testing requirements',
    ],
    'Execution rules for penetration testing including environment and rules of engagement.',
  )
  @Form([
    Field(
      'testingEnvironment',
      String,
      'Testing Environment',
      hint: 'Production, staging, dedicated pentest environment',
    ),
    Field(
      'rulesOfEngagement',
      String,
      'Rules of Engagement',
      hint: 'Boundaries, excluded systems, testing windows, escalation',
    ),
    Field(
      'socialEngineeringScope',
      String,
      'Social Engineering Scope',
      hint: 'Phishing, vishing, physical access testing if applicable',
    ),
    Field(
      'dosTestingAllowed',
      String,
      'DoS Testing Allowed',
      hint: 'Whether denial-of-service testing is in scope',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? execution;

  /// Reporting and remediation.
  @SectionId('PTRR')
  @StandardReferences(
    [
      'OWASP WSTG — web security testing guide (penetration testing)',
      'NIST SP 800-53 — audit and accountability (AU) controls',
    ],
    'Reporting format and remediation timelines for penetration testing findings.',
  )
  @Form([
    Field(
      'findingSeverityScale',
      String,
      'Finding Severity Scale',
      hint: 'CVSS, custom scale (Critical/High/Medium/Low/Info)',
    ),
    Field(
      'reportingFormat',
      String,
      'Reporting Format',
      hint: 'Executive summary, technical findings, remediation guidance',
    ),
    Field(
      'remediationTimelines',
      String,
      'Remediation Timelines',
      required: true,
      hint: 'SLAs per severity: Critical 48h, High 7d, Medium 30d, Low 90d',
    ),
    Field(
      'managementBriefing',
      String,
      'Management Briefing',
      hint: 'Post-test executive debrief requirements',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional penetration testing notes',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? reporting;
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
class SecurityCodeReviewPolicy extends DocSpecsSection {
  @Form([
    Field(
      'securityReviewTriggers',
      String,
      'Security Review Triggers',
      required: true,
      hint:
          'New features, auth changes, crypto code, data handling changes, third-party integrations',
    ),
    Field(
      'securityReviewScope',
      String,
      'Review Scope',
      hint:
          'Authentication, authorization, input validation, cryptography, session management',
    ),
    Field(
      'reviewMethodology',
      String,
      'Review Methodology',
      hint: 'OWASP Code Review Guide, CWE/SANS Top 25, manual + automated',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Reviewer qualification and independence rules.
  @SectionId('SCRPR')
  @StandardReferences(
    [
      'ISO 19011 — auditing management systems (audit programme)',
      'OWASP ASVS — verification and security testing requirements',
    ],
    'Reviewer qualification, independence, and rotation rules for security code review.',
  )
  @Form([
    Field(
      'securityReviewerRequirements',
      String,
      'Reviewer Requirements',
      required: true,
      hint:
          'Security training certifications, experience requirements for reviewers',
    ),
    Field(
      'externalReviewCriteria',
      String,
      'External Review Criteria',
      hint: 'When external security review firm is engaged',
    ),
    Field(
      'reviewerRotation',
      String,
      'Reviewer Rotation',
      hint: 'How security reviewers are rotated to avoid bias',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? reviewers;

  /// Review process guidance.
  @SectionId('SCRPP')
  @StandardReferences(
    [
      'OWASP ASVS — verification and security testing requirements',
      'OWASP WSTG — web security testing guide (penetration testing)',
    ],
    'Process guidance for security-focused code review including checklists and threat modeling.',
  )
  @Form([
    Field(
      'securityChecklist',
      String,
      'Security Checklist',
      hint: 'OWASP Top 10, injection, XSS, CSRF, auth bypass, data exposure',
    ),
    Field(
      'threatModelingIntegration',
      String,
      'Threat Modeling Integration',
      hint: 'How threat models inform code review focus areas',
    ),
    Field(
      'securityAnnotations',
      String,
      'Security Annotations',
      hint:
          'Code annotations marking security-critical sections for priority review',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? process;

  /// Finding management and residual risk handling.
  @SectionId('SCRPF')
  @StandardReferences(
    [
      'OWASP ASVS — verification and security testing requirements',
      'ISO/IEC 27001 — internal audit and management review (Clause 9)',
    ],
    'Finding classification, tracking, and residual-risk handling for security code review.',
  )
  @Form([
    Field(
      'findingClassification',
      String,
      'Finding Classification',
      hint: 'Vulnerability, weakness, informational, best-practice deviation',
    ),
    Field(
      'findingTrackingProcess',
      String,
      'Finding Tracking',
      hint: 'How findings are tracked from discovery to resolution',
    ),
    Field(
      'securityDebtManagement',
      String,
      'Security Debt Management',
      hint: 'How accepted security risks are documented and reviewed',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional security code review notes',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? findings;
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
class DependencyScanningRequirements extends DocSpecsSection {
  @Form([
    Field(
      'scaScanningTool',
      String,
      'SCA Scanning Tool',
      required: true,
      hint:
          'Software Composition Analysis tool: Snyk, Dependabot, OWASP Dependency-Check, Trivy',
    ),
    Field(
      'scanFrequency',
      String,
      'Scan Frequency',
      required: true,
      hint: 'Every build, daily, weekly, on dependency change',
    ),
    Field(
      'registryScanning',
      String,
      'Registry Scanning',
      hint:
          'Scanning package registries (pub.dev, npm, Docker Hub) for known vulnerabilities',
    ),
    Field(
      'severityThresholds',
      String,
      'Severity Thresholds',
      required: true,
      hint: 'Build-blocking severity: Critical blocks, High warns, etc.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Vulnerability-management rules.
  @SectionId('DSRV')
  @StandardReferences(
    [
      'OWASP ASVS — verification and security testing requirements',
      'PCI DSS — logging, monitoring, and regular security testing',
    ],
    'Vulnerability database sources, remediation SLAs, and exception handling for dependencies.',
  )
  @Form([
    Field(
      'vulnerabilityDatabase',
      String,
      'Vulnerability Database',
      hint: 'NVD, GitHub Advisory Database, OSV, vendor-specific advisories',
    ),
    Field(
      'remediationSla',
      String,
      'Remediation SLA',
      hint: 'Time to patch per severity level',
    ),
    Field(
      'exceptionProcess',
      String,
      'Exception Process',
      hint: 'How vulnerabilities are risk-accepted with justification',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? vulnerabilities;

  /// SBOM requirements.
  @SectionId('DSRS')
  @StandardReferences(
    [
      'OWASP ASVS — verification and security testing requirements',
      'NIST SP 800-53 — audit and accountability (AU) controls',
    ],
    'Software bill of materials generation, update frequency, and distribution requirements.',
  )
  @Form([
    Field(
      'sbomGeneration',
      String,
      'SBOM Generation',
      hint: 'Software Bill of Materials format: SPDX, CycloneDX',
    ),
    Field(
      'sbomUpdateFrequency',
      String,
      'SBOM Update Frequency',
      hint: 'How often SBOM is regenerated and published',
    ),
    Field(
      'sbomDistribution',
      String,
      'SBOM Distribution',
      hint: 'Who receives SBOM: customers, auditors, regulators',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? sbom;

  /// License-compliance rules.
  @SectionId('DSRL')
  @StandardReferences([
    'OWASP ASVS — verification and security testing requirements',
    'ISO/IEC 27002 — logging and monitoring controls',
  ], 'License policy and automated license scanning rules for dependencies.')
  @Form([
    Field(
      'licensePolicy',
      String,
      'License Policy',
      hint:
          'Allowed licenses (MIT, BSD, Apache 2.0), restricted (GPL, AGPL), review-required',
    ),
    Field(
      'licenseScanning',
      String,
      'License Scanning',
      hint: 'Automated license detection and policy enforcement',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? licensing;

  /// Supply-chain security rules.
  @SectionId('DSRSC')
  @StandardReferences(
    [
      'OWASP ASVS — verification and security testing requirements',
      'NIST SP 800-53 — audit and accountability (AU) controls',
    ],
    'Supply-chain security rules covering dependency pinning, signature verification, and registry policy.',
  )
  @Form([
    Field(
      'dependencyPinning',
      String,
      'Dependency Pinning',
      hint: 'Lock file requirements, version pinning strategy',
    ),
    Field(
      'signatureVerification',
      String,
      'Signature Verification',
      hint: 'Package signature verification, provenance attestation',
    ),
    Field(
      'privateRegistryPolicy',
      String,
      'Private Registry Policy',
      hint: 'Internal package registry, proxy settings, caching policy',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional dependency scanning notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? supplyChain;
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
class SecurityCertificationRequirements extends DocSpecsSection {
  @Form([
    Field(
      'targetCertifications',
      String,
      'Target Certifications',
      required: true,
      hint: 'ISO 27001, SOC 2 Type II, PCI DSS, HIPAA, FedRAMP, CSA STAR',
    ),
    Field(
      'certificationTimeline',
      String,
      'Certification Timeline',
      hint: 'Target dates for achieving each certification',
    ),
    Field(
      'certificationScope',
      String,
      'Certification Scope',
      hint: 'Which systems, processes, and data are in scope',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// ISO 27001 requirements.
  @SectionId('SCRI')
  @StandardReferences(
    [
      'ISO/IEC 27001 — internal audit and management review (Clause 9)',
      'ISO/IEC 27002 — logging and monitoring controls',
    ],
    'ISO 27001 controls, ISMS scope, and risk assessment methodology requirements.',
  )
  @Form([
    Field(
      'iso27001Controls',
      String,
      'ISO 27001 Controls',
      hint: 'Annex A controls applicable, Statement of Applicability',
    ),
    Field(
      'ismsScope',
      String,
      'ISMS Scope',
      hint: 'Information Security Management System boundary definition',
    ),
    Field(
      'riskAssessmentMethodology',
      String,
      'Risk Assessment Methodology',
      hint: 'Risk assessment approach for ISO 27001 compliance',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? iso27001;

  /// SOC 2 requirements.
  @SectionId('SCRS')
  @StandardReferences(
    [
      'SOC 2 — trust services criteria (security, audit evidence)',
      'ISO/IEC 27001 — internal audit and management review (Clause 9)',
    ],
    'SOC 2 trust services criteria, report type, and audit period requirements.',
  )
  @Form([
    Field(
      'soc2TrustServiceCriteria',
      String,
      'SOC 2 Trust Criteria',
      hint:
          'Security, Availability, Processing Integrity, Confidentiality, Privacy',
    ),
    Field(
      'soc2ReportType',
      String,
      'SOC 2 Report Type',
      hint: 'Type I (point in time) or Type II (over period)',
    ),
    Field(
      'soc2AuditPeriod',
      String,
      'SOC 2 Audit Period',
      hint: 'Observation window for Type II audit',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? soc2;

  /// Industry-specific requirements.
  @SectionId('SECEREIN')
  @StandardReferences(
    [
      'PCI DSS — logging, monitoring, and regular security testing',
      'ISO/IEC 27002 — logging and monitoring controls',
    ],
    'Industry-specific certification requirements such as PCI DSS, HIPAA, and sector regulations.',
  )
  @Form([
    Field(
      'pciDssLevel',
      String,
      'PCI DSS Level',
      hint: 'PCI DSS compliance level based on transaction volume',
    ),
    Field(
      'hipaaRequirements',
      String,
      'HIPAA Requirements',
      hint: 'PHI handling, BAA requirements if applicable',
    ),
    Field(
      'industrySpecificCompliance',
      String,
      'Industry-Specific Compliance',
      hint: 'FINRA, FDA 21 CFR Part 11, NERC CIP, etc.',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? industry;

  /// Maintenance and budget.
  @SectionId('SCRM')
  @StandardReferences(
    [
      'ISO/IEC 27001 — internal audit and management review (Clause 9)',
      'SOC 2 — trust services criteria (security, audit evidence)',
    ],
    'Recertification cycle, continuous monitoring, and budget for security certifications.',
  )
  @Form([
    Field(
      'recertificationCycle',
      String,
      'Recertification Cycle',
      hint: 'Annual surveillance audits, triennial recertification',
    ),
    Field(
      'continuousComplianceMonitoring',
      String,
      'Continuous Monitoring',
      hint: 'How ongoing compliance is monitored between audits',
    ),
    Field(
      'certificationBudget',
      String,
      'Certification Budget',
      hint: 'Estimated budget for certification and maintenance',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional security certification notes',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? maintenance;
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
class ComplianceAuditSchedule extends DocSpecsSection {
  @Form([
    // Audit types
    Field(
      'internalAuditFrequency',
      String,
      'Internal Audit Frequency',
      required: true,
      hint: 'How often internal security audits are conducted',
    ),
    Field(
      'externalAuditFrequency',
      String,
      'External Audit Frequency',
      required: true,
      hint: 'How often external/third-party audits are conducted',
    ),
    Field(
      'auditTypes',
      String,
      'Audit Types',
      hint: 'Technical audit, process audit, compliance audit, forensic audit',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Annual planning and scoping rules.
  @SectionId('CASP')
  @StandardReferences([
    'ISO/IEC 27001 — internal audit and management review (Clause 9)',
    'ISO 19011 — auditing management systems (audit programme)',
  ], 'Annual planning and scoping rules for the compliance audit schedule.')
  @Form([
    Field(
      'annualAuditPlan',
      String,
      'Annual Audit Plan',
      hint: 'Documented plan with scope, schedule, resources for the year',
    ),
    Field(
      'auditScopeDefinition',
      String,
      'Scope Definition',
      hint:
          'How audit scope is determined: risk-based, regulatory, coverage rotation',
    ),
    Field(
      'auditResourceRequirements',
      String,
      'Resource Requirements',
      hint: 'Internal staff, external auditors, tools, budget',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? planning;

  /// Audit execution and evidence collection.
  @SectionId('CASE')
  @StandardReferences(
    [
      'ISO 19011 — auditing management systems (audit programme)',
      'SOC 2 — trust services criteria (security, audit evidence)',
    ],
    'Auditor qualifications, evidence collection, and interview process for the compliance audit schedule.',
  )
  @Form([
    Field(
      'auditorQualifications',
      String,
      'Auditor Qualifications',
      hint: 'CISA, CISSP, ISO 27001 Lead Auditor, industry-specific',
    ),
    Field(
      'auditEvidenceCollection',
      String,
      'Evidence Collection',
      hint: 'How audit evidence is gathered, documented, and preserved',
    ),
    Field(
      'auditInterviewProcess',
      String,
      'Interview Process',
      hint: 'Staff interview methodology during audits',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? execution;

  /// Reporting and remediation follow-up.
  @SectionId('CASR')
  @StandardReferences(
    [
      'ISO/IEC 27001 — internal audit and management review (Clause 9)',
      'SOC 2 — trust services criteria (security, audit evidence)',
    ],
    'Reporting structure and remediation follow-up for the compliance audit schedule.',
  )
  @Form([
    Field(
      'auditReportingStructure',
      String,
      'Reporting Structure',
      hint: 'Finding format, severity rating, recommendation structure',
    ),
    Field(
      'findingRemediationTracking',
      String,
      'Remediation Tracking',
      hint: 'How audit findings are tracked to resolution',
    ),
    Field(
      'managementResponseTimeline',
      String,
      'Management Response Timeline',
      hint: 'Time for management to respond to audit findings',
    ),
    Field(
      'auditCommitteeReporting',
      String,
      'Committee Reporting',
      hint: 'How audit results are reported to board/audit committee',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional compliance audit schedule notes',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? reporting;
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
class SecurityTestingAutomation extends DocSpecsSection {
  @Form([
    Field(
      'sastTool',
      String,
      'SAST Tool',
      required: true,
      hint:
          'Static Application Security Testing: SonarQube, Semgrep, Fortify, Checkmarx',
    ),
    Field(
      'sastIntegration',
      String,
      'SAST Integration',
      hint: 'CI/CD pipeline integration point: pre-commit, PR, build',
    ),
    Field(
      'sastRuleConfiguration',
      String,
      'SAST Rule Configuration',
      hint: 'Custom rules, severity mapping, false-positive management',
    ),
    Field(
      'securityQualityGates',
      String,
      'Security Quality Gates',
      required: true,
      hint:
          'Build-blocking criteria: no critical/high SAST findings, clean container scan',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Dynamic analysis configuration.
  @SectionId('STAD')
  @StandardReferences(
    [
      'OWASP WSTG — web security testing guide (penetration testing)',
      'OWASP ASVS — verification and security testing requirements',
    ],
    'Dynamic application security testing configuration within automated security testing.',
  )
  @Form([
    Field(
      'dastTool',
      String,
      'DAST Tool',
      hint:
          'Dynamic Application Security Testing: OWASP ZAP, Burp Suite, Nuclei',
    ),
    Field(
      'dastScanSchedule',
      String,
      'DAST Scan Schedule',
      hint: 'Automated scan frequency against staging/QA environment',
    ),
    Field(
      'dastAuthenticationConfig',
      String,
      'DAST Authentication',
      hint: 'How DAST scanner authenticates to test protected resources',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? dast;

  /// Interactive analysis configuration.
  @SectionId('STAI')
  @StandardReferences(
    [
      'OWASP ASVS — verification and security testing requirements',
      'OWASP WSTG — web security testing guide (penetration testing)',
    ],
    'Interactive application security testing configuration within automated security testing.',
  )
  @Form([
    Field(
      'iastTool',
      String,
      'IAST Tool',
      hint: 'Interactive Application Security Testing: Contrast Security, Hdiv',
    ),
    Field(
      'iastDeploymentModel',
      String,
      'IAST Deployment',
      hint: 'Agent-based in QA/staging, runtime instrumentation approach',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? iast;

  /// Fuzzing configuration.
  @SectionId('STAF')
  @StandardReferences([
    'OWASP WSTG — web security testing guide (penetration testing)',
    'OWASP ASVS — verification and security testing requirements',
  ], 'Fuzzing requirements and targets within automated security testing.')
  @Form([
    Field(
      'fuzzingRequirements',
      String,
      'Fuzzing Requirements',
      hint: 'API fuzzing, protocol fuzzing, input mutation testing',
    ),
    Field(
      'fuzzingTargets',
      String,
      'Fuzzing Targets',
      hint: 'API endpoints, file parsers, protocol handlers to fuzz',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? fuzzing;

  /// Container and IaC scanning.
  @SectionId('STAS')
  @StandardReferences(
    [
      'OWASP ASVS — verification and security testing requirements',
      'NIST SP 800-53 — audit and accountability (AU) controls',
    ],
    'Container image, infrastructure-as-code, and secrets scanning within automated security testing.',
  )
  @Form([
    Field(
      'containerScanning',
      String,
      'Container Scanning',
      hint: 'Docker image vulnerability scanning: Trivy, Grype, Snyk Container',
    ),
    Field(
      'infrastructureAsCodeScanning',
      String,
      'IaC Scanning',
      hint: 'Terraform, CloudFormation scanning: Checkov, tfsec, KICS',
    ),
    Field(
      'secretsDetection',
      String,
      'Secrets Detection',
      hint: 'Pre-commit secrets scanning: GitLeaks, TruffleHog, detect-secrets',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? scanning;

  /// Governance and reporting.
  @SectionId('STAG')
  @StandardReferences(
    [
      'OWASP ASVS — verification and security testing requirements',
      'PCI DSS — logging, monitoring, and regular security testing',
    ],
    'Governance and reporting for automated security testing, including false-positive triage and dashboards.',
  )
  @Form([
    Field(
      'falsePositiveProcess',
      String,
      'False Positive Process',
      hint: 'How false positives are triaged, suppressed, and documented',
    ),
    Field(
      'securityDashboard',
      String,
      'Security Dashboard',
      hint: 'Centralized security metrics and trend visualization',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional security testing automation notes',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? governance;
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
class SecurityAuditEntry extends DocSpecsSection {
  @Form([
    // Audit identification
    Field(
      'auditName',
      String,
      'Audit Name',
      required: true,
      hint: 'Name or title of the audit requirement',
    ),
    Field(
      'auditCategory',
      String,
      'Audit Category',
      hint:
          'Penetration test, compliance audit, code audit, infrastructure audit',
    ),
    Field(
      'auditDescription',
      String,
      'Description',
      hint: 'Detailed description of what the audit covers',
    ),
    Field(
      'frequency',
      String,
      'Frequency',
      required: true,
      hint: 'Annual, semi-annual, quarterly, on-demand',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Audit schedule and cadence.
  @SectionId('SAES')
  @StandardReferences([
    'ISO 19011 — auditing management systems (audit programme)',
    'PCI DSS — logging, monitoring, and regular security testing',
  ], 'Schedule and cadence for a security audit requirement.')
  @Form([
    Field(
      'lastAuditDate',
      String,
      'Last Audit Date',
      hint: 'Date of most recent audit',
    ),
    Field(
      'nextAuditDate',
      String,
      'Next Audit Date',
      hint: 'Planned date for next audit',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? scheduling;

  /// Scope, standards, and execution model.
  @SectionId('SAEE')
  @StandardReferences(
    [
      'ISO 19011 — auditing management systems (audit programme)',
      'ISO/IEC 27001 — internal audit and management review (Clause 9)',
    ],
    'Scope, applicable standards, and execution model for a security audit requirement.',
  )
  @Form([
    Field(
      'auditScope',
      String,
      'Audit Scope',
      hint: 'Systems, processes, and data in scope',
    ),
    Field(
      'auditStandard',
      String,
      'Audit Standard',
      hint: 'Standard or framework: ISO 27001, SOC 2, OWASP, PCI DSS',
    ),
    Field(
      'auditorType',
      String,
      'Auditor Type',
      hint: 'Internal team, external firm, regulatory body',
    ),
    Field(
      'estimatedDuration',
      String,
      'Estimated Duration',
      hint: 'Expected duration of the audit engagement',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? execution;

  /// Deliverables, ownership, and notes.
  @SectionId('SAEFU')
  @StandardReferences(
    [
      'ISO 19011 — auditing management systems (audit programme)',
      'NIST SP 800-53 — audit and accountability (AU) controls',
    ],
    'Deliverables, ownership, and remediation follow-up for a security audit requirement.',
  )
  @Form([
    Field(
      'expectedDeliverables',
      String,
      'Expected Deliverables',
      hint: 'Audit report, remediation plan, certification, attestation',
    ),
    Field(
      'remediationTimeline',
      String,
      'Remediation Timeline',
      hint: 'Expected timeline for addressing findings',
    ),
    Field(
      'responsibleParty',
      String,
      'Responsible Party',
      hint: 'Team or individual responsible for coordinating the audit',
    ),
    Field('notes', String, 'Notes', hint: 'Additional audit requirement notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? followUp;
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
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description of software-intensive systems',
    'arc42 — software architecture documentation template',
    'C4 model — context, container, component, and code diagrams',
  ],
  'Describes the detailed internal system architecture: layering, package structure, adopted design patterns, and architectural drivers and trade-offs.',
)
@SectionId('SYARSP')
@DetailedIn(D06ArchitectureTechnologySpecification)
class SystemArchitectureSpec extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;
}
