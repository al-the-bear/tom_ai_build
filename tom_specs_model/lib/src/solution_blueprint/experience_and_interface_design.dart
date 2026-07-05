/// Section 10: Experience & Interface Design.
///
/// Seeds → XDS, TRP, ATS depending on subsection.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';



/// 10. Experience & Interface Design. Seeds → XDS.
@StandardReferences(
  [
    'ISO 9241-210:2019 — human-centred design for interactive systems across the whole experience',
    'ISO 9241-11:2018 — usability defined by effectiveness, efficiency, and satisfaction in context of use',
    'ISO/IEC 25010:2023 — interaction capability as a product-quality characteristic',
  ],
  'The complete specification of how users experience and interact with the application across every screen and interface concern.',
)
@SectionId('XID')
@Comment('Seeds → XDS')
class ExperienceAndInterfaceDesign {
  @ContentHelp('''
Provide an executive overview of the User Interface Design, establishing the
foundation for all visual and interactive aspects of the application.

**Purpose:**
This section bridges business requirements and visual implementation. It ensures
the UI supports all business processes, respects authorization boundaries, and
provides a consistent user experience across all application areas.

**Section structure:**
1. **Design Vision** — Goals, principles, and user personas that guide all UI decisions
2. **Screen Descriptions** — Detailed inventory of all application screens
3. **Screen Flow Structure** — Navigation paths and user journeys through the application
4. **Print Layout** — Reports, exports, and print output formats
5. **Data Structure Alignment** — Mapping of UI fields to data model entities
6. **Authorization Compliance** — UI adaptation based on user roles and permissions
7. **Error Handling** — User feedback for validation errors and system failures
8. **User Assistance** — Contextual help, tooltips, onboarding, and documentation
9. **Accessibility** — WCAG compliance, keyboard navigation, screen reader support
10. **Responsive Design** — Layout adaptation for desktop, tablet, and mobile
11. **UI Components** — Reusable component library and design system
12. **Multi-language Support** — Internationalization and localization approach
13. **Prototype** — Clickable prototype deliverables and fidelity levels

**Flutter UI framework context:**
This specification targets Flutter-based UI using the Tom UI framework:
- Observable state binding via `TomObject<T>` and `TomClass`
- Form system with typed fields, validation, and resource lookup
- Action system for user interactions and command execution
- Authorization-aware widgets with four-state visibility model
- Resource-based text, icons, and configuration
- Theming system for consistent visual styling

**Specification depth:**
The UI specification should be detailed enough to specify every screen, field,
button, icon, label, tooltip, error message, layout breakpoint, and interaction
pattern. The structure allows progressive refinement from high-level wireframes
to pixel-perfect designs with exact typography and spacing.

**Cross-references:**
- Data Model (section 7) → field mappings and data types
- Security & Access Model (section 9) → role-based UI visibility
- Business Processes (section 6) → user task flows
- Requirements (section 4) → functional requirements for each screen
''')
  @SerializationOrder(0)
  String? content;

  /// 10.1. Design Vision. Seeds → XDS.
  @SerializationOrder(1)
  DesignVision designVision = DesignVision();

  /// 10.2. Screen Descriptions. Seeds → XDS.
  @SerializationOrder(2)
  ScreenDescriptions screens = ScreenDescriptions();

  /// 10.3. Screen Flow Structure. Seeds → XDS.
  @SerializationOrder(3)
  ScreenFlowStructure screenFlow = ScreenFlowStructure();

  /// 10.4. Print Layout. Seeds → XDS.
  @SerializationOrder(4)
  PrintAndExportLayout printLayout = PrintAndExportLayout();

  /// Data Structure Alignment.
  @SerializationOrder(5)
  TextSection dataStructureAlignment = TextSection();

  /// Authorization Compliance.
  @SerializationOrder(6)
  TextSection authorizationCompliance = TextSection();

  /// 10.7. Error Handling. Seeds → XDS.
  @SerializationOrder(7)
  ErrorHandling errorHandling = ErrorHandling();

  /// 10.8. User Assistance. Seeds → XDS.
  @SerializationOrder(8)
  UserAssistance userAssistance = UserAssistance();

  /// 10.9. Accessibility. Seeds → XDS.
  @SerializationOrder(9)
  Accessibility accessibility = Accessibility();

  /// 10.10. Responsive Design. Seeds → XDS.
  @SerializationOrder(10)
  ResponsiveDesign responsiveDesign = ResponsiveDesign();

  /// 10.11. UI Components. Seeds → XDS.
  @SerializationOrder(11)
  UiComponents uiComponents = UiComponents();

  /// 10.12. Multi-language Support.
  @SerializationOrder(12)
  MultiLanguageSupport multiLanguageSupport = MultiLanguageSupport();

  /// 10.13. Prototype. Seeds → XDS.
  @SerializationOrder(13)
  Prototype prototype = Prototype();

  /// 10.14. Wireframes and Mockups.
  ///
  /// One whole-catalog content section; collapsed from
  /// `List<WireframesAndMockups>` (L34C-12 SR-52).
  @SerializationOrder(14)
  WireframesAndMockups wireframesAndMockups = WireframesAndMockups();
}

// ---------------------------------------------------------------------------
// 10.1 Design Vision
// ---------------------------------------------------------------------------

/// 10.1. Design Vision.
///
/// Overall design vision for the user interface, encompassing goals,
/// principles, and user personas that guide all UI decisions.
@StandardReferences(
  [
    'ISO 9241-210:2019 — plan and apply human-centred design throughout the interactive system lifecycle',
    'ISO 9241-11:2018 — usability is framed by users, their goals, and the operating environment',
  ],
  'The overall human-centred design vision that governs every UI decision through goals, principles, and personas.',
)
@SectionId('DEVIZ')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@SecondLevelSectionId(D09ExperienceDesignSpecification, 'XDS-VIS')
class DesignVision {
  @ContentHelp('''
## Design Vision (10.1)

Overall design vision governing all UI decisions.

### Subsections
- **10.1.1 Design Goals** — Prioritized UI objectives (simplicity, efficiency, accessibility)
- **10.1.2 Design Principles** — Guiding principles (progressive disclosure, direct manipulation)
- **10.1.3 User Personas** — Distinct user archetypes with goals/pain points

### Tom UI Framework Context
Design vision informs:
- Widget selection and customization
- Color schemes and theming via `TomTheme`
- Spacing and typography scales
- Interaction patterns and feedback timing

### Specification Notes
Document the visual language and interaction vocabulary — how the Tom UI component 
library will be configured and extended to express this vision.
''')
  @SerializationOrder(0)
  String? content;

  /// 10.1.1. Design Goals.
  @SerializationOrder(1)
  DesignGoals designGoals = DesignGoals();

  /// 10.1.2. Design Principles.
  @SerializationOrder(2)
  DesignPrinciples designPrinciples = DesignPrinciples();

  /// 10.1.3. User Personas.
  @SerializationOrder(3)
  UserPersonas personas = UserPersonas();
}

// ---------------------------------------------------------------------------
// 10.1.1 Design Goals
// ---------------------------------------------------------------------------

/// 10.1.1. Design Goals.
///
/// Primary design objectives that the UI must achieve: simplicity, efficiency,
/// accessibility, consistency, delight. Goals are prioritized for the project.
@StandardReferences(
  [
    'ISO 9241-11:2018 — usability comprises effectiveness, efficiency, and satisfaction as measurable objectives',
    'ISO 9241-210:2019 — human-centred design defines and prioritises usability goals',
  ],
  'The prioritized set of measurable usability objectives the interface must achieve.',
)
@SectionId('DEGOL')
class DesignGoals {
  @ContentHelp('''
## Design Goals (10.1.1)

Prioritized UI objectives the system must achieve.

### Goal Categories
- **Usability** — Task completion, learnability, error prevention
- **Performance** — Perceived speed, responsiveness, load times
- **Accessibility** — WCAG compliance level, assistive tech support
- **Aesthetics** — Visual appeal, brand alignment, delight
- **Engagement** — User retention, feature adoption

### Form Fields Guide
**goalName**: Concise label ("Zero-Click Ordering")
**measurementCriteria**: Specific test ("95% can complete in <3 clicks")
**targetMetric**: Quantified target ("<2s load time on 3G")
**relatedPrinciples**: Cross-reference to VIS-PRI entries

### Tom UI Mapping
Goals drive widget configuration — e.g., performance goals → lazy loading, 
accessibility goals → semantic labels and focus management.
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of the design goal framework and prioritization approach.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× DesignGoal.
  @StandardReferences(
    [
      'ISO 9241-11:2018 — measurable usability objectives for the interface',
      'ISO 9241-210:2019 — human-centred design sets and tracks usability goals',
    ],
    'The collection of individual design-goal entries for the interface.',
  )
  @SectionId('DGOEN-ITEM-LST')
  @SectionIdPattern('DGOEN-ITEM-xxx')
  @ContentHelp('Add one entry per design goal.')
  @SerializationOrder(2)
  List<DesignGoalEntry> items = [];
}

/// A design goal entry (form).
///
/// Each goal represents a measurable UI objective with success criteria.
@StandardReferences(
  [
    'ISO 9241-11:2018 — usability objectives are stated as measurable effectiveness and efficiency targets',
    'ISO 9241-210:2019 — human-centred design sets measurable usability goals',
  ],
  'A single measurable UI objective with success criteria and a target metric.',
)
@SectionId('DGOEN')
class DesignGoalEntry {
  @Form([
    Field('goalName', String, 'Goal Name', required: true,
        hint: 'A concise label for the design goal'),
    Field('description', String, 'Goal Description',
        hint: 'What this goal means for the UI'),
    Field('priority', String, 'Priority',
        hint: 'Critical/High/Medium/Low'),
    Field('category', String, 'Category',
        hint: 'Usability/Performance/Accessibility/Aesthetics/Engagement'),
    Field('measurementCriteria', String, 'Measurement Criteria',
        hint: 'How we verify goal achievement'),
    Field('targetMetric', String, 'Target Metric',
        hint: 'Quantifiable target if applicable'),
    Field('relatedPrinciples', String, 'Related Principles',
        hint: 'Design principles that support this goal'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.1.2 Design Principles
// ---------------------------------------------------------------------------

/// 10.1.2. Design Principles.
///
/// Guiding principles for all UI decisions: progressive disclosure, direct
/// manipulation, feedback, consistency, error prevention.
@StandardReferences(
  [
    'ISO 9241-110:2020 — interaction principles such as self-descriptiveness, controllability, and use error tolerance',
    'ISO 9241-210:2019 — human-centred design is guided by established interaction principles',
  ],
  'The guiding interaction principles that govern all UI decisions across the interface.',
)
@SectionId('DEPRI')
class DesignPrinciples {
  @ContentHelp('''
## Design Principles (10.1.2)

Guiding principles for all UI decisions.

### Principle Categories
- **Visual** — Hierarchy, whitespace, color usage, typography
- **Interaction** — Feedback, affordance, direct manipulation
- **Accessibility** — Perceivable, operable, understandable, robust
- **Information** — Progressive disclosure, chunking, scent
- **Navigation** — Wayfinding, landmarks, predictability

### Form Fields Guide
**principleName**: Clear label ("Progressive Disclosure")
**rationale**: Why it matters for this project
**examples**: Concrete UI manifestations
**exceptions**: When deviation is acceptable

### Tom UI Mapping
Principles configure shared behaviors:
- Animation curves via `TomAnimations`
- Feedback patterns via `TomFeedback`
- Spacing/rhythm via `TomSpacing`
- Typography scale via `TomTypography`
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of the design principle framework.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× UiDesignPrinciple.
  @StandardReferences(
    [
      'ISO 9241-110:2020 — the set of interaction principles guiding dialogue design',
      'ISO 9241-210:2019 — human-centred design applies established interaction principles',
    ],
    'The collection of individual design-principle entries for the interface.',
  )
  @SectionId('UDPEN-ITEM-LST')
  @SectionIdPattern('UDPEN-ITEM-xxx')
  @ContentHelp('Add one entry per design principle.')
  @SerializationOrder(2)
  List<DesignPrincipleEntry> items = [];
}

/// A design principle entry (form).
///
/// Each principle guides UI decisions with rationale and examples.
@StandardReferences(
  [
    'ISO 9241-110:2020 — interaction principles such as suitability for the task and conformity with user expectations',
    'ISO 9241-210:2019 — human-centred design applies established interaction principles',
  ],
  'A single guiding interaction principle that shapes UI decisions with rationale and examples.',
)
@SectionId('UDPEN')
class DesignPrincipleEntry {
  @Form([
    Field('principleName', String, 'Principle Name', required: true,
        hint: 'A clear name for the design principle'),
    Field('description', String, 'Description',
        hint: 'What this principle means'),
    Field('rationale', String, 'Rationale',
        hint: 'Why this principle matters'),
    Field('category', String, 'Category',
        hint: 'Visual/Interaction/Accessibility/Information/Navigation'),
    Field('examples', String, 'Examples',
        hint: 'How the principle manifests in the UI'),
    Field('exceptions', String, 'Exceptions',
        hint: 'When deviation is acceptable'),
    Field('sourceReference', String, 'Source Reference',
        hint: 'Design system or external reference'),
    Field('relatedGoals', String, 'Related Goals',
        hint: 'Design goals this principle supports'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.1.3 User Personas
// ---------------------------------------------------------------------------

/// 10.1.3. User Personas.
///
/// Container for user persona definitions. Each persona represents a distinct
/// user archetype with goals, pain points, and context.
@StandardReferences(
  [
    'ISO 9241-210:2019 — understand and specify the context of use including user characteristics',
    'ISO 9241-11:2018 — context of use comprises users goals and operating environment',
  ],
  'The set of distinct user archetypes the interface is designed to serve.',
)
@SectionId('USPER')
class UserPersonas {
  @ContentHelp('''
## User Personas (10.1.3)

User archetype definitions driving UI personalization.

### Persona Structure
Each persona includes:
- Demographics and role context
- Technical proficiency and device preferences
- Goals, pain points, and key scenarios
- Accessibility needs

### Form Fields Guide
**personaName**: Name + role ("Marco, Finance Manager")
**technicalProficiency**: Beginner/Intermediate/Advanced with context
**accessibilityNeeds**: Visual/Motor/Cognitive/None
**quote**: Representative voice capturing their perspective

### Tom UI Mapping
Personas inform:
- Default settings per user category
- Feature visibility/hiding
- Onboarding flows
- Help topic prioritization
- Responsive breakpoint priorities
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of persona research methodology and usage.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 1+× Persona.
  @StandardReferences(
    [
      'ISO 9241-210:2019 — the characteristics of users form part of the context of use',
      'ISO 9241-11:2018 — usability is defined relative to specified users',
    ],
    'The collection of individual user-persona entries for the interface.',
  )
  @SectionId('PEREN-ITEM-LST')
  @SectionIdPattern('PEREN-ITEM-xxx')
  @ContentHelp('Add one entry per user persona.')
  @Min(1)
  @SerializationOrder(2)
  List<PersonaEntry> items = [];
}

/// A user persona entry (form).
///
/// Represents a distinct user archetype with detailed context for UI design.
@StandardReferences(
  [
    'ISO 9241-210:2019 — specify the context of use including the characteristics of users',
    'ISO 9241-11:2018 — usability is defined relative to specified users and their goals',
  ],
  'A single distinct user archetype with the detailed context that guides interface design.',
)
@SectionId('PEREN')
class PersonaEntry {
  @Form([
    Field('personaName', String, 'Persona Name', required: true,
        hint: 'Name and title, e.g., "Marco, Finance Manager"'),
    Field('age', String, 'Age',
        hint: 'Age or age range'),
    Field('role', String, 'Role',
        hint: 'Job title and responsibilities'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Background and capability profile.
  @SerializationOrder(1)
  PersonaEntryProfile profile = PersonaEntryProfile();

  /// Usage environment and device context.
  @SerializationOrder(2)
  PersonaEntryContext context = PersonaEntryContext();

  /// Motivations, frustrations, and success markers.
  @SerializationOrder(3)
  PersonaEntryNeeds needs = PersonaEntryNeeds();

  /// 10.1.3.n.1. Persona Goals.
  @SerializationOrder(4)
  PersonaGoals goals = PersonaGoals();

  /// 10.1.3.n.2. Persona Pain Points.
  @SerializationOrder(5)
  PersonaPainPoints painPoints = PersonaPainPoints();

  /// 10.1.3.n.3. Persona Scenarios.
  @SerializationOrder(6)
  PersonaScenarios scenarios = PersonaScenarios();
}

/// Background and capability profile.
@StandardReferences(
  [
    'ISO 9241-210:2019 — user characteristics such as knowledge and skills form the context of use',
    'ISO 9241-11:2018 — usability depends on the capabilities of specified users',
  ],
  'The background, technical proficiency, and accessibility profile of a persona.',
)
@SectionId('PEPRF')
class PersonaEntryProfile {
    @Form([
        Field('bio', String, 'Background',
                hint: 'Brief biographical context'),
        Field('technicalProficiency', String, 'Technical Proficiency',
                hint: 'Beginner/Intermediate/Advanced — with context'),
        Field('accessibilityNeeds', String, 'Accessibility Needs',
                hint: 'Visual/Motor/Cognitive/None'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Usage environment and device context.
@StandardReferences(
  [
    'ISO 9241-210:2019 — context of use includes the technical and physical environment',
    'ISO 9241-11:2018 — operating environment is part of the context in which usability is achieved',
  ],
  'The usage environment and device context in which a persona interacts with the system.',
)
@SectionId('PECTX')
class PersonaEntryContext {
    @Form([
        Field('typicalUsage', String, 'Typical Usage',
                hint: 'Frequency, duration, and primary activities'),
        Field('primaryDevice', String, 'Primary Device',
                hint: 'Desktop/Laptop/Tablet/Mobile'),
        Field('additionalDevices', String, 'Additional Devices',
                hint: 'Secondary devices used'),
        Field('workEnvironment', String, 'Work Environment',
                hint: 'Office/Remote/Field/Hybrid'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Motivations, frustrations, and success markers.
@StandardReferences(
  [
    'ISO 9241-11:2018 — usability accounts for the needs and satisfaction of specified users',
    'ISO 9241-210:2019 — user characteristics form part of the context of use',
  ],
  'The motivations, frustrations, and success markers that characterise what a persona needs.',
)
@SectionId('PENDS')
class PersonaEntryNeeds {
    @Form([
        Field('motivations', String, 'Motivations',
                hint: 'What drives their behavior'),
        Field('frustrationsWithCurrent', String, 'Current Frustrations',
                hint: 'Issues with existing solutions'),
        Field('successCriteria', String, 'Success Criteria',
                hint: 'How they measure success'),
        Field('quote', String, 'Representative Quote',
                hint: 'A quote that captures their perspective'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 10.1.3.n.1. Persona Goals.
@StandardReferences(
  [
    'ISO 9241-11:2018 — usability is defined relative to specified users and their goals',
    'ISO 9241-210:2019 — specify the context of use including the goals users pursue',
  ],
  'The set of specific goals a persona pursues that drive feature requirements.',
)
@SectionId('PERGL')
class PersonaGoals {
  @ContentHelp('''
## Persona Goals (10.1.3.n.1)

Specific goals for this persona that drive feature requirements.

### Form Fields Guide
**goal**: Clear action ("Quickly approve pending invoices")
**priority**: Critical/High/Medium/Low
**frequency**: Daily/Weekly/Monthly/Occasional
**desiredOutcome**: Success state description

### Mapping to Screens
Goals link to screens via requiredScreens in PersonaScenarios.
High-priority goals drive primary screen actions and dashboard widgets.
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× PersonaGoal.
  @StandardReferences(
    [
      'ISO 9241-11:2018 — usability is measured against the goals of specified users',
      'ISO 9241-210:2019 — context of use records the goals users pursue',
    ],
    'The collection of individual goal entries for a persona.',
  )
  @SectionId('PGOEN-ITEM-LST')
  @SectionIdPattern('PGOEN-ITEM-xxx')
  @ContentHelp('Add one entry per persona goal.')
  @SerializationOrder(1)
  List<PersonaGoalEntry> items = [];
}

/// A persona goal entry (form).
@StandardReferences(
  [
    'ISO 9241-11:2018 — usability is defined relative to specified users and their goals',
    'ISO 9241-210:2019 — context of use captures the goals users pursue with the system',
  ],
  'A single objective a persona wants to achieve that shapes feature requirements.',
)
@SectionId('PGOEN')
class PersonaGoalEntry {
  @Form([
    Field('goal', String, 'Goal', required: true,
        hint: 'The concrete action or outcome the persona wants to achieve'),
    Field('priority', String, 'Priority',
        hint: 'Critical/High/Medium/Low'),
    Field('frequency', String, 'Frequency',
        hint: 'How often this goal arises'),
    Field('currentApproach', String, 'Current Approach',
        hint: 'How they achieve this today'),
    Field('desiredOutcome', String, 'Desired Outcome',
        hint: 'What success looks like'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 10.1.3.n.2. Persona Pain Points.
@StandardReferences(
  [
    'ISO 9241-210:2019 — specify the context of use including the problems users encounter',
    'ISO 9241-11:2018 — usability addresses obstacles to users goals and environment',
  ],
  'The set of frustrations and obstacles a persona faces that the design should address.',
)
@SectionId('PEPPT')
class PersonaPainPoints {
  @ContentHelp('''
## Persona Pain Points (10.1.3.n.2)

Frustrations and obstacles this persona faces.

### Form Fields Guide
**painPoint**: Specific frustration ("Manual data re-entry across systems")
**severity**: Critical/High/Medium/Low
**impact**: Effect on productivity/satisfaction
**workaround**: Current coping strategy
**desiredSolution**: What would help

### Design Implications
High-severity pain points become design priorities:
- Automation opportunities
- Error prevention patterns
- Streamlined workflows
- Contextual help placement
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× PersonaPainPoint.
  @StandardReferences(
    [
      'ISO 9241-210:2019 — context of use records the problems and constraints users face',
      'ISO 9241-11:2018 — usability considers obstacles to users goals and environment',
    ],
    'The collection of individual pain-point entries for a persona.',
  )
  @SectionId('PPPEN-ITEM-LST')
  @SectionIdPattern('PPPEN-ITEM-xxx')
  @ContentHelp('Add one entry per persona pain point.')
  @SerializationOrder(1)
  List<PersonaPainPointEntry> items = [];
}

/// A pain point entry (form).
@StandardReferences(
  [
    'ISO 9241-210:2019 — context of use includes the problems and constraints users experience',
    'ISO 9241-11:2018 — usability addresses obstacles to users goals in their environment',
  ],
  'A single frustration or obstacle a persona faces that the interface should help relieve.',
)
@SectionId('PPPEN')
class PersonaPainPointEntry {
  @Form([
    Field('painPoint', String, 'Pain Point', required: true,
        hint: 'The specific frustration or obstacle the persona encounters'),
    Field('severity', String, 'Severity',
        hint: 'Critical/High/Medium/Low'),
    Field('frequency', String, 'Frequency',
        hint: 'How often this occurs'),
    Field('impact', String, 'Impact',
        hint: 'Effect on productivity/satisfaction'),
    Field('workaround', String, 'Current Workaround',
        hint: 'How they cope today'),
    Field('desiredSolution', String, 'Desired Solution',
        hint: 'What would help'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 10.1.3.n.3. Persona Scenarios.
///
/// Key usage scenarios for this persona — helps map personas to screens/flows.
@StandardReferences(
  [
    'ISO 9241-210:2019 — specify the context of use through representative task scenarios',
    'ISO 9241-11:2018 — context of use comprises users goals and operating environment',
  ],
  'The set of key usage scenarios that connect a persona to the screens and flows they need.',
)
@SectionId('PERSC')
class PersonaScenarios {
  @ContentHelp('''
## Persona Scenarios (10.1.3.n.3)

Key usage scenarios for this persona — maps personas to screens/flows.

### Form Fields Guide
**scenarioName**: Action-oriented ("Approve Pending Orders")
**frequency**: Daily/Weekly/Monthly/Occasional
**urgency**: Time-sensitive nature
**context**: Where/when this occurs
**requiredScreens**: SCR-INV references needed
**successMetric**: Measurable outcome

### Traceability
Scenarios link to:
- Screen Inventory (SCR-INV) via requiredScreens
- Screen Flow (SCF) via navigation paths
- Use Cases (ISC-xxx) via related requirements
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× PersonaScenario.
  @StandardReferences(
    [
      'ISO 9241-210:2019 — context of use is described through representative task scenarios',
      'ISO 9241-11:2018 — scenarios ground usability in users goals and environment',
    ],
    'The collection of individual usage-scenario entries for a persona.',
  )
  @SectionId('PSCEN-ITEM-LST')
  @SectionIdPattern('PSCEN-ITEM-xxx')
  @ContentHelp('Add one entry per persona scenario.')
  @SerializationOrder(1)
  List<PersonaScenarioEntry> items = [];
}

/// A persona scenario entry (form).
@StandardReferences(
  [
    'ISO 9241-210:2019 — context of use describes the tasks users perform with the system',
    'ISO 9241-11:2018 — usability context comprises users goals and operating environment',
  ],
  'A single key usage scenario capturing how one persona accomplishes a task with the system.',
)
@SectionId('PSCEN')
class PersonaScenarioEntry {
  @Form([
    Field('scenarioName', String, 'Scenario Name', required: true,
        hint: 'A short action-oriented name for the scenario'),
    Field('description', String, 'Description',
        hint: 'What the persona is trying to accomplish'),
    Field('frequency', String, 'Frequency',
        hint: 'Daily/Weekly/Monthly/Occasional'),
    Field('urgency', String, 'Urgency',
        hint: 'Time-sensitive nature'),
    Field('context', String, 'Context',
        hint: 'Where/when this scenario occurs'),
    Field('requiredScreens', String, 'Required Screens',
        hint: 'Screens needed for this scenario'),
    Field('successMetric', String, 'Success Metric',
        hint: 'How we measure scenario success'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.2 Screen Descriptions
// ---------------------------------------------------------------------------

/// 10.2. Screen Descriptions.
@StandardReferences(
  [
    'ISO 9241-151:2008 — the structure and content of screens in the user interface',
    'ISO 9241-210:2019 — human-centred specification of screens for the users tasks',
  ],
  'The comprehensive specification of every screen in the application and its information architecture.',
)
@SectionId('SCRDZ')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@SecondLevelSectionId(D09ExperienceDesignSpecification, 'XDS-SCR')
class ScreenDescriptions {
  @ContentHelp('''
## Screen Descriptions (10.2)

Comprehensive screen specifications for the application.

### Subsections
- **10.2.1 Screen Inventory** — Individual screen definitions
- **10.2.2 Information Architecture** — Content organization and hierarchy

### Tom UI Framework Integration
Screens map to Flutter route definitions and scaffold configurations.
Each screen specifies:
- Layout structure (zones, sections)
- UI elements (fields, buttons, displays)
- Actions and their authorization
- State management requirements

### Specification Depth
Each screen should have enough detail to generate:
- Route registration
- Scaffold layout code
- State holder classes
- Authorization checks
''')
  @SerializationOrder(0)
  String? content;

  /// 10.2.1. Screen Inventory.
  @SerializationOrder(1)
  ScreenInventory screenInventory = ScreenInventory();

  /// 10.2.2. Information Architecture.
  @SerializationOrder(2)
  InformationArchitecture informationArchitecture = InformationArchitecture();
}

// ---------------------------------------------------------------------------
// 10.2.1 Screen Inventory
// ---------------------------------------------------------------------------

/// 10.2.1. Screen Inventory.
///
/// Container for screen definitions. Each entry fully describes one application
/// screen including its purpose, layout zones, elements, actions, and states.
@StandardReferences(
  [
    'ISO 9241-151:2008 — the complete catalogue and structure of interface screens',
    'ISO 9241-112:2017 — organisation of screen content for presentation to the user',
  ],
  'The complete catalogue of application screens with each screen fully described.',
)
@SectionId('SCRINV')
class ScreenInventory {
  @ContentHelp('''
## Screen Inventory (10.2.1)

Complete catalog of application screens.

### Screen Categories
- **List** — Data tables with filtering/sorting
- **Detail** — Single record view
- **Form** — Data entry/editing
- **Dashboard** — Aggregated metrics and widgets
- **Settings** — Configuration screens
- **Wizard** — Multi-step guided flows
- **Dialog** — Modal interactions
- **Report** — Formatted output views
- **Landing** — Entry points and navigation hubs

### Screen Entry Structure
Each ScreenEntry includes:
- Identity (ID, name, route pattern)
- Authorization (roles, permissions, effect)
- Sections (layout zones)
- Elements (fields, displays, actions)
- States (loading, empty, error, success)

### Tom UI Mapping
Screens generate TomScaffold configurations with:
- AppBar setup
- Drawer/navigation
- Body layout
- FAB/action buttons
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of the screen inventory structure and conventions.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 1+× Screen.
  @StandardReferences(
    [
      'ISO 9241-151:2008 — the catalogue of screens that make up the user interface',
      'ISO 9241-210:2019 — the full set of screens supporting the user tasks',
    ],
    'The catalogue of individual screen entries that make up the application.',
  )
  @SectionId('SCREN-ITEM-LST')
  @SectionIdPattern('SCREN-ITEM-xxx')
  @Min(1)
  @ContentHelp('Add one entry per screen.')
  @SerializationOrder(2)
  List<ScreenEntry> items = [];
}

/// A screen entry (form).
///
/// Comprehensive specification of a single application screen, covering
/// identity, purpose, authorization, layout, elements, and behavior.
@StandardReferences(
  [
    'ISO 9241-151:2008 — the content objects and structure of a single interface screen',
    'ISO 9241-210:2019 — the user tasks a screen must support in its context of use',
  ],
  'A single application screen with its identity, purpose, layout, and behavior fully specified.',
)
@SectionId('SCREN')
class ScreenEntry {
  @Form([
    Field('screenId', String, 'Screen ID', required: true,
        hint: 'Unique identifier, e.g., SCR-001'),
    Field('screenName', String, 'Screen Name', required: true,
        hint: 'Human-readable screen title'),
    Field('purpose', String, 'Purpose',
        hint: 'Business purpose — what the user accomplishes here'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Classification and routing metadata.
  @SerializationOrder(1)
  ScreenEntryClassification classification = ScreenEntryClassification();

  /// Access control settings.
  @SerializationOrder(2)
  ScreenEntryAccess access = ScreenEntryAccess();

  /// Traceability metadata.
  @SerializationOrder(3)
  ScreenEntryTraceability traceability = ScreenEntryTraceability();

  /// Presentation metadata.
  @SerializationOrder(4)
  ScreenEntryPresentation presentation = ScreenEntryPresentation();

  /// Screen design rationale and notes.
  @SerializationOrder(5)
  TextSection designNotes = TextSection();

  /// 10.2.1.n.1. Screen Sections.
  @SerializationOrder(6)
  ScreenSections sections = ScreenSections();

  /// 10.2.1.n.2. Screen Actions.
  @SerializationOrder(7)
  ScreenActions actions = ScreenActions();

  /// 10.2.1.n.3. Screen States.
  @SerializationOrder(8)
  ScreenStates states = ScreenStates();

  /// Contains 0+× ScreenUserCategory.
  @StandardReferences(
    [
      'ISO 9241-11:2018 — the categories of users and their context of use for a screen',
      'ISO 9241-210:2019 — user groups whose tasks the interface must support',
    ],
    'The collection of user categories that describe who uses this screen and in what context.',
  )
  @SectionId('SCRUSC-USER-LST')
  @SectionIdPattern('SCRUSC-USER-xxx')
  @ContentHelp('Add one entry per user category.')
  @SerializationOrder(9)
  List<ScreenUserCategoryEntry> userCategories = [];

  /// Contains 0+× EntryPoint.
  @StandardReferences(
    [
      'ISO 9241-151:2008 — navigation entry points into the user interface',
      'ISO 9241-210:2019 — the paths by which users reach a screen to perform their tasks',
    ],
    'The collection of navigation entry points from which users can reach this screen.',
  )
  @SectionId('EPNT-ENTR-LST')
  @SectionIdPattern('EPNT-ENTR-xxx')
  @ContentHelp('Add one entry per entry point.')
  @SerializationOrder(10)
  List<EntryPointEntry> entryPoints = [];

  /// Contains 0+× ScreenResponsiveRule.
  @StandardReferences(
    [
      'ISO 9241-125:2017 — adaptation of visual presentation to different display conditions',
      'ISO 9241-112:2017 — presentation of information across varying contexts of use',
    ],
    'The collection of responsive rules that adapt a screen layout to different device sizes.',
  )
  @SectionId('SRRE-RESP-LST')
  @SectionIdPattern('SRRE-RESP-xxx')
  @ContentHelp('Add one entry per responsive rule.')
  @SerializationOrder(11)
  List<ScreenResponsiveRuleEntry> responsiveRules = [];
}

/// Classification and routing metadata.
@StandardReferences(
  [
    'ISO 9241-151:2008 — navigation structure and routing within the user interface',
    'ISO 9241-112:2017 — categorisation of information for structured presentation',
  ],
  'The classification and routing metadata that categorises a screen and locates it in the navigation structure.',
)
@SectionId('SCECL')
class ScreenEntryClassification {
  @Form([
    Field('screenCategory', String, 'Screen Category',
        hint:
            'List/Detail/Form/Dashboard/Settings/Wizard/Dialog/Report/Landing'),
    Field('parentScreenId', String, 'Parent Screen ID',
        hint: 'Parent screen if this is a sub-screen or drill-down'),
    Field('routePattern', String, 'Route Pattern',
        hint: 'Navigation route path, e.g., /orders/:id/edit'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access control settings.
@StandardReferences(
  [
    'ISO 9241-110:2020 — controllability governing who may access an interface',
    'ISO/IEC 25010:2023 — interaction capability constrained by authorization',
  ],
  'The access-control settings that determine which roles and permissions may reach a screen.',
)
@SectionId('SCEAC')
class ScreenEntryAccess {
  @Form([
    Field('accessLevel', String, 'Access Level',
        hint: 'Public/Authenticated/Role-specific'),
    Field('requiredRoles', String, 'Required Roles',
        hint: 'Authorization roles that may access this screen'),
    Field('requiredPermissions', String, 'Required Permissions',
        hint: 'Specific permissions needed'),
    Field('permissionEffect', String, 'Permission Effect',
        hint: 'Hide-Screen/Show-Readonly/Show-With-Restrictions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Traceability metadata.
@StandardReferences(
  [
    'ISO 9241-210:2019 — linkage of screens to the user tasks and requirements they serve',
    'ISO/IEC 25010:2023 — interaction capability traced to product requirements',
  ],
  'The traceability metadata linking a screen to the use cases, requirements, and data entities it serves.',
)
@SectionId('SCETR')
class ScreenEntryTraceability {
  @Form([
    Field('relatedUseCases', String, 'Related Use Cases',
        hint: 'ISC references this screen serves'),
    Field('relatedRequirements', String, 'Related Requirements',
        hint: 'RSP references this screen satisfies'),
    Field('relatedBusinessProcesses', String, 'Related Business Processes',
        hint: 'TOM references where this screen appears'),
    Field('dataEntities', String, 'Data Entities',
        hint: 'IFM entity references displayed/edited'),
    Field('primaryAction', String, 'Primary Action',
        hint: 'Main user action on this screen'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Presentation metadata.
@StandardReferences(
  [
    'ISO 9241-112:2017 — presentation of screen titles, icons, and identifying information',
    'ISO 9241-125:2017 — visual presentation and layout of the screen',
  ],
  'The presentation metadata such as title, icon, and layout that defines how a screen appears.',
)
@SectionId('SCENPR')
class ScreenEntryPresentation {
  @Form([
    Field('pageTitleResource', String, 'Page Title Resource',
        hint: 'Resource key for the screen title text'),
    Field('pageIconResource', String, 'Page Icon Resource',
        hint: 'Resource key for the screen icon'),
    Field('helpTopicId', String, 'Help Topic ID',
        hint: 'Link to help/documentation topic'),
    Field('layout', String, 'Layout',
        hint:
            'Layout description, e.g., Responsive grid — 3 col desktop, 1 col mobile'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.2.1.n.1 Screen Sections (Zones)
// ---------------------------------------------------------------------------

/// 10.2.1.n.1. Screen Sections.
///
/// Logical zones within a screen that group related elements.
@StandardReferences(
  [
    'ISO 9241-112:2017 — organisation of presented information into structured zones',
    'ISO 9241-151:2008 — information architecture and content structure of the interface',
  ],
  'The container that holds the logical zones grouping related elements within a screen.',
)
@SectionId('SCSE')
class ScreenSections {
  @ContentHelp('''
## Screen Sections (10.2.1.n.1)

Logical zones within a screen that group related elements.

### Section Types
- **Header** — Title bar and global actions
- **Toolbar** — Primary action buttons
- **Filter-Bar** — Search and filter controls
- **Content-Primary** — Main content area
- **Content-Secondary** — Supporting content
- **Sidebar** — Navigation or context panels
- **Footer** — Status and secondary actions
- **Tab-Panel** — Tabbed content containers
- **Accordion-Panel** — Collapsible sections
- **Drawer** — Slide-out panels
- **Action-Bar** — Contextual action buttons
- **Form-Group** — Logical field groupings

### Tom UI Mapping
Sections map to Flutter layout widgets:
- Row/Column for directional layout
- Wrap for responsive content
- GridView for structured grids
- Visibility for collapsible sections
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× ScreenSection.
  @StandardReferences(
    [
      'ISO 9241-112:2017 — the set of information zones that structure a display',
      'ISO 9241-151:2008 — content structure and layout of the user interface',
    ],
    'The collection of logical zones that partition a screen into grouped areas.',
  )
  @SectionId('SCRSC-ITEM-LST')
  @SectionIdPattern('SCRSC-ITEM-xxx')
  @ContentHelp('Add one entry per screen section.')
  @SerializationOrder(1)
  List<ScreenSectionEntry> items = [];
}

/// A screen section entry (form).
///
/// A logical zone within a screen: header, toolbar, content area, sidebar, etc.
@StandardReferences(
  [
    'ISO 9241-112:2017 — grouping and structuring of information into presentation zones',
    'ISO 9241-125:2017 — spatial organisation of content within a display',
  ],
  'A single logical zone within a screen that groups related elements together.',
)
@SectionId('SCRSC')
class ScreenSectionEntry {
  @Form([
    Field('sectionId', String, 'Section ID', required: true,
        hint: 'Unique within screen, e.g., header, filter-bar, main-content'),
    Field('sectionName', String, 'Section Name', required: true,
        hint: 'Human label, e.g., "Filter Bar", "Order Details"'),
    Field('purpose', String, 'Purpose',
        hint: 'What this zone contains'),
    Field('sectionType', String, 'Section Type',
        hint:
            'Header/Toolbar/Filter-Bar/Content-Primary/Content-Secondary/Sidebar/Footer/Tab-Panel/Accordion-Panel/Drawer/Action-Bar/Form-Group'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Layout and ordering for the section.
  @SerializationOrder(1)
  ScreenSectionEntryLayout layout = ScreenSectionEntryLayout();

  /// Visibility and collapse behavior.
  @SerializationOrder(2)
  ScreenSectionEntryBehavior behavior = ScreenSectionEntryBehavior();

  /// Contains 0+× ScreenElement within this section.
  @StandardReferences(
    [
      'ISO 9241-161:2016 — the set of visual user-interface elements contained in a display region',
      'ISO 9241-112:2017 — grouping of related information elements for presentation',
    ],
    'The collection of interactive and display elements that belong to this screen section.',
  )
  @SectionId('SCREL-ELEM-LST')
  @SectionIdPattern('SCREL-ELEM-xxx')
  @ContentHelp('Add one entry per screen element.')
  @SerializationOrder(3)
  List<ScreenElementEntry> elements = [];
}

/// Layout and ordering for the section.
@StandardReferences(
  [
    'ISO 9241-125:2017 — spatial layout and ordering of presented information',
    'ISO 9241-112:2017 — organisation of information within a display area',
  ],
  'The layout direction, order, and border styling that arrange a screen section within its screen.',
)
@SectionId('SSEL')
class ScreenSectionEntryLayout {
    @Form([
        Field('layoutDirection', String, 'Layout Direction',
                hint: 'Horizontal/Vertical/Wrap/Grid'),
        Field('displayOrder', int, 'Display Order',
                hint: 'Position in reading order'),
        Field('titleResource', String, 'Title Resource',
                hint: 'Resource key for section header text'),
        Field('borderStyle', String, 'Border Style',
                hint: 'Named style or resource key'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Visibility and collapse behavior.
@StandardReferences(
  [
    'ISO 9241-161:2016 — collapsible and expandable states of user-interface containers',
    'ISO 9241-110:2020 — controllability over the visibility of interface zones',
  ],
  'The visibility and collapse behavior that governs when and how a screen section is shown.',
)
@SectionId('SSEB')
class ScreenSectionEntryBehavior {
    @Form([
        Field('collapsible', String, 'Collapsible',
                hint: 'Yes/No — can the user collapse this section?'),
        Field('initiallyCollapsed', String, 'Initially Collapsed',
                hint: 'Yes/No — default collapsed state'),
        Field('visibilityCondition', String, 'Visibility Condition',
                hint: 'When this section is shown, e.g., role==Admin'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A screen element entry (form).
///
/// Any interactive or display element within a screen section: buttons, fields,
/// data displays, icons, labels, status indicators.
@StandardReferences(
  [
    'ISO 9241-161:2016 — the catalogue of visual user-interface elements such as buttons, fields, and displays',
    'ISO 9241-143:2012 — form fields and input controls within a screen',
  ],
  'A single interactive or display element within a screen section together with its type and behavior.',
)
@SectionId('SCREL')
class ScreenElementEntry {
  @Form([
    Field('elementId', String, 'Element ID', required: true,
        hint: 'Unique within screen, e.g., btn-submit, fld-customer-name'),
    Field('elementName', String, 'Element Name', required: true,
        hint: 'Human-readable label'),
    Field('elementType', String, 'Element Type', required: true,
        hint:
            'Action-Button/Text-Field/Number-Field/Date-Field/Select-Field/'
            'Checkbox/Toggle/Data-Display/Data-Table/Card/Chart/Status-Indicator/'
            'Icon/Label/Link/Image/Divider/Spacer/Tab-Bar/Badge'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Labels and icon resources.
  @SerializationOrder(1)
  ScreenElementEntryResources resources = ScreenElementEntryResources();

  /// Placement and layout settings.
  @SerializationOrder(2)
  ScreenElementEntryLayout layout = ScreenElementEntryLayout();

  /// Visibility and permission rules.
  @SerializationOrder(3)
  ScreenElementEntryBehavior behavior = ScreenElementEntryBehavior();

  /// Styling and data binding.
  @SerializationOrder(4)
  ScreenElementEntryPresentation presentation =
      ScreenElementEntryPresentation();

  /// 10.2.1.n.m.k.1. Element Action.
  @SerializationOrder(5)
  ScreenElementAction? elementAction;

  /// 10.2.1.n.m.k.2. Element Field Spec.
  @SerializationOrder(6)
  ScreenElementFieldSpec? fieldSpec;

  /// 10.2.1.n.m.k.3. Element Data Display.
  @SerializationOrder(7)
  ScreenElementDataDisplay? dataDisplay;

  /// Contains 0+× ElementValidationRule.
  @StandardReferences(
    [
      'ISO 9241-143:2012 — validation of user input in form-based interaction',
      'ISO 9241-110:2020 — use error tolerance through input validation',
    ],
    'The collection of validation rules that constrain and check the input for a screen element.',
  )
  @SectionId('EVRE-VALI-LST')
  @SectionIdPattern('EVRE-VALI-xxx')
  @ContentHelp('Add one entry per validation rule.')
  @SerializationOrder(8)
  List<ElementValidationRuleEntry> validationRules = [];
}

/// Labels and icon resources for screen element.
@StandardReferences(
  [
    'ISO 9241-161:2016 — labels, icons, and tooltips associated with user-interface elements',
    'ISO 9241-112:2017 — presentation of labels and identifying information to the user',
  ],
  'The label, hint, description, and icon resources that identify a screen element to the user.',
)
@SectionId('SEER')
class ScreenElementEntryResources {
  @Form([
    Field('labelResource', String, 'Label Resource',
        hint: 'Resource key for display label'),
    Field('hintResource', String, 'Hint Resource',
        hint: 'Resource key for tooltip/helper text'),
    Field('descriptionResource', String, 'Description Resource',
        hint: 'Resource key for extended description'),
    Field('iconResource', String, 'Icon Resource',
        hint: 'Resource key for icon'),
    Field('iconPosition', String, 'Icon Position',
        hint: 'Leading/Trailing/Above/Below/Only'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Placement and layout settings for screen element.
@StandardReferences(
  [
    'ISO 9241-161:2016 — placement and layout of visual user-interface elements',
    'ISO 9241-125:2017 — spatial arrangement of information for visual presentation',
  ],
  'The placement, sizing, and alignment settings that position a screen element within its section.',
)
@SectionId('SCELENLA')
class ScreenElementEntryLayout {
  @Form([
    Field('placementOrder', int, 'Placement Order',
        hint: 'Order within parent section'),
    Field('width', String, 'Width',
        hint: 'Fill/Auto/Fixed(200)/Proportion(1/3)'),
    Field('alignment', String, 'Alignment',
        hint: 'Start/Center/End/Stretch'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Visibility and permission rules for screen element.
@StandardReferences(
  [
    'ISO 9241-161:2016 — states of user-interface elements such as visible, enabled, and read-only',
    'ISO 9241-110:2020 — controllability governing when an element is interactive',
  ],
  'The visibility, enablement, and permission rules that determine when a screen element can be seen or used.',
)
@SectionId('SEEB')
class ScreenElementEntryBehavior {
  @Form([
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'When this element is shown'),
    Field('enabledCondition', String, 'Enabled Condition',
        hint: 'When this element is interactive'),
    Field('readonlyCondition', String, 'Readonly Condition',
        hint: 'When this element is read-only'),
    Field('requiredPermission', String, 'Required Permission',
        hint: 'Permission needed to see/interact'),
    Field('permissionEffect', String, 'Permission Effect',
        hint: 'Hide/Disable/Readonly'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Styling and data binding for screen element.
@StandardReferences(
  [
    'ISO 9241-125:2017 — visual presentation attributes such as style and colour of information',
    'ISO 9241-112:2017 — coding of information through visual style variants',
  ],
  'The styling and data-binding attributes that govern how a screen element appears and connects to data.',
)
@SectionId('SCELENPR')
class ScreenElementEntryPresentation {
  @Form([
    Field('styleVariant', String, 'Style Variant',
        hint: 'Primary/Secondary/Danger/Subtle/Custom'),
    Field('accessibilityLabel', String, 'Accessibility Label',
        hint: 'Override for screen readers'),
    Field('dataBinding', String, 'Data Binding',
        hint: 'Path to bound data field, e.g., order.customerName'),
    Field('defaultValue', String, 'Default Value',
        hint: 'Default value or expression'),
    Field('notes', String, 'Design Notes',
        hint: 'Design rationale or open questions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Action specification for an action-type element (form).
///
/// Defines button/link behavior: action reference, confirmation, navigation.
@StandardReferences(
  [
    'ISO 9241-161:2016 — command and action user-interface elements such as buttons and links',
    'ISO 9241-110:2020 — controllability over action-type element behavior',
  ],
  'The specification of button or link behavior for an action-type element including its reference and effect.',
)
@SectionId('SCELAC')
class ScreenElementAction {
  @Form([
    Field('actionId', String, 'Action ID',
        hint: 'Reference to action system action'),
    Field('actionType', String, 'Action Type',
        hint:
            'Submit/Save/Cancel/Delete/Navigate/Export/Import/Print/Refresh/Custom'),
    Field('buttonStyle', String, 'Button Style',
        hint:
            'Primary/Secondary/Tertiary/Danger/Text-Only/Icon-Only/Outlined/Floating'),
    Field('actionTrigger', String, 'Action Trigger',
        hint: 'User interaction that triggers execution'),
    Field('actionPayload', String, 'Action Payload',
        hint: 'Data passed when the action fires'),
    Field('keyboardShortcut', String, 'Keyboard Shortcut',
        hint: 'Shortcut binding, e.g., Ctrl+S'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Confirmation and execution feedback behavior.
  @SerializationOrder(1)
  ScreenElementActionExecution execution = ScreenElementActionExecution();

  /// Post-action navigation rules.
  @SerializationOrder(2)
  ScreenElementActionNavigation navigation = ScreenElementActionNavigation();
}

/// Confirmation and execution feedback behavior.
@StandardReferences(
  [
    'ISO 9241-110:2020 — use error tolerance and feedback during action execution',
    'ISO 9241-161:2016 — user-interface elements for confirmation and progress feedback',
  ],
  'The confirmation and execution-feedback behavior that governs how an action element runs and reports.',
)
@SectionId('SEAE')
class ScreenElementActionExecution {
  @Form([
    Field('confirmationRequired', String, 'Confirmation Required',
        hint: 'Yes/No — show confirmation dialog?'),
    Field('confirmationMessageResource', String,
        'Confirmation Message Resource',
        hint: 'Resource key for confirmation prompt'),
    Field('loadingLabelResource', String, 'Loading Label Resource',
        hint: 'Resource key for label during async execution'),
    Field('successMessageResource', String, 'Success Message Resource',
        hint: 'Resource key for success notification'),
    Field('errorHandling', String, 'Error Handling',
        hint: 'Inline/Toast/Dialog/Banner'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Post-action navigation rules.
@StandardReferences(
  [
    'ISO 9241-151:2008 — navigation between screens following an action',
    'ISO 9241-110:2020 — conformity with user expectations for post-action navigation',
  ],
  'The navigation rules that determine where the user is taken after an action completes.',
)
@SectionId('SEAN')
class ScreenElementActionNavigation {
  @Form([
    Field('navigateTo', String, 'Navigate To',
        hint: 'Target screen ID or route after action'),
    Field('navigateParams', String, 'Navigate Params',
        hint: 'Parameters to pass to navigation target'),
    Field('doubleClickPrevention', String, 'Double-Click Prevention',
        hint: 'Yes/No — disable during execution?'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Field specification for an input-type element (form).
///
/// Defines input behavior: data type, constraints, validation trigger, masks.
@StandardReferences(
  [
    'ISO 9241-143:2012 — form-based interaction and input-field behavior',
    'ISO 9241-110:2020 — suitability for the task in accepting user input',
  ],
  'The specification of input behavior for an input-type element including data type and constraints.',
)
@SectionId('SEFS')
class ScreenElementFieldSpec {
  @Form([
    Field('fieldName', String, 'Field Name',
        hint: 'Logical form field name, maps to data model attribute'),
    Field('dataType', String, 'Data Type',
        hint:
            'String/Integer/Decimal/Currency/Date/DateTime/Time/Boolean/Enum/'
            'Email/Phone/URL/Password/Rich-Text/Color/File'),
    Field('placeholderResource', String, 'Placeholder Resource',
        hint: 'Resource key for placeholder text'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Prefix, suffix, and formatting.
  @SerializationOrder(1)
  ScreenElementFieldSpecFormatting formatting =
      ScreenElementFieldSpecFormatting();

  /// Length and value constraints.
  @SerializationOrder(2)
  ScreenElementFieldSpecConstraints constraints =
      ScreenElementFieldSpecConstraints();

  /// Validation behavior.
  @SerializationOrder(3)
  ScreenElementFieldSpecValidation validation =
      ScreenElementFieldSpecValidation();

  /// Selection and input assistance.
  @SerializationOrder(4)
  ScreenElementFieldSpecSelection selection =
      ScreenElementFieldSpecSelection();
}

/// Prefix, suffix, and formatting for field spec.
@StandardReferences(
  [
    'ISO 9241-143:2012 — formatting and affordances for form-field input',
    'ISO 9241-112:2017 — presentation of formatted information such as masks and prefixes',
  ],
  'The prefix, suffix, and formatting that shape how a form field displays and accepts input.',
)
@SectionId('SEFSF')
class ScreenElementFieldSpecFormatting {
  @Form([
    Field('prefixResource', String, 'Prefix Resource',
        hint: 'Prefix text/icon resource, e.g., currency symbol'),
    Field('suffixResource', String, 'Suffix Resource',
        hint: 'Suffix text/icon resource, e.g., unit label'),
    Field('inputMask', String, 'Input Mask',
        hint: 'Pattern, e.g., ##/##/####'),
    Field('displayFormat', String, 'Display Format',
        hint: 'Format pattern, e.g., #,##0.00'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Length and value constraints for field spec.
@StandardReferences(
  [
    'ISO 9241-143:2012 — constraints on form-field input such as length and value ranges',
    'ISO 9241-110:2020 — use error tolerance through bounded input constraints',
  ],
  'The length and value constraints that bound acceptable input for a form field.',
)
@SectionId('SEFSC')
class ScreenElementFieldSpecConstraints {
  @Form([
    Field('maxLength', int, 'Max Length',
        hint: 'Character limit'),
    Field('minLength', int, 'Min Length',
        hint: 'Minimum length'),
    Field('minValue', String, 'Min Value',
        hint: 'Minimum allowed value for numeric/date fields'),
    Field('maxValue', String, 'Max Value',
        hint: 'Maximum allowed value for numeric/date fields'),
    Field('decimalPlaces', int, 'Decimal Places',
        hint: 'Number of decimal places'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Validation behavior for field spec.
@StandardReferences(
  [
    'ISO 9241-110:2020 — use error tolerance through input validation and error display',
    'ISO 9241-143:2012 — validation behavior for form fields',
  ],
  'The validation behavior for a form field including trigger, required rules, and error display.',
)
@SectionId('SEFSV')
class ScreenElementFieldSpecValidation {
  @Form([
    Field('validationTrigger', String, 'Validation Trigger',
        hint: 'On-Change/On-Blur/On-Submit/Debounced'),
    Field('errorDisplayMode', String, 'Error Display Mode',
        hint: 'Below-Field/Tooltip/Inline/Banner'),
    Field('required', String, 'Required',
        hint: 'Yes/No/Conditional'),
    Field('requiredCondition', String, 'Required Condition',
        hint: 'Condition when field becomes required'),
    Field('clearButton', String, 'Clear Button',
        hint: 'Yes/No — show clear/reset affordance'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Selection and input assistance for field spec.
@StandardReferences(
  [
    'ISO 9241-143:2012 — form fields with selection and input assistance',
    'ISO 9241-161:2016 — selection controls such as dropdowns and radio groups',
  ],
  'The selection and input-assistance behavior for a form field such as autocomplete and option sources.',
)
@SectionId('SEFSS')
class ScreenElementFieldSpecSelection {
  @Form([
    Field('autocompleteSource', String, 'Autocomplete Source',
        hint: 'Source reference for autocomplete suggestions'),
    Field('optionsSource', String, 'Options Source',
        hint: 'For select fields: static list, API endpoint, or entity query'),
    Field('selectMode', String, 'Select Mode',
        hint: 'Single/Multi'),
    Field('displayMode', String, 'Display Mode',
        hint:
            'Dropdown/Radio-Group/Chip-Group/Segmented-Button/Autocomplete/'
            'Dialog-Picker'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Data display specification for display-type elements (form).
///
/// Defines how data is presented: format, empty state, refresh, drill-down.
@StandardReferences(
  [
    'ISO 9241-112:2017 — principles for the presentation of information',
    'ISO 9241-125:2017 — visual presentation of information to the user',
  ],
  'The specification of how data is presented for a display-type element including format and empty state.',
)
@SectionId('SEDD')
class ScreenElementDataDisplay {
  @Form([
    Field('dataSource', String, 'Data Source',
        hint: 'Data entity or query reference'),
    Field('displayFormat', String, 'Display Format',
        hint: 'How data is formatted for display'),
    Field('emptyStateMessageResource', String, 'Empty State Message',
        hint: 'Resource key for message when no data'),
    Field('emptyStateIconResource', String, 'Empty State Icon',
        hint: 'Resource key for icon when no data'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Refresh and drill-down behavior.
  @SerializationOrder(1)
  ScreenElementDataDisplayBehavior behavior =
      ScreenElementDataDisplayBehavior();

  /// Table/list interaction controls.
  @SerializationOrder(2)
  ScreenElementDataDisplayOptions options = ScreenElementDataDisplayOptions();
}

/// Refresh and drill-down behavior.
@StandardReferences(
  [
    'ISO 9241-112:2017 — presentation of information as it refreshes and updates',
    'ISO 9241-151:2008 — navigation such as drill-down between related views',
  ],
  'The refresh and drill-down behavior that governs how displayed data updates and navigates deeper.',
)
@SectionId('SEDDB')
class ScreenElementDataDisplayBehavior {
  @Form([
    Field('refreshMode', String, 'Refresh Mode',
        hint: 'Auto/Manual/Interval(seconds)'),
    Field('drillDownTarget', String, 'Drill-Down Target',
        hint: 'Screen ID navigated to on click/tap'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Table/list interaction controls.
@StandardReferences(
  [
    'ISO 9241-143:2012 — form and table interaction controls such as sorting and filtering',
    'ISO 9241-112:2017 — presentation of tabular and list information',
  ],
  'The interaction controls for tables and lists such as sorting, filtering, pagination, and selection.',
)
@SectionId('SEDDO')
class ScreenElementDataDisplayOptions {
  @Form([
    Field('sortable', String, 'Sortable',
        hint: 'Yes/No — for table columns'),
    Field('filterable', String, 'Filterable',
        hint: 'Yes/No — for table columns'),
    Field('paginated', String, 'Paginated',
        hint: 'Yes/No — for lists and tables'),
    Field('pageSize', int, 'Page Size',
        hint: 'Default items per page'),
    Field('selectable', String, 'Selectable',
        hint: 'None/Single/Multi — row selection mode'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A validation rule entry (form).
@StandardReferences(
  [
    'ISO 9241-110:2020 — use error tolerance through validation of user input',
    'ISO 9241-143:2012 — form-based interaction and input validation',
  ],
  'A single validation rule describing how one input constraint is checked and reported.',
)
@SectionId('ELVARUEN')
class ElementValidationRuleEntry {
  @Form([
    Field('ruleType', String, 'Rule Type', required: true,
        hint:
            'Required/Min-Length/Max-Length/Pattern/Range/Custom/Cross-Field/'
            'Async/Unique'),
    Field('ruleExpression', String, 'Rule Expression',
        hint: 'Validation expression or pattern'),
    Field('errorMessageResource', String, 'Error Message Resource',
        hint: 'Resource key for validation error message'),
    Field('severity', String, 'Severity',
        hint: 'Error/Warning/Info'),
    Field('validateOn', String, 'Validate On',
        hint: 'On-Change/On-Blur/On-Submit'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.2.1.n.2 Screen Actions
// ---------------------------------------------------------------------------

/// 10.2.1.n.2. Screen Actions.
///
/// Top-level actions available on the screen (toolbar, app bar, FAB).
@StandardReferences(
  [
    'ISO 9241-110:2020 — controllability over available top-level screen actions',
    'ISO 9241-161:2016 — command and action user-interface elements',
  ],
  'The set of top-level actions available on the screen through the toolbar, app bar, or FAB.',
)
@SectionId('SCAC')
class ScreenActions {
  @ContentHelp('''
## Screen Actions (10.2.1.n.2)

Top-level actions available on the screen.

### Action Placements
- **App-Bar** — Always visible, max 2-3 icons
- **Toolbar** — Below app bar, primary operations
- **FAB** — Prominent single primary action
- **Context-Menu** — Right-click/long-press
- **Overflow-Menu** — Secondary actions in ... menu

### Tom UI Mapping
Actions integrate with `TomAction` system:
- Authorization checks via permission field
- Confirmation dialogs via confirmationRequired
- Keyboard shortcuts via keyboardShortcut
- Success/error feedback via message resources
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× ScreenAction.
  @StandardReferences(
    [
      'ISO 9241-110:2020 — controllability over the set of available screen actions',
      'ISO 9241-161:2016 — command and action user-interface elements',
    ],
    'The collection of individual screen-action entries for this screen.',
  )
  @SectionId('SCRAC-ITEM-LST')
  @SectionIdPattern('SCRAC-ITEM-xxx')
  @ContentHelp('Add one entry per screen action.')
  @SerializationOrder(1)
  List<ScreenActionEntry> items = [];
}

/// A screen action entry (form).
///
/// A top-level action available on the screen via toolbar, app bar, or FAB.
@StandardReferences(
  [
    'ISO 9241-110:2020 — controllability over the sequence and pace of screen actions',
    'ISO 9241-161:2016 — command and action user-interface elements',
  ],
  'A single top-level screen action available via toolbar, app bar, or floating action button.',
)
@SectionId('SCRAC')
class ScreenActionEntry {
  @Form([
    Field('actionId', String, 'Action ID', required: true,
        hint: 'Unique action identifier'),
    Field('actionName', String, 'Action Name', required: true,
        hint: 'Human-readable action name'),
    Field('actionType', String, 'Action Type',
        hint:
            'Submit/Save/Cancel/Delete/Navigate/Export/Import/Print/Refresh'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Visual presentation of the action.
  @SerializationOrder(1)
  ScreenActionEntryVisual visual = ScreenActionEntryVisual();

  /// Visibility, enablement, and permission rules.
  @SerializationOrder(2)
  ScreenActionEntryConditions conditions = ScreenActionEntryConditions();

  /// Confirmation, navigation, and feedback behavior.
  @SerializationOrder(3)
  ScreenActionEntryBehavior behavior = ScreenActionEntryBehavior();
}

/// Visual presentation of the action.
@StandardReferences(
  [
    'ISO 9241-161:2016 — visual presentation of command and action elements',
    'ISO 9241-125:2017 — visual presentation of information such as labels and icons',
  ],
  'The visual presentation of a screen action including its label, icon, placement, and style.',
)
@SectionId('SAEV')
class ScreenActionEntryVisual {
  @Form([
    Field('labelResource', String, 'Label Resource',
        hint: 'Resource key for button label'),
    Field('iconResource', String, 'Icon Resource',
        hint: 'Resource key for action icon'),
    Field('placement', String, 'Placement',
        hint: 'App-Bar/Toolbar/FAB/Context-Menu/Overflow-Menu'),
    Field('buttonStyle', String, 'Button Style',
        hint: 'Primary/Secondary/Tertiary/Danger/Icon-Only/Text-Only'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Visibility, enablement, and permission rules.
@StandardReferences(
  [
    'ISO 9241-110:2020 — controllability over when an action is available to the user',
    'ISO 9241-161:2016 — states of command and action elements such as enabled or hidden',
  ],
  'The visibility, enablement, and permission rules that determine when a screen action is available.',
)
@SectionId('SAEC')
class ScreenActionEntryConditions {
  @Form([
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'When this action is shown'),
    Field('enabledCondition', String, 'Enabled Condition',
        hint: 'When this action is active'),
    Field('requiredPermission', String, 'Required Permission',
        hint: 'Permission needed to use this action'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Confirmation, navigation, and feedback behavior.
@StandardReferences(
  [
    'ISO 9241-110:2020 — controllability and use error tolerance for action execution',
    'ISO 9241-161:2016 — command and action user-interface elements',
  ],
  'The confirmation, navigation, and feedback behavior that governs how a screen action executes.',
)
@SectionId('SAEB')
class ScreenActionEntryBehavior {
  @Form([
    Field('confirmationRequired', String, 'Confirmation Required',
        hint: 'Yes/No'),
    Field('confirmationMessageResource', String, 'Confirmation Message',
        hint: 'Resource key for confirmation dialog'),
    Field('keyboardShortcut', String, 'Keyboard Shortcut',
        hint: 'Shortcut binding, e.g., Ctrl+N'),
    Field('navigateTo', String, 'Navigate To',
        hint: 'Target screen after action'),
    Field('successMessageResource', String, 'Success Message',
        hint: 'Resource key for success notification'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.2.1.n.3 Screen States
// ---------------------------------------------------------------------------

/// 10.2.1.n.3. Screen States.
///
/// Different visual/behavioral states the screen can be in.
@StandardReferences(
  [
    'ISO 9241-110:2020 — self-descriptiveness and use error tolerance across interface states',
    'ISO 9241-161:2016 — visual user-interface elements and their states',
  ],
  'The set of visual and behavioral states the screen can present to the user.',
)
@SectionId('SCST')
class ScreenStates {
  @ContentHelp('''
## Screen States (10.2.1.n.3)

Visual/behavioral states the screen can be in.

### Common Screen States
- **Loading** — Data fetching in progress
- **Empty** — No data to display
- **Error** — Load/save failure
- **Permission-Denied** — Unauthorized access
- **First-Use** — Onboarding prompts
- **Offline** — No connectivity
- **Success** — Transient confirmation

### State Display
Each state specifies:
- Message and icon resources
- Illustration (empty state graphic)
- Primary/secondary actions
- Auto-retry behavior

### Tom UI Mapping
States map to `TomStateWidget` with standardized skeletons,
empty states, and error displays.
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× ScreenState.
  @StandardReferences(
    [
      'ISO 9241-110:2020 — self-descriptiveness of the available screen states',
      'ISO 9241-161:2016 — visual elements representing interface states',
    ],
    'The collection of individual screen-state entries for this screen.',
  )
  @SectionId('SCRST-ITEM-LST')
  @SectionIdPattern('SCRST-ITEM-xxx')
  @ContentHelp('Add one entry per screen state.')
  @SerializationOrder(1)
  List<ScreenStateEntry> items = [];
}

/// A screen state entry (form).
///
/// A specific state the screen can be in: loading, empty, error, permission-denied.
@StandardReferences(
  [
    'ISO 9241-110:2020 — use error tolerance and controllability through clear state feedback',
    'ISO 9241-161:2016 — visual user-interface elements conveying interface states',
  ],
  'A single screen state describing one visual or behavioral condition the screen can be in.',
)
@SectionId('SCRST')
class ScreenStateEntry {
  @Form([
    Field('stateName', String, 'State Name', required: true,
        hint:
            'Loading/Empty/Error/Permission-Denied/First-Use/Offline/Success'),
    Field('description', String, 'Description',
        hint: 'When this state occurs'),
    Field('messageResource', String, 'Message Resource',
        hint: 'Resource key for state message'),
    Field('iconResource', String, 'Icon Resource',
        hint: 'Resource key for state icon'),
    Field('illustrationResource', String, 'Illustration Resource',
        hint: 'Resource key for state illustration/image'),
    Field('primaryActionLabel', String, 'Primary Action Label',
        hint: 'Resource key for recovery action, e.g., Try Again'),
    Field('primaryActionTarget', String, 'Primary Action Target',
        hint: 'Action or navigation on recovery'),
    Field('secondaryActionLabel', String, 'Secondary Action Label',
        hint: 'Resource key for alternative action'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A user category entry (form).
@StandardReferences(
  [
    'ISO 9241-11:2018 — usability for a specified group of users and context of use',
    'ISO 9241-210:2019 — human-centred design accounting for distinct user groups',
  ],
  'A single user category describing how screen content varies for one class of users.',
)
@SectionId('SUCE')
class ScreenUserCategoryEntry {
  @Form([
    Field('categoryName', String, 'Category Name', required: true,
        hint: 'The name of this user category'),
    Field('description', String, 'Description',
        hint: 'What this user category sees/can do'),
    Field('contentVariations', String, 'Content Variations',
        hint: 'How screen content differs for this category'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// An entry point entry (form).
@StandardReferences(
  [
    'ISO 9241-151:2008 — navigation and entry points into the user interface',
    'ISO 9241-11:2018 — context of use from which the user arrives',
  ],
  'A single entry point describing where a user comes from when reaching this screen.',
)
@SectionId('EPNT')
class EntryPointEntry {
  @Form([
    Field('entryPoint', String, 'Entry Point', required: true,
        hint: 'Where the user comes from'),
    Field('source', String, 'Source',
        hint: 'Source screen, navigation item, or external link'),
    Field('contextPassed', String, 'Context Passed',
        hint: 'Data or parameters passed from source'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A responsive rule entry (form).
///
/// How the screen adapts at different breakpoints.
@StandardReferences(
  [
    'ISO 9241-112:2017 — presentation of information adapted to the display context',
    'ISO 9241-125:2017 — visual presentation of information across viewports',
  ],
  'A single responsive-adaptation rule describing how the screen changes at a given breakpoint.',
)
@SectionId('SCRERUEN')
class ScreenResponsiveRuleEntry {
  @Form([
    Field('breakpoint', String, 'Breakpoint', required: true,
        hint: 'Mobile/Tablet/Desktop/Large-Desktop'),
    Field('layoutChanges', String, 'Layout Changes',
        hint: 'How layout adapts, e.g., 3-col → 1-col'),
    Field('hiddenElements', String, 'Hidden Elements',
        hint: 'Elements hidden at this breakpoint'),
    Field('collapsedSections', String, 'Collapsed Sections',
        hint: 'Sections that collapse at this breakpoint'),
    Field('navigationMode', String, 'Navigation Mode',
        hint: 'Sidebar/Bottom-Nav/Drawer/Hamburger'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.2.2 Information Architecture
// ---------------------------------------------------------------------------

/// 10.2.2. Information Architecture.
///
/// Overall information architecture: site map, content hierarchy, navigation
/// structure, and entry points. Describes how screens relate to each other
/// and how content is organized across the application.
@StandardReferences(
  [
    'ISO 9241-151:2008 — information architecture and navigation structure for user interfaces',
    'ISO 9241-11:2018 — usability across the full context of use',
  ],
  'The overall organization of content and navigation that relates screens to one another across the application.',
)
@SectionId('IA')
class InformationArchitecture {
  @ContentHelp('''
## Information Architecture (10.2.2)

Overall content organization and navigation structure.

### Components
- **Site Map** — Full screen hierarchy
- **Content Hierarchy** — Logical grouping of features
- **Navigation Structure** — How users move between screens
- **Global Entry Points** — External access points
- **Architecture Diagram** — Visual representation (mermaid)

### Design Principles
- Maximum 3 clicks to any feature
- Clear wayfinding landmarks
- Consistent mental model
- Graceful degradation for authorization
''')
  @SerializationOrder(0)
  String? content;

  /// Site map overview.
  @SerializationOrder(1)
  TextSection siteMap = TextSection();

  /// Content hierarchy description.
  @SerializationOrder(2)
  TextSection contentHierarchy = TextSection();

  /// Navigation structure.
  @SerializationOrder(3)
  TextSection navigationStructure = TextSection();

  /// Global entry points.
  @StandardReferences(
    [
      'ISO 9241-151:2008 — information architecture and navigation entry points to the site',
      'ISO 9241-11:2018 — context of use in which users reach the system',
    ],
    'The collection of global access points through which users enter the application.',
  )
  @SectionId('GLOBA-GLOB-LST')
  @SectionIdPattern('GLOBA-GLOB-xxx')
  @ContentHelp('Add one entry per global entry point.')
  @SerializationOrder(4)
  List<GlobalEntryPointEntry> globalEntryPoints = [];

  /// 10.2.2.5. Information Architecture Diagram.
  @SerializationOrder(5)
  FlowDiagramSection architectureDiagram = FlowDiagramSection();
}

// ---------------------------------------------------------------------------
// 10.3 Screen Flow Structure
// ---------------------------------------------------------------------------

/// 10.3. Screen Flow Structure.
@SectionId('SCFLST')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@SecondLevelSectionId(D09ExperienceDesignSpecification, 'XDS-SCF')
class ScreenFlowStructure {
  @ContentHelp('''
## Screen Flow Structure (10.3)

Navigation model and screen flow diagrams.

### Subsections
- **10.3.1 Navigation Model** — Comprehensive navigation structure
- **10.3.2 Screen Flow Diagram** — Mermaid flowchart

### Tom UI Integration
Screen flow drives:
- Router configuration (go_router)
- Transition animations
- Navigation stack management
- Deep link handling
''')
  @SerializationOrder(0)
  String? content;

  /// 10.3.1. Navigation Model.
  @SerializationOrder(1)
  NavigationModel navigationModel = NavigationModel();

  /// 10.3.2. Screen Flow Diagram (mermaid-flow).
  @SerializationOrder(2)
  FlowDiagramSection screenFlowDiagram = FlowDiagramSection();
}

// ---------------------------------------------------------------------------
// 10.3.1 Navigation Model
// ---------------------------------------------------------------------------

/// 10.3.1. Navigation Model.
///
/// Comprehensive navigation structure: primary, secondary, utility, contextual
/// navigation, deep linking, navigation guards, and platform adaptation.
@SectionId('NAMO')
class NavigationModel {
  @ContentHelp('''
## Navigation Model (10.3.1)

Comprehensive navigation structure definition.

### Subsections
- **10.3.1.1 Overview** — Strategy and landing screens
- **10.3.1.2 Hierarchy** — Full navigation tree
- **10.3.1.3 Primary** — Drawer/sidebar/bottom nav
- **10.3.1.4 Secondary** — Tab bars, segmented controls
- **10.3.1.5 Utility** — User menu, notifications, help
- **10.3.1.6 Contextual** — Breadcrumbs, back, related links
- **10.3.1.7 Deep Linking** — External URL entry points
- **10.3.1.8 Guards** — Route protection (auth, unsaved)

### Tom UI Mapping
Navigation model generates:
- `TomNavigator` configuration
- `TomShell` scaffold setup
- Route guards and redirects
''')
  @SerializationOrder(0)
  String? content;

  /// 10.3.1.1. Navigation Overview.
  @SerializationOrder(1)
  NavigationOverview overview = NavigationOverview();

  /// 10.3.1.2. Navigation Hierarchy.
  @SerializationOrder(2)
  NavigationHierarchy hierarchy = NavigationHierarchy();

  /// 10.3.1.3. Primary Navigation.
  @SerializationOrder(3)
  PrimaryNavigation primaryNavigation = PrimaryNavigation();

  /// 10.3.1.4. Secondary Navigation.
  @SerializationOrder(4)
  SecondaryNavigation secondaryNavigation = SecondaryNavigation();

  /// 10.3.1.5. Utility Navigation.
  @SerializationOrder(5)
  UtilityNavigation utilityNavigation = UtilityNavigation();

  /// 10.3.1.6. Contextual Navigation.
  @SerializationOrder(6)
  ContextualNavigation contextualNavigation = ContextualNavigation();

  /// 10.3.1.7. Deep Linking.
  @SerializationOrder(7)
  DeepLinking deepLinking = DeepLinking();

  /// 10.3.1.8. Navigation Guards.
  @SerializationOrder(8)
  NavigationGuards navigationGuards = NavigationGuards();
}

// ---------------------------------------------------------------------------
// 10.3.1.1 Navigation Overview
// ---------------------------------------------------------------------------

/// 10.3.1.1. Navigation Overview.
///
/// Overall navigation strategy, routing approach, and design decisions.
@SectionId('NAOV')
class NavigationOverview {
  @Form([
    Field('navigationStrategy', String, 'Navigation Strategy',
        hint: 'URL-based/State-based/Hybrid'),
    Field('maxNavigationDepth', int, 'Max Navigation Depth',
        hint: 'Maximum levels of nesting the user encounters'),
    Field('defaultLandingScreen', String, 'Default Landing Screen',
        hint: 'Screen ID the user sees after login'),
    Field('unauthenticatedLanding', String, 'Unauthenticated Landing',
        hint: 'Screen ID for unauthenticated users'),
    Field('navigationPersistence', String, 'Navigation Persistence',
        hint: 'Whether navigation state survives app restart: Yes/No/Partial'),
    Field('historyManagement', String, 'History Management',
        hint: 'Browser-like-stack/Flat/Tab-specific-stacks'),
    Field('backBehavior', String, 'Back Button Behavior',
        hint: 'System-back/In-app-back/Both'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Design rationale and open questions.
  @SerializationOrder(1)
  TextSection designNotes = TextSection();
}

// ---------------------------------------------------------------------------
// 10.3.1.2 Navigation Hierarchy
// ---------------------------------------------------------------------------

/// 10.3.1.2. Navigation Hierarchy.
///
/// Full navigation tree: groups and items forming the app's navigation structure.
@SectionId('NAHI')
class NavigationHierarchy {
  @ContentHelp('''
## Navigation Hierarchy (10.3.1.2)

Full navigation tree: groups and items.

### Structure
- **Groups** — Logical groupings (Sales, Admin, Reports)
- **Items** — Individual destinations within groups

### Group Properties
- Label, icon, description resources
- Display order and collapsibility
- Authorization (roles, permissions)
- Badge aggregation from children

### Item Properties
- Target screen and route
- Icons (normal and active variants)
- Authorization and visibility conditions
- Badges (count, dot, text)
- Keyboard shortcuts
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of the navigation hierarchy structure.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× NavigationGroup.
  @SectionId('NAVGRP-GROU-LST')
  @SectionIdPattern('NAVGRP-GROU-xxx')
  @SerializationOrder(2)
  List<NavigationGroupEntry> groups = [];
}

/// A navigation group entry (form).
///
/// Logical grouping of navigation items (e.g., "Sales", "Administration").
@SectionId('NAVGRP')
class NavigationGroupEntry {
  @Form([
    Field('groupId', String, 'Group ID', required: true,
        hint: 'Unique identifier, e.g., nav-grp-sales'),
    Field('groupLabel', String, 'Label Resource', required: true,
        hint: 'Resource key for display label'),
    Field('groupIcon', String, 'Icon Resource',
        hint: 'Resource key for group icon'),
    Field('groupDescription', String, 'Description Resource',
        hint: 'Resource key for tooltip/subtitle'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Display and expansion behavior.
  @SerializationOrder(1)
  NavigationGroupEntryDisplay display = NavigationGroupEntryDisplay();

  /// Access-control settings.
  @SerializationOrder(2)
  NavigationGroupEntryAccess access = NavigationGroupEntryAccess();

  /// Badge and hierarchy settings.
  @SerializationOrder(3)
  NavigationGroupEntryStructure structure = NavigationGroupEntryStructure();

  /// Contains 0+× NavigationItem.
  @SectionId('NAVIIT-ITEM-LST')
  @SectionIdPattern('NAVIIT-ITEM-xxx')
  @SerializationOrder(4)
  List<NavigationItemEntry> items = [];
}

/// Display and expansion behavior.
@SectionId('NGED')
class NavigationGroupEntryDisplay {
  @Form([
    Field('displayOrder', int, 'Display Order',
        hint: 'Sort position among siblings'),
    Field('collapsible', String, 'Collapsible',
        hint: 'Yes/No — can the group be collapsed?'),
    Field('initiallyExpanded', String, 'Initially Expanded',
        hint: 'Yes/No — default expanded state'),
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'Business rule for visibility'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access-control settings.
@SectionId('NGEA')
class NavigationGroupEntryAccess {
  @Form([
    Field('requiredRoles', String, 'Required Roles',
        hint: 'Comma-separated role IDs'),
    Field('requiredPermissions', String, 'Required Permissions',
        hint: 'Specific permissions required'),
    Field('permissionBehavior', String, 'Permission Behavior',
        hint: 'Hide/Disable/Collapse when unauthorized'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Badge and hierarchy settings.
@SectionId('NGES')
class NavigationGroupEntryStructure {
  @Form([
    Field('badgeType', String, 'Badge Type',
        hint: 'None/Count/Dot/Text — aggregate from children'),
    Field('badgeSource', String, 'Badge Source',
        hint: 'Data source for badge value'),
    Field('navigationLevel', String, 'Navigation Level',
        hint: 'Primary/Secondary/Tertiary'),
    Field('parentGroupId', String, 'Parent Group ID',
        hint: 'For nested groups, null = top-level'),
    Field('dividerBefore', String, 'Divider Before',
        hint: 'Yes/No — show divider above'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A navigation item entry (form).
///
/// A single navigable destination within a group.
@SectionId('NAVIIT')
class NavigationItemEntry {
  @Form([
    Field('itemId', String, 'Item ID', required: true,
        hint: 'Unique identifier, e.g., nav-customers'),
    Field('label', String, 'Label Resource', required: true,
        hint: 'Resource key for display label'),
    Field('targetRoute', String, 'Target Route',
        hint: 'Route path, e.g., /customers'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Display properties: icons, labels, descriptions.
  @SerializationOrder(1)
  NavigationItemEntryDisplay display = NavigationItemEntryDisplay();

  /// Routing configuration.
  @SerializationOrder(2)
  NavigationItemEntryRouting routing = NavigationItemEntryRouting();

  /// Access control settings.
  @SerializationOrder(3)
  NavigationItemEntryAccess access = NavigationItemEntryAccess();

  /// Badge configuration.
  @SerializationOrder(4)
  NavigationItemEntryBadge badge = NavigationItemEntryBadge();

  /// Interaction settings.
  @SerializationOrder(5)
  NavigationItemEntryInteraction interaction = NavigationItemEntryInteraction();
}

/// Display properties for navigation item.
@SectionId('NIED')
class NavigationItemEntryDisplay {
  @Form([
    Field('shortLabel', String, 'Short Label Resource',
        hint: 'Abbreviated label for bottom nav/compact mode'),
    Field('icon', String, 'Icon Resource',
        hint: 'Primary icon resource key'),
    Field('activeIcon', String, 'Active Icon Resource',
        hint: 'Icon variant when selected (filled vs outlined)'),
    Field('description', String, 'Description Resource',
        hint: 'Tooltip or subtitle text'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Routing configuration for navigation item.
@SectionId('NIER')
class NavigationItemEntryRouting {
  @Form([
    Field('targetScreenId', String, 'Target Screen ID',
        hint: 'Reference to Screen Inventory SCR-xxx'),
    Field('targetRouteParams', String, 'Route Parameters',
        hint: 'Default params, e.g., {status: active}'),
    Field('displayOrder', int, 'Display Order',
        hint: 'Position within parent group'),
    Field('isDefault', String, 'Is Default',
        hint: 'Yes/No — default selected item in group'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access control for navigation item.
@SectionId('NIEA')
class NavigationItemEntryAccess {
  @Form([
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'Business condition for visibility'),
    Field('enabledCondition', String, 'Enabled Condition',
        hint: 'When item is visible but non-interactive'),
    Field('requiredRoles', String, 'Required Roles',
        hint: 'Comma-separated roles'),
    Field('requiredPermissions', String, 'Required Permissions',
        hint: 'Specific permissions'),
    Field('permissionBehavior', String, 'Permission Behavior',
        hint: 'Hide/Disable/Show-Locked-Icon'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Badge configuration for navigation item.
@SectionId('NIEB')
class NavigationItemEntryBadge {
  @Form([
    Field('badgeType', String, 'Badge Type',
        hint: 'None/Count/Dot/Text/Icon'),
    Field('badgeSource', String, 'Badge Source',
        hint: 'Data binding for badge, e.g., inbox.unreadCount'),
    Field('badgeColor', String, 'Badge Color',
        hint: 'Error/Warning/Info/Success/Neutral'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Interaction settings for navigation item.
@SectionId('NIEI')
class NavigationItemEntryInteraction {
  @Form([
    Field('keyboardShortcut', String, 'Keyboard Shortcut',
        hint: 'Global shortcut, e.g., Ctrl+Shift+C'),
    Field('searchKeywords', String, 'Search Keywords',
        hint: 'Keywords for global search matching'),
    Field('openBehavior', String, 'Open Behavior',
        hint: 'Replace/Push/New-Tab/Dialog'),
    Field('highlightRules', String, 'Highlight Rules',
        hint: 'Routes that keep this item highlighted'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.3.1.3 Primary Navigation
// ---------------------------------------------------------------------------

/// 10.3.1.3. Primary Navigation.
///
/// How the main navigation appears across platforms: drawer, sidebar, bottom nav.
@SectionId('PRNA')
class PrimaryNavigation {
  @Form([
    Field('mobilePattern', String, 'Mobile Pattern',
        hint: 'Drawer/Bottom-Nav/Bottom-Nav+Drawer'),
    Field('tabletPattern', String, 'Tablet Pattern',
        hint: 'Rail/Collapsible-Sidebar/Drawer'),
    Field('desktopPattern', String, 'Desktop Pattern',
        hint: 'Sidebar/Sidebar-Collapsible/Top-Nav+Sidebar'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Drawer and rail behavior.
  @SerializationOrder(1)
  PrimaryNavigationDrawer drawer = PrimaryNavigationDrawer();

  /// Bottom navigation rules.
  @SerializationOrder(2)
  PrimaryNavigationBottomNav bottomNav = PrimaryNavigationBottomNav();

  /// Sidebar sizing and selection behavior.
  @SerializationOrder(3)
  PrimaryNavigationSidebar sidebar = PrimaryNavigationSidebar();

  /// Design notes and tradeoffs.
  @SerializationOrder(4)
  TextSection designNotes = TextSection();
}

/// Drawer and rail behavior.
@SectionId('PRNADR')
class PrimaryNavigationDrawer {
  @Form([
    Field('drawerBehavior', String, 'Drawer Behavior',
        hint: 'Modal-Overlay/Push-Content/Persistent'),
    Field('drawerWidth', String, 'Drawer Width',
        hint: 'Width specification, e.g., 280dp/25%'),
    Field('drawerHeaderContent', String, 'Drawer Header',
        hint: 'User-Avatar/App-Logo/User-Card/Custom'),
    Field('drawerFooterContent', String, 'Drawer Footer',
        hint: 'Version-Info/Settings-Link/Logout/None'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Bottom navigation rules.
@SectionId('PNBN')
class PrimaryNavigationBottomNav {
  @Form([
    Field('bottomNavMaxItems', int, 'Bottom Nav Max Items',
        hint: 'Maximum items (Material guideline: 3-5)'),
    Field('bottomNavStyle', String, 'Bottom Nav Style',
        hint: 'Fixed/Shifting/Labeled/Icon-Only'),
    Field('bottomNavShowLabels', String, 'Show Labels',
        hint: 'Always/Selected-Only/Never'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Sidebar sizing and selection behavior.
@SectionId('PRNASI')
class PrimaryNavigationSidebar {
  @Form([
    Field('sidebarCollapsedWidth', String, 'Collapsed Width',
        hint: 'Rail/icon width when collapsed'),
    Field('sidebarExpandedWidth', String, 'Expanded Width',
        hint: 'Full sidebar width'),
    Field('selectedItemStyle', String, 'Selected Item Style',
        hint: 'Background-Highlight/Indicator-Bar/Bold/Color-Change'),
    Field('overflowBehavior', String, 'Overflow Behavior',
        hint: 'Scroll/More-Menu/Paginated'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.3.1.4 Secondary Navigation
// ---------------------------------------------------------------------------

/// 10.3.1.4. Secondary Navigation.
///
/// In-page navigation: tab bars, segmented controls.
@SectionId('SENA')
class SecondaryNavigation {
  @ContentHelp('''
## Secondary Navigation (10.3.1.4)

In-page navigation: tab bars and segmented controls.

### Tab Bar Properties
- Host screen ID
- Style (Material/Segmented/Pill/Scrollable)
- Position (Top/Bottom/Left)
- Default tab and persistence
- Swipe and lazy loading behavior

### Tab Item Properties
- Label, icon, and content screen
- Authorization and visibility
- Badges for attention

### Tom UI Mapping
Tab bars map to `TomTabBar` with:
- Swipe navigation on mobile
- Lazy content loading
- Permission-aware tab visibility
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of secondary navigation patterns.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× TabBarDefinition.
  @SectionId('TBDE-TABB-LST')
  @SectionIdPattern('TBDE-TABB-xxx')
  @SerializationOrder(2)
  List<TabBarDefinitionEntry> tabBars = [];
}

/// A tab bar definition entry (form).
///
/// Defines a tab bar or segmented control on a specific screen.
@SectionId('TABADEEN')
class TabBarDefinitionEntry {
  @Form([
    Field('tabBarId', String, 'Tab Bar ID', required: true,
        hint: 'Unique identifier, e.g., tabs-customer-detail'),
    Field('tabBarName', String, 'Tab Bar Name', required: true,
        hint: 'Human label'),
    Field('hostScreenId', String, 'Host Screen ID',
        hint: 'Screen that contains this tab bar'),
    Field('tabBarStyle', String, 'Style',
        hint: 'Material-Tabs/Segmented-Control/Pill-Tabs/Scrollable-Tabs'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Position and selection behavior.
  @SerializationOrder(1)
  TabBarDefinitionEntryBehavior behavior = TabBarDefinitionEntryBehavior();

  /// Visibility and loading profile.
  @SerializationOrder(2)
  TabBarDefinitionEntryLoading loading = TabBarDefinitionEntryLoading();

  /// Contains 1+× TabItem.
  @SectionId('TAITEN-TABS-LST')
  @SectionIdPattern('TAITEN-TABS-xxx')
  @Min(1)
  @SerializationOrder(3)
  List<TabItemEntry> tabs = [];
}

/// Position and selection behavior.
@SectionId('TBDEB')
class TabBarDefinitionEntryBehavior {
    @Form([
        Field('tabBarPosition', String, 'Position',
                hint: 'Top/Bottom/Left'),
        Field('isScrollable', String, 'Scrollable',
                hint: 'Yes/No — scrollable when tabs exceed width'),
        Field('defaultTabIndex', int, 'Default Tab',
                hint: 'Zero-based index of initially selected tab'),
        Field('persistSelection', String, 'Persist Selection',
                hint: 'Yes/No — remember last selected tab'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Visibility and loading profile.
@SectionId('TBDEL')
class TabBarDefinitionEntryLoading {
    @Form([
        Field('swipeEnabled', String, 'Swipe Navigation',
                hint: 'Yes/No — swipe between tabs on mobile'),
        Field('lazyLoading', String, 'Lazy Loading',
                hint: 'Yes/No — load tab content when first selected'),
        Field('visibilityCondition', String, 'Visibility Condition',
                hint: 'When entire tab bar is shown'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A tab item entry (form).
@SectionId('TIE')
class TabItemEntry {
  @Form([
    Field('tabId', String, 'Tab ID', required: true,
        hint: 'Unique within tab bar'),
    Field('label', String, 'Label Resource', required: true,
        hint: 'Resource key for tab label'),
    Field('icon', String, 'Icon Resource',
        hint: 'Tab icon'),
    Field('displayOrder', int, 'Display Order',
        hint: 'Position in tab bar'),
    Field('contentScreenId', String, 'Content Screen ID',
        hint: 'Screen/fragment loaded in tab'),
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'Business rule for visibility'),
    Field('requiredPermissions', String, 'Required Permissions',
        hint: 'Tab-level access control'),
    Field('permissionBehavior', String, 'Permission Behavior',
        hint: 'Hide/Disable'),
    Field('badgeType', String, 'Badge Type',
        hint: 'None/Count/Dot'),
    Field('badgeSource', String, 'Badge Source',
        hint: 'Data source for badge'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.3.1.5 Utility Navigation
// ---------------------------------------------------------------------------

/// 10.3.1.5. Utility Navigation.
///
/// Always-visible utility items: user menu, notifications, help, settings.
@SectionId('UTNA')
class UtilityNavigation {
  @ContentHelp('''
## Utility Navigation (10.3.1.5)

Always-visible utility items in app bar.

### Common Utilities
- **User Menu** — Avatar with profile/settings/logout
- **Notifications** — Bell with unread count
- **Help** — Documentation access
- **Settings** — Quick preferences

### Item Properties
- Position (AppBar-Leading/Trailing, Drawer-Footer)
- Widget type (Icon-Button/Avatar/Dropdown/Popup)
- Badge display (count, dot)
- Interaction (Navigate/Popup/Drawer/Sheet/Dialog)

### Menu Items
Dropdown/popup menus have nested items with:
- Label, icon, display order
- Action type (Navigate/Action/External)
- Danger styling and confirmation
''')
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× UtilityNavigationItem.
  @SectionId('UNIE-ITEM-LST')
  @SectionIdPattern('UNIE-ITEM-xxx')
  @SerializationOrder(1)
  List<UtilityNavigationItemEntry> items = [];
}

/// A utility navigation item entry (form).
///
/// A persistent utility element in the app bar: user avatar, notifications bell,
/// help icon, settings.
@SectionId('UTNAITEN')
class UtilityNavigationItemEntry {
  @Form([
    Field('utilityId', String, 'Utility ID', required: true,
        hint: 'e.g., util-user-menu, util-notifications'),
    Field('label', String, 'Label Resource',
        hint: 'Display label (may be hidden)'),
    Field('icon', String, 'Icon Resource', required: true,
        hint: 'Primary icon'),
    Field('position', String, 'Position',
        hint: 'AppBar-Leading/AppBar-Trailing/Drawer-Footer'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Ordering, rendering, and access rules.
  @SerializationOrder(1)
  UtilityNavigationItemEntryDisplay display =
      UtilityNavigationItemEntryDisplay();

  /// Badge and interaction behavior.
  @SerializationOrder(2)
  UtilityNavigationItemEntryBehavior behavior =
      UtilityNavigationItemEntryBehavior();

    /// Contains 0+× UtilityMenuItem.
    @SectionId('UMIE-MENU-LST')
    @SectionIdPattern('UMIE-MENU-xxx')
    @SerializationOrder(3)
    List<UtilityMenuItemEntry> menuItems = [];
}


/// Ordering, rendering, and access rules.
@SectionId('UNIED')
class UtilityNavigationItemEntryDisplay {
  @Form([
    Field('displayOrder', int, 'Display Order',
        hint: 'Sort position'),
    Field('widgetType', String, 'Widget Type',
        hint: 'Icon-Button/Avatar/Dropdown/Popup-Menu/Badge-Icon'),
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'When shown'),
    Field('requiredRoles', String, 'Required Roles',
        hint: 'Access control'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Badge and interaction behavior.
@SectionId('UNIEB')
class UtilityNavigationItemEntryBehavior {
  @Form([
    Field('badgeType', String, 'Badge Type',
        hint: 'None/Count/Dot'),
    Field('badgeSource', String, 'Badge Source',
        hint: 'Data binding for badge'),
    Field('interactionType', String, 'Interaction Type',
        hint: 'Navigate/Open-Popup/Open-Drawer/Open-Bottom-Sheet/Open-Dialog'),
    Field('targetScreenId', String, 'Target Screen ID',
        hint: 'Navigation target'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A utility menu item entry (form).
///
/// Entry in a utility popup/dropdown menu (e.g., user menu items).
@SectionId('UTMEITEN')
class UtilityMenuItemEntry {
  @Form([
    Field('menuItemId', String, 'Menu Item ID', required: true),
    Field('label', String, 'Label Resource', required: true,
        hint: 'Display text'),
    Field('icon', String, 'Icon Resource',
        hint: 'Leading icon'),
    Field('displayOrder', int, 'Display Order',
        hint: 'Position in menu'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Routing and action references.
  @SerializationOrder(1)
  UtilityMenuItemEntryAction action = UtilityMenuItemEntryAction();

  /// Visibility and confirmation behavior.
  @SerializationOrder(2)
  UtilityMenuItemEntryBehavior behavior = UtilityMenuItemEntryBehavior();
}

/// Routing and action references.
@SectionId('UMIEA')
class UtilityMenuItemEntryAction {
  @Form([
    Field('actionType', String, 'Action Type',
        hint: 'Navigate/Action/External-Link/Divider'),
    Field('targetRoute', String, 'Target Route',
        hint: 'Navigation target'),
    Field('actionId', String, 'Action ID',
        hint: 'Action system reference, e.g., logout'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Visibility and confirmation behavior.
@SectionId('UMIEB')
class UtilityMenuItemEntryBehavior {
  @Form([
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'When shown'),
    Field('requiredPermissions', String, 'Required Permissions',
        hint: 'Access control'),
    Field('isDangerous', String, 'Is Dangerous',
        hint: 'Yes/No — show in danger style'),
    Field('confirmationRequired', String, 'Confirmation Required',
        hint: 'Yes/No — show confirmation dialog'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.3.1.6 Contextual Navigation
// ---------------------------------------------------------------------------

/// 10.3.1.6. Contextual Navigation.
///
/// Breadcrumbs, back navigation, related links.
@SectionId('CONA')
class ContextualNavigation {
  @ContentHelp('''
## Contextual Navigation (10.3.1.6)

Breadcrumbs, back navigation, related links.

### Breadcrumbs
- Platform visibility (desktop-only typical)
- Max visible items before collapse
- Home item configuration
- Separator style
- Position in page layout

### Back Navigation
- System back vs in-app back
- Platform-specific behavior

### Related Links
- "See also" navigation
- Cross-entity links
''')
  @SerializationOrder(0)
  String? content;

  /// 10.3.1.6.1. Breadcrumb Configuration.
  @SerializationOrder(1)
  BreadcrumbConfiguration breadcrumbs = BreadcrumbConfiguration();

  /// Back navigation behavior.
  @SerializationOrder(2)
  TextSection backNavigation = TextSection();

  /// Related links behavior.
  @SerializationOrder(3)
  TextSection relatedLinks = TextSection();
}

/// 10.3.1.6.1. Breadcrumb Configuration.
@SectionId('BRCO')
class BreadcrumbConfiguration {
  @Form([
    Field('enabled', String, 'Enabled',
        hint: 'Yes/No — whether breadcrumbs are shown'),
    Field('platformVisibility', String, 'Platform Visibility',
        hint: 'All/Desktop-Only/Tablet-Up'),
    Field('maxVisibleItems', int, 'Max Visible Items',
        hint: 'Items before collapsing with ellipsis'),
    Field('collapseBehavior', String, 'Collapse Behavior',
        hint: 'Ellipsis-Menu/Hide-Middle/Truncate'),
    Field('showHomeItem', String, 'Show Home',
        hint: 'Yes/No — include root/home as first crumb'),
    Field('homeLabel', String, 'Home Label Resource',
        hint: 'Resource key for home crumb'),
    Field('homeIcon', String, 'Home Icon Resource',
        hint: 'Icon for home crumb'),
    Field('separator', String, 'Separator',
        hint: 'Visual separator: / , > , chevron-icon'),
    Field('currentItemStyle', String, 'Current Item Style',
        hint: 'Bold/Muted/Normal — style of last item'),
    Field('position', String, 'Position',
        hint: 'Below-AppBar/Inside-Content/Top-Of-Page'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.3.1.7 Deep Linking
// ---------------------------------------------------------------------------

/// 10.3.1.7. Deep Linking.
///
/// External entry points, URL patterns, share links.
@SectionId('DELI')
class DeepLinking {
  @ContentHelp('''
## Deep Linking (10.3.1.7)

External entry points and shareable URLs.

### Pattern Properties
- URL pattern with parameters
- Target screen and description
- Authentication requirements
- Permission checks
- Fallback routes
- Share enablement

### Use Cases
- Email links to specific records
- Push notification targets
- External system integrations
- Bookmarkable pages
''')
  @SerializationOrder(0)
  String? content;

  /// Deep linking strategy overview.
  @SerializationOrder(1)
  TextSection strategy = TextSection();

  /// Contains 0+× DeepLinkPattern.
  @SectionId('DELNPT-PATT-LST')
  @SectionIdPattern('DELNPT-PATT-xxx')
  @SerializationOrder(2)
  List<DeepLinkPatternEntry> patterns = [];
}

/// A deep link pattern entry (form).
@SectionId('DELNPT')
class DeepLinkPatternEntry {
  @Form([
    Field('patternId', String, 'Pattern ID', required: true),
    Field('urlPattern', String, 'URL Pattern', required: true,
        hint: 'Route pattern, e.g., /orders/:orderId'),
    Field('targetScreenId', String, 'Target Screen ID',
        hint: 'Screen to open'),
    Field('description', String, 'Description',
        hint: 'When/why this link is used'),
    Field('authenticationRequired', String, 'Authentication Required',
        hint: 'Yes/No — redirect to login if unauthenticated'),
    Field('requiredPermissions', String, 'Required Permissions',
        hint: 'Permissions needed to access via deep link'),
    Field('fallbackRoute', String, 'Fallback Route',
        hint: 'Where to go if target is unavailable'),
    Field('shareEnabled', String, 'Share Enabled',
        hint: 'Yes/No — can users share this link'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.3.1.8 Navigation Guards
// ---------------------------------------------------------------------------

/// 10.3.1.8. Navigation Guards.
///
/// Route guards: unsaved changes, authentication redirects, permission checks.
@SectionId('NAGU')
class NavigationGuards {
  @ContentHelp('''
## Navigation Guards (10.3.1.8)

Route protection for unsaved changes, auth, permissions.

### Guard Types
- **Unsaved-Changes** — Confirm discard
- **Authentication** — Redirect to login
- **Permission** — Block/redirect unauthorized
- **Feature-Flag** — Hide unreleased features
- **Onboarding** — Require initial setup
- **Maintenance** — Show maintenance page

### Guard Properties
- Trigger condition (e.g., form.isDirty)
- Routes/screens covered
- Dialog resources (title, message, buttons)
- Redirect target
- Priority for multi-guard ordering

### Tom UI Mapping
Guards integrate with `TomRouter` middleware.
''')
  @SerializationOrder(0)
  String? content;

  /// Overview of navigation guard strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× NavigationGuard.
  @SectionId('NAVGRD-GUAR-LST')
  @SectionIdPattern('NAVGRD-GUAR-xxx')
  @SerializationOrder(2)
  List<NavigationGuardEntry> guards = [];
}

/// A navigation guard entry (form).
@SectionId('NAVGRD')
class NavigationGuardEntry {
  @Form([
    Field('guardId', String, 'Guard ID', required: true,
        hint: 'Unique identifier, e.g., guard-unsaved-changes'),
    Field('guardName', String, 'Guard Name', required: true,
        hint: 'Human-readable name'),
    Field('guardType', String, 'Guard Type',
        hint:
            'Unsaved-Changes/Authentication/Permission/Feature-Flag/'
            'Onboarding/Maintenance'),
    Field('triggerCondition', String, 'Trigger Condition',
        hint: 'When this guard activates, e.g., form.isDirty'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Covered routes and dialog resources.
  @SerializationOrder(1)
  NavigationGuardEntryDialog dialog = NavigationGuardEntryDialog();

  /// Redirect routing and evaluation priority.
  @SerializationOrder(2)
  NavigationGuardEntryRouting routing = NavigationGuardEntryRouting();
}

/// Covered routes and dialog resources.
@SectionId('NAGUENDI')
class NavigationGuardEntryDialog {
  @Form([
    Field('appliesTo', String, 'Applies To',
        hint: 'Route patterns or screen IDs this guard covers'),
    Field('dialogTitleResource', String, 'Dialog Title Resource',
        hint: 'Resource key for confirmation dialog title'),
    Field('dialogMessageResource', String, 'Dialog Message Resource',
        hint: 'Resource key for confirmation dialog message'),
    Field('confirmActionResource', String, 'Confirm Action Resource',
        hint: 'Resource key for confirm button, e.g., Discard'),
    Field('cancelActionResource', String, 'Cancel Action Resource',
        hint: 'Resource key for cancel button, e.g., Stay'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Redirect routing and evaluation priority.
@SectionId('NGER')
class NavigationGuardEntryRouting {
  @Form([
    Field('redirectTo', String, 'Redirect To',
        hint: 'Route to redirect to if guard blocks navigation'),
    Field('priority', int, 'Priority',
        hint: 'Execution order when multiple guards apply'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.4 Print Layout
// ---------------------------------------------------------------------------

/// 10.4. Print Layout.
@SectionId('PRLA')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@SecondLevelSectionId(D09ExperienceDesignSpecification, 'XDS-PRI')
class PrintAndExportLayout {
  @Form([
    Field('printStrategy', String, 'Print Strategy',
        hint: 'Browser-native / Server-side-PDF / Hybrid / Third-party-service'),
    Field('defaultPaperSize', String, 'Default Paper Size',
        hint: 'A4 / Letter / Legal / A3 / Custom'),
    Field('defaultOrientation', String, 'Default Orientation',
        hint: 'Portrait / Landscape'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Page margins and setup.
  @SerializationOrder(1)
  PrintLayoutPageSetup pageSetup = PrintLayoutPageSetup();

  /// Branding configuration.
  @SerializationOrder(2)
  PrintLayoutBranding branding = PrintLayoutBranding();

  /// Watermark and confidentiality.
  @SerializationOrder(3)
  PrintLayoutWatermark watermark = PrintLayoutWatermark();

  /// Header and footer settings.
  @SerializationOrder(4)
  PrintLayoutHeaderFooter headerFooter = PrintLayoutHeaderFooter();

  /// Archive and batch settings.
  @SerializationOrder(5)
  PrintLayoutArchive archive = PrintLayoutArchive();

  /// 10.4.1. Reports — contains 0+× Report.
  @SectionId('REEN-REPO-LST')
  @SectionIdPattern('REEN-REPO-xxx')
  @SerializationOrder(6)
  List<ReportEntry> reports = [];

  /// 10.4.2. Export Formats — contains 0+× Export Format.
  @SectionId('EXFOEN-EXPO-LST')
  @SectionIdPattern('EXFOEN-EXPO-xxx')
  @SerializationOrder(7)
  List<ExportFormatEntry> exportFormats = [];

  /// 10.4.3. Export Templates — contains 0+× Export
  /// Template.
  @SectionId('EXTEEN-EXPO-LST')
  @SectionIdPattern('EXTEEN-EXPO-xxx')
  @SerializationOrder(8)
  List<ExportTemplateEntry> exportTemplates = [];
}

/// Page margins and setup.
@SectionId('PLPS')
class PrintLayoutPageSetup {
  @Form([
    Field('defaultMarginTop', String, 'Default Margin Top',
        hint: 'Top margin, e.g. 20mm'),
    Field('defaultMarginBottom', String, 'Default Margin Bottom',
        hint: 'Bottom margin, e.g. 20mm'),
    Field('defaultMarginLeft', String, 'Default Margin Left',
        hint: 'Left margin, e.g. 15mm'),
    Field('defaultMarginRight', String, 'Default Margin Right',
        hint: 'Right margin, e.g. 15mm'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Branding configuration.
@SectionId('PRLABR')
class PrintLayoutBranding {
  @Form([
    Field('brandingLogoResource', String, 'Branding Logo Resource',
        hint: 'Resource key or path for company logo'),
    Field('brandingColorPrimary', String, 'Branding Primary Color',
        hint: 'Primary brand color, e.g. #003366'),
    Field('brandingColorSecondary', String, 'Branding Secondary Color',
        hint: 'Secondary brand color for subheadings'),
    Field('brandingFontFamily', String, 'Branding Font Family',
        hint: 'Font family, e.g. Helvetica, Arial'),
    Field('brandingFontSizeBase', String, 'Branding Base Font Size',
        hint: 'Base font size, e.g. 10pt'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Watermark and confidentiality.
@SectionId('PRLAWA')
class PrintLayoutWatermark {
  @Form([
    Field('watermarkText', String, 'Watermark Text',
        hint: 'Text watermark, e.g. DRAFT, CONFIDENTIAL'),
    Field('watermarkImageResource', String, 'Watermark Image Resource',
        hint: 'Resource key for image watermark'),
    Field('watermarkOpacity', String, 'Watermark Opacity',
        hint: 'Watermark opacity, e.g. 0.1'),
    Field('confidentialityMarking', String, 'Confidentiality Marking',
        hint: 'Internal / Confidential / Public'),
    Field('confidentialityPosition', String, 'Confidentiality Position',
        hint: 'Header / Footer / Both / Watermark'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Header and footer settings.
@SectionId('PLHF')
class PrintLayoutHeaderFooter {
  @Form([
    Field('defaultHeaderContent', String, 'Default Header Content',
        hint: 'Header template, e.g. {logo} {reportTitle} {date}'),
    Field('defaultFooterContent', String, 'Default Footer Content',
        hint: 'Footer template, e.g. {companyName} — Page {page}/{pages}'),
    Field('defaultDateFormat', String, 'Default Date Format',
        hint: 'Date format, e.g. dd.MM.yyyy'),
    Field('defaultNumberFormat', String, 'Default Number Format',
        hint: 'Number format, e.g. #,##0.00'),
    Field('defaultCurrencyFormat', String, 'Default Currency Format',
        hint: 'Currency format, e.g. €#,##0.00'),
    Field('defaultTimezone', String, 'Default Timezone',
        hint: 'Timezone, e.g. Europe/Berlin'),
    Field('defaultLocale', String, 'Default Locale',
        hint: 'Locale, e.g. de-DE'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Archive and batch settings.
@SectionId('PRLAAR')
class PrintLayoutArchive {
  @Form([
    Field('archivePolicy', String, 'Archive Policy',
        hint: 'None / 30-days / 1-year / Permanent'),
    Field('reportNamingConvention', String, 'Report Naming Convention',
        hint: 'File naming pattern, e.g. {reportId}_{date}_{version}'),
    Field('batchGenerationSupport', String, 'Batch Generation Support',
        hint: 'Yes / No — support batch report generation'),
    Field('maxConcurrentReports', int, 'Max Concurrent Reports',
        hint: 'Maximum concurrent reports'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.4.1 Reports
// ---------------------------------------------------------------------------

/// A report entry (form).
@SectionId('REPENT')
class ReportEntry {
  @Form([
    Field('reportId', String, 'Report ID',
        hint: 'Unique identifier, e.g. RPT-001', required: true),
    Field('reportName', String, 'Report Name',
        hint: 'Human-readable report title', required: true),
    Field('reportType', String, 'Report Type',
        hint: 'Tabular / Summary / Dashboard / KPI-Card / Chart-Only / Mixed'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Identity and context.
  @SerializationOrder(1)
  ReportIdentity identity = ReportIdentity();

  /// Data source configuration.
  @SerializationOrder(2)
  ReportDataSource dataSource = ReportDataSource();

  /// Output format options.
  @SerializationOrder(3)
  ReportFormat format = ReportFormat();

  /// Page layout settings.
  @SerializationOrder(4)
  ReportLayout layout = ReportLayout();

  /// Header and footer templates.
  @SerializationOrder(5)
  ReportHeaderFooter headerFooter = ReportHeaderFooter();

  /// Sorting and grouping.
  @SerializationOrder(6)
  ReportGrouping grouping = ReportGrouping();

  /// Conditional formatting.
  @SerializationOrder(7)
  ReportFormatting formatting = ReportFormatting();

  /// Interactivity and parameters.
  @SerializationOrder(8)
  ReportInteractivity interactivity = ReportInteractivity();

  /// Pagination settings.
  @SerializationOrder(9)
  ReportPagination pagination = ReportPagination();

  /// Security and access.
  @SerializationOrder(10)
  ReportSecurity security = ReportSecurity();

  /// Lifecycle and archiving.
  @SerializationOrder(11)
  ReportLifecycle lifecycle = ReportLifecycle();

  /// Contains 0+× Report Section.
  @SectionId('RESEE1-SECT-LST')
  @SectionIdPattern('RESEE1-SECT-xxx')
  @SerializationOrder(12)
  List<ReportSectionEntry> sections = [];

  /// Contains 0+× Report Filter.
  @SectionId('REFIEN-FILT-LST')
  @SectionIdPattern('REFIEN-FILT-xxx')
  @SerializationOrder(13)
  List<ReportFilterEntry> filters = [];

  /// Contains 0+× Report Schedule.
  @SectionId('RESCEN-SCHE-LST')
  @SectionIdPattern('RESCEN-SCHE-xxx')
  @SerializationOrder(14)
  List<ReportScheduleEntry> schedules = [];

  /// Contains 0+× Report Distribution.
  @SectionId('REDIEN-DIST-LST')
  @SectionIdPattern('REDIEN-DIST-xxx')
  @SerializationOrder(15)
  List<ReportDistributionEntry> distributions = [];

  /// Contains 0+× Recipient.
  @SectionId('REREEN-RECI-LST')
  @SectionIdPattern('REREEN-RECI-xxx')
  @SerializationOrder(16)
  List<ReportRecipientEntry> recipients = [];
}

/// Report identity and context.
@SectionId('REID')
class ReportIdentity {
  @Form([
    Field('description', String, 'Description',
        hint: 'Business purpose and summary of the report'),
    Field('reportCategory', String, 'Report Category',
        hint: 'Operational / Analytical / Compliance / Financial / Audit'),
    Field('relatedUseCases', String, 'Related Use Cases',
        hint: 'ISC references this report serves'),
    Field('relatedBusinessProcesses', String, 'Related Business Processes',
        hint: 'TOM references where this report is used'),
    Field('relatedDataEntities', String, 'Related Data Entities',
        hint: 'IFM entity references used as data sources'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Report data source configuration.
@SectionId('REDASO')
class ReportDataSource {
  @Form([
    Field('dataSource', String, 'Data Source',
        hint: 'Primary data source or query reference'),
    Field('dataScope', String, 'Data Scope',
        hint: 'What data is included, e.g. All orders for current fiscal year'),
    Field('dataCurrency', String, 'Data Currency',
        hint: 'Real-time / Near-real-time / Daily-snapshot / As-of-date'),
    Field('generationTrigger', String, 'Generation Trigger',
        hint: 'On-demand / Scheduled / Event-triggered / Batch'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Report output format options.
@SectionId('REFO')
class ReportFormat {
  @Form([
    Field('format', String, 'Output Format',
        hint: 'PDF / Excel / CSV / HTML / Word / Print / Multi-format'),
    Field('interactivity', String, 'Interactivity',
        hint: 'Static / Interactive / Drill-down / Parameterized'),
    Field('pageSize', String, 'Page Size',
        hint: 'Override: A4 / Letter / Legal / A3 / Custom'),
    Field('orientation', String, 'Orientation',
        hint: 'Override: Portrait / Landscape / Auto'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Report page layout settings.
@SectionId('RELA')
class ReportLayout {
  @Form([
    Field('marginTop', String, 'Margin Top', hint: 'Override top margin'),
    Field('marginBottom', String, 'Margin Bottom', hint: 'Override bottom margin'),
    Field('marginLeft', String, 'Margin Left', hint: 'Override left margin'),
    Field('marginRight', String, 'Margin Right', hint: 'Override right margin'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Report header and footer templates.
@SectionId('REHEFO')
class ReportHeaderFooter {
  @Form([
    Field('headerTemplate', String, 'Header Template',
        hint: 'Page header override, e.g. {logo} {reportTitle}'),
    Field('footerTemplate', String, 'Footer Template',
        hint: 'Page footer override'),
    Field('coverPage', String, 'Cover Page',
        hint: 'Yes / No — include a cover page'),
    Field('coverPageTemplate', String, 'Cover Page Template',
        hint: 'Cover page content template'),
    Field('tableOfContents', String, 'Table of Contents',
        hint: 'Yes / No — include TOC for multi-section reports'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Report sorting and grouping.
@SectionId('REGR')
class ReportGrouping {
  @Form([
    Field('defaultSortField', String, 'Default Sort Field',
        hint: 'Default sort column or field'),
    Field('defaultSortDirection', String, 'Default Sort Direction',
        hint: 'Ascending / Descending'),
    Field('defaultGroupBy', String, 'Default Group By',
        hint: 'Default grouping field'),
    Field('groupSummary', String, 'Group Summary',
        hint: 'Yes / No — show subtotals per group'),
    Field('grandTotal', String, 'Grand Total',
        hint: 'Yes / No — show grand total row'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Report conditional formatting.
@SectionId('RF')
class ReportFormatting {
  @Form([
    Field('conditionalFormatting', String, 'Conditional Formatting',
        hint: 'Description of conditional formatting rules'),
    Field('highlightRules', String, 'Highlight Rules',
        hint: 'Row/cell highlight rules, e.g. overdue items in red'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Report interactivity and parameters.
@SectionId('REIN')
class ReportInteractivity {
  @Form([
    Field('drillDownTarget', String, 'Drill-Down Target',
        hint: 'Report or screen navigated to on row click'),
    Field('drillThroughReports', String, 'Drill-Through Reports',
        hint: 'Comma-separated report IDs reachable from this report'),
    Field('parameterForm', String, 'Parameter Form',
        hint: 'Description of user input form shown before generation'),
    Field('emptyDataMessage', String, 'Empty Data Message',
        hint: 'Message to display when report has no data'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Report pagination settings.
@SectionId('REPA')
class ReportPagination {
  @Form([
    Field('maxRows', int, 'Maximum Rows',
        hint: 'Row limit for performance; 0 = unlimited'),
    Field('paginationStyle', String, 'Pagination Style',
        hint: 'Page-break / Continuous / Scrollable'),
    Field('rowsPerPage', int, 'Rows Per Page',
        hint: 'For paginated tabular reports'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Report security and access.
@SectionId('RESE')
class ReportSecurity {
  @Form([
    Field('localization', String, 'Localization',
        hint: 'Locales supported, e.g. de-DE, en-US, fr-FR'),
    Field('brandingOverride', String, 'Branding Override',
        hint: 'Override branding for this report'),
    Field('accessLevel', String, 'Access Level',
        hint: 'Public / Authenticated / Role-specific / Confidential'),
    Field('requiredRoles', String, 'Required Roles',
        hint: 'Roles permitted to generate this report'),
    Field('dataLevelSecurity', String, 'Data-Level Security',
        hint: 'Row/column level security rules'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Report lifecycle and archiving.
@SectionId('RELI')
class ReportLifecycle {
  @Form([
    Field('archiveRetention', String, 'Archive Retention',
        hint: 'Retention policy for generated instances, e.g. 90 days'),
    Field('signatureRequired', String, 'Signature Required',
        hint: 'Yes / No — does the report require a digital signature'),
    Field('approvalWorkflow', String, 'Approval Workflow',
        hint: 'Approval steps before distribution, if any'),
    Field('notes', String, 'Notes',
        hint: 'Additional design notes or open questions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A section within a report (form).
@SectionId('RSE')
class ReportSectionEntry {
  @Form([
    Field('sectionId', String, 'Section ID',
        hint: 'Unique within report, e.g. SEC-01', required: true),
    Field('title', String, 'Title',
        hint: 'Section heading displayed in the report', required: true),
    Field('sectionType', String, 'Section Type',
        hint: 'Table / Chart / Summary / Text / KPI-Card / Mixed'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Data source configuration.
  @SerializationOrder(1)
  ReportSectionData data = ReportSectionData();

  /// Layout and page settings.
  @SerializationOrder(2)
  ReportSectionLayout layout = ReportSectionLayout();

  /// Sorting and grouping.
  @SerializationOrder(3)
  ReportSectionSorting sorting = ReportSectionSorting();

  /// Aggregation and limits.
  @SerializationOrder(4)
  ReportSectionAggregation aggregation = ReportSectionAggregation();

  /// Contains 0+× Report Column.
  @SectionId('RECOE1-COLU-LST')
  @SectionIdPattern('RECOE1-COLU-xxx')
  @SerializationOrder(5)
  List<ReportColumnEntry> columns = [];

  /// Contains 0+× Report Chart.
  @SectionId('RECHEN-CHAR-LST')
  @SectionIdPattern('RECHEN-CHAR-xxx')
  @SerializationOrder(6)
  List<ReportChartEntry> charts = [];
}

/// Data source configuration.
@SectionId('RESEDA')
class ReportSectionData {
  @Form([
    Field('purpose', String, 'Purpose',
        hint: 'What this section communicates'),
    Field('dataSource', String, 'Data Source',
        hint: 'Data source or query for this section'),
    Field('dataScope', String, 'Data Scope',
        hint: 'Scope filter applied to the section data'),
    Field('textContent', String, 'Text Content',
        hint: 'Static text or template for text-type sections'),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Layout and page settings.
@SectionId('RESELA')
class ReportSectionLayout {
  @Form([
    Field('displayOrder', int, 'Display Order',
        hint: 'Position within the report'),
    Field('pageBreakBefore', String, 'Page Break Before',
        hint: 'Yes / No — force page break before this section'),
    Field('pageBreakAfter', String, 'Page Break After',
        hint: 'Yes / No — force page break after this section'),
    Field('repeatOnNewPage', String, 'Repeat on New Page',
        hint: 'Yes / No — repeat section header on each new page'),
    Field('orientation', String, 'Orientation',
        hint: 'Override: Portrait / Landscape'),
    Field('conditionalVisibility', String, 'Conditional Visibility',
        hint: 'Condition when section is shown'),
    Field('backgroundColor', String, 'Background Color',
        hint: 'Background color or shading'),
    Field('borderStyle', String, 'Border Style',
        hint: 'None / Thin / Medium / Thick / Custom'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Sorting and grouping.
@SectionId('RESESO')
class ReportSectionSorting {
  @Form([
    Field('sortField', String, 'Sort Field',
        hint: 'Default sort for this section data'),
    Field('sortDirection', String, 'Sort Direction',
        hint: 'Ascending / Descending'),
    Field('groupByField', String, 'Group By Field',
        hint: 'Field used for grouping rows'),
    Field('showGroupSubtotals', String, 'Show Group Subtotals',
        hint: 'Yes / No'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Aggregation and limits.
@SectionId('RESEAG')
class ReportSectionAggregation {
  @Form([
    Field('showSectionTotal', String, 'Show Section Total',
        hint: 'Yes / No — show totals row at section end'),
    Field('aggregationFields', String, 'Aggregation Fields',
        hint: 'Comma-separated fields with aggregation'),
    Field('maxRows', int, 'Max Rows',
        hint: 'Row limit for this section; 0 = unlimited'),
    Field('overflowBehavior', String, 'Overflow Behavior',
        hint: 'Truncate / Continue-next-page / Scroll'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A column in a tabular report section
/// (form).
@SectionId('REPCOLENT')
class ReportColumnEntry {
  @Form([
    Field('columnId', String, 'Column ID',
        hint: 'Unique within section, e.g. COL-01', required: true),
    Field('columnName', String, 'Column Name',
        hint: 'Internal field reference', required: true),
    Field('displayLabel', String, 'Display Label',
        hint: 'Column header text shown in report', required: true),
  ])
  @SerializationOrder(0)
  String? content;

  /// Data source and type.
  @SerializationOrder(1)
  ReportColumnDataSource dataSource = ReportColumnDataSource();

  /// Display formatting.
  @SerializationOrder(2)
  ReportColumnFormatting formatting = ReportColumnFormatting();

  /// Aggregation settings.
  @SerializationOrder(3)
  ReportColumnAggregation aggregation = ReportColumnAggregation();

  /// Interaction options.
  @SerializationOrder(4)
  ReportColumnInteraction interaction = ReportColumnInteraction();

  /// Visibility and layout.
  @SerializationOrder(5)
  ReportColumnLayout layout = ReportColumnLayout();
}

/// Data source and type.
@SectionId('RCDS')
class ReportColumnDataSource {
  @Form([
    Field('dataSourceField', String, 'Data Source Field',
        hint: 'Path to the data field, e.g. order.customer.name'),
    Field('dataType', String, 'Data Type',
        hint: 'String / Integer / Decimal / Currency / Date / Boolean'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Display formatting.
@SectionId('RECOFO')
class ReportColumnFormatting {
  @Form([
    Field('displayOrder', int, 'Display Order',
        hint: 'Column position left to right'),
    Field('width', String, 'Width',
        hint: 'Auto / Fixed(120px) / Proportion(25%)'),
    Field('alignment', String, 'Alignment', hint: 'Left / Center / Right'),
    Field('verticalAlignment', String, 'Vertical Alignment',
        hint: 'Top / Middle / Bottom'),
    Field('formatPattern', String, 'Format Pattern',
        hint: 'Display format, e.g. #,##0.00'),
    Field('currencyCode', String, 'Currency Code',
        hint: 'Currency code if type is Currency'),
    Field('nullDisplay', String, 'Null Display',
        hint: 'What to show for null/empty values'),
    Field('booleanTrueDisplay', String, 'Boolean True Display',
        hint: 'Display for true, e.g. Yes / ✓'),
    Field('booleanFalseDisplay', String, 'Boolean False Display',
        hint: 'Display for false, e.g. No / —'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Aggregation settings.
@SectionId('RECOAG')
class ReportColumnAggregation {
  @Form([
    Field('aggregation', String, 'Aggregation',
        hint: 'None / Sum / Average / Count / Min / Max'),
    Field('aggregationLabel', String, 'Aggregation Label',
        hint: 'Custom label for the aggregation row'),
    Field('conditionalFormattingRules', String, 'Conditional Formatting Rules',
        hint: 'Rules for value-based formatting'),
    Field('hyperlinkTarget', String, 'Hyperlink Target',
        hint: 'Make column values clickable'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Interaction options.
@SectionId('RECOIN')
class ReportColumnInteraction {
  @Form([
    Field('sortable', String, 'Sortable',
        hint: 'Yes / No — can user sort by this column'),
    Field('filterable', String, 'Filterable',
        hint: 'Yes / No — can user filter by this column'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Visibility and layout.
@SectionId('RECOLA')
class ReportColumnLayout {
  @Form([
    Field('visible', String, 'Visible', hint: 'Yes / No / Conditional'),
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'When this column is shown'),
    Field('wordWrap', String, 'Word Wrap', hint: 'Yes / No — wrap long text'),
    Field('truncateAt', int, 'Truncate At',
        hint: 'Character limit before truncation'),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A chart/visualization in a report
/// (form).
@SectionId('REPCHAENT')
class ReportChartEntry {
  @Form([
    Field('chartId', String, 'Chart ID',
        hint: 'Unique within section, e.g. CHT-01', required: true),
    Field('title', String, 'Title',
        hint: 'Chart title', required: true),
    Field('chartType', String, 'Chart Type',
        hint: 'Bar / Line / Pie / Donut / Scatter / Gauge / Heatmap'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Axes configuration.
  @SectionId('RECHAX-AXES-LST')
  @SectionIdPattern('RECHAX-AXES-xxx')
  @SerializationOrder(1)
  List<ReportChartAxes> axes = [];

  /// Series and colors.
  @SerializationOrder(2)
  ReportChartSeries series = ReportChartSeries();

  /// Display options.
  @SerializationOrder(3)
  ReportChartDisplay display = ReportChartDisplay();

  /// Interaction.
  @SerializationOrder(4)
  ReportChartInteraction interaction = ReportChartInteraction();

  /// Layout.
  @SerializationOrder(5)
  ReportChartLayout layout = ReportChartLayout();
}

/// Axes for report chart.
@SectionId('RECHAX')
class ReportChartAxes {
  @Form([
    Field('dataSource', String, 'Data Source',
        hint: 'Data source or query if different from section'),
    Field('xAxisField', String, 'X-Axis Field',
        hint: 'Field mapped to X-axis / category axis'),
    Field('xAxisLabel', String, 'X-Axis Label', hint: 'Axis label text'),
    Field('xAxisFormat', String, 'X-Axis Format',
        hint: 'Format for axis values, e.g. MMM yyyy'),
    Field('yAxisField', String, 'Y-Axis Field',
        hint: 'Field mapped to Y-axis / value axis'),
    Field('yAxisLabel', String, 'Y-Axis Label', hint: 'Axis label text'),
    Field('yAxisFormat', String, 'Y-Axis Format',
        hint: 'Format for axis values, e.g. #,##0'),
    Field('yAxisMin', String, 'Y-Axis Min',
        hint: 'Minimum axis value; Auto or fixed'),
    Field('yAxisMax', String, 'Y-Axis Max',
        hint: 'Maximum axis value; Auto or fixed'),
    Field('secondaryYAxisField', String, 'Secondary Y-Axis Field',
        hint: 'Field for dual-axis charts'),
    Field('secondaryYAxisLabel', String, 'Secondary Y-Axis Label',
        hint: 'Label for secondary axis'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Series for report chart.
@SectionId('RECHSE')
class ReportChartSeries {
  @Form([
    Field('seriesField', String, 'Series Field',
        hint: 'Field used to split data into series'),
    Field('seriesColors', String, 'Series Colors',
        hint: 'Comma-separated color assignments'),
    Field('colorScheme', String, 'Color Scheme',
        hint: 'Named palette, e.g. Corporate / Pastel / Sequential-Blue'),
    Field('legendPosition', String, 'Legend Position',
        hint: 'Top / Bottom / Left / Right / None'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Display for report chart.
@SectionId('RECHDI')
class ReportChartDisplay {
  @Form([
    Field('showDataLabels', String, 'Show Data Labels',
        hint: 'Yes / No / On-Hover'),
    Field('dataLabelFormat', String, 'Data Label Format',
        hint: 'Format for data labels'),
    Field('thresholdLines', String, 'Threshold Lines',
        hint: 'Reference lines, e.g. Target:500000:green'),
    Field('trendLine', String, 'Trend Line',
        hint: 'None / Linear / Moving-Average / Polynomial'),
    Field('goalValue', String, 'Goal Value',
        hint: 'Target/goal value for gauge/KPI charts'),
    Field('emptyDataMessage', String, 'Empty Data Message',
        hint: 'Message when chart has no data'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Interaction for report chart.
@SectionId('RECHIN')
class ReportChartInteraction {
  @Form([
    Field('interactive', String, 'Interactive',
        hint: 'Yes / No — tooltips, zoom, click events'),
    Field('drillDownTarget', String, 'Drill-Down Target',
        hint: 'Report or screen navigated to on chart element click'),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Layout for report chart.
@SectionId('RECHLA')
class ReportChartLayout {
  @Form([
    Field('width', String, 'Width',
        hint: 'Chart width: Full / Half / Third / Custom(400px)'),
    Field('height', String, 'Height',
        hint: 'Chart height, e.g. 300px / Auto'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.4.1 Report Filters, Schedules, Distribution, Recipients
// ---------------------------------------------------------------------------

/// A filter parameter for a report (form).
@SectionId('RFE')
class ReportFilterEntry {
  @Form([
    Field('filterId', String, 'Filter ID',
        hint: 'Unique within report, e.g. FLT-01', required: true),
    Field('filterName', String, 'Filter Name',
        hint: 'Internal reference name', required: true),
    Field('displayLabel', String, 'Display Label',
        hint: 'Label shown in parameter form', required: true),
  ])
  @SerializationOrder(0)
  String? content;

  /// Input and value configuration.
  @SerializationOrder(1)
  ReportFilterEntryInput input = ReportFilterEntryInput();

  /// Scope and validation behavior.
  @SerializationOrder(2)
  ReportFilterEntryBehavior behavior = ReportFilterEntryBehavior();

  /// Presentation options.
  @SerializationOrder(3)
  ReportFilterEntryPresentation presentation =
      ReportFilterEntryPresentation();
}

/// Input and value configuration for a report filter.
@SectionId('RFEI')
class ReportFilterEntryInput {
  @Form([
    Field('dataType', String, 'Data Type',
        hint:
            'String / Integer / Decimal / Date / DateTime / DateRange / Boolean / Enum / Entity-Ref'),
    Field('inputType', String, 'Input Type',
        hint:
            'Text-Field / Select / Multi-Select / Date-Picker / Date-Range-Picker / Checkbox / Radio / Autocomplete / Cascading-Select'),
    Field('defaultValue', String, 'Default Value',
        hint: 'Default filter value, e.g. current_month, today, *'),
    Field('availableValuesSource', String, 'Available Values Source',
        hint:
            'Source for dropdown/select values: static list, entity query, API endpoint'),
    Field('staticValues', String, 'Static Values',
        hint:
            'Comma-separated values if source is static, e.g. Active,Inactive,All'),
    Field('cascadeParent', String, 'Cascade Parent',
        hint: 'Filter ID of parent filter for cascading dropdowns'),
    Field('multiSelect', String, 'Multi-Select',
        hint: 'Yes / No — allow selecting multiple values'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scope and validation behavior for a report filter.
@SectionId('RFEB')
class ReportFilterEntryBehavior {
  @Form([
    Field('required', String, 'Required',
        hint: 'Yes / No — must user provide a value'),
    Field('appliedScope', String, 'Applied Scope',
        hint:
            'Whole-Report / Section:{sectionId} — where the filter applies'),
    Field('displayOrder', int, 'Display Order',
        hint: 'Position in parameter form'),
    Field('groupName', String, 'Group Name',
        hint:
            'Group related filters visually, e.g. Date Filters, Entity Filters'),
    Field('validationRule', String, 'Validation Rule',
        hint: 'Validation expression, e.g. startDate <= endDate'),
    Field('dependsOn', String, 'Depends On',
        hint: 'Other filter IDs this filter depends on'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Presentation options for a report filter.
@SectionId('RFEP')
class ReportFilterEntryPresentation {
  @Form([
    Field('hiddenFilter', String, 'Hidden Filter',
        hint: 'Yes / No — filter applied programmatically, not shown to user'),
    Field('quickFilterBar', String, 'Quick Filter Bar',
        hint: 'Yes / No — show in report quick filter bar'),
    Field('rememberLastValue', String, 'Remember Last Value',
        hint: 'Yes / No — persist user last selection'),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Scheduling rules for report generation
/// (form).
@SectionId('REPSCHENT')
class ReportScheduleEntry {
  @Form([
    Field('scheduleId', String, 'Schedule ID',
        hint: 'Unique within report, e.g. SCH-01', required: true),
    Field('scheduleName', String, 'Schedule Name',
        hint: 'Human-readable name, e.g. Monthly Financial Close',
        required: true),
    Field('frequency', String, 'Frequency',
        hint: 'Daily / Weekly / Bi-weekly / Monthly / Quarterly / Semi-annually / Annually / On-demand / Event-triggered'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Timing configuration.
  @SerializationOrder(1)
  ReportScheduleEntryTiming timing = ReportScheduleEntryTiming();

  /// Retry configuration.
  @SerializationOrder(2)
  ReportScheduleEntryRetry retry = ReportScheduleEntryRetry();

  /// Notification settings.
  @SerializationOrder(3)
  ReportScheduleEntryNotifications notifications =
      ReportScheduleEntryNotifications();

  /// Output configuration.
  @SerializationOrder(4)
  ReportScheduleEntryOutput output = ReportScheduleEntryOutput();
}

/// Timing configuration for report schedule.
@SectionId('RSET')
class ReportScheduleEntryTiming {
  @Form([
    Field('scheduleExpression', String, 'Schedule Expression',
        hint: 'Cron-like expression or recurrence rule, e.g. 0 6 1 * * (1st of month at 06:00)'),
    Field('timezone', String, 'Timezone',
        hint: 'Timezone for schedule, e.g. Europe/Berlin'),
    Field('startDate', String, 'Start Date',
        hint: 'Schedule effective start date'),
    Field('endDate', String, 'End Date',
        hint: 'Schedule expiry date; empty = no expiry'),
    Field('generationWindow', String, 'Generation Window',
        hint: 'Time window for generation, e.g. 02:00–06:00 (off-peak)'),
    Field('generationTimeout', String, 'Generation Timeout',
        hint: 'Max duration before timeout, e.g. 30min'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Retry configuration for report schedule.
@SectionId('RSER')
class ReportScheduleEntryRetry {
  @Form([
    Field('retryOnFailure', String, 'Retry On Failure', hint: 'Yes / No'),
    Field('maxRetries', int, 'Max Retries',
        hint: 'Number of retry attempts'),
    Field('retryDelay', String, 'Retry Delay',
        hint: 'Delay between retries, e.g. 5min / 15min / Exponential'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Notification settings for report schedule.
@SectionId('RSEN')
class ReportScheduleEntryNotifications {
  @Form([
    Field('notifyOnCompletion', String, 'Notify On Completion',
        hint: 'Yes / No — send notification when report is ready'),
    Field('completionRecipients', String, 'Completion Recipients',
        hint: 'Recipients for completion notification (if different from report recipients)'),
    Field('notifyOnFailure', String, 'Notify On Failure',
        hint: 'Yes / No — send alert on generation failure'),
    Field('failureRecipients', String, 'Failure Recipients',
        hint: 'Recipients for failure alerts'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Output configuration for report schedule.
@SectionId('RSEO')
class ReportScheduleEntryOutput {
  @Form([
    Field('filterOverrides', String, 'Filter Overrides',
        hint: 'Parameter values for scheduled run, e.g. dateRange=last_month'),
    Field('outputFormat', String, 'Output Format',
        hint: 'Override format for this schedule, e.g. PDF'),
    Field('outputDestination', String, 'Output Destination',
        hint: 'Where to store generated output: Archive / File-Share / Dashboard / S3-Bucket'),
    Field('priority', String, 'Priority',
        hint: 'Low / Normal / High / Critical — queue priority'),
    Field('enabled', String, 'Enabled',
        hint: 'Yes / No — is this schedule active'),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Distribution channel configuration (form).
@SectionId('RDE')
class ReportDistributionEntry {
  @Form([
    Field('distributionId', String, 'Distribution ID',
        hint: 'Unique within report, e.g. DST-01', required: true),
    Field('channel', String, 'Channel',
        hint:
            'Email / Dashboard / File-Share / API / Print / Push-Notification / Webhook / SFTP',
        required: true),
    Field('description', String, 'Description',
        hint: 'Purpose of this distribution channel'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Recipient and format settings.
  @SerializationOrder(1)
  ReportDistributionEntryRecipients recipients =
      ReportDistributionEntryRecipients();

  /// Message and attachment content.
  @SerializationOrder(2)
  ReportDistributionEntryContent contentSettings =
      ReportDistributionEntryContent();

  /// Delivery conditions and lifecycle settings.
  @SerializationOrder(3)
  ReportDistributionEntryDelivery delivery =
      ReportDistributionEntryDelivery();
}

/// Recipient and format settings for report distribution.
@SectionId('REDIENRE')
class ReportDistributionEntryRecipients {
  @Form([
    Field('formatPerChannel', String, 'Format Per Channel',
        hint:
            'Output format for this channel, e.g. PDF for email, Excel for file-share'),
    Field('recipientSource', String, 'Recipient Source',
        hint: 'Static-List / Role-Based / Query / Report-Filter'),
    Field('recipientList', String, 'Recipient List',
        hint: 'Comma-separated recipient IDs or addresses'),
    Field('recipientRoles', String, 'Recipient Roles',
        hint: 'Roles whose members receive the report'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Message and attachment content for report distribution.
@SectionId('REDIENCO')
class ReportDistributionEntryContent {
  @Form([
    Field('subjectTemplate', String, 'Subject Template',
        hint:
            'Email/notification subject, e.g. {reportName} — {dateRange}'),
    Field('bodyTemplate', String, 'Body Template',
        hint: 'Email/notification body template'),
    Field('attachmentOption', String, 'Attachment Option',
        hint: 'Inline / Attachment / Link-Only / Embedded-Preview'),
    Field('attachmentFileNamePattern', String, 'Attachment File Name Pattern',
        hint:
            'Pattern for attachment filename, e.g. {reportName}_{date}.pdf'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Delivery conditions and lifecycle settings for report distribution.
@SectionId('RDED')
class ReportDistributionEntryDelivery {
  @Form([
    Field('compressionEnabled', String, 'Compression Enabled',
        hint: 'Yes / No — compress attachment (ZIP)'),
    Field('passwordProtect', String, 'Password Protect',
        hint: 'Yes / No — encrypt attachment with password'),
    Field('conditionalDistribution', String, 'Conditional Distribution',
        hint:
            'Condition for sending, e.g. data.rows > 0 or totalAmount > threshold'),
    Field('suppressIfEmpty', String, 'Suppress If Empty',
        hint: 'Yes / No — skip distribution if report has no data'),
    Field('fileSharePath', String, 'File Share Path',
        hint: 'Network/cloud path for file-share distribution'),
    Field('retainCopy', String, 'Retain Copy',
        hint: 'Yes / No — keep a copy in the archive'),
    Field('sendTime', String, 'Send Time',
        hint:
            'When to distribute after generation: Immediately / Delay(1h) / Scheduled-Window'),
    Field('enabled', String, 'Enabled',
        hint: 'Yes / No — is this channel active'),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A recipient entry (form).
@SectionId('RRE')
class ReportRecipientEntry {
  @Form([
    Field('recipientId', String, 'Recipient ID',
        hint: 'Unique within report, e.g. REC-01', required: true),
    Field('recipientName', String, 'Recipient Name',
        hint: 'Display name', required: true),
    Field('recipientType', String, 'Recipient Type',
        hint:
            'User / Role / Group / Email / Distribution-List / External-Contact / System-Account'),
    Field('recipientReference', String, 'Recipient Reference',
        hint: 'User ID, role name, group name, or email address'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Recipient business context.
  @SerializationOrder(1)
  ReportRecipientEntryContext context = ReportRecipientEntryContext();

  /// Delivery preferences.
  @SerializationOrder(2)
  ReportRecipientEntryDelivery delivery = ReportRecipientEntryDelivery();

  /// Lifecycle settings.
  @SerializationOrder(3)
  ReportRecipientEntryLifecycle lifecycle = ReportRecipientEntryLifecycle();
}

/// Recipient business context.
@SectionId('REREENCO')
class ReportRecipientEntryContext {
  @Form([
    Field('role', String, 'Role',
        hint:
            'Business role of this recipient, e.g. Department Head, Controller'),
    Field('dataScopeRestriction', String, 'Data Scope Restriction',
        hint: 'Data visibility restriction, e.g. own-department-only'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Delivery preferences.
@SectionId('RRED')
class ReportRecipientEntryDelivery {
  @Form([
    Field('deliveryPreference', String, 'Delivery Preference',
        hint:
            'Email / Dashboard / Print / File-Share / API — preferred channel'),
    Field('formatPreference', String, 'Format Preference',
        hint: 'PDF / Excel / HTML — preferred output format'),
    Field('localePreference', String, 'Locale Preference',
        hint: 'Preferred locale for this recipient, e.g. en-US'),
    Field('scheduleOverride', String, 'Schedule Override',
        hint:
            'Override schedule for this recipient, e.g. Weekly instead of Monthly'),
    Field('notifyOnReady', String, 'Notify On Ready',
        hint: 'Yes / No — send notification when report is available'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Lifecycle settings.
@SectionId('RREL')
class ReportRecipientEntryLifecycle {
  @Form([
    Field('active', String, 'Active',
        hint: 'Yes / No — is this recipient currently receiving reports'),
    Field('effectiveFrom', String, 'Effective From',
        hint: 'Date this recipient is added'),
    Field('effectiveTo', String, 'Effective To',
        hint: 'Date this recipient is removed; empty = indefinite'),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.4.2 Export Formats
// ---------------------------------------------------------------------------

/// An export format entry (form).
@SectionId('EFE')
class ExportFormatEntry {
  @Form([
    Field('exportId', String, 'Export ID',
        hint: 'Unique identifier, e.g. EXP-001', required: true),
    Field('formatName', String, 'Format Name',
        hint: 'Human-readable name, e.g. Monthly Orders CSV', required: true),
    Field('formatType', String, 'Format Type',
        hint: 'CSV / Excel / PDF / JSON / XML / HTML / Fixed-Width'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Identity and data source.
  @SerializationOrder(1)
  ExportIdentity identity = ExportIdentity();

  /// File format settings.
  @SerializationOrder(2)
  ExportFileFormat fileFormat = ExportFileFormat();

  /// Delimiter and quoting.
  @SerializationOrder(3)
  ExportDelimiter delimiter = ExportDelimiter();

  /// Data formatting.
  @SerializationOrder(4)
  ExportDataFormat dataFormat = ExportDataFormat();

  /// Size and splitting.
  @SectionId('EXSISE-SIZE-LST')
  @SectionIdPattern('EXSISE-SIZE-xxx')
  @SerializationOrder(5)
  List<ExportSizeSettings> sizeSettings = [];

  /// Security settings.
  @SerializationOrder(6)
  ExportSecurity security = ExportSecurity();

  /// Output and scheduling.
  @SerializationOrder(7)
  ExportOutput output = ExportOutput();

  /// Access and audit.
  @SerializationOrder(8)
  ExportAccess access = ExportAccess();

  /// Contains 0+× Export Field Mapping.
  @SectionId('EFME-FIEL-LST')
  @SectionIdPattern('EFME-FIEL-xxx')
  @SerializationOrder(9)
  List<ExportFieldMappingEntry> fieldMappings = [];
}

/// Export identity and data source.
@SectionId('EXID')
class ExportIdentity {
  @Form([
    Field('description', String, 'Description',
        hint: 'Business purpose of this export'),
    Field('relatedDataEntities', String, 'Related Data Entities',
        hint: 'IFM entity references included in export'),
    Field('dataSource', String, 'Data Source',
        hint: 'Data source or query reference'),
    Field('dataScope', String, 'Data Scope',
        hint: 'Scope of exported data'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Export file format settings.
@SectionId('EXFIFO')
class ExportFileFormat {
  @Form([
    Field('fileNamingPattern', String, 'File Naming Pattern',
        hint: 'Output filename pattern, e.g. orders_{date}.csv'),
    Field('encoding', String, 'Encoding',
        hint: 'UTF-8 / UTF-16 / ISO-8859-1 / ASCII'),
    Field('lineEnding', String, 'Line Ending', hint: 'CRLF / LF / CR'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Export delimiter and quoting.
@SectionId('EXDE')
class ExportDelimiter {
  @Form([
    Field('delimiter', String, 'Delimiter',
        hint: 'Column delimiter: Comma / Semicolon / Tab / Pipe'),
    Field('quoteCharacter', String, 'Quote Character',
        hint: 'Field quote character'),
    Field('headerRow', String, 'Header Row',
        hint: 'Yes / No — include column header row'),
    Field('headerStyle', String, 'Header Style',
        hint: 'Display-Labels / Field-Names / Custom-Mapping'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Export data formatting.
@SectionId('EXDAFO')
class ExportDataFormat {
  @Form([
    Field('dateFormat', String, 'Date Format',
        hint: 'Date format, e.g. yyyy-MM-dd / ISO-8601'),
    Field('numberFormat', String, 'Number Format',
        hint: 'Locale-default / US / EU / Raw'),
    Field('decimalSeparator', String, 'Decimal Separator', hint: '. or ,'),
    Field('currencyFormat', String, 'Currency Format',
        hint: 'Symbol-prefix / Code-suffix / Raw-number'),
    Field('booleanTrueValue', String, 'Boolean True Value',
        hint: 'String value for true, e.g. 1, true, Yes'),
    Field('booleanFalseValue', String, 'Boolean False Value',
        hint: 'String value for false, e.g. 0, false, No'),
    Field('nullHandling', String, 'Null Handling',
        hint: 'Empty-string / Null-literal / Custom-value'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Export size settings.
@SectionId('EXSISE')
class ExportSizeSettings {
  @Form([
    Field('maxRows', int, 'Maximum Rows',
        hint: 'Row limit; 0 = unlimited'),
    Field('splitLargeFiles', String, 'Split Large Files',
        hint: 'Yes / No — split into chunks'),
    Field('splitThreshold', String, 'Split Threshold',
        hint: 'Split point, e.g. 100000 rows or 50MB'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Export security settings.
@SectionId('EXSE')
class ExportSecurity {
  @Form([
    Field('compressionFormat', String, 'Compression Format',
        hint: 'None / ZIP / GZIP / BZIP2'),
    Field('encryptionEnabled', String, 'Encryption Enabled',
        hint: 'Yes / No'),
    Field('encryptionMethod', String, 'Encryption Method',
        hint: 'AES-256 / Password-Protected-ZIP / PGP / None'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Export output and scheduling.
@SectionId('EXOU')
class ExportOutput {
  @Form([
    Field('outputDestination', String, 'Output Destination',
        hint: 'Download / File-Share / S3 / SFTP / API / Email'),
    Field('outputPath', String, 'Output Path',
        hint: 'Path or URL for destination'),
    Field('schedulingEnabled', String, 'Scheduling Enabled',
        hint: 'Yes / No — can this export be scheduled'),
    Field('schedulingExpression', String, 'Scheduling Expression',
        hint: 'Cron-like expression for automated export'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Export access and audit.
@SectionId('EXAC')
class ExportAccess {
  @Form([
    Field('accessLevel', String, 'Access Level',
        hint: 'Public / Authenticated / Role-specific'),
    Field('requiredRoles', String, 'Required Roles',
        hint: 'Roles permitted to run this export'),
    Field('auditLogging', String, 'Audit Logging',
        hint: 'Yes / No — log export executions'),
    Field('previewAvailable', String, 'Preview Available',
        hint: 'Yes / No — allow user to preview'),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A field mapping within an export (form).
@SectionId('EXFIMAEN')
class ExportFieldMappingEntry {
  @Form([
    Field('mappingId', String, 'Mapping ID',
        hint: 'Unique within export, e.g. FLD-01', required: true),
    Field('sourceField', String, 'Source Field',
        hint: 'Data model field path, e.g. order.customer.name',
        required: true),
    Field('targetFieldName', String, 'Target Field Name',
        hint: 'Column/field name in output file', required: true),
  ])
  @SerializationOrder(0)
  String? content;

  /// Ordering and formatting settings.
  @SerializationOrder(1)
  ExportFieldMappingEntryFormatting formatting =
      ExportFieldMappingEntryFormatting();

  /// Transformation rules.
  @SerializationOrder(2)
  ExportFieldMappingEntryTransformation transformation =
      ExportFieldMappingEntryTransformation();

  /// Inclusion and defaults.
  @SerializationOrder(3)
  ExportFieldMappingEntryInclusion inclusion =
      ExportFieldMappingEntryInclusion();

  /// Fixed-width and quoting rules.
  @SerializationOrder(4)
  ExportFieldMappingEntryLayout layout = ExportFieldMappingEntryLayout();
}

/// Ordering and formatting settings.
@SectionId('EFMEF')
class ExportFieldMappingEntryFormatting {
  @Form([
    Field('displayOrder', int, 'Display Order',
        hint: 'Position in the export output (column order)'),
    Field('dataType', String, 'Data Type',
        hint:
            'String / Integer / Decimal / Date / DateTime / Boolean / Enum'),
    Field('formatPattern', String, 'Format Pattern',
        hint:
            'Output format, e.g. dd.MM.yyyy for dates, #,##0.00 for numbers'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Transformation rules.
@SectionId('EFMET')
class ExportFieldMappingEntryTransformation {
  @Form([
    Field('transformationRule', String, 'Transformation Rule',
        hint:
            'Value transformation: None / Uppercase / Lowercase / Trim / Truncate(n) / Map / Concatenate / Calculate / Custom'),
    Field('transformationExpression', String, 'Transformation Expression',
        hint: 'Expression for transform, e.g. firstName + lastName'),
    Field('valueMapping', String, 'Value Mapping',
        hint: 'Value substitution map, e.g. ACTIVE→A, INACTIVE→I'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Inclusion and defaults.
@SectionId('EFMEI')
class ExportFieldMappingEntryInclusion {
  @Form([
    Field('defaultValue', String, 'Default Value',
        hint: 'Value to use when source is null/empty'),
    Field('includeInExport', String, 'Include In Export',
        hint: 'Yes / No / Conditional'),
    Field('inclusionCondition', String, 'Inclusion Condition',
        hint: 'Condition for conditional inclusion'),
    Field('maxLength', int, 'Max Length',
        hint: 'Truncate output to this character length'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Fixed-width and quoting rules.
@SectionId('EFMEL')
class ExportFieldMappingEntryLayout {
  @Form([
    Field('paddingChar', String, 'Padding Char',
        hint: 'For fixed-width: padding character, e.g. space or 0'),
    Field('paddingDirection', String, 'Padding Direction',
        hint: 'Left / Right for fixed-width formats'),
    Field('fixedWidth', int, 'Fixed Width',
        hint: 'Column width for fixed-width format exports'),
    Field('quoteAlways', String, 'Quote Always',
        hint: 'Yes / No — always quote this field in CSV'),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.4.3 Export Templates
// ---------------------------------------------------------------------------

/// A reusable export template (form).
@SectionId('ETE')
class ExportTemplateEntry {
  @Form([
    Field('templateId', String, 'Template ID',
        hint: 'Unique identifier, e.g. TPL-001', required: true),
    Field('templateName', String, 'Template Name',
        hint: 'Human-readable name, e.g. Standard Customer Export',
        required: true),
    Field('baseFormatType', String, 'Base Format Type',
        hint: 'CSV / Excel / PDF / JSON / XML / HTML'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Format configuration.
  @SerializationOrder(1)
  ExportTemplateEntryFormat format = ExportTemplateEntryFormat();

  /// Field and filter settings.
  @SerializationOrder(2)
  ExportTemplateEntryFields fields = ExportTemplateEntryFields();

  /// Layout configuration.
  @SerializationOrder(3)
  ExportTemplateEntryLayout layout = ExportTemplateEntryLayout();

  /// Access and metadata.
  @SerializationOrder(4)
  ExportTemplateEntryAccess access = ExportTemplateEntryAccess();
}

/// Format configuration for export template.
@SectionId('ETEF')
class ExportTemplateEntryFormat {
  @Form([
    Field('description', String, 'Description',
        hint: 'Purpose and use cases for this template'),
    Field('encoding', String, 'Encoding',
        hint: 'Default encoding for this template'),
    Field('delimiter', String, 'Delimiter', hint: 'Default delimiter'),
    Field('headerRow', String, 'Header Row', hint: 'Yes / No'),
    Field('dateFormat', String, 'Date Format', hint: 'Default date format'),
    Field('numberFormat', String, 'Number Format',
        hint: 'Default number format'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Field and filter settings for export template.
@SectionId('EXTEENFI')
class ExportTemplateEntryFields {
  @Form([
    Field('fieldSet', String, 'Field Set',
        hint: 'Comma-separated field names included in this template'),
    Field('defaultFilters', String, 'Default Filters',
        hint: 'Pre-applied filters, e.g. status=active'),
    Field('defaultSortField', String, 'Default Sort Field',
        hint: 'Default sort column'),
    Field('defaultSortDirection', String, 'Default Sort Direction',
        hint: 'Ascending / Descending'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Layout configuration for export template.
@SectionId('ETEL')
class ExportTemplateEntryLayout {
  @Form([
    Field('headerConfig', String, 'Header Config',
        hint: 'Header content template for PDF/Excel exports'),
    Field('footerConfig', String, 'Footer Config',
        hint: 'Footer content template for PDF/Excel exports'),
    Field('brandingOverride', String, 'Branding Override',
        hint: 'Template-specific branding (for PDF)'),
    Field('compressionFormat', String, 'Compression Format',
        hint: 'None / ZIP / GZIP'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Access and metadata for export template.
@SectionId('ETEA')
class ExportTemplateEntryAccess {
  @Form([
    Field('accessLevel', String, 'Access Level',
        hint: 'Public / Authenticated / Role-specific'),
    Field('requiredRoles', String, 'Required Roles',
        hint: 'Roles permitted to use this template'),
    Field('reusableAcrossReports', String, 'Reusable Across Reports',
        hint: 'Yes / No — can this template be used by multiple reports/exports'),
    Field('version', String, 'Version',
        hint: 'Template version, e.g. 1.0'),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.7 Error Handling
// ---------------------------------------------------------------------------

/// 10.7. Error Handling.
///
/// Comprehensive error handling user experience framework covering validation
/// feedback, system error presentation, and error recovery flows. Follows
/// UX best practices for error prevention, detection, and graceful recovery.
@SectionId('ERHACO')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@SecondLevelSectionId(D09ExperienceDesignSpecification, 'XDS-ERR')
class ErrorHandling {
  // ─────────────────────────────────────────────────────────────────────────
  // Error Handling Philosophy
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    // Philosophy and approach
    Field('errorPhilosophy', String, 'Error Handling Philosophy',
        hint: 'Prevention-first, graceful degradation, user empowerment'),
    Field('errorToneOfVoice', String, 'Error Tone of Voice',
        hint: 'Friendly, professional, apologetic, neutral'),
    Field('errorLanguageStyle', String, 'Error Language Style',
        hint: 'Plain language, technical, user-focused'),
    Field('blameAvoidance', String, 'Blame Avoidance Approach',
        hint: 'Never blame user, focus on solutions'),
  ])
  @SerializationOrder(0)
  String? errorPhilosophyContent;

  /// Error categorization and display priority.
  @SerializationOrder(1)
  ErrorHandlingClassification classification =
      ErrorHandlingClassification();

  /// Accessibility and inclusive error cues.
  @SerializationOrder(2)
  ErrorHandlingAccessibility accessibility =
      ErrorHandlingAccessibility();

  /// Localization and analytics behavior.
  @SerializationOrder(3)
  ErrorHandlingOperations operations =
      ErrorHandlingOperations();

  /// Error handling overview and strategy.
  @ContentHelp('Executive summary of error handling approach, '
      'key principles, and user experience goals.')
  @SerializationOrder(4)
  TextSection errorHandlingOverview = TextSection();

  /// 10.7.1. Validation Feedback.
  @SerializationOrder(5)
  ValidationFeedback validationFeedback = ValidationFeedback();

  /// 10.7.2. System Error Display.
  @SerializationOrder(6)
  SystemErrorDisplay systemErrorDisplay = SystemErrorDisplay();

  /// 10.7.3. Error Recovery.
  @SerializationOrder(7)
  ErrorRecovery errorRecovery = ErrorRecovery();

  /// Error message catalog.
  @ContentHelp('Centralized catalog of error message templates '
      'with consistent formatting and tone.')
  @SerializationOrder(8)
  TextSection errorMessageCatalog = TextSection();

  /// Error state visual design.
  @ContentHelp('Visual design specifications for error states '
      'including colors, icons, animations.')
  @SerializationOrder(9)
  TextSection errorVisualDesign = TextSection();
}

/// Error categorization and display priority.
@SectionId('EHCC')
class ErrorHandlingClassification {
    @Form([
        Field('errorCategories', String, 'Error Categories',
                hint: 'Validation, network, server, permission, data'),
        Field('errorSeverityLevels', String, 'Severity Levels',
                hint: 'Critical, warning, info, success'),
        Field('errorPriorityDisplay', String, 'Priority Display Order',
                hint: 'Most severe first, chronological, by field'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Accessibility and inclusive error cues.
///
/// The authoritative WCAG conformance targets (AA/AAA levels, success
/// criteria) are defined in §10.9 `Accessibility`. This section *applies*
/// those targets to error states (screen-reader announcements, contrast,
/// non-color indicators) — reference §10.9, do not restate the conformance
/// levels here.
@SectionId('EHCA')
class ErrorHandlingAccessibility {
    @Form([
        Field('errorAccessibility', String, 'Error Accessibility',
                hint: 'Screen reader announcements, ARIA live regions'),
        Field('colorContrastCompliance', String, 'Color Contrast Compliance',
                hint: 'WCAG AA, AAA for error states'),
        Field('nonColorIndicators', String, 'Non-Color Indicators',
                hint: 'Icons, text, patterns for colorblind users'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Localization and analytics behavior.
@SectionId('EHCO')
class ErrorHandlingOperations {
    @Form([
        Field('errorLocalization', String, 'Error Localization',
                hint: 'All messages localized, fallback language'),
        Field('dynamicContentHandling', String, 'Dynamic Content Handling',
                hint: 'How dynamic values are inserted into messages'),
        Field('errorTrackingApproach', String, 'Error Tracking Approach',
                hint: 'Analytics for user errors, trend analysis'),
        Field('userFrustrationDetection', String, 'User Frustration Detection',
                hint: 'Rage click detection, repeated errors'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 10.7.1. Validation Feedback.
///
/// Field validation error display and feedback mechanisms.
@SectionId('VAFE')
class ValidationFeedback {
  @Form([
    Field('validationTiming', String, 'Validation Timing',
        hint: 'Real-time, on-blur, on-submit, debounced'),
    Field('debounceDelay', String, 'Debounce Delay',
        hint: 'Milliseconds before validation triggers'),
    Field('validationSequence', String, 'Validation Sequence',
        hint: 'Field-by-field, all-at-once, progressive'),
  ])
  @SerializationOrder(0)
  String? validationDisplayContent;

  /// Display placement details.
  @SerializationOrder(1)
  ValidationFeedbackPlacement placement = ValidationFeedbackPlacement();

  /// Message formatting details.
  @SerializationOrder(2)
  ValidationFeedbackMessages messages = ValidationFeedbackMessages();

  /// Guidance settings.
  @SerializationOrder(3)
  ValidationFeedbackGuidance guidance = ValidationFeedbackGuidance();

  /// Animation and focus behavior.
  @SerializationOrder(4)
  ValidationFeedbackBehavior behavior = ValidationFeedbackBehavior();

  /// Validation feedback narrative.
  @ContentHelp('Detailed specification of validation feedback behavior '
      'and user experience considerations.')
  @SerializationOrder(5)
  TextSection validationNarrative = TextSection();

  /// Validation message templates.
  @SectionId('VAMETE-MESS-LST')
  @SectionIdPattern('VAMETE-MESS-xxx')
  @SerializationOrder(6)
  List<ValidationMessageTemplate> messageTemplates = [];

  /// Field validation rules by type.
  @SectionId('FIELD-FIEL-LST')
  @SectionIdPattern('FIELD-FIEL-xxx')
  @SerializationOrder(7)
  List<FieldValidationRuleEntry> fieldValidationRules = [];
}

/// Display placement details.
@SectionId('VAFEPL')
class ValidationFeedbackPlacement {
    @Form([
        Field('errorMessagePlacement', String, 'Error Message Placement',
                hint: 'Inline below field, above field, tooltip, summary'),
        Field('summaryPosition', String, 'Error Summary Position',
                hint: 'Top of form, bottom of form, modal'),
        Field('fieldHighlighting', String, 'Field Highlighting',
                hint: 'Border color, background color, icon'),
        Field('fieldErrorIcon', String, 'Field Error Icon',
                hint: 'Icon displayed on invalid fields'),
        Field('fieldErrorIconPosition', String, 'Icon Position',
                hint: 'Leading, trailing, inside field, outside'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Message formatting details.
@SectionId('VAFEME')
class ValidationFeedbackMessages {
    @Form([
        Field('messageFormat', String, 'Message Format',
                hint: 'Text only, icon + text, structured'),
        Field('maxMessageLength', String, 'Max Message Length',
                hint: 'Character limit for inline messages'),
        Field('multipleErrorsDisplay', String, 'Multiple Errors Display',
                hint: 'First only, all, expandable list'),
        Field('errorPersistence', String, 'Error Persistence',
                hint: 'Until fixed, until field accessed, timed'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Guidance settings.
@SectionId('VAFEGU')
class ValidationFeedbackGuidance {
    @Form([
        Field('showRequirements', bool, 'Show Requirements',
                hint: 'Display field requirements before error'),
        Field('showSuggestions', bool, 'Show Suggestions',
                hint: 'Suggest corrections for common errors'),
        Field('showExamples', bool, 'Show Examples',
                hint: 'Show example valid input'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Animation and focus behavior.
@SectionId('VAFEBE')
class ValidationFeedbackBehavior {
    @Form([
        Field('errorAnimation', String, 'Error Animation',
                hint: 'Shake, fade-in, bounce, none'),
        Field('clearAnimation', String, 'Clear Animation',
                hint: 'Animation when error is resolved'),
        Field('scrollToError', bool, 'Scroll to Error',
                hint: 'Auto-scroll to first error on submit'),
        Field('focusOnError', bool, 'Focus on Error',
                hint: 'Move focus to first invalid field'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A validation message template.
@SectionId('VMT')
class ValidationMessageTemplate {
  @Form([
    Field('messageId', String, 'Message ID', required: true,
        hint: 'Unique identifier (e.g., VAL-REQ-001)'),
    Field('validationType', String, 'Validation Type', required: true,
        hint: 'Required, format, range, length, custom'),
    Field('fieldTypes', String, 'Applicable Field Types',
        hint: 'Text, email, number, date, select'),
    Field('messageTemplate', String, 'Message Template', required: true,
        hint: 'Template with {field}, {value} placeholders'),
    Field('shortMessage', String, 'Short Message',
        hint: 'Brief version for space-constrained contexts'),
    Field('helpText', String, 'Help Text',
        hint: 'Extended guidance for complex errors'),
    Field('exampleCorrection', String, 'Example Correction',
        hint: 'Example of valid input'),
    Field('severity', String, 'Severity',
        hint: 'Error, warning, info'),
    Field('iconCode', String, 'Icon Code',
        hint: 'Icon to display with message'),
    Field('localizationKey', String, 'Localization Key',
        hint: 'i18n key for translation'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 10.7.2. System Error Display.
///
/// System error presentation including server errors, network issues,
/// and timeouts.
@SectionId('SYERDI')
class SystemErrorDisplay {
  // ─────────────────────────────────────────────────────────────────────────
  // System Error Handling
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('networkErrorHandling', String, 'Network Error Handling',
        hint: 'How connectivity issues are displayed'),
    Field('systemErrorDisplayMethod', String, 'Display Method',
        hint: 'Modal, snackbar, banner, full-page'),
    Field('gracefulDegradation', String, 'Graceful Degradation',
        hint: 'How features degrade on partial failure'),
  ])
  @SerializationOrder(0)
  String? systemErrorContent;

  /// Error type handling configuration.
  @SerializationOrder(1)
  SystemErrorDisplayErrorTypes errorTypes = SystemErrorDisplayErrorTypes();

  /// Display method settings.
  @SerializationOrder(2)
  SystemErrorDisplayMethods displayMethods = SystemErrorDisplayMethods();

  /// Content options.
  @SerializationOrder(3)
  SystemErrorDisplayContent displayContent = SystemErrorDisplayContent();

  /// Fallback behavior.
  @SerializationOrder(4)
  SystemErrorDisplayFallback fallback = SystemErrorDisplayFallback();

  /// System error display narrative.
  @ContentHelp('Detailed specification of system error presentation '
      'and user communication approach.')
  @SerializationOrder(5)
  TextSection systemErrorNarrative = TextSection();

  /// Error page designs.
  @SectionId('EPDE-ERRO-LST')
  @SectionIdPattern('EPDE-ERRO-xxx')
  @SerializationOrder(6)
  List<ErrorPageDesignEntry> errorPageDesigns = [];

  /// Error codes catalog.
  @SectionId('SECE-ERRO-LST')
  @SectionIdPattern('SECE-ERRO-xxx')
  @SerializationOrder(7)
  List<SystemErrorCodeEntry> errorCodes = [];
}

/// Error type handling configuration.
@SectionId('SEDET')
class SystemErrorDisplayErrorTypes {
  @Form([
    Field('serverErrorHandling', String, 'Server Error Handling',
        hint: 'How 5xx errors are presented'),
    Field('timeoutHandling', String, 'Timeout Handling',
        hint: 'How request timeouts are displayed'),
    Field('authenticationErrorHandling', String, 'Authentication Error',
        hint: 'Session expired, unauthorized'),
    Field('permissionErrorHandling', String, 'Permission Error',
        hint: 'Forbidden access display'),
    Field('maintenanceModeHandling', String, 'Maintenance Mode',
        hint: 'Scheduled downtime display'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Display method settings for system errors.
@SectionId('SEDM')
class SystemErrorDisplayMethods {
  @Form([
    Field('errorModalStyle', String, 'Error Modal Style',
        hint: 'Dialog design for error modals'),
    Field('snackbarPosition', String, 'Snackbar Position',
        hint: 'Bottom, top, bottom-left, top-right'),
    Field('snackbarDuration', String, 'Snackbar Duration',
        hint: 'Auto-dismiss time or persistent'),
    Field('bannerPosition', String, 'Banner Position',
        hint: 'Top of page, top of content'),
    Field('fullPageErrorTemplate', String, 'Full Page Error Template',
        hint: 'Design for full-page errors (500, 503)'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Content options for system error display.
@SectionId('SEDC')
class SystemErrorDisplayContent {
  @Form([
    Field('showTechnicalDetails', bool, 'Show Technical Details',
        hint: 'Display error codes, request IDs'),
    Field('showRetryOption', bool, 'Show Retry Option'),
    Field('showContactSupport', bool, 'Show Contact Support'),
    Field('showStatusPageLink', bool, 'Show Status Page Link'),
    Field('offlineModeMessage', String, 'Offline Mode Message',
        hint: 'Message when app detects offline state'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Fallback behavior for system errors.
@SectionId('SEDF')
class SystemErrorDisplayFallback {
  @Form([
    Field('cachedDataFallback', String, 'Cached Data Fallback',
        hint: 'Show stale data with indicator'),
    Field('retryStrategy', String, 'Retry Strategy',
        hint: 'Automatic retry with backoff'),
    Field('maxRetryAttempts', int, 'Max Retry Attempts'),
    Field('retryDelaySeconds', int, 'Retry Delay (seconds)'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A system error code entry.
@SectionId('SYERCOEN')
class SystemErrorCodeEntry {
  @Form([
    Field('errorCode', String, 'Error Code', required: true,
        hint: 'System error code (e.g., ERR-NET-001)'),
    Field('httpStatus', int, 'HTTP Status',
        hint: 'Associated HTTP status code'),
    Field('errorCategory', String, 'Error Category',
        hint: 'Network, server, authentication, data'),
    Field('userMessage', String, 'User Message', required: true,
        hint: 'User-friendly error message'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Recovery and display guidance.
  @SerializationOrder(1)
  SystemErrorCodeEntryHandling handling = SystemErrorCodeEntryHandling();

  /// Operational support and logging controls.
  @SerializationOrder(2)
  SystemErrorCodeEntryOperations operations =
      SystemErrorCodeEntryOperations();
}

/// Recovery and display guidance.
@SectionId('SECEH')
class SystemErrorCodeEntryHandling {
  @Form([
    Field('technicalDescription', String, 'Technical Description',
        hint: 'Developer-facing description'),
    Field('suggestedAction', String, 'Suggested Action',
        hint: 'What user should do'),
    Field('retryable', bool, 'Retryable',
        hint: 'Whether retry is likely to help'),
    Field('autoRetry', bool, 'Auto Retry',
        hint: 'System automatically retries'),
    Field('displayMethod', String, 'Display Method',
        hint: 'How this error is displayed'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Operational support and logging controls.
@SectionId('SECEO')
class SystemErrorCodeEntryOperations {
  @Form([
    Field('notifySupport', bool, 'Notify Support',
        hint: 'Auto-notify support team'),
    Field('logLevel', String, 'Log Level',
        hint: 'Error, warning, info'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 10.7.3. Error Recovery.
///
/// Error recovery flows including data preservation, retry mechanisms,
/// and guided recovery steps.
@SectionId('ERRE')
class ErrorRecovery {
  // ─────────────────────────────────────────────────────────────────────────
  // Recovery Mechanisms
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('formDataPreservation', String, 'Form Data Preservation',
        hint: 'How unsaved form data is preserved on error'),
    Field('sessionRecovery', String, 'Session Recovery',
        hint: 'How expired sessions are handled'),
    Field('supportContactMethod', String, 'Support Contact Method',
        hint: 'Chat, email, phone, ticket'),
  ])
  @SerializationOrder(0)
  String? recoveryMechanismsContent;

  /// Data preservation: draft auto-save settings.
  @SerializationOrder(1)
  ErrorRecoveryDataPreservation dataPreservation =
      ErrorRecoveryDataPreservation();

  /// Retry mechanisms configuration.
  @SerializationOrder(2)
  ErrorRecoveryRetryMechanisms retryMechanisms =
      ErrorRecoveryRetryMechanisms();

  /// Guided recovery options.
  @SerializationOrder(3)
  ErrorRecoveryGuidedRecovery guidedRecovery = ErrorRecoveryGuidedRecovery();

  /// Support contact details.
  @SerializationOrder(4)
  ErrorRecoverySupportContact supportContact = ErrorRecoverySupportContact();

  /// Session handling configuration.
  @SerializationOrder(5)
  ErrorRecoverySessionHandling sessionHandling =
      ErrorRecoverySessionHandling();

  /// Error recovery narrative.
  @ContentHelp('Detailed specification of error recovery flows '
      'and user empowerment strategies.')
  @SerializationOrder(6)
  TextSection recoveryNarrative = TextSection();

  /// Recovery flow diagrams.
  @SectionId('RECOV-RECO-LST')
  @SectionIdPattern('RECOV-RECO-xxx')
  @SerializationOrder(7)
  List<RecoveryFlowEntry> recoveryFlows = [];

  /// Common recovery scenarios.
  @SectionId('RCVSCN-RECO-LST')
  @SectionIdPattern('RCVSCN-RECO-xxx')
  @SerializationOrder(8)
  List<RecoveryScenarioEntry> recoveryScenarios = [];
}

/// Data preservation: draft auto-save settings.
@SectionId('ERDP')
class ErrorRecoveryDataPreservation {
  @Form([
    Field('draftAutoSave', bool, 'Draft Auto-Save',
        hint: 'Automatic draft saving before submission'),
    Field('draftSaveInterval', String, 'Draft Save Interval',
        hint: 'How often drafts are auto-saved'),
    Field('draftStorageMethod', String, 'Draft Storage Method',
        hint: 'LocalStorage, IndexedDB, server-side'),
    Field('draftRetentionPeriod', String, 'Draft Retention Period',
        hint: 'How long drafts are kept'),
    Field('draftRecoveryPrompt', String, 'Draft Recovery Prompt',
        hint: 'How users are notified of recoverable drafts'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Retry mechanisms configuration.
@SectionId('ERRM')
class ErrorRecoveryRetryMechanisms {
  @Form([
    Field('automaticRetryEnabled', bool, 'Automatic Retry Enabled'),
    Field('retryBackoffStrategy', String, 'Retry Backoff Strategy',
        hint: 'Exponential, linear, fixed'),
    Field('maxAutomaticRetries', int, 'Max Automatic Retries'),
    Field('manualRetryButton', bool, 'Manual Retry Button'),
    Field('retryButtonLabel', String, 'Retry Button Label',
        hint: 'Button text (e.g., "Try Again")'),
    Field('retryFeedback', String, 'Retry Feedback',
        hint: 'How retry attempts are indicated'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Guided recovery options.
@SectionId('ERGR')
class ErrorRecoveryGuidedRecovery {
  @Form([
    Field('stepByStepRecovery', bool, 'Step-by-Step Recovery',
        hint: 'Guided recovery wizard'),
    Field('alternativeActions', String, 'Alternative Actions',
        hint: 'What else user can do'),
    Field('skipOption', bool, 'Skip Option',
        hint: 'Allow skipping failed operation'),
    Field('cancelOption', bool, 'Cancel Option',
        hint: 'Allow canceling and returning'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Support contact details.
@SectionId('ERSC')
class ErrorRecoverySupportContact {
  @Form([
    Field('supportAvailability', String, 'Support Availability',
        hint: 'When support is available'),
    Field('errorReportSubmission', bool, 'Error Report Submission',
        hint: 'Allow user to submit error report'),
    Field('includeDebugInfo', bool, 'Include Debug Info',
        hint: 'Include technical details in report'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Session handling configuration.
@SectionId('ERSH')
class ErrorRecoverySessionHandling {
  @Form([
    Field('reauthenticationFlow', String, 'Reauthentication Flow',
        hint: 'Inline login, redirect, modal'),
    Field('preserveContextOnReauth', bool, 'Preserve Context on Reauth',
        hint: 'Return to original location after reauth'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A recovery scenario entry.
@SectionId('RCVSCN')
class RecoveryScenarioEntry {
  @Form([
    Field('scenarioId', String, 'Scenario ID', required: true),
    Field('scenarioName', String, 'Scenario Name', required: true,
        hint: 'Descriptive name'),
    Field('triggerCondition', String, 'Trigger Condition',
        hint: 'What error triggers this scenario'),
    Field('userImpact', String, 'User Impact',
        hint: 'How user is affected'),
    Field('recoverySteps', String, 'Recovery Steps',
        hint: 'Step-by-step recovery process'),
    Field('dataAtRisk', String, 'Data at Risk',
        hint: 'What data might be lost'),
    Field('preventionMeasures', String, 'Prevention Measures',
        hint: 'How scenario can be prevented'),
    Field('timeToRecover', String, 'Time to Recover',
        hint: 'Expected recovery duration'),
    Field('supportEscalation', String, 'Support Escalation',
        hint: 'When to escalate to support'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Detailed recovery flow.
  @ContentHelp('Detailed recovery flow for this scenario.')
  @SerializationOrder(1)
  TextSection detailedFlow = TextSection();
}

// ---------------------------------------------------------------------------
// 10.8 User Assistance
// ---------------------------------------------------------------------------

/// 10.8. User Assistance.
///
/// Comprehensive in-app help system including contextual help, onboarding,
/// and support access mechanisms.
@SectionId('HECO')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@SecondLevelSectionId(D09ExperienceDesignSpecification, 'XDS-HLP')
class UserAssistance {
  // ─────────────────────────────────────────────────────────────────────────
  // Help System Overview
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    // Help philosophy
    Field('helpPhilosophy', String, 'Help Philosophy',
        hint: 'Self-service first, guided, on-demand'),
    Field('helpAccessibility', String, 'Help Accessibility',
        hint: 'Always visible, contextual, searchable'),
    Field('helpPersonalization', String, 'Help Personalization',
        hint: 'Role-based, skill-based, contextual'),
    // Help content
    Field('helpContentStrategy', String, 'Help Content Strategy',
        hint: 'Video, text, interactive, mixed'),
  ])
  @SerializationOrder(0)
  String? helpOverviewContent;

  /// Content stewardship and help affordances.
  @SerializationOrder(1)
  UserAssistanceDelivery delivery = UserAssistanceDelivery();

  /// Analytics and improvement feedback.
  @SerializationOrder(2)
  UserAssistanceInsights insights = UserAssistanceInsights();

  /// Help system overview narrative.
  @ContentHelp('Executive summary of help system approach, '
      'content strategy, and user empowerment goals.')
  @SerializationOrder(3)
  TextSection helpOverview = TextSection();

  /// 10.8.1. Contextual Help.
  @SerializationOrder(4)
  ContextualHelp contextualHelp = ContextualHelp();

  /// 10.8.2. Onboarding.
  @SerializationOrder(5)
  OnboardingHelp onboarding = OnboardingHelp();

  /// 10.8.3. Support Access.
  @SerializationOrder(6)
  SupportAccess supportAccess = SupportAccess();

  /// Help content inventory.
  @ContentHelp('Inventory of all help content by feature area.')
  @SerializationOrder(7)
  TextSection helpContentInventory = TextSection();
}

/// Content stewardship and help affordances.
@SectionId('HECODE')
class UserAssistanceDelivery {
    @Form([
        Field('helpContentOwnership', String, 'Help Content Ownership',
                hint: 'Who maintains help content'),
        Field('helpUpdateProcess', String, 'Help Update Process',
                hint: 'How help content is kept current'),
        Field('helpIconStandard', String, 'Help Icon Standard',
                hint: 'Question mark, info icon, custom'),
        Field('helpIconPlacement', String, 'Help Icon Placement',
                hint: 'By field labels, in headers, floating'),
        Field('helpTooltipStyle', String, 'Help Tooltip Style',
                hint: 'Tooltip design and behavior'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Analytics and improvement feedback.
@SectionId('HECOIN')
class UserAssistanceInsights {
    @Form([
        Field('helpAnalytics', String, 'Help Analytics',
                hint: 'Track help usage, identify gaps'),
        Field('helpFeedback', String, 'Help Feedback',
                hint: 'Rate help articles, suggest improvements'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 10.8.1. Contextual Help.
@SectionId('COHE')
class ContextualHelp {
  @Form([
    Field('tooltipTrigger', String, 'Tooltip Trigger',
        hint: 'Hover, click, focus, icon click'),
    Field('tooltipDelay', String, 'Tooltip Delay',
        hint: 'Milliseconds before showing'),
    Field('tooltipDuration', String, 'Tooltip Duration',
        hint: 'How long tooltip stays visible'),
    Field('tooltipMaxWidth', String, 'Tooltip Max Width',
        hint: 'Maximum width in pixels'),
    Field('tooltipPosition', String, 'Tooltip Position',
        hint: 'Above, below, auto-position'),
  ])
  @SerializationOrder(0)
  String? contextualHelpContent;

  /// Inline help behavior.
  @SerializationOrder(1)
  ContextualHelpInline inline = ContextualHelpInline();

  /// Help panel behavior.
  @SerializationOrder(2)
  ContextualHelpPanels panels = ContextualHelpPanels();

  /// What's-this mode settings.
  @SerializationOrder(3)
  ContextualHelpWhatsThis whatsThis = ContextualHelpWhatsThis();

  /// Rich help media settings.
  @SerializationOrder(4)
  ContextualHelpRich rich = ContextualHelpRich();

  /// Contextual help narrative.
  @SerializationOrder(5)
  TextSection contextualHelpNarrative = TextSection();

  /// Field help catalog.
  @SectionId('FLDHP-FIEL-LST')
  @SectionIdPattern('FLDHP-FIEL-xxx')
  @SerializationOrder(6)
  List<FieldHelpEntry> fieldHelpCatalog = [];
}

/// Inline help behavior.
@SectionId('COHEIN')
class ContextualHelpInline {
    @Form([
        Field('inlineHelpPlacement', String, 'Inline Help Placement',
                hint: 'Below labels, below fields, expandable'),
        Field('inlineHelpVisibility', String, 'Inline Help Visibility',
                hint: 'Always visible, on demand, progressive'),
        Field('inlineHelpLength', String, 'Inline Help Length',
                hint: 'Max characters for inline help'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Help panel behavior.
@SectionId('COHEPA')
class ContextualHelpPanels {
    @Form([
        Field('helpPanelAvailable', bool, 'Help Panel Available',
                hint: 'Slide-out help panel'),
        Field('helpPanelPosition', String, 'Help Panel Position',
                hint: 'Right side, bottom, overlay'),
        Field('helpPanelContent', String, 'Help Panel Content',
                hint: 'Field help, page help, related articles'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// What's-this mode settings.
@SectionId('CHWT')
class ContextualHelpWhatsThis {
    @Form([
        Field('whatsThisMode', bool, 'What\'s This Mode',
                hint: 'Click-anywhere help mode'),
        Field('whatsThisActivation', String, 'What\'s This Activation',
                hint: 'Keyboard shortcut, toolbar button'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Rich help media settings.
@SectionId('COHERI')
class ContextualHelpRich {
    @Form([
        Field('helpScreenshots', bool, 'Help Screenshots',
                hint: 'Include screenshots in help'),
        Field('helpVideos', bool, 'Help Videos',
                hint: 'Include video tutorials'),
        Field('helpAnimations', bool, 'Help Animations',
                hint: 'Animated demonstrations'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A field help entry.
@SectionId('FLDHP')
class FieldHelpEntry {
  @Form([
    Field('fieldId', String, 'Field ID', required: true),
    Field('fieldLabel', String, 'Field Label', required: true),
    Field('tooltipText', String, 'Tooltip Text',
        hint: 'Brief tooltip content'),
    Field('inlineHelpText', String, 'Inline Help Text',
        hint: 'Longer inline help'),
    Field('extendedHelp', String, 'Extended Help',
        hint: 'Full help panel content'),
    Field('relatedArticles', String, 'Related Articles',
        hint: 'Links to related help articles'),
    Field('exampleValues', String, 'Example Values',
        hint: 'Examples of valid input'),
    Field('commonMistakes', String, 'Common Mistakes',
        hint: 'Frequently made errors'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 10.8.2. Onboarding Help.
@SectionId('ONHE')
class OnboardingHelp {
  @Form([
    Field('welcomeFlowEnabled', bool, 'Welcome Flow Enabled'),
    Field('welcomeFlowStyle', String, 'Welcome Flow Style',
        hint: 'Modal wizard, full-page, inline'),
    Field('welcomeFlowSkippable', bool, 'Welcome Flow Skippable'),
    Field('welcomeFlowDuration', String, 'Welcome Flow Duration',
        hint: 'Expected completion time'),
  ])
  @SerializationOrder(0)
  String? onboardingContent;

  /// Feature tour settings.
  @SerializationOrder(1)
  OnboardingHelpTours tours = OnboardingHelpTours();

  /// Sample data settings.
  @SerializationOrder(2)
  OnboardingHelpSampleData sampleData = OnboardingHelpSampleData();

  /// Getting started checklist configuration.
  @SerializationOrder(3)
  OnboardingHelpChecklist checklist = OnboardingHelpChecklist();

  /// Progressive disclosure configuration.
  @SerializationOrder(4)
  OnboardingHelpDisclosure disclosure = OnboardingHelpDisclosure();

  /// Returning user experience.
  @SerializationOrder(5)
  OnboardingHelpReengagement reengagement = OnboardingHelpReengagement();

  /// Onboarding narrative.
  @SerializationOrder(6)
  TextSection onboardingNarrative = TextSection();

  /// Feature tour definitions.
  @SectionId('FTRTUR-FEAT-LST')
  @SectionIdPattern('FTRTUR-FEAT-xxx')
  @SerializationOrder(7)
  List<FeatureTourEntry> featureTours = [];
}

/// Feature tour settings.
@SectionId('ONHETO')
class OnboardingHelpTours {
    @Form([
        Field('featureToursEnabled', bool, 'Feature Tours Enabled'),
        Field('featureTourStyle', String, 'Feature Tour Style',
                hint: 'Spotlight, coach marks, carousel'),
        Field('featureTourTrigger', String, 'Feature Tour Trigger',
                hint: 'First visit, after action, manual'),
        Field('featureTourProgress', bool, 'Feature Tour Progress',
                hint: 'Show progress indicator'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Sample data settings.
@SectionId('OHSD')
class OnboardingHelpSampleData {
    @Form([
        Field('sampleDataAvailable', bool, 'Sample Data Available'),
        Field('sampleDataScope', String, 'Sample Data Scope',
                hint: 'What sample data is provided'),
        Field('sampleDataClear', String, 'Sample Data Clear',
                hint: 'How users remove sample data'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Getting started checklist configuration.
@SectionId('ONHECH')
class OnboardingHelpChecklist {
    @Form([
        Field('gettingStartedChecklist', bool, 'Getting Started Checklist'),
        Field('checklistItems', String, 'Checklist Items',
                hint: 'Setup tasks to complete'),
        Field('checklistProgress', String, 'Checklist Progress',
                hint: 'How progress is shown'),
        Field('checklistRewards', String, 'Checklist Rewards',
                hint: 'Gamification elements'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Progressive disclosure configuration.
@SectionId('ONHEDI')
class OnboardingHelpDisclosure {
    @Form([
        Field('progressiveDisclosure', String, 'Progressive Disclosure',
                hint: 'How features are revealed over time'),
        Field('skillLevelAdaptation', String, 'Skill Level Adaptation',
                hint: 'Adapt to user skill level'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Returning user experience.
@SectionId('ONHERE')
class OnboardingHelpReengagement {
    @Form([
        Field('returnUserWelcome', String, 'Return User Welcome',
                hint: 'Message for returning users'),
        Field('whatsNewFeature', bool, 'What\'s New Feature',
                hint: 'Show new features to returning users'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A feature tour entry.
@SectionId('FTRTUR')
class FeatureTourEntry {
  @Form([
    Field('tourId', String, 'Tour ID', required: true),
    Field('tourName', String, 'Tour Name', required: true),
    Field('tourDescription', String, 'Tour Description'),
    Field('targetAudience', String, 'Target Audience',
        hint: 'New users, specific role, all'),
    Field('triggerCondition', String, 'Trigger Condition',
        hint: 'When tour is shown'),
    Field('stepCount', int, 'Step Count'),
    Field('estimatedDuration', String, 'Estimated Duration'),
    Field('skippable', bool, 'Skippable'),
    Field('repeatPolicy', String, 'Repeat Policy',
        hint: 'Once only, on request, periodic'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Tour steps.
  @SectionId('TURST-STEP-LST')
  @SectionIdPattern('TURST-STEP-xxx')
  @SerializationOrder(1)
  List<TourStepEntry> steps = [];
}

/// A tour step entry.
@SectionId('TURST')
class TourStepEntry {
  @Form([
    Field('stepOrder', int, 'Step Order', required: true),
    Field('targetElement', String, 'Target Element',
        hint: 'Element to highlight'),
    Field('stepTitle', String, 'Step Title'),
    Field('stepContent', String, 'Step Content', required: true),
    Field('placement', String, 'Placement',
        hint: 'Position of coach mark'),
    Field('actionRequired', String, 'Action Required',
        hint: 'User action to proceed'),
    Field('spotlightShape', String, 'Spotlight Shape',
        hint: 'Circle, rectangle, custom'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 10.8.3. Support Access.
@SectionId('SUAC')
class SupportAccess {
  @Form([
    Field('helpCenterAvailable', bool, 'Help Center Available'),
    Field('liveChatAvailable', bool, 'Live Chat Available'),
    Field('ticketSubmission', bool, 'Ticket Submission'),
  ])
  @SerializationOrder(0)
  String? supportAccessContent;

  /// Help center configuration.
  @SerializationOrder(1)
  SupportAccessHelpCenter helpCenter = SupportAccessHelpCenter();

  /// Live support settings.
  @SerializationOrder(2)
  SupportAccessLiveSupport liveSupport = SupportAccessLiveSupport();

  /// Ticket system configuration.
  @SerializationOrder(3)
  SupportAccessTickets tickets = SupportAccessTickets();

  /// Contact methods.
  @SerializationOrder(4)
  SupportAccessContactMethods contactMethods = SupportAccessContactMethods();

  /// Self-service and feedback options.
  @SerializationOrder(5)
  SupportAccessSelfService selfService = SupportAccessSelfService();

  /// Support access narrative.
  @SerializationOrder(6)
  TextSection supportAccessNarrative = TextSection();
}

/// Help center configuration.
@SectionId('SAHC')
class SupportAccessHelpCenter {
  @Form([
    Field('helpCenterLocation', String, 'Help Center Location',
        hint: 'In-app, external, hybrid'),
    Field('helpCenterSearch', bool, 'Help Center Search',
        hint: 'Searchable knowledge base'),
    Field('helpArticleCategories', String, 'Article Categories',
        hint: 'How help is organized'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Live support settings.
@SectionId('SALS')
class SupportAccessLiveSupport {
  @Form([
    Field('liveChatHours', String, 'Live Chat Hours',
        hint: 'Availability hours'),
    Field('chatbotFirstLine', bool, 'Chatbot First Line',
        hint: 'Chatbot before human'),
    Field('chatbotCapabilities', String, 'Chatbot Capabilities',
        hint: 'What chatbot can handle'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Ticket system configuration.
@SectionId('SUACTI')
class SupportAccessTickets {
  @Form([
    Field('ticketFormFields', String, 'Ticket Form Fields',
        hint: 'Required ticket information'),
    Field('ticketAttachments', bool, 'Ticket Attachments',
        hint: 'Allow file attachments'),
    Field('ticketResponseSla', String, 'Ticket Response SLA',
        hint: 'Expected response time'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Contact methods.
@SectionId('SACM')
class SupportAccessContactMethods {
  @Form([
    Field('emailSupport', bool, 'Email Support'),
    Field('phoneSupport', bool, 'Phone Support'),
    Field('phoneNumber', String, 'Phone Number'),
    Field('communityForum', bool, 'Community Forum'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Self-service and feedback options.
@SectionId('SASS')
class SupportAccessSelfService {
  @Form([
    Field('faqSection', bool, 'FAQ Section'),
    Field('troubleshootingGuides', bool, 'Troubleshooting Guides'),
    Field('videoTutorials', bool, 'Video Tutorials'),
    Field('releaseNotes', bool, 'Release Notes'),
    Field('feedbackButton', bool, 'Feedback Button',
        hint: 'Always-visible feedback option'),
    Field('featureRequests', bool, 'Feature Requests',
        hint: 'Submit feature requests'),
    Field('bugReporting', bool, 'Bug Reporting',
        hint: 'Report bugs from app'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.9 Accessibility
// ---------------------------------------------------------------------------

/// 10.9. Accessibility.
///
/// Comprehensive accessibility requirements for the user interface following
/// WCAG guidelines and inclusive design principles.
@SectionId('ACCESS')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@SecondLevelSectionId(D09ExperienceDesignSpecification, 'XDS-ACC')
class Accessibility {
  // ─────────────────────────────────────────────────────────────────────────
  // Accessibility Overview
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('wcagComplianceTarget', String, 'WCAG Compliance Target',
        hint: 'A, AA, AAA'),
    Field('wcagVersion', String, 'WCAG Version',
        hint: '2.0, 2.1, 2.2'),
    Field('additionalStandards', String, 'Additional Standards',
        hint: 'Section 508, EN 301 549, ADA'),
    Field('accessibilityStatement', bool, 'Accessibility Statement',
        hint: 'Publish accessibility statement'),
  ])
  @SerializationOrder(0)
  String? accessibilityOverviewContent;

  /// Ownership and inclusive design philosophy.
  @SerializationOrder(1)
  AccessibilityStrategy strategy = AccessibilityStrategy();

  /// Accessibility testing approach.
  @SerializationOrder(2)
  AccessibilityTesting testing = AccessibilityTesting();

  /// Supported assistive technologies and platform features.
  @SerializationOrder(3)
  AccessibilitySupport support = AccessibilitySupport();

  /// Accessibility overview narrative.
  @ContentHelp('Executive summary of accessibility approach, '
      'compliance targets, and inclusive design principles.')
  @SerializationOrder(4)
  TextSection accessibilityOverview = TextSection();

  /// 10.9.1. WCAG Compliance Level.
  @SerializationOrder(5)
  WcagCompliance wcagComplianceLevel = WcagCompliance();

  /// 10.9.2. Accessibility Checklist.
  @SerializationOrder(6)
  AccessibilityChecklist accessibilityChecklist = AccessibilityChecklist();

  /// Keyboard navigation specification.
  @ContentHelp('Keyboard navigation patterns, focus management, '
      'and keyboard shortcuts.')
  @SerializationOrder(7)
  TextSection keyboardNavigation = TextSection();

  /// Screen reader support specification.
  @ContentHelp('Screen reader support: ARIA labels, landmarks, '
      'live regions, and announcements.')
  @SerializationOrder(8)
  TextSection screenReaderSupport = TextSection();

  /// Color and contrast specification.
  @ContentHelp('Color contrast requirements, color-blind-friendly '
      'design, and non-color indicators.')
  @SerializationOrder(9)
  TextSection colorAndContrast = TextSection();
}

/// Ownership and inclusive design philosophy.
@SectionId('ACSTGY')
class AccessibilityStrategy {
    @Form([
        Field('accessibilityPhilosophy', String, 'Accessibility Philosophy',
                hint: 'Inclusive design, equivalent experience'),
        Field('accessibilityOwnership', String, 'Accessibility Ownership',
                hint: 'Who is responsible for accessibility'),
        Field('accessibilityTraining', String, 'Accessibility Training',
                hint: 'Team training requirements'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Accessibility testing approach.
@SectionId('ACTE')
class AccessibilityTesting {
    @Form([
        Field('automatedTestingTools', String, 'Automated Testing Tools',
                hint: 'axe, WAVE, Lighthouse'),
        Field('manualTestingProcess', String, 'Manual Testing Process',
                hint: 'How manual testing is performed'),
        Field('assistiveTechTesting', String, 'Assistive Tech Testing',
                hint: 'Screen readers, switch devices'),
        Field('userTestingWithDisabilities', bool, 'User Testing with Disabilities',
                hint: 'Include users with disabilities'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Supported assistive technologies and platform features.
@SectionId('ACSU')
class AccessibilitySupport {
    @Form([
        Field('targetScreenReaders', String, 'Target Screen Readers',
                hint: 'NVDA, JAWS, VoiceOver, TalkBack'),
        Field('targetBrowserAccessibility', String, 'Target Browser Accessibility',
                hint: 'Browser accessibility features used'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 10.9.1. WCAG Compliance Level.
@SectionId('WCCO')
class WcagCompliance {
  @Form([
    Field('textAlternatives', String, 'Text Alternatives (1.1)',
        hint: 'Alt text for non-text content'),
    Field('timeBasedMedia', String, 'Time-Based Media (1.2)',
        hint: 'Captions, audio descriptions'),
    Field('adaptableContent', String, 'Adaptable Content (1.3)',
        hint: 'Structure, sequence, sensory'),
    Field('distinguishableContent', String, 'Distinguishable (1.4)',
        hint: 'Color, contrast, resize, audio'),
  ])
  @SerializationOrder(0)
  String? wcagComplianceContent;

  /// Operable principles.
  @SerializationOrder(1)
  WcagComplianceOperable operable = WcagComplianceOperable();

  /// Understandable principles.
  @SerializationOrder(2)
  WcagComplianceUnderstandable understandable =
      WcagComplianceUnderstandable();

  /// Robustness requirements.
  @SerializationOrder(3)
  WcagComplianceRobust robust = WcagComplianceRobust();

  /// WCAG compliance narrative.
  @SerializationOrder(4)
  TextSection wcagNarrative = TextSection();

  /// WCAG success criteria mapping.
  @SectionId('WSCE-SUCC-LST')
  @SectionIdPattern('WSCE-SUCC-xxx')
  @SerializationOrder(5)
  List<WcagSuccessCriterionEntry> successCriteria = [];
}

/// Operable principles.
@SectionId('WCCOOP')
class WcagComplianceOperable {
    @Form([
        Field('keyboardAccessible', String, 'Keyboard Accessible (2.1)',
                hint: 'Full keyboard operation'),
        Field('enoughTime', String, 'Enough Time (2.2)',
                hint: 'Adjustable timing, pause'),
        Field('seizureSafe', String, 'Seizure Safe (2.3)',
                hint: 'No flashing content'),
        Field('navigable', String, 'Navigable (2.4)',
                hint: 'Skip links, page titles, focus'),
        Field('inputModalities', String, 'Input Modalities (2.5)',
                hint: 'Pointer, motion, touch'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Understandable principles.
@SectionId('WCCOUN')
class WcagComplianceUnderstandable {
    @Form([
        Field('readable', String, 'Readable (3.1)',
                hint: 'Language, abbreviations'),
        Field('predictable', String, 'Predictable (3.2)',
                hint: 'Consistent navigation, identification'),
        Field('inputAssistance', String, 'Input Assistance (3.3)',
                hint: 'Error prevention, labels, suggestions'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Robustness requirements.
@SectionId('WCCORO')
class WcagComplianceRobust {
    @Form([
        Field('compatible', String, 'Compatible (4.1)',
                hint: 'Parsing, name/role/value'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A WCAG success criterion entry.
@SectionId('WCSUCREN')
class WcagSuccessCriterionEntry {
  @Form([
    Field('criterionId', String, 'Criterion ID', required: true,
        hint: 'WCAG SC ID (e.g., 1.4.3)'),
    Field('criterionName', String, 'Criterion Name', required: true),
    Field('level', String, 'Level',
        hint: 'A, AA, AAA'),
    Field('applicability', String, 'Applicability',
        hint: 'Where this applies in the app'),
    Field('implementation', String, 'Implementation',
        hint: 'How we meet this criterion'),
    Field('testingMethod', String, 'Testing Method',
        hint: 'How compliance is verified'),
    Field('status', String, 'Status',
        hint: 'Not started, in progress, compliant, not applicable'),
    Field('exceptions', String, 'Exceptions',
        hint: 'Any documented exceptions'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 10.9.2. Accessibility Checklist.
///
/// Comprehensive accessibility verification checklist.
@SectionId('ACCHLS')
class AccessibilityChecklist {
  @Form([
    Field('checklistStandard', String, 'Checklist Standard',
        hint: 'Based on WCAG, custom additions'),
    Field('checklistOwner', String, 'Checklist Owner',
        hint: 'Who maintains the checklist'),
    Field('checkFrequency', String, 'Check Frequency',
        hint: 'Per feature, per release, continuous'),
    Field('automatedChecks', String, 'Automated Checks',
        hint: 'Automated accessibility testing coverage'),
    Field('manualChecks', String, 'Manual Checks',
        hint: 'Manual testing procedures'),
    Field('userTesting', String, 'User Testing',
        hint: 'Testing with users with disabilities'),
    Field('reportingFormat', String, 'Reporting Format',
        hint: 'How accessibility status is reported'),
    Field('remediationProcess', String, 'Remediation Process',
        hint: 'How issues are fixed'),
  ])
  @SerializationOrder(0)
  String? checklistOverviewContent;

  /// Accessibility checklist overview.
  @SerializationOrder(1)
  TextSection checklistOverview = TextSection();

  /// Contains 0+× AccessibilityCheck.
  @SectionId('ACCH-ITEM-LST')
  @SectionIdPattern('ACCH-ITEM-xxx')
  @SerializationOrder(2)
  List<AccessibilityCheckEntry> items = [];
}

/// An accessibility check entry (form).
@SectionId('ACCH')
class AccessibilityCheckEntry {
  @Form([
    Field('checkId', String, 'Check ID', required: true),
    Field('checkItem', String, 'Check Item', required: true,
        hint: 'What is being checked'),
    Field('checkDescription', String, 'Check Description',
        hint: 'Detailed description'),
    Field('verificationMethod', String, 'Verification Method', required: true,
        hint: 'Automated, manual, user testing'),
  ])
  @SerializationOrder(0)
  String? content;

  /// WCAG mapping and compliance classification.
  @SerializationOrder(1)
  AccessibilityCheckEntryCompliance compliance =
      AccessibilityCheckEntryCompliance();

  /// Testing execution ownership and status.
  @SerializationOrder(2)
  AccessibilityCheckEntryExecution execution =
      AccessibilityCheckEntryExecution();

  /// Issue tracking and remediation details.
  @SerializationOrder(3)
  AccessibilityCheckEntryRemediation remediation =
      AccessibilityCheckEntryRemediation();
}

/// WCAG mapping and compliance classification.
@SectionId('ACEC')
class AccessibilityCheckEntryCompliance {
  @Form([
    Field('wcagCriterion', String, 'WCAG Criterion',
        hint: 'Related WCAG success criterion'),
    Field('complianceLevel', String, 'Compliance Level',
        hint: 'A, AA, AAA'),
    Field('checkCategory', String, 'Check Category',
        hint: 'Perceivable, operable, understandable, robust'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Testing execution ownership and status.
@SectionId('ACEE')
class AccessibilityCheckEntryExecution {
  @Form([
    Field('testingTool', String, 'Testing Tool',
        hint: 'Specific tool or technique'),
    Field('responsibleParty', String, 'Responsible Party',
        hint: 'Developer, QA, accessibility specialist'),
    Field('checkStatus', String, 'Check Status',
        hint: 'Not tested, passed, failed, n/a'),
    Field('testDate', String, 'Test Date'),
    Field('testedBy', String, 'Tested By'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Issue tracking and remediation details.
@SectionId('ACER')
class AccessibilityCheckEntryRemediation {
  @Form([
    Field('issuesFound', String, 'Issues Found',
        hint: 'Description of any issues'),
    Field('remediationPlan', String, 'Remediation Plan',
        hint: 'How issues will be fixed'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.10 Responsive Design
// ---------------------------------------------------------------------------

/// 10.10. Responsive Design.
///
/// Comprehensive responsive design specification covering breakpoints,
/// adaptive layouts, and device-specific behavior for Flutter applications.
@SectionId('REDE')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@SecondLevelSectionId(D09ExperienceDesignSpecification, 'XDS-RES')
class ResponsiveDesign {
  // ─────────────────────────────────────────────────────────────────────────
  // Responsive Design Overview
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    // Philosophy
    Field('responsivePhilosophy', String, 'Responsive Philosophy',
        hint: 'Mobile-first, desktop-first, adaptive'),
    Field('primaryTargetDevice', String, 'Primary Target Device',
        hint: 'Mobile phone, tablet, desktop'),
    Field('deviceAssumptions', String, 'Device Assumptions',
        hint: 'Assumptions about target devices'),
    // Framework approach
    Field('responsiveFramework', String, 'Responsive Framework',
        hint: 'LayoutBuilder, MediaQuery, responsive_framework'),
    Field('breakpointPackage', String, 'Breakpoint Package',
        hint: 'Custom, responsive_framework, flutter_screenutil'),
    Field('orientationSupport', String, 'Orientation Support',
        hint: 'Portrait only, landscape only, both'),
    // Testing approach
    Field('responsiveTestingApproach', String, 'Responsive Testing Approach',
        hint: 'Device lab, emulator matrix, golden tests'),
    Field('targetDeviceMatrix', String, 'Target Device Matrix',
        hint: 'List of target devices for testing'),
  ])
  @SerializationOrder(0)
  String? responsiveOverview;

  /// Responsive design narrative.
  @ContentHelp('Overview of responsive design approach, '
      'key decisions, and implementation strategy.')
  @SerializationOrder(1)
  TextSection responsiveNarrative = TextSection();

  /// 10.10.1. Breakpoints.
  @SerializationOrder(2)
  BreakpointConfiguration breakpointConfig = BreakpointConfiguration();

  /// 10.10.2. Responsive Behavior.
  @SerializationOrder(3)
  ResponsiveBehavior responsiveBehavior = ResponsiveBehavior();
}

/// 10.10.1. Breakpoints.
///
/// Breakpoint definitions for responsive layouts.
@SectionId('BC')
class BreakpointConfiguration {
  @Form([
    // Standard breakpoints
    Field('mobileMax', String, 'Mobile Max Width',
        hint: 'Maximum width for mobile (e.g., 599)'),
    Field('tabletMin', String, 'Tablet Min Width',
        hint: 'Minimum width for tablet (e.g., 600)'),
    Field('tabletMax', String, 'Tablet Max Width',
        hint: 'Maximum width for tablet (e.g., 1023)'),
    Field('desktopMin', String, 'Desktop Min Width',
        hint: 'Minimum width for desktop (e.g., 1024)'),
    Field('largeDesktopMin', String, 'Large Desktop Min Width',
        hint: 'Minimum width for large screens (e.g., 1440)'),
    // Additional breakpoints
    Field('watchMax', String, 'Watch Max Width',
        hint: 'Maximum width for wearables'),
    Field('foldableBreakpoint', String, 'Foldable Breakpoint',
        hint: 'Breakpoint for foldable devices'),
    Field('customBreakpoints', String, 'Custom Breakpoints',
        hint: 'Additional app-specific breakpoints'),
    // Units and density
    Field('breakpointUnit', String, 'Breakpoint Unit',
        hint: 'Logical pixels, device pixels'),
    Field('densityHandling', String, 'Density Handling',
        hint: 'How pixel density is handled'),
  ])
  @SerializationOrder(0)
  String? breakpointOverview;

  /// Breakpoint entries.
  @SectionId('BRE-BREA-LST')
  @SectionIdPattern('BRE-BREA-xxx')
  @SerializationOrder(1)
  List<BreakpointEntry> breakpoints = [];
}

/// A breakpoint entry.
@SectionId('BE')
class BreakpointEntry {
  @Form([
    Field('breakpointId', String, 'Breakpoint ID', required: true,
        hint: 'Unique identifier (e.g., TOM-MOBILE)'),
    Field('breakpointName', String, 'Breakpoint Name', required: true,
        hint: 'Mobile, Tablet, Desktop, Large Desktop'),
    Field('minWidth', String, 'Min Width',
        hint: 'Minimum width in logical pixels'),
    Field('maxWidth', String, 'Max Width',
        hint: 'Maximum width in logical pixels'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Grid and layout rules for this breakpoint.
  @SerializationOrder(1)
  BreakpointEntryLayout layout = BreakpointEntryLayout();

  /// Navigation and visual scaling rules.
  @SerializationOrder(2)
  BreakpointEntryScaling scaling = BreakpointEntryScaling();
}

/// Grid and layout rules for this breakpoint.
@SectionId('BRENLA')
class BreakpointEntryLayout {
  @Form([
    Field('columns', int, 'Grid Columns',
        hint: 'Number of grid columns at this breakpoint'),
    Field('gutterWidth', String, 'Gutter Width',
        hint: 'Space between columns'),
    Field('marginWidth', String, 'Margin Width',
        hint: 'Edge margins'),
    Field('layoutBehavior', String, 'Layout Behavior',
        hint: 'How layout changes at this breakpoint'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Navigation and visual scaling rules.
@SectionId('BRENSC')
class BreakpointEntryScaling {
  @Form([
    Field('navigationPattern', String, 'Navigation Pattern',
        hint: 'Bottom nav, drawer, rail, tabs'),
    Field('typographyScale', String, 'Typography Scale',
        hint: 'Font size scaling factor'),
    Field('spacingScale', String, 'Spacing Scale',
        hint: 'Spacing multiplier'),
    Field('iconScale', String, 'Icon Scale',
        hint: 'Icon size scaling factor'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 10.10.2. Responsive Behavior.
///
/// How the UI adapts across breakpoints.
@SectionId('REBE')
class ResponsiveBehavior {
  // ─────────────────────────────────────────────────────────────────────────
  // Layout Adaptation
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('mobileColumnLayout', String, 'Mobile Column Layout',
        hint: 'Single column, stacked'),
    Field('tabletColumnLayout', String, 'Tablet Column Layout',
        hint: '2-column, master-detail'),
    Field('desktopColumnLayout', String, 'Desktop Column Layout',
        hint: '3-column, sidebar + main'),
  ])
  @SerializationOrder(0)
  String? layoutAdaptation;

  /// Navigation patterns per device class.
  @SerializationOrder(1)
  ResponsiveBehaviorNavigation navigation = ResponsiveBehaviorNavigation();

  /// Visibility rules.
  @SerializationOrder(2)
  ResponsiveBehaviorVisibility visibility = ResponsiveBehaviorVisibility();

  /// Touch and interaction optimizations.
  @SerializationOrder(3)
  ResponsiveBehaviorTouch touch = ResponsiveBehaviorTouch();

  /// Content reflow rules.
  @SerializationOrder(4)
  ResponsiveBehaviorContent content = ResponsiveBehaviorContent();

  /// Responsive behavior narrative.
  @ContentHelp('Detailed description of responsive behavior '
      'across all breakpoints and device types.')
  @SerializationOrder(5)
  TextSection behaviorNarrative = TextSection();

  /// Screen-specific responsive rules.
  @SectionId('RESPSR-SCRE-LST')
  @SectionIdPattern('RESPSR-SCRE-xxx')
  @SerializationOrder(6)
  List<ResponsiveScreenRuleEntry> screenRules = [];
}

/// Navigation patterns per device class.
@SectionId('REBENA')
class ResponsiveBehaviorNavigation {
    @Form([
        Field('mobileNavigation', String, 'Mobile Navigation',
                hint: 'Bottom nav bar, hamburger drawer'),
        Field('tabletNavigation', String, 'Tablet Navigation',
                hint: 'Navigation rail, collapsible drawer'),
        Field('desktopNavigation', String, 'Desktop Navigation',
                hint: 'Full sidebar, top navigation'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Visibility rules.
@SectionId('REBEVI')
class ResponsiveBehaviorVisibility {
    @Form([
        Field('mobileHiddenElements', String, 'Mobile Hidden Elements',
                hint: 'Elements hidden on mobile'),
        Field('tabletHiddenElements', String, 'Tablet Hidden Elements'),
        Field('desktopOnlyElements', String, 'Desktop Only Elements'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Touch and interaction optimizations.
@SectionId('REBETO')
class ResponsiveBehaviorTouch {
    @Form([
        Field('touchTargetMinSize', String, 'Touch Target Min Size',
                hint: 'Minimum touch target (48dp recommended)'),
        Field('hoverEffects', String, 'Hover Effects',
                hint: 'When to show hover effects'),
        Field('gesturePriority', String, 'Gesture Priority',
                hint: 'Swipe, long-press on touch devices'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Content reflow rules.
@SectionId('REBECO')
class ResponsiveBehaviorContent {
    @Form([
        Field('contentReflowStrategy', String, 'Content Reflow Strategy',
                hint: 'How content reflows across breakpoints'),
        Field('imageScaling', String, 'Image Scaling',
                hint: 'How images scale responsively'),
        Field('tableResponsiveness', String, 'Table Responsiveness',
                hint: 'Horizontal scroll, cards, hide columns'),
        Field('formLayout', String, 'Form Layout',
                hint: 'How forms adapt: single column, multi-column'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A screen-specific responsive rule entry.
@SectionId('RESPSR')
class ResponsiveScreenRuleEntry {
  @Form([
    Field('screenId', String, 'Screen ID', required: true),
    Field('screenName', String, 'Screen Name', required: true),
    Field('mobileLayout', String, 'Mobile Layout'),
    Field('tabletLayout', String, 'Tablet Layout'),
    Field('desktopLayout', String, 'Desktop Layout'),
    Field('specialConsiderations', String, 'Special Considerations'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.11 UI Components
// ---------------------------------------------------------------------------

/// 10.11. UI Components.
///
/// Comprehensive UI component library specification covering design system,
/// component catalog, and detailed per-component specifications. Supports
/// Flutter-based implementation with Tom framework integration.
@SectionId('UICO')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@SecondLevelSectionId(D09ExperienceDesignSpecification, 'XDS-COM')
class UiComponents {
  // ─────────────────────────────────────────────────────────────────────────
  // Component Library Overview
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('designSystemName', String, 'Design System Name',
        hint: 'Name of the design system (e.g., "Acme Design System")'),
    Field('designSystemVersion', String, 'Design System Version'),
    Field('basedOnFramework', String, 'Based On Framework',
        hint: 'Material Design 3, Cupertino, Custom'),
    Field('tomFlutterUiIntegration', bool, 'Tom Flutter UI Integration',
        hint: 'Uses tom_flutter_ui component library'),
  ])
  @SerializationOrder(0)
  String? componentLibraryOverview;

  /// Visual language and brand alignment.
  @SerializationOrder(1)
  ComponentVisualLanguage visualLanguage = ComponentVisualLanguage();

  /// Component naming and documentation approach.
  @SerializationOrder(2)
  ComponentApproach componentApproach =
      ComponentApproach();

  /// Extension and theming boundaries.
  @SerializationOrder(3)
  ComponentCustomization customization = ComponentCustomization();

  /// 10.11.1. Component Library.
  @SerializationOrder(4)
  ComponentLibrary componentLibrary = ComponentLibrary();

  /// 10.11.2. Component Specifications — contains 0+×.
  @SectionId('UICOEN-COMP-LST')
  @SectionIdPattern('UICOEN-COMP-xxx')
  @SerializationOrder(5)
  List<UiComponentEntry> componentSpecs = [];

  /// 10.11.3. Component Families — contains 0+×.
  @SectionId('CMFA-COMP-LST')
  @SectionIdPattern('CMFA-COMP-xxx')
  @SerializationOrder(6)
  List<ComponentFamilyEntry> componentFamilies = [];
}

/// Visual language and brand alignment.
@SectionId('UCVL')
class ComponentVisualLanguage {
    @Form([
        Field('visualLanguage', String, 'Visual Language',
                hint: 'Clean, playful, professional, minimal'),
        Field('brandAlignment', String, 'Brand Alignment',
                hint: 'How design aligns with brand guidelines'),
        Field('motionPrinciples', String, 'Motion Principles',
                hint: 'Animation philosophy: subtle, expressive, functional'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Component naming and documentation approach.
@SectionId('UCCA')
class ComponentApproach {
    @Form([
        Field('componentGranularity', String, 'Component Granularity',
                hint: 'Atomic design levels: atoms, molecules, organisms'),
        Field('componentNaming', String, 'Component Naming Convention',
                hint: 'PascalCase, kebab-case, prefix rules'),
        Field('componentDocumentation', String, 'Component Documentation',
                hint: 'Storybook, living style guide, doc site'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Extension and theming boundaries.
@SectionId('UICOCU')
class ComponentCustomization {
    @Form([
        Field('extensionModel', String, 'Extension Model',
                hint: 'How components can be extended or themed'),
        Field('themingApproach', String, 'Theming Approach',
                hint: 'Token-based, widget-level, theme data'),
        Field('customizationBoundaries', String, 'Customization Boundaries',
                hint: 'What can vs. cannot be customized'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 10.11.1. Component Library.
///
/// Design system and component catalog specification.
@SectionId('COLI')
class ComponentLibrary {
  @SectionId('DESIG-DESI-LST')
  @SectionIdPattern('DESIG-DESI-xxx')
  @SerializationOrder(0)
  List<DesignFoundationEntry> designFoundations = [];

  /// Color system.
  @SerializationOrder(1)
  ComponentLibraryColors colors = ComponentLibraryColors();

  /// Typography system.
  @SerializationOrder(2)
  ComponentLibraryTypography typography = ComponentLibraryTypography();

  /// Spacing and elevation.
  @SerializationOrder(3)
  ComponentLibrarySpacing spacing = ComponentLibrarySpacing();

  /// Borders and corners.
  @SerializationOrder(4)
  ComponentLibraryBorders borders = ComponentLibraryBorders();

  /// Icons and animation.
  @SerializationOrder(5)
  ComponentLibraryVisuals visuals = ComponentLibraryVisuals();

  /// Design system narrative.
  @ContentHelp('Comprehensive description of the design system foundations, '
      'visual language, and component philosophy.')
  @SerializationOrder(6)
  TextSection designSystemNarrative = TextSection();

  /// Design token catalog.
  @ContentHelp('Catalog of all design tokens: colors, typography, spacing, '
      'elevation, borders, and animation values.')
  @SerializationOrder(7)
  TextSection designTokenCatalog = TextSection();

  /// Color palette specification.
  @SectionId('COPA-COLO-LST')
  @SectionIdPattern('COPA-COLO-xxx')
  @SerializationOrder(8)
  List<ColorPaletteEntry> colorPalettes = [];

  /// Typography styles.
  @SectionId('TYST-TYPO-LST')
  @SectionIdPattern('TYST-TYPO-xxx')
  @SerializationOrder(9)
  List<TypographyStyleEntry> typographyStyles = [];
}

/// Color system.
@SectionId('COLICO')
class ComponentLibraryColors {
  @Form([
    Field('secondaryColor', String, 'Secondary Color'),
    Field('tertiaryColor', String, 'Tertiary Color'),
    Field('errorColor', String, 'Error Color'),
    Field('warningColor', String, 'Warning Color'),
    Field('successColor', String, 'Success Color'),
    Field('infoColor', String, 'Info Color'),
    Field('surfaceColors', String, 'Surface Colors',
        hint: 'Background, card, dialog surfaces'),
    Field('colorTokenFormat', String, 'Color Token Format',
        hint: 'CSS variables, Dart constants, theme data'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Typography system.
@SectionId('COLITY')
class ComponentLibraryTypography {
  @Form([
    Field('fontFamilySecondary', String, 'Secondary Font Family'),
    Field('fontFamilyMonospace', String, 'Monospace Font Family'),
    Field('typographyScale', String, 'Typography Scale',
        hint: 'Material type scale, custom scale'),
    Field('fontSizeUnit', String, 'Font Size Unit',
        hint: 'Logical pixels, rem, sp'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Spacing and elevation.
@SectionId('COLISP')
class ComponentLibrarySpacing {
  @Form([
    Field('spacingTokens', String, 'Spacing Tokens',
        hint: 'xxs, xs, sm, md, lg, xl, xxl'),
    Field('elevationLevels', String, 'Elevation Levels',
        hint: 'Number of elevation levels'),
    Field('elevationImplementation', String, 'Elevation Implementation',
        hint: 'Shadows, borders, color shifts'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Borders and corners.
@SectionId('COLIBO')
class ComponentLibraryBorders {
  @Form([
    Field('cornerRadiusScale', String, 'Corner Radius Scale',
        hint: 'Rounded levels: none, sm, md, lg, full'),
    Field('borderStyleDefaults', String, 'Border Style Defaults'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Icons and animation.
@SectionId('COLIVI')
class ComponentLibraryVisuals {
  @Form([
    Field('iconLibrary', String, 'Icon Library',
        hint: 'Material Icons, Cupertino, custom'),
    Field('iconSizeScale', String, 'Icon Size Scale',
        hint: 'Small, medium, large sizes'),
    Field('animationDurations', String, 'Animation Durations',
        hint: 'Fast, normal, slow durations'),
    Field('animationCurves', String, 'Animation Curves',
        hint: 'Easing curves: ease, easeInOut, custom'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A color palette entry.
@SectionId('COPA')
class ColorPaletteEntry {
  @Form([
    Field('paletteName', String, 'Palette Name', required: true,
        hint: 'Primary, Secondary, Neutral, Error'),
    Field('paletteRole', String, 'Palette Role',
        hint: 'Brand, functional, semantic'),
    Field('colorCount', int, 'Color Count',
        hint: 'Number of color stops in palette'),
    Field('baseColor', String, 'Base Color',
        hint: 'Primary color value (hex)'),
    Field('lightVariants', String, 'Light Variants',
        hint: 'Lighter color stops'),
    Field('darkVariants', String, 'Dark Variants',
        hint: 'Darker color stops'),
    Field('onColorDefault', String, 'On-Color Default',
        hint: 'Default text color on this palette'),
    Field('wcagCompliance', String, 'WCAG Compliance',
        hint: 'Contrast compliance level'),
    Field('usageGuidelines', String, 'Usage Guidelines'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A typography style entry.
@SectionId('TYST')
class TypographyStyleEntry {
  @Form([
    Field('styleName', String, 'Style Name', required: true,
        hint: 'DisplayLarge, BodyMedium, LabelSmall'),
    Field('fontFamily', String, 'Font Family'),
    Field('fontSize', String, 'Font Size',
        hint: 'Size in logical pixels'),
    Field('fontWeight', String, 'Font Weight',
        hint: 'Normal, medium, semibold, bold'),
    Field('lineHeight', String, 'Line Height',
        hint: 'Line height multiplier'),
    Field('letterSpacing', String, 'Letter Spacing'),
    Field('textDecoration', String, 'Text Decoration',
        hint: 'None, underline, strikethrough'),
    Field('useCase', String, 'Use Case',
        hint: 'Where this style is used'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A component family entry.
///
/// Groups related components by function (buttons, inputs, navigation, etc.).
@SectionId('CMFA')
class ComponentFamilyEntry {
  @Form([
    Field('familyId', String, 'Family ID', required: true,
        hint: 'Unique identifier (e.g., FAM-BTN)'),
    Field('familyName', String, 'Family Name', required: true,
        hint: 'Buttons, Inputs, Navigation, Tables'),
    Field('familyDescription', String, 'Family Description'),
    Field('componentCount', int, 'Component Count'),
    Field('sharedPatterns', String, 'Shared Patterns',
        hint: 'Common patterns across family'),
    Field('consistencyRules', String, 'Consistency Rules',
        hint: 'Rules for family consistency'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Family narrative.
  @SerializationOrder(1)
  TextSection familyNarrative = TextSection();

  /// Components in this family.
  @SectionId('FAMREF-COMP-LST')
  @SectionIdPattern('FAMREF-COMP-xxx')
  @SerializationOrder(2)
  List<FamilyComponentRef> components = [];
}

/// A component reference within a family.
@SectionId('FAMREF')
class FamilyComponentRef {
  @Form([
    Field('componentId', String, 'Component ID', required: true),
    Field('componentName', String, 'Component Name', required: true),
    Field('familyRole', String, 'Family Role',
        hint: 'Primary, secondary, specialized'),
    Field('relationToOthers', String, 'Relation to Others',
        hint: 'How it relates to other family members'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A UI component entry.
///
/// Comprehensive specification for a single UI component covering identity,
/// visual design, behavior, states, responsiveness, accessibility,
/// authorization, and data binding.
@SectionId('UICOMENT')
class UiComponentEntry {
  // ─────────────────────────────────────────────────────────────────────────
  // Component Identity
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    // Identity
    Field('componentId', String, 'Component ID', required: true,
        hint: 'Unique identifier (e.g., CMP-DTT-001)'),
    Field('componentName', String, 'Component Name', required: true,
        hint: 'Human-readable name'),
    Field('componentFamily', String, 'Component Family',
        hint: 'Button, Input, Table, Navigation, etc.'),
    Field('flutterWidgetBase', String, 'Flutter Widget Base',
        hint: 'Base Flutter widget (DataTable, TextField)'),
  ])
  @SerializationOrder(0)
  String? identity;

  /// Wrapper mapping and business purpose.
  @SerializationOrder(1)
  UiComponentEntryPurpose purposeProfile = UiComponentEntryPurpose();

  /// Classification details.
  @SerializationOrder(2)
  UiComponentEntryClassification classification =
      UiComponentEntryClassification();

  // ─────────────────────────────────────────────────────────────────────────
  // Visual Design
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('defaultAppearance', String, 'Default Appearance',
        hint: 'Visual description of default state'),
    Field('colorScheme', String, 'Color Scheme',
        hint: 'Primary, secondary, surface colors used'),
    Field('typography', String, 'Typography',
        hint: 'Text styles used'),
    Field('iconography', String, 'Iconography',
        hint: 'Icons used and their placement'),
  ])
  @SerializationOrder(3)
  String? visualDesign;

  /// Visual dimensions.
  @SerializationOrder(4)
  UiComponentEntryDimensions dimensions = UiComponentEntryDimensions();

  /// Spacing rules.
  @SerializationOrder(5)
  UiComponentEntrySpacing spacing = UiComponentEntrySpacing();

  /// Surface treatment.
  @SerializationOrder(6)
  UiComponentEntrySurface surface = UiComponentEntrySurface();

  /// Visual design diagram.
  @ContentHelp('Visual diagram or mockup of the component.')
  @SerializationOrder(7)
  DiagramSection visualDiagram = DiagramSection();

  // ─────────────────────────────────────────────────────────────────────────
  // Interactive Behavior
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('tapBehavior', String, 'Tap Behavior',
        hint: 'What happens on tap/click'),
    Field('longPressBehavior', String, 'Long Press Behavior'),
    Field('doubleTapBehavior', String, 'Double Tap Behavior'),
    Field('swipeBehavior', String, 'Swipe Behavior'),
    Field('dragBehavior', String, 'Drag Behavior'),
    Field('hoverBehavior', String, 'Hover Behavior'),
  ])
  @SerializationOrder(8)
  String? interactiveBehavior;

  /// Focus and keyboard behavior.
  @SerializationOrder(9)
  UiComponentEntryInputBehavior inputBehavior = UiComponentEntryInputBehavior();

  /// Animation behavior.
  @SerializationOrder(10)
  UiComponentEntryAnimation animation = UiComponentEntryAnimation();

  /// Scrolling behavior.
  @SerializationOrder(11)
  UiComponentEntryScroll scroll = UiComponentEntryScroll();

  // ─────────────────────────────────────────────────────────────────────────
  // Responsiveness
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('mobileLayout', String, 'Mobile Layout',
        hint: 'Layout on mobile (< 600dp)'),
    Field('tabletLayout', String, 'Tablet Layout',
        hint: 'Layout on tablet (600-1024dp)'),
    Field('desktopLayout', String, 'Desktop Layout',
        hint: 'Layout on desktop (> 1024dp)'),
    Field('breakpointBehavior', String, 'Breakpoint Behavior',
        hint: 'What changes at breakpoints'),
    Field('adaptiveContent', String, 'Adaptive Content',
        hint: 'Content that appears/hides'),
    Field('touchTargets', String, 'Touch Targets',
        hint: 'Minimum touch target sizes'),
    Field('orientationBehavior', String, 'Orientation Behavior',
        hint: 'Portrait vs. landscape'),
  ])
  @SerializationOrder(12)
  String? responsiveness;

  // ─────────────────────────────────────────────────────────────────────────
  // Accessibility
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('semanticRole', String, 'Semantic Role',
        hint: 'ARIA role or semantic meaning'),
    Field('screenReaderLabel', String, 'Screen Reader Label',
        hint: 'How screen readers announce'),
    Field('screenReaderHint', String, 'Screen Reader Hint',
        hint: 'Additional context for screen readers'),
    Field('focusOrder', String, 'Focus Order',
        hint: 'Tab order in context'),
    Field('ariaAttributes', String, 'ARIA Attributes',
        hint: 'Required ARIA attributes'),
    Field('colorContrastNotes', String, 'Color Contrast Notes'),
    Field('motionSensitivity', String, 'Motion Sensitivity',
        hint: 'Reduced motion behavior'),
    Field('textScalingBehavior', String, 'Text Scaling Behavior',
        hint: 'How component responds to text scaling'),
  ])
  @SerializationOrder(13)
  String? accessibility;

  // ─────────────────────────────────────────────────────────────────────────
  // Authorization Integration
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('authBasePath', String, 'Auth Base Path',
        hint: 'Base path for authorization lookup'),
    Field('authVisibilityBehavior', String, 'Visibility Behavior',
        hint: 'Hidden, visible, conditionally visible'),
    Field('authEnabledBehavior', String, 'Enabled Behavior',
        hint: 'Disabled, enabled, conditionally enabled'),
    Field('authReadonlyBehavior', String, 'Readonly Behavior',
        hint: 'Readonly state behavior'),
    Field('authActionControl', String, 'Action Control',
        hint: 'Which actions are auth-controlled'),
    Field('authFallbackBehavior', String, 'Fallback Behavior',
        hint: 'Behavior when auth unavailable'),
    Field('fourStateMapping', String, 'Four-State Mapping',
        hint: 'Mapping to TomAuthState four states'),
  ])
  @SerializationOrder(14)
  String? authorization;

  // ─────────────────────────────────────────────────────────────────────────
  // Resource Integration
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('resourceBasePath', String, 'Resource Base Path',
        hint: 'Base path for resource lookup'),
    Field('labelResource', String, 'Label Resource',
        hint: 'Resource key for label text'),
    Field('hintResource', String, 'Hint Resource',
        hint: 'Resource key for hint text'),
    Field('errorResource', String, 'Error Resource',
        hint: 'Resource key for error messages'),
    Field('tooltipResource', String, 'Tooltip Resource'),
    Field('placeholderResource', String, 'Placeholder Resource'),
    Field('ariaLabelResource', String, 'ARIA Label Resource'),
    Field('iconResource', String, 'Icon Resource',
        hint: 'Resource key for icon selection'),
    Field('resourceFallbacks', String, 'Resource Fallbacks',
        hint: 'Fallback behavior when resource missing'),
  ])
  @SerializationOrder(15)
  String? resourceIntegration;

  // ─────────────────────────────────────────────────────────────────────────
  // Data Binding
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('dataType', String, 'Data Type',
        hint: 'Type of data component displays/edits'),
    Field('bindingPattern', String, 'Binding Pattern',
        hint: 'Observable, form field, direct'),
    Field('valueAccessor', String, 'Value Accessor',
        hint: 'How value is read/written'),
    Field('changeNotification', String, 'Change Notification',
        hint: 'How changes are communicated'),
    Field('validationIntegration', String, 'Validation Integration',
        hint: 'How validation errors are displayed'),
    Field('dirtyTracking', String, 'Dirty Tracking',
        hint: 'How dirty state is tracked'),
    Field('undoRedoSupport', String, 'Undo/Redo Support'),
  ])
  @SerializationOrder(16)
  String? dataBinding;

  /// Component behavior narrative.
  @ContentHelp('Detailed description of component behavior, '
      'user interactions, and edge cases.')
  @SerializationOrder(17)
  TextSection behaviorNarrative = TextSection();

  /// Contains 0+× ComponentState.
  @SectionId('CMST-STAT-LST')
  @SectionIdPattern('CMST-STAT-xxx')
  @SerializationOrder(18)
  List<ComponentStateEntry> states = [];

  /// Contains 0+× ComponentVariant.
  @SectionId('CMVN-VARI-LST')
  @SectionIdPattern('CMVN-VARI-xxx')
  @SerializationOrder(19)
  List<ComponentVariantEntry> variants = [];

  /// Contains 0+× ComponentAction.
  @SectionId('CMAC-ACTI-LST')
  @SectionIdPattern('CMAC-ACTI-xxx')
  @SerializationOrder(20)
  List<ComponentActionEntry> actions = [];

  /// Contains 0+× ComponentSlot.
  @SectionId('CMSL-SLOT-LST')
  @SectionIdPattern('CMSL-SLOT-xxx')
  @SerializationOrder(21)
  List<ComponentSlotEntry> slots = [];

  /// Contains 0+× ComponentProperty.
  @SectionId('CMPR-PROP-LST')
  @SectionIdPattern('CMPR-PROP-xxx')
  @SerializationOrder(22)
  List<ComponentPropertyEntry> properties = [];
}

/// Wrapper mapping and business purpose.
@SectionId('UCEP')
class UiComponentEntryPurpose {
    @Form([
        Field('tomWrapperClass', String, 'Tom Wrapper Class',
                hint: 'TomDataTable, TomTextField, etc.'),
        Field('purpose', String, 'Purpose', required: true,
                hint: 'What the component does'),
        Field('businessContext', String, 'Business Context',
                hint: 'Business scenarios where used'),
        Field('userGoals', String, 'User Goals',
                hint: 'What user accomplishes with this'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Classification details.
@SectionId('UCEC')
class UiComponentEntryClassification {
    @Form([
        Field('atomicLevel', String, 'Atomic Level',
                hint: 'Atom, molecule, organism'),
        Field('complexity', String, 'Complexity',
                hint: 'Simple, moderate, complex'),
        Field('reusability', String, 'Reusability',
                hint: 'Generic, semi-generic, specialized'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Visual dimensions.
@SectionId('UCED')
class UiComponentEntryDimensions {
    @Form([
        Field('defaultWidth', String, 'Default Width',
                hint: 'Default width or width behavior'),
        Field('defaultHeight', String, 'Default Height',
                hint: 'Default height or height behavior'),
        Field('minDimensions', String, 'Minimum Dimensions'),
        Field('maxDimensions', String, 'Maximum Dimensions'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Spacing rules.
@SectionId('UCES')
class UiComponentEntrySpacing {
    @Form([
        Field('internalPadding', String, 'Internal Padding'),
        Field('externalMargin', String, 'External Margin'),
        Field('contentSpacing', String, 'Content Spacing',
                hint: 'Spacing between internal elements'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Surface treatment.
@SectionId('UICOENSU')
class UiComponentEntrySurface {
    @Form([
        Field('borderStyle', String, 'Border Style'),
        Field('cornerRadius', String, 'Corner Radius'),
        Field('elevation', String, 'Elevation'),
        Field('shadowStyle', String, 'Shadow Style'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Focus and keyboard behavior.
@SectionId('UCEIB')
class UiComponentEntryInputBehavior {
    @Form([
        Field('focusBehavior', String, 'Focus Behavior',
                hint: 'Focus ring, highlight, navigation'),
        Field('keyboardNavigation', String, 'Keyboard Navigation',
                hint: 'Tab order, arrow key behavior'),
        Field('keyboardShortcuts', String, 'Keyboard Shortcuts'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Animation behavior.
@SectionId('UCEA')
class UiComponentEntryAnimation {
    @Form([
        Field('entryAnimation', String, 'Entry Animation'),
        Field('exitAnimation', String, 'Exit Animation'),
        Field('stateTransitions', String, 'State Transitions',
                hint: 'Animation between states'),
        Field('feedbackAnimations', String, 'Feedback Animations',
                hint: 'Ripple, scale, color change'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Scrolling behavior.
@SectionId('UICOENSC')
class UiComponentEntryScroll {
    @Form([
        Field('scrollBehavior', String, 'Scroll Behavior',
                hint: 'If component is scrollable'),
        Field('stickyBehavior', String, 'Sticky Behavior',
                hint: 'Headers, columns that stick'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A component state entry.
///
/// Defines a visual/functional state of the component.
@SectionId('COMSTAENT')
class ComponentStateEntry {
  @Form([
    Field('stateId', String, 'State ID', required: true,
        hint: 'Unique state identifier'),
    Field('stateName', String, 'State Name', required: true,
        hint: 'Loading, Empty, Error, Disabled, etc.'),
    Field('stateDescription', String, 'State Description'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Visual appearance in this state.
    @SerializationOrder(1)
    ComponentStateEntryVisual visual = ComponentStateEntryVisual();

    /// Behavior and accessibility changes in this state.
    @SerializationOrder(2)
    ComponentStateEntryBehavior behavior = ComponentStateEntryBehavior();

    /// Entry and exit transition rules.
    @SerializationOrder(3)
    ComponentStateEntryTransitions transitions =
            ComponentStateEntryTransitions();

  /// State visual mockup.
  @SerializationOrder(4)
  DiagramSection stateMockup = DiagramSection();
}

/// Visual appearance in this state.
@SectionId('CSEV')
class ComponentStateEntryVisual {
    @Form([
        Field('visualChanges', String, 'Visual Changes',
                hint: 'How appearance changes in this state'),
        Field('colorOverrides', String, 'Color Overrides'),
        Field('opacityChange', String, 'Opacity Change'),
        Field('iconChange', String, 'Icon Change'),
        Field('textChange', String, 'Text Change'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Behavior and accessibility changes in this state.
@SectionId('CSEB')
class ComponentStateEntryBehavior {
    @Form([
        Field('interactionChanges', String, 'Interaction Changes',
                hint: 'How interactions change'),
        Field('accessibilityState', String, 'Accessibility State',
                hint: 'Screen reader announcements'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Entry and exit transition rules.
@SectionId('CSET')
class ComponentStateEntryTransitions {
    @Form([
        Field('entryTrigger', String, 'Entry Trigger',
                hint: 'What causes entry to this state'),
        Field('exitTrigger', String, 'Exit Trigger',
                hint: 'What causes exit from this state'),
        Field('transitionAnimation', String, 'Transition Animation'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A component variant entry.
///
/// Defines a variation of the component with different appearance or behavior.
@SectionId('CVE')
class ComponentVariantEntry {
  @Form([
    Field('variantId', String, 'Variant ID', required: true),
    Field('variantName', String, 'Variant Name', required: true,
        hint: 'Filled, Outlined, Tonal, Text'),
    Field('variantDescription', String, 'Variant Description'),
    // Visual differentiation
    Field('visualDifferences', String, 'Visual Differences',
        hint: 'How variant looks different'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Visual styling details.
  @SerializationOrder(1)
  ComponentVariantEntryVisual visual = ComponentVariantEntryVisual();

  /// Behavioral and implementation notes.
  @SerializationOrder(2)
  ComponentVariantEntryBehavior behavior = ComponentVariantEntryBehavior();

  /// Variant visual mockup.
  @SerializationOrder(3)
  DiagramSection variantMockup = DiagramSection();
}

/// Visual styling details.
@SectionId('CVEV')
class ComponentVariantEntryVisual {
    @Form([
        Field('colorSchemeVariant', String, 'Color Scheme Variant'),
        Field('borderVariant', String, 'Border Variant'),
        Field('elevationVariant', String, 'Elevation Variant'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Behavioral and implementation notes.
@SectionId('CVEB')
class ComponentVariantEntryBehavior {
    @Form([
        Field('behaviorDifferences', String, 'Behavior Differences'),
        Field('useCaseDifferences', String, 'Use Case Differences',
                hint: 'When to use this variant'),
        Field('implementationNote', String, 'Implementation Note',
                hint: 'How variant is implemented'),
        Field('flutterVariant', String, 'Flutter Variant',
                hint: 'Corresponding Flutter variant'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A component action entry.
///
/// Defines an action that can be triggered from the component.
@SectionId('CMAC')
class ComponentActionEntry {
  @Form([
    Field('actionId', String, 'Action ID', required: true),
    Field('actionName', String, 'Action Name', required: true,
        hint: 'onTap, onSubmit, onDelete'),
    Field('actionTrigger', String, 'Action Trigger',
        hint: 'User interaction that triggers'),
    Field('actionPayload', String, 'Action Payload',
        hint: 'Data passed with action'),
  ])
  @SerializationOrder(0)
  String? content;

    /// Authorization and confirmation behavior.
    @SerializationOrder(1)
    ComponentActionEntryGovernance governance =
            ComponentActionEntryGovernance();

    /// Async execution and feedback behavior.
    @SerializationOrder(2)
    ComponentActionEntryExecution execution =
            ComponentActionEntryExecution();
}

/// Authorization and confirmation behavior.
@SectionId('CAEG')
class ComponentActionEntryGovernance {
    @Form([
        Field('actionResult', String, 'Action Result',
                hint: 'Expected outcome'),
        Field('authRequired', bool, 'Auth Required',
                hint: 'Requires authorization'),
        Field('authPermission', String, 'Auth Permission',
                hint: 'Required permission'),
        Field('confirmationRequired', bool, 'Confirmation Required'),
        Field('confirmationMessage', String, 'Confirmation Message'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Async execution and feedback behavior.
@SectionId('CAEE')
class ComponentActionEntryExecution {
    @Form([
        Field('asyncBehavior', String, 'Async Behavior',
                hint: 'Loading state during async'),
        Field('errorHandling', String, 'Error Handling'),
        Field('successFeedback', String, 'Success Feedback'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A component slot entry.
///
/// Defines a slot where child widgets can be placed.
@SectionId('CMSL')
class ComponentSlotEntry {
  @Form([
    Field('slotId', String, 'Slot ID', required: true),
    Field('slotName', String, 'Slot Name', required: true,
        hint: 'leading, trailing, title, content'),
    Field('slotDescription', String, 'Slot Description'),
    Field('slotRequired', bool, 'Slot Required'),
    Field('acceptedWidgets', String, 'Accepted Widgets',
        hint: 'Widget types allowed in slot'),
    Field('defaultContent', String, 'Default Content',
        hint: 'What shows if slot is empty'),
    Field('sizingBehavior', String, 'Sizing Behavior',
        hint: 'How slot affects component size'),
    Field('resourceKey', String, 'Resource Key',
        hint: 'Resource for slot content'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A component property entry.
///
/// Defines a configurable property of the component.
@SectionId('CMPR')
class ComponentPropertyEntry {
  @Form([
    Field('propertyId', String, 'Property ID', required: true),
    Field('propertyName', String, 'Property Name', required: true,
        hint: 'enabled, selected, elevation'),
    Field('propertyType', String, 'Property Type',
        hint: 'bool, String, Color, int'),
    Field('defaultValue', String, 'Default Value'),
    Field('allowedValues', String, 'Allowed Values',
        hint: 'Enum values or constraints'),
    Field('propertyDescription', String, 'Property Description'),
    Field('affectsAppearance', bool, 'Affects Appearance'),
    Field('affectsBehavior', bool, 'Affects Behavior'),
    Field('resourceResolvable', bool, 'Resource Resolvable',
        hint: 'Can be resolved from resources'),
    Field('authControlled', bool, 'Auth Controlled',
        hint: 'Controlled by authorization'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.12 Multi-language Support
// ---------------------------------------------------------------------------

/// 10.12. Multi-language Support.
///
/// Locale-picker / UX-side multi-language concerns that stay on the
/// Experience & Interface Design side. IP-6 re-homed the requirement-side
/// concerns (i18n requirements, documentation, training) to SBP.9 and the
/// execution-side concerns (localization/translation processes, rollout
/// sequencing) to SBP.15; only the stay-put UX members remain here.
@SectionId('MLAR')
class MultiLanguageSupport {
  // ─────────────────────────────────────────────────────────────────────────
  // Multi-language Overview
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    // Scope
    Field('supportedLanguages', String, 'Supported Languages',
        hint: 'List of supported languages (e.g., en, de, fr, es)'),
    Field('primaryLanguage', String, 'Primary Language',
        hint: 'Default/fallback language'),
    Field('futureLanguages', String, 'Future Languages',
        hint: 'Languages planned for future support'),
    Field('rtlLanguages', String, 'RTL Languages',
        hint: 'Right-to-left languages supported'),
    // Locale handling
  ])
  @SerializationOrder(0)
  String? multiLanguageOverview;

  /// Multi-language overview narrative.
  @ContentHelp('Executive summary of internationalization and '
      'localization approach for the system.')
  @SerializationOrder(1)
  TextSection overviewNarrative = TextSection();

  /// 10.12.4. Language and Country Selection.
  @SerializationOrder(2)
  LanguageCountrySelection languageCountrySelection = LanguageCountrySelection();

  /// Supported locale entries.
  @SectionId('SULOEN-SUPP-LST')
  @SectionIdPattern('SULOEN-SUPP-xxx')
  @SerializationOrder(3)
  List<SupportedLocaleEntry> supportedLocales = [];
}

/// Locale modeling and fallback behavior.
@SectionId('MLARLH')
class LocaleHandlingRequirements {
    @Form([
        Field('localeFormat', String, 'Locale Format',
                hint: 'BCP 47, ISO 639-1, custom'),
        Field('countryVariants', String, 'Country Variants',
                hint: 'en-US vs en-GB, de-DE vs de-AT'),
        Field('localeDetection', String, 'Locale Detection',
                hint: 'Browser, OS, user setting, geo-IP'),
        Field('localeFallbackChain', String, 'Locale Fallback Chain',
                hint: 'Fallback order when locale not available'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Rollout sequencing by region and time.
@SectionId('LOCRP')
@MapsTo(D12TransitionRolloutPlan)
@DetailedIn(D12TransitionRolloutPlan)
@SecondLevelSectionId(D12TransitionRolloutPlan, 'TRP-RLP')
class LocaleRolloutPlan {
    @Form([
        Field('rolloutStrategy', String, 'Rollout Strategy',
                hint: 'Big bang, phased, pilot'),
        Field('rolloutTimeline', String, 'Rollout Timeline',
                hint: 'High-level rollout schedule'),
        Field('rolloutRegions', String, 'Rollout Regions',
                hint: 'Geographic rollout order'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 10.12.1. Localization Process.
///
/// Workflow for identifying and preparing content for localization.
@SectionId('LOPR')
@MapsTo(D12TransitionRolloutPlan)
@DetailedIn(D12TransitionRolloutPlan)
@SecondLevelSectionId(D12TransitionRolloutPlan, 'TRP-LOC')
class LocalizationProcess {
  @Form([
    Field('contentIdentification', String, 'Content Identification',
        hint: 'How localizable content is identified'),
    Field('stringExternalization', String, 'String Externalization',
        hint: 'Approach to externalizing strings'),
    Field('contentTagging', String, 'Content Tagging',
        hint: 'How content is tagged for translation'),
    Field('localizationScope', String, 'Localization Scope',
        hint: 'UI text, images, audio, video, documents'),
  ])
  @SerializationOrder(0)
  String? localizationProcessContent;

  /// Review process.
  @SerializationOrder(1)
  LocalizationReview review = LocalizationReview();

  /// Formatting rules.
  @SerializationOrder(2)
  LocalizationFormatting formatting = LocalizationFormatting();

  /// Deployment settings.
  @SerializationOrder(3)
  LocalizationDeployment deployment = LocalizationDeployment();

  /// Localization process narrative.
  @SerializationOrder(4)
  TextSection localizationNarrative = TextSection();

  /// Localization workflow diagram.
  @SerializationOrder(5)
  FlowDiagramSection workflowDiagram = FlowDiagramSection();
}

/// Review process.
@SectionId('LOPRR1')
class LocalizationReview {
    @Form([
        Field('reviewWorkflow', String, 'Review Workflow',
                hint: 'Steps in the localization review'),
        Field('stakeholderApproval', String, 'Stakeholder Approval',
                hint: 'Who approves localized content'),
        Field('qualityAssurance', String, 'Quality Assurance',
                hint: 'QA process for localized content'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Formatting rules.
@SectionId('LOPRFO')
class LocalizationFormatting {
    @Form([
        Field('dateFormatRules', String, 'Date Format Rules',
                hint: 'Locale-specific date formatting'),
        Field('numberFormatRules', String, 'Number Format Rules',
                hint: 'Locale-specific number formatting'),
        Field('currencyFormatRules', String, 'Currency Format Rules',
                hint: 'Locale-specific currency formatting'),
        Field('addressFormatRules', String, 'Address Format Rules',
                hint: 'Locale-specific address formatting'),
        Field('phoneFormatRules', String, 'Phone Format Rules',
                hint: 'Locale-specific phone number formatting'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Deployment settings.
@SectionId('LOPRDE')
class LocalizationDeployment {
    @Form([
        Field('localeDeployment', String, 'Locale Deployment',
                hint: 'How locales are deployed'),
        Field('localeToggling', String, 'Locale Toggling',
                hint: 'Feature flags for locales'),
        Field('perLocaleCustomization', String, 'Per-Locale Customization',
                hint: 'Locale-specific features or content'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 10.12.2. Translation Process.
///
/// Workflow for translating content.
@SectionId('TRPR')
@MapsTo(D12TransitionRolloutPlan)
@DetailedIn(D12TransitionRolloutPlan)
@SecondLevelSectionId(D12TransitionRolloutPlan, 'TRP-TRA')
class TranslationProcess {
  @Form([
    Field('translationManagementSystem', String, 'Translation Management System',
        hint: 'TMS tool (Phrase, Lokalise, Crowdin)'),
    Field('translationMemory', String, 'Translation Memory',
        hint: 'TM usage and maintenance'),
    Field('machineTranslation', String, 'Machine Translation',
        hint: 'MT usage (Google, DeepL, none)'),
    Field('catTools', String, 'CAT Tools',
        hint: 'Computer-assisted translation tools'),
  ])
  @SerializationOrder(0)
  String? translationProcessContent;

  /// Translation workflow.
  @SerializationOrder(1)
  TranslationWorkflow workflow = TranslationWorkflow();

  /// Quality assurance.
  @SerializationOrder(2)
  TranslationQuality quality = TranslationQuality();

  /// Terminology and voice management.
  @SerializationOrder(3)
  TranslationTerminology terminology =
      TranslationTerminology();

  /// Ongoing localization operations.
  @SerializationOrder(4)
  TranslationOngoing ongoing = TranslationOngoing();

  /// Translation process narrative.
  @SerializationOrder(5)
  TextSection translationNarrative = TextSection();

  /// Translation vendor entries.
  @SectionId('TRVEEN-VEND-LST')
  @SectionIdPattern('TRVEEN-VEND-xxx')
  @SerializationOrder(6)
  List<TranslationVendorEntry> vendors = [];
}

/// Translation workflow.
@SectionId('TRPRWO')
class TranslationWorkflow {
    @Form([
        Field('translationWorkflow', String, 'Translation Workflow',
                hint: 'Steps: extract → translate → review → integrate'),
        Field('reviewCycles', String, 'Review Cycles',
                hint: 'Number of review rounds'),
        Field('inCountryReview', String, 'In-Country Review',
                hint: 'Native speaker review process'),
        Field('contextualReview', String, 'Contextual Review',
                hint: 'In-app review process'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Quality assurance.
@SectionId('TRPRQU')
class TranslationQuality {
    @Form([
        Field('qualityChecks', String, 'Quality Checks',
                hint: 'Automated quality checks'),
        Field('linguisticQA', String, 'Linguistic QA',
                hint: 'Linguistic quality assurance'),
        Field('functionalQA', String, 'Functional QA',
                hint: 'Functional testing of translations'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Terminology and voice management.
@SectionId('TRPRTE')
class TranslationTerminology {
    @Form([
        Field('glossaryManagement', String, 'Glossary Management',
                hint: 'Term base management'),
        Field('styleGuide', String, 'Style Guide',
                hint: 'Translation style guidelines'),
        Field('brandVoice', String, 'Brand Voice',
                hint: 'How brand voice is maintained'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Ongoing localization operations.
@SectionId('TRPRON')
class TranslationOngoing {
    @Form([
        Field('continuousLocalization', String, 'Continuous Localization',
                hint: 'CI/CD integration for translations'),
        Field('translationMemoryMaintenance', String, 'TM Maintenance',
                hint: 'How translation memory is maintained'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A translation vendor entry.
@SectionId('TVE')
class TranslationVendorEntry {
  @Form([
    Field('vendorName', String, 'Vendor Name', required: true),
    Field('vendorType', String, 'Vendor Type',
        hint: 'LSP, freelance, in-house'),
    Field('languages', String, 'Languages',
        hint: 'Languages handled by vendor'),
    Field('specializations', String, 'Specializations',
        hint: 'Technical, legal, marketing'),
    Field('turnaroundTime', String, 'Turnaround Time'),
    Field('qualityRating', String, 'Quality Rating'),
    Field('contactInfo', String, 'Contact Info'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 10.12.3. User Documentation Requirements.
///
/// End-user documentation deliverables. The documentation half of the former
/// `DocumentationAndTraining` (`DOANTR`); split from its training half in
/// L34C-7 (SR-29). Logically re-homed under SBP.9 `InformationForUseRequirements`
/// (`IFUR`) while physically staying in this file alongside its `DATD`/`DATL`
/// sub-forms and the shared `TextSection`. Retains `DOANTR` + the shared
/// `TRP-DOC` D12 detail subsection.
@SectionId('DOANTR')
@MapsTo(D12TransitionRolloutPlan)
@DetailedIn(D12TransitionRolloutPlan)
@SecondLevelSectionId(D12TransitionRolloutPlan, 'TRP-DOC')
class UserDocumentationRequirements {
  @Form([
    Field('documentationFormat', String, 'Documentation Format',
        hint: 'HTML, PDF, in-app, wiki'),
    Field('documentationPlatform', String, 'Documentation Platform',
        hint: 'GitBook, Notion, custom, Confluence'),
    Field('documentationVersioning', String, 'Documentation Versioning',
        hint: 'How docs are versioned with releases'),
  ])
  @SerializationOrder(0)
  String? documentationContent;

  /// Documentation deliverables provided to users.
  @SerializationOrder(1)
  DocumentationAndTrainingDeliverables deliverables =
      DocumentationAndTrainingDeliverables();

  /// Documentation localization approach.
  @SerializationOrder(2)
  DocumentationAndTrainingLocalization localization =
      DocumentationAndTrainingLocalization();

  /// Documentation narrative.
  @SerializationOrder(3)
  TextSection documentationNarrative = TextSection();
}

/// 10.12.3b. Training Deliverable Requirements.
///
/// End-user training materials and module catalogue. The training half of the
/// former `DocumentationAndTraining` (`DOANTR`); split from its documentation
/// half in L34C-7 (SR-29). Logically re-homed under SBP.9
/// `TrainingEnablementRequirements` (`TREQ`) while physically staying in this
/// file. Maps to D12 under the existing training detail subsection `TRP-TRN`
/// (shared with SBP.15 `RolloutTrainingMaterial`), grouping all training
/// content in one D12 subsection rather than fragmenting it across a new id.
@SectionId('TRMAT')
@MapsTo(D12TransitionRolloutPlan)
@DetailedIn(D12TransitionRolloutPlan)
@SecondLevelSectionId(D12TransitionRolloutPlan, 'TRP-TRN')
class TrainingDeliverableRequirements {
  @Form([
    // Training materials
    Field('trainingMaterials', String, 'Training Materials',
        hint: 'Slides, workbooks, exercises'),
    Field('trainingFormat', String, 'Training Format',
        hint: 'In-person, virtual, self-paced'),
    Field('trainingDuration', String, 'Training Duration',
        hint: 'Duration per role/module'),
    // Training schedule
    Field('trainingSchedule', String, 'Training Schedule',
        hint: 'When training occurs'),
    Field('trainTheTrainer', bool, 'Train-the-Trainer',
        hint: 'Train internal trainers'),
    Field('refresherTraining', String, 'Refresher Training',
        hint: 'Ongoing training approach'),
    // Knowledge transfer
    Field('knowledgeTransferPlan', String, 'Knowledge Transfer Plan',
        hint: 'How knowledge is transferred'),
    Field('supportHandoff', String, 'Support Handoff',
        hint: 'Transition to support team'),
    Field('certificationProgram', String, 'Certification Program',
        hint: 'User certification if applicable'),
  ])
  @SerializationOrder(0)
  String? trainingContent;

  /// Training narrative.
  @SerializationOrder(1)
  TextSection trainingNarrative = TextSection();

  /// Training module entries.
  @SectionId('TRMOEN-TRAI-LST')
  @SectionIdPattern('TRMOEN-TRAI-xxx')
  @SerializationOrder(2)
  List<TrainingModuleEntry> trainingModules = [];
}

/// Documentation deliverables provided to users.
@SectionId('DATD')
class DocumentationAndTrainingDeliverables {
    @Form([
        Field('userGuide', bool, 'User Guide'),
        Field('quickStartGuide', bool, 'Quick Start Guide'),
        Field('onlineHelp', bool, 'Online Help'),
        Field('videoTutorials', bool, 'Video Tutorials'),
        Field('contextualHelp', bool, 'Contextual Help'),
        Field('faq', bool, 'FAQ'),
        Field('releaseNotes', bool, 'Release Notes'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Documentation localization approach.
@SectionId('DATL')
class DocumentationAndTrainingLocalization {
    @Form([
        Field('documentationLanguages', String, 'Documentation Languages',
                hint: 'Languages for documentation'),
        Field('documentationTranslation', String, 'Documentation Translation',
                hint: 'Translation approach for docs'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A training module entry.
@SectionId('TME')
class TrainingModuleEntry {
  @Form([
    Field('moduleId', String, 'Module ID', required: true),
    Field('moduleName', String, 'Module Name', required: true),
    Field('targetAudience', String, 'Target Audience',
        hint: 'End users, admins, power users'),
    Field('duration', String, 'Duration'),
    Field('deliveryMethod', String, 'Delivery Method',
        hint: 'In-person, virtual, self-paced'),
    Field('prerequisites', String, 'Prerequisites'),
    Field('learningObjectives', String, 'Learning Objectives'),
    Field('assessmentMethod', String, 'Assessment Method'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 10.12.4. Language and Country Selection.
///
/// UI specification for language and country selection.
@SectionId('LACOSE')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@SecondLevelSectionId(D09ExperienceDesignSpecification, 'XDS-LCS')
class LanguageCountrySelection {
  @Form([
    Field('pickerLocation', String, 'Picker Location',
        hint: 'Header, footer, settings, onboarding'),
    Field('pickerStyle', String, 'Picker Style',
        hint: 'Dropdown, modal, full page'),
    Field('languageDisplay', String, 'Language Display',
        hint: 'Native names, English names, flags'),
    Field('countryDisplay', String, 'Country Display',
        hint: 'How countries are displayed'),
    Field('searchable', bool, 'Searchable',
        hint: 'Can user search languages/countries'),
  ])
  @SerializationOrder(0)
  String? languageSelectionContent;

  /// Default locale behavior.
  @SerializationOrder(1)
  LanguageCountrySelectionDefaults defaults =
      LanguageCountrySelectionDefaults();

  /// Persistence rules.
  @SerializationOrder(2)
  LanguageCountrySelectionPersistence persistence =
      LanguageCountrySelectionPersistence();

  /// Fallback behavior.
  @SerializationOrder(3)
  LanguageCountrySelectionFallback fallback =
      LanguageCountrySelectionFallback();

  /// Switching UX behavior.
  @SerializationOrder(4)
  LanguageCountrySelectionUx ux = LanguageCountrySelectionUx();

  /// Language selection narrative.
  @SerializationOrder(5)
  TextSection languageSelectionNarrative = TextSection();

  /// Language selection mockup.
  @SerializationOrder(6)
  DiagramSection languagePickerMockup = DiagramSection();
}

/// Default locale behavior.
@SectionId('LCSD')
class LanguageCountrySelectionDefaults {
    @Form([
        Field('defaultLanguage', String, 'Default Language',
                hint: 'How default language is determined'),
        Field('defaultCountry', String, 'Default Country',
                hint: 'How default country is determined'),
        Field('autoDetection', String, 'Auto-Detection',
                hint: 'Browser, OS, geo-IP detection'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Persistence rules.
@SectionId('LCSP')
class LanguageCountrySelectionPersistence {
    @Form([
        Field('persistenceMethod', String, 'Persistence Method',
                hint: 'Cookie, localStorage, user profile'),
        Field('crossDeviceSync', bool, 'Cross-Device Sync',
                hint: 'Sync preference across devices'),
        Field('anonymousPersistence', String, 'Anonymous Persistence',
                hint: 'How preference persists for guests'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Fallback behavior.
@SectionId('LCSF')
class LanguageCountrySelectionFallback {
    @Form([
        Field('localeFallbackBehavior', String, 'Locale Fallback Behavior',
                hint: 'What happens when locale unavailable'),
        Field('partialLocalSupport', String, 'Partial Locale Support',
                hint: 'UI in one locale, content in another'),
        Field('missingTranslationDisplay', String, 'Missing Translation Display',
                hint: 'How missing translations are shown'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Switching UX behavior.
@SectionId('LCSU')
class LanguageCountrySelectionUx {
    @Form([
        Field('languageSwitchBehavior', String, 'Language Switch Behavior',
                hint: 'Page reload, inline update'),
        Field('confirmationRequired', bool, 'Confirmation Required',
                hint: 'Confirm before switching'),
        Field('contentRetention', String, 'Content Retention',
                hint: 'What happens to in-progress content'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 10.12.5. Translation Handling Requirements.
///
/// Technical requirements for internationalization framework.
@SectionId('TRAREQ')
@MapsTo(D06ArchitectureTechnologySpecification)
@DetailedIn(D06ArchitectureTechnologySpecification)
@SecondLevelSectionId(D06ArchitectureTechnologySpecification, 'ATS-REQ')
class TranslationRequirements {
  @Form([
    Field('i18nFramework', String, 'I18N Framework',
        hint: 'flutter_localizations, intl, easy_localization'),
    Field('stringExternalizationFormat', String, 'String Externalization Format',
        hint: 'ARB, JSON, YAML, Gettext'),
    Field('localeHandling', String, 'Locale Handling',
        hint: 'How locales are loaded and switched'),
  ])
  @SerializationOrder(0)
  String? translationRequirementsContent;

  /// RTL and bidirectional support.
  @SerializationOrder(1)
  TranslationRequirementsRtl rtl = TranslationRequirementsRtl();

  /// Locale-specific formatting rules.
  @SerializationOrder(2)
  TranslationRequirementsFormatting formatting =
      TranslationRequirementsFormatting();

  /// Pluralization and variants.
  @SerializationOrder(3)
  TranslationRequirementsVariants variants = TranslationRequirementsVariants();

  /// Technical text and font support.
  @SerializationOrder(4)
  TranslationRequirementsTechnical technical =
      TranslationRequirementsTechnical();

  /// Translation requirements narrative.
  @SerializationOrder(5)
  TextSection requirementsNarrative = TextSection();
}

/// RTL and bidirectional support.
@SectionId('TRRERT')
class TranslationRequirementsRtl {
  @Form([
    Field('rtlSupport', bool, 'RTL Support'),
    Field('rtlImplementation', String, 'RTL Implementation',
        hint: 'How RTL is implemented'),
    Field('bidirectionalText', String, 'Bidirectional Text',
        hint: 'Handling mixed LTR/RTL content'),
    Field('rtlMirroring', String, 'RTL Mirroring',
        hint: 'UI element mirroring rules'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Locale-specific formatting rules.
@SectionId('TRREFO')
class TranslationRequirementsFormatting {
  @Form([
    Field('dateTimeFormatting', String, 'Date/Time Formatting',
        hint: 'intl DateFormat, custom'),
    Field('numberFormatting', String, 'Number Formatting',
        hint: 'intl NumberFormat, custom'),
    Field('currencyFormatting', String, 'Currency Formatting',
        hint: 'Currency display and conversion'),
    Field('measurementUnits', String, 'Measurement Units',
        hint: 'Metric, imperial, locale-based'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Pluralization and variants.
@SectionId('TRREVA')
class TranslationRequirementsVariants {
  @Form([
    Field('pluralizationRules', String, 'Pluralization Rules',
        hint: 'ICU plural format, custom'),
    Field('genderSupport', String, 'Gender Support',
        hint: 'Grammatical gender handling'),
    Field('contextualVariants', String, 'Contextual Variants',
        hint: 'Formal/informal, regional variants'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Technical text and font support.
@SectionId('TRRETE')
class TranslationRequirementsTechnical {
  @Form([
    Field('unicodeSupport', String, 'Unicode Support',
        hint: 'Unicode handling and normalization'),
    Field('fontFallback', String, 'Font Fallback',
        hint: 'Font fallback for different scripts'),
    Field('textDirection', String, 'Text Direction',
        hint: 'Directionality handling'),
    Field('keyboardLayouts', String, 'Keyboard Layouts',
        hint: 'IME and keyboard support'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A supported locale entry.
@SectionId('SUPLOCENT')
class SupportedLocaleEntry {
  @Form([
    Field('localeCode', String, 'Locale Code', required: true,
        hint: 'BCP 47 code (e.g., en-US)'),
    Field('languageName', String, 'Language Name', required: true,
        hint: 'English name'),
    Field('nativeLanguageName', String, 'Native Language Name',
        hint: 'Name in native language'),
    Field('countryRegion', String, 'Country/Region',
        hint: 'Country or region'),
  ])
  @SerializationOrder(0)
  String? content;

  /// Formatting and direction rules for the locale.
  @SerializationOrder(1)
  SupportedLocaleEntryFormatting formatting = SupportedLocaleEntryFormatting();

  /// Launch readiness and locale ownership.
  @SerializationOrder(2)
  SupportedLocaleEntryRollout rollout = SupportedLocaleEntryRollout();
}

/// Formatting and direction rules for the locale.
@SectionId('SLEF')
class SupportedLocaleEntryFormatting {
  @Form([
    Field('textDirection', String, 'Text Direction',
        hint: 'LTR, RTL'),
    Field('dateFormat', String, 'Date Format',
        hint: 'Preferred date format'),
    Field('numberFormat', String, 'Number Format',
        hint: 'Decimal separator, thousand separator'),
    Field('currency', String, 'Currency',
        hint: 'Default currency for locale'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// Launch readiness and locale ownership.
@SectionId('SULOENRO')
class SupportedLocaleEntryRollout {
  @Form([
    Field('launchPhase', String, 'Launch Phase',
        hint: 'When locale will be available'),
    Field('translationCoverage', String, 'Translation Coverage',
        hint: 'Percentage translated'),
    Field('localeOwner', String, 'Locale Owner',
        hint: 'Person responsible for locale'),
  ])
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.13 Prototype
// ---------------------------------------------------------------------------

/// 10.13. Prototype.
///
/// Comprehensive prototype planning covering goals, feature selection,
/// prototype type, evaluation criteria, and stakeholder alignment.
@SectionId('PROTOT')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@SecondLevelSectionId(D09ExperienceDesignSpecification, 'XDS-PRO')
class Prototype {
  // ─────────────────────────────────────────────────────────────────────────
  // Prototype Overview
  // ─────────────────────────────────────────────────────────────────────────
  @Form([
    Field('prototypePurpose', String, 'Prototype Purpose',
        hint: 'Primary goal: validation, alignment, feasibility'),
    Field('prototypeScope', String, 'Prototype Scope',
        hint: 'What is included in prototype'),
    Field('targetAudience', String, 'Target Audience',
        hint: 'Who will evaluate the prototype'),
    Field('successCriteria', String, 'Success Criteria',
        hint: 'How success is measured'),
  ])
  @SerializationOrder(0)
  String? prototypeOverview;

  /// Prototype timing commitments.
  @SerializationOrder(1)
  PrototypeTimeline timeline = PrototypeTimeline();

  /// Prototype staffing and environment.
  @SerializationOrder(2)
  PrototypeResources resources = PrototypeResources();

  /// Approval and progression criteria.
  @SerializationOrder(3)
  PrototypeGovernance governance = PrototypeGovernance();

  /// Prototype overview narrative.
  @ContentHelp('Executive summary of prototype approach, '
      'objectives, and expected outcomes.')
  @SerializationOrder(4)
  TextSection overviewNarrative = TextSection();

  /// 10.13.1. Prototype Goals.
  @SerializationOrder(5)
  PrototypeGoals prototypeGoals = PrototypeGoals();

  /// 10.13.2. Selected Feature Subset.
  @SerializationOrder(6)
  PrototypeFeatureSubset featureSubset = PrototypeFeatureSubset();

  /// 10.13.3. Prototype Type.
  @SerializationOrder(7)
  PrototypeType prototypeType = PrototypeType();

  /// Prototype schedule.
  @ContentHelp('Detailed timeline for prototype development and evaluation.')
  @SerializationOrder(8)
  TextSection prototypeSchedule = TextSection();
}

/// Prototype timing commitments.
@SectionId('PRTI')
class PrototypeTimeline {
    @Form([
        Field('prototypeTimeline', String, 'Prototype Timeline',
                hint: 'Duration for prototype phase'),
        Field('prototypeDeadline', String, 'Prototype Deadline',
                hint: 'When prototype must be ready'),
        Field('evaluationPeriod', String, 'Evaluation Period',
                hint: 'How long for evaluation'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Prototype staffing and environment.
@SectionId('PRORES')
class PrototypeResources {
    @Form([
        Field('prototypeTeam', String, 'Prototype Team',
                hint: 'Who builds the prototype'),
        Field('prototypeBudget', String, 'Prototype Budget',
                hint: 'Budget allocation'),
        Field('prototypeEnvironment', String, 'Prototype Environment',
                hint: 'Where prototype is deployed'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Approval and progression criteria.
@SectionId('PRGO')
class PrototypeGovernance {
    @Form([
        Field('acceptanceCriteria', String, 'Acceptance Criteria',
                hint: 'Required criteria to proceed'),
        Field('stakeholderSignoff', String, 'Stakeholder Signoff',
                hint: 'Who must approve prototype'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 10.13.1. Prototype Goals.
///
/// What the prototype should validate.
@SectionId('PG')
class PrototypeGoals {
  @Form([
    // Validation goals
    Field('usabilityValidation', bool, 'Usability Validation',
        hint: 'Validate usability of key workflows'),
    Field('stakeholderAlignment', bool, 'Stakeholder Alignment',
        hint: 'Align stakeholders on UI/UX'),
    Field('technicalFeasibility', bool, 'Technical Feasibility',
        hint: 'Prove technical approach works'),
    Field('performanceValidation', bool, 'Performance Validation',
        hint: 'Validate performance targets'),
    Field('integrationValidation', bool, 'Integration Validation',
        hint: 'Validate third-party integrations'),
  ])
  @SerializationOrder(0)
  String? goalsContent;

  /// Risk reduction and assumption testing.
  @SerializationOrder(1)
  PrototypeGoalsRisk riskProfile = PrototypeGoalsRisk();

  /// User feedback objectives and intake.
  @SerializationOrder(2)
  PrototypeGoalsFeedback feedbackProfile = PrototypeGoalsFeedback();

  /// Prototype goals narrative.
  @SerializationOrder(3)
  TextSection goalsNarrative = TextSection();

  /// Individual goal entries.
  @SectionId('PRGOEN-GOAL-LST')
  @SectionIdPattern('PRGOEN-GOAL-xxx')
  @SerializationOrder(4)
  List<PrototypeGoalEntry> goals = [];
}

/// Risk reduction and assumption testing.
@SectionId('PRGORI')
class PrototypeGoalsRisk {
    @Form([
        Field('riskMitigation', String, 'Risk Mitigation',
                hint: 'Risks the prototype addresses'),
        Field('unknownsResolution', String, 'Unknowns Resolution',
                hint: 'Unknowns to be resolved'),
        Field('assumptionsTesting', String, 'Assumptions Testing',
                hint: 'Assumptions to be tested'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// User feedback objectives and intake.
@SectionId('PRGOFE')
class PrototypeGoalsFeedback {
    @Form([
        Field('userFeedbackGoals', String, 'User Feedback Goals',
                hint: 'What feedback to gather'),
        Field('usabilityTestingPlan', String, 'Usability Testing Plan',
                hint: 'How usability testing is done'),
        Field('feedbackIntegration', String, 'Feedback Integration',
                hint: 'How feedback flows back'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A prototype goal entry.
@SectionId('PGE')
class PrototypeGoalEntry {
  @Form([
    Field('goalId', String, 'Goal ID', required: true),
    Field('goalDescription', String, 'Goal Description', required: true),
    Field('goalCategory', String, 'Goal Category',
        hint: 'Usability, technical, business'),
    Field('validationMethod', String, 'Validation Method',
        hint: 'How goal is validated'),
    Field('successMetric', String, 'Success Metric',
        hint: 'How success is measured'),
    Field('priority', String, 'Priority',
        hint: 'Must-have, should-have, nice-to-have'),
    Field('relatedRisks', String, 'Related Risks',
        hint: 'Risks this goal addresses'),
    Field('stakeholders', String, 'Stakeholders',
        hint: 'Stakeholders interested in this goal'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 10.13.2. Selected Feature Subset.
///
/// Features included in the prototype.
@SectionId('PRFESU')
class PrototypeFeatureSubset {
  @Form([
    // Selection criteria
    Field('selectionCriteria', String, 'Selection Criteria',
        hint: 'How features were selected'),
    Field('riskBasedSelection', String, 'Risk-Based Selection',
        hint: 'High-risk features included'),
    Field('valueBasedSelection', String, 'Value-Based Selection',
        hint: 'High-value features included'),
    Field('uncertaintyBasedSelection', String, 'Uncertainty-Based Selection',
        hint: 'Most uncertain features included'),
  ])
  @SerializationOrder(0)
  String? featureSubsetContent;

  /// Included and excluded feature scope.
  @SerializationOrder(1)
  PrototypeFeatureSubsetScope scope = PrototypeFeatureSubsetScope();

  /// Fidelity expectations for the prototype.
  @SerializationOrder(2)
  PrototypeFeatureSubsetFidelity fidelity =
      PrototypeFeatureSubsetFidelity();

  /// Feature subset narrative.
  @SerializationOrder(3)
  TextSection featureNarrative = TextSection();

  /// Prototype feature entries.
  @SectionId('PRFEEN-FEAT-LST')
  @SectionIdPattern('PRFEEN-FEAT-xxx')
  @SerializationOrder(4)
  List<PrototypeFeatureEntry> features = [];
}

/// Included and excluded feature scope.
@SectionId('PFSS')
class PrototypeFeatureSubsetScope {
    @Form([
        Field('includedFeatures', String, 'Included Features',
                hint: 'Features in prototype'),
        Field('excludedFeatures', String, 'Excluded Features',
                hint: 'Features not in prototype'),
        Field('partialFeatures', String, 'Partial Features',
                hint: 'Features partially implemented'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Fidelity expectations for the prototype.
@SectionId('PFSF')
class PrototypeFeatureSubsetFidelity {
    @Form([
        Field('prototypeFidelity', String, 'Prototype Fidelity',
                hint: 'Low, medium, high fidelity'),
        Field('interactiveFidelity', String, 'Interactive Fidelity',
                hint: 'Level of interactivity'),
        Field('dataFidelity', String, 'Data Fidelity',
                hint: 'Real vs. mock data'),
        Field('visualFidelity', String, 'Visual Fidelity',
                hint: 'Production visuals vs. wireframes'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// A prototype feature entry.
@SectionId('PFE')
class PrototypeFeatureEntry {
  @Form([
    Field('featureId', String, 'Feature ID', required: true),
    Field('featureName', String, 'Feature Name', required: true),
    Field('inclusionReason', String, 'Inclusion Reason',
        hint: 'Why this feature is included'),
    Field('fidelityLevel', String, 'Fidelity Level',
        hint: 'Low, medium, high'),
    Field('completenessLevel', String, 'Completeness Level',
        hint: 'Full, partial, stub'),
    Field('relatedGoals', String, 'Related Goals',
        hint: 'Prototype goals this addresses'),
    Field('implementationNotes', String, 'Implementation Notes'),
    Field('knownLimitations', String, 'Known Limitations'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// 10.13.3. Prototype Type.
///
/// Classification and implications of the prototype type.
@SectionId('PRTYSE')
class PrototypeType {
  @Form([
    Field('prototypeType', String, 'Prototype Type', required: true,
        hint: 'Reusable, Training, Throwaway'),
    Field('typeRationale', String, 'Type Rationale',
        hint: 'Why this type was chosen'),
    Field('typeImplications', String, 'Type Implications',
        hint: 'Implications for development'),
    Field('codeQualityExpectation', String, 'Code Quality Expectation',
        hint: 'Production, demo, quick-and-dirty'),
    Field('documentationRequirement', String, 'Documentation Requirement',
        hint: 'Documentation needed'),
    Field('transitionPlan', String, 'Transition Plan',
        hint: 'How prototype transitions'),
  ])
  @SerializationOrder(0)
  String? prototypeTypeOverview;

  /// 10.13.3.1. Reusable Prototype.
  @SerializationOrder(1)
  ReusablePrototype reusablePrototype = ReusablePrototype();

  /// 10.13.3.2. Training Prototype.
  @SerializationOrder(2)
  TrainingPrototype trainingPrototype = TrainingPrototype();

  /// 10.13.3.3. Throwaway Prototype.
  @SerializationOrder(3)
  ThrowawayPrototype throwawayPrototype = ThrowawayPrototype();
}

/// 10.13.3.1. Reusable Prototype.
///
/// Prototype that becomes part of the final product.
@SectionId('REUPRO')
class ReusablePrototype {
  @Form([
    Field('codeQualityRequirements', String, 'Code Quality Requirements',
        hint: 'Standards prototype code must meet'),
    Field('testCoverageRequirement', String, 'Test Coverage Requirement',
        hint: 'Required test coverage'),
    Field('codeReviewRequired', bool, 'Code Review Required'),
    Field('documentationRequired', bool, 'Documentation Required'),
  ])
  @SerializationOrder(0)
  String? reusableContent;

  /// Architecture alignment and refactoring expectations.
  @SerializationOrder(1)
  ReusablePrototypeArchitecture architecture =
      ReusablePrototypeArchitecture();

  /// Integration and merge strategy.
  @SerializationOrder(2)
  ReusablePrototypeIntegration integration =
      ReusablePrototypeIntegration();

  /// Transition and handoff planning.
  @SerializationOrder(3)
  ReusablePrototypeTransition transition = ReusablePrototypeTransition();

  /// Reusable prototype narrative.
  @SerializationOrder(4)
  TextSection reusableNarrative = TextSection();
}

/// Architecture alignment and refactoring expectations.
@SectionId('REPRAR')
class ReusablePrototypeArchitecture {
    @Form([
        Field('architectureAlignment', String, 'Architecture Alignment',
                hint: 'How prototype aligns with target architecture'),
        Field('refactoringPlan', String, 'Refactoring Plan',
                hint: 'Planned refactoring after prototype'),
        Field('technicalDebt', String, 'Technical Debt',
                hint: 'Acceptable technical debt'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Integration and merge strategy.
@SectionId('REPRIN')
class ReusablePrototypeIntegration {
    @Form([
        Field('integrationPlan', String, 'Integration Plan',
                hint: 'How prototype integrates into product'),
        Field('featureBranchStrategy', String, 'Feature Branch Strategy',
                hint: 'Git branching approach'),
        Field('mergeCriteria', String, 'Merge Criteria',
                hint: 'Criteria to merge prototype code'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Transition and handoff planning.
@SectionId('REPRTR')
class ReusablePrototypeTransition {
    @Form([
        Field('transitionTimeline', String, 'Transition Timeline'),
        Field('teamHandoff', String, 'Team Handoff',
                hint: 'Handoff to development team'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 10.13.3.2. Training Prototype.
///
/// Prototype where concepts are reused but not code.
@SectionId('TP')
class TrainingPrototype {
  @Form([
    // Knowledge transfer
    Field('designDecisionsCarriedForward', String, 'Design Decisions Carried Forward',
        hint: 'What design decisions are preserved'),
    Field('patternsDocumented', String, 'Patterns Documented',
        hint: 'Patterns documented from prototype'),
    Field('lessonsLearned', String, 'Lessons Learned',
        hint: 'What was learned'),
  ])
  @SerializationOrder(0)
  String? trainingContent;

  /// Code disposition and reimplementation planning.
  @SerializationOrder(1)
  TrainingPrototypeDisposition disposition = TrainingPrototypeDisposition();

  /// Documentation outputs and team learning.
  @SerializationOrder(2)
  TrainingPrototypeOutputs outputs = TrainingPrototypeOutputs();

  /// Training prototype narrative.
  @SerializationOrder(3)
  TextSection trainingNarrative = TextSection();
}

/// Code disposition and reimplementation planning.
@SectionId('TRPRDI')
class TrainingPrototypeDisposition {
    @Form([
        Field('codeDisposition', String, 'Code Disposition',
                hint: 'What happens to prototype code'),
        Field('reimplementationPlan', String, 'Reimplementation Plan',
                hint: 'Plan for reimplementing features'),
        Field('reimplementationEstimate', String, 'Reimplementation Estimate',
                hint: 'Effort to reimplement'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Documentation outputs and team learning.
@SectionId('TRPROU')
class TrainingPrototypeOutputs {
    @Form([
        Field('documentationProduced', String, 'Documentation Produced',
                hint: 'Documentation from prototype'),
        Field('designSystemOutput', String, 'Design System Output',
                hint: 'Design system artifacts'),
        Field('componentSpecifications', String, 'Component Specifications',
                hint: 'Component specs from prototype'),
        Field('teamSkillsGained', String, 'Team Skills Gained',
                hint: 'Skills team gained'),
        Field('technologyInsights', String, 'Technology Insights',
                hint: 'Technology insights gained'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// 10.13.3.3. Throwaway Prototype.
///
/// Prototype evaluated and then discarded.
@SectionId('THPR')
class ThrowawayPrototype {
  @Form([
    Field('evaluationCriteria', String, 'Evaluation Criteria',
        hint: 'Criteria for evaluation'),
    Field('evaluationMethod', String, 'Evaluation Method',
        hint: 'How prototype is evaluated'),
    Field('evaluationParticipants', String, 'Evaluation Participants',
        hint: 'Who participates in evaluation'),
    Field('evaluationTimeline', String, 'Evaluation Timeline'),
  ])
  @SerializationOrder(0)
  String? throwawayContent;

  /// Findings and decisions captured from evaluation.
  @SerializationOrder(1)
  ThrowawayPrototypeFindings findings = ThrowawayPrototypeFindings();

  /// Disposal and follow-up handling.
  @SerializationOrder(2)
  ThrowawayPrototypeDisposition disposition = ThrowawayPrototypeDisposition();

  /// Long-term value retained from the prototype.
  @SerializationOrder(3)
  ThrowawayPrototypeValue value = ThrowawayPrototypeValue();

  /// Throwaway prototype narrative.
  @SerializationOrder(4)
  TextSection throwawayNarrative = TextSection();
}

/// Findings and decisions captured from evaluation.
@SectionId('THPRFI')
class ThrowawayPrototypeFindings {
    @Form([
        Field('findingsDocumentation', String, 'Findings Documentation',
                hint: 'How findings are documented'),
        Field('recommendationsOutput', String, 'Recommendations Output',
                hint: 'Recommendations produced'),
        Field('decisionsMade', String, 'Decisions Made',
                hint: 'Decisions made based on prototype'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Disposal and follow-up handling.
@SectionId('THPRDI')
class ThrowawayPrototypeDisposition {
    @Form([
        Field('disposalPlan', String, 'Disposal Plan',
                hint: 'How prototype is disposed'),
        Field('archivingApproach', String, 'Archiving Approach',
                hint: 'Whether/how prototype is archived'),
        Field('nextSteps', String, 'Next Steps',
                hint: 'What happens after evaluation'),
    ])
    @SerializationOrder(0)
    String? content;
}

/// Long-term value retained from the prototype.
@SectionId('THPRVA')
class ThrowawayPrototypeValue {
    @Form([
        Field('insightsCaptured', String, 'Insights Captured',
                hint: 'Key insights from prototype'),
        Field('futureReference', String, 'Future Reference',
                hint: 'What to preserve for future'),
    ])
    @SerializationOrder(0)
    String? content;
}

// ---------------------------------------------------------------------------
// 10.14 Wireframes and Mockups
// ---------------------------------------------------------------------------

/// 10.14. Wireframes and Mockups.
///
/// Wireframe and mockup inventory beyond individual screen descriptions.
///.
@SectionId('WIANMO')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@SecondLevelSectionId(D09ExperienceDesignSpecification, 'XDS-WIR')
class WireframesAndMockups {
  @ContentHelp('''
Catalog of wireframes and mockups across the UI. Complements the
per-screen content in the screen-design section with cross-cutting,
comparison, and narrative-flow views.

**What to capture:**
- Wireframe catalog (name, fidelity level, screen coverage)
- Mockup catalog (static / interactive / click-through)
- Fidelity progression (sketch → wireframe → mockup → prototype)
- Tooling conventions (Figma / Sketch / etc., file naming)
- Storyboard / user-journey visuals
- Review and sign-off status per artifact
''')
  @SerializationOrder(0)
  String? content;
}

/// A single design foundation entry.
@SectionId('DESIG')
class DesignFoundationEntry {
  @Form([
    Field('primaryColor', String, 'Primary Color',
        hint: 'Primary brand color (hex or semantic name)'),
    Field('fontFamilyPrimary', String, 'Primary Font Family'),
    Field('spacingScale', String, 'Spacing Scale',
        hint: '4px base, 8px base, custom scale'),
  ])
  @SerializationOrder(0)
  String? content;
}

/// A single recovery flow entry.
@SectionId('RECOV')
class RecoveryFlowEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single global entry point entry.
@SectionId('GLOBA')
class GlobalEntryPointEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single error page design entry.
@SectionId('EPDE')
class ErrorPageDesignEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}

/// A single field validation rule entry.
@SectionId('FIELD')
class FieldValidationRuleEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  @SerializationOrder(0)
  String? content;
}
