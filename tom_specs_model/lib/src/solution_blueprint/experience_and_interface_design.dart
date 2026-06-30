/// Section 10: Experience & Interface Design.
///
/// Seeds → XDS, TRP, ATS depending on subsection.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';



/// 10. Experience & Interface Design. Seeds → XDS.
@SectionId('UIDI')
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
  String? content;

  /// 10.1. Design Vision. Seeds → XDS.
  DesignVision designVision = DesignVision();

  /// 10.2. Screen Descriptions. Seeds → XDS.
  ScreenDescriptions screens = ScreenDescriptions();

  /// 10.3. Screen Flow Structure. Seeds → XDS.
  ScreenFlowStructure screenFlow = ScreenFlowStructure();

  /// 10.4. Print Layout. Seeds → XDS.
  PrintAndExportLayout printLayout = PrintAndExportLayout();

  /// Data Structure Alignment.
  TextSection dataStructureAlignment = TextSection();

  /// Authorization Compliance.
  TextSection authorizationCompliance = TextSection();

  /// 10.7. Error Handling. Seeds → XDS.
  ErrorHandling errorHandling = ErrorHandling();

  /// 10.8. User Assistance. Seeds → XDS.
  UserAssistance userAssistance = UserAssistance();

  /// 10.9. Accessibility. Seeds → XDS.
  Accessibility accessibility = Accessibility();

  /// 10.10. Responsive Design. Seeds → XDS.
  ResponsiveDesign responsiveDesign = ResponsiveDesign();

  /// 10.11. UI Components. Seeds → XDS.
  UiComponents uiComponents = UiComponents();

  /// 10.12. Multi-language Support.
  MultiLanguageSupport multiLanguageSupport = MultiLanguageSupport();

  /// 10.13. Prototype. Seeds → XDS.
  Prototype prototype = Prototype();

  /// 10.14. Wireframes and Mockups..
  @SectionId('WIANMO-WIRE-LST')
  @SectionIdPattern('WIANMO-WIRE-xxx')
  List<WireframesAndMockups> wireframesAndMockups = [];
}

// ---------------------------------------------------------------------------
// 10.1 Design Vision
// ---------------------------------------------------------------------------

/// 10.1. Design Vision.
///
/// Overall design vision for the user interface, encompassing goals,
/// principles, and user personas that guide all UI decisions.
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
  String? content;

  /// 10.1.1. Design Goals.
  DesignGoals designGoals = DesignGoals();

  /// 10.1.2. Design Principles.
  DesignPrinciples designPrinciples = DesignPrinciples();

  /// 10.1.3. User Personas.
  UserPersonas personas = UserPersonas();
}

// ---------------------------------------------------------------------------
// 10.1.1 Design Goals
// ---------------------------------------------------------------------------

/// 10.1.1. Design Goals.
///
/// Primary design objectives that the UI must achieve: simplicity, efficiency,
/// accessibility, consistency, delight. Goals are prioritized for the project.
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
  String? content;

  /// Overview of the design goal framework and prioritization approach.
  TextSection overview = TextSection();

  /// Contains 0+× DesignGoal.
  @SectionId('DGOEN-ITEM-LST')
  @SectionIdPattern('DGOEN-ITEM-xxx')
  List<DesignGoalEntry> items = [];
}

/// A design goal entry (form).
///
/// Each goal represents a measurable UI objective with success criteria.
@SectionId('DGOEN')
class DesignGoalEntry {
  @Form([
    Field('goalName', String, 'Goal Name', required: true),
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
  String? content;
}

// ---------------------------------------------------------------------------
// 10.1.2 Design Principles
// ---------------------------------------------------------------------------

/// 10.1.2. Design Principles.
///
/// Guiding principles for all UI decisions: progressive disclosure, direct
/// manipulation, feedback, consistency, error prevention.
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
  String? content;

  /// Overview of the design principle framework.
  TextSection overview = TextSection();

  /// Contains 0+× UiDesignPrinciple.
  @SectionId('UDPEN-ITEM-LST')
  @SectionIdPattern('UDPEN-ITEM-xxx')
  List<DesignPrincipleEntry> items = [];
}

/// A design principle entry (form).
///
/// Each principle guides UI decisions with rationale and examples.
@SectionId('UDPEN')
class DesignPrincipleEntry {
  @Form([
    Field('principleName', String, 'Principle Name', required: true),
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
  String? content;
}

// ---------------------------------------------------------------------------
// 10.1.3 User Personas
// ---------------------------------------------------------------------------

/// 10.1.3. User Personas.
///
/// Container for user persona definitions. Each persona represents a distinct
/// user archetype with goals, pain points, and context.
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
  String? content;

  /// Overview of persona research methodology and usage.
  TextSection overview = TextSection();

  /// Contains 1+× Persona.
  @SectionId('PEREN-ITEM-LST')
  @SectionIdPattern('PEREN-ITEM-xxx')
  @Min(1)
  List<PersonaEntry> items = [];
}

/// A user persona entry (form).
///
/// Represents a distinct user archetype with detailed context for UI design.
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
  String? content;

  /// Background and capability profile.
  PersonaEntryProfile profile = PersonaEntryProfile();

  /// Usage environment and device context.
  PersonaEntryContext context = PersonaEntryContext();

  /// Motivations, frustrations, and success markers.
  PersonaEntryNeeds needs = PersonaEntryNeeds();

  /// 10.1.3.n.1. Persona Goals.
  PersonaGoals goals = PersonaGoals();

  /// 10.1.3.n.2. Persona Pain Points.
  PersonaPainPoints painPoints = PersonaPainPoints();

  /// 10.1.3.n.3. Persona Scenarios.
  PersonaScenarios scenarios = PersonaScenarios();
}

/// Background and capability profile.
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
    String? content;
}

/// Usage environment and device context.
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
    String? content;
}

/// Motivations, frustrations, and success markers.
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
    String? content;
}

/// 10.1.3.n.1. Persona Goals.
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
  String? content;

  /// Contains 0+× PersonaGoal.
  @SectionId('PGOEN-ITEM-LST')
  @SectionIdPattern('PGOEN-ITEM-xxx')
  List<PersonaGoalEntry> items = [];
}

/// A persona goal entry (form).
@SectionId('PGOEN')
class PersonaGoalEntry {
  @Form([
    Field('goal', String, 'Goal', required: true),
    Field('priority', String, 'Priority',
        hint: 'Critical/High/Medium/Low'),
    Field('frequency', String, 'Frequency',
        hint: 'How often this goal arises'),
    Field('currentApproach', String, 'Current Approach',
        hint: 'How they achieve this today'),
    Field('desiredOutcome', String, 'Desired Outcome',
        hint: 'What success looks like'),
  ])
  String? content;
}

/// 10.1.3.n.2. Persona Pain Points.
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
  String? content;

  /// Contains 0+× PersonaPainPoint.
  @SectionId('PPPEN-ITEM-LST')
  @SectionIdPattern('PPPEN-ITEM-xxx')
  List<PersonaPainPointEntry> items = [];
}

/// A pain point entry (form).
@SectionId('PPPEN')
class PersonaPainPointEntry {
  @Form([
    Field('painPoint', String, 'Pain Point', required: true),
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
  String? content;
}

/// 10.1.3.n.3. Persona Scenarios.
///
/// Key usage scenarios for this persona — helps map personas to screens/flows.
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
  String? content;

  /// Contains 0+× PersonaScenario.
  @SectionId('PSCEN-ITEM-LST')
  @SectionIdPattern('PSCEN-ITEM-xxx')
  List<PersonaScenarioEntry> items = [];
}

/// A persona scenario entry (form).
@SectionId('PSCEN')
class PersonaScenarioEntry {
  @Form([
    Field('scenarioName', String, 'Scenario Name', required: true),
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
  String? content;
}

// ---------------------------------------------------------------------------
// 10.2 Screen Descriptions
// ---------------------------------------------------------------------------

/// 10.2. Screen Descriptions.
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
  String? content;

  /// 10.2.1. Screen Inventory.
  ScreenInventory screenInventory = ScreenInventory();

  /// 10.2.2. Information Architecture.
  InformationArchitecture informationArchitecture = InformationArchitecture();
}

// ---------------------------------------------------------------------------
// 10.2.1 Screen Inventory
// ---------------------------------------------------------------------------

/// 10.2.1. Screen Inventory.
///
/// Container for screen definitions. Each entry fully describes one application
/// screen including its purpose, layout zones, elements, actions, and states.
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
  String? content;

  /// Overview of the screen inventory structure and conventions.
  TextSection overview = TextSection();

  /// Contains 1+× Screen.
  @SectionId('SCREN-ITEM-LST')
  @SectionIdPattern('SCREN-ITEM-xxx')
  @Min(1)
  List<ScreenEntry> items = [];
}

/// A screen entry (form).
///
/// Comprehensive specification of a single application screen, covering
/// identity, purpose, authorization, layout, elements, and behavior.
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
  String? content;

  /// Classification and routing metadata.
  ScreenEntryClassification classification = ScreenEntryClassification();

  /// Access control settings.
  ScreenEntryAccess access = ScreenEntryAccess();

  /// Traceability metadata.
  ScreenEntryTraceability traceability = ScreenEntryTraceability();

  /// Presentation metadata.
  ScreenEntryPresentation presentation = ScreenEntryPresentation();

  /// Screen design rationale and notes.
  TextSection designNotes = TextSection();

  /// 10.2.1.n.1. Screen Sections.
  ScreenSections sections = ScreenSections();

  /// 10.2.1.n.2. Screen Actions.
  ScreenActions actions = ScreenActions();

  /// 10.2.1.n.3. Screen States.
  ScreenStates states = ScreenStates();

  /// Contains 0+× ScreenUserCategory.
  @SectionId('SCRUSC-USER-LST')
  @SectionIdPattern('SCRUSC-USER-xxx')
  List<ScreenUserCategoryEntry> userCategories = [];

  /// Contains 0+× EntryPoint.
  @SectionId('EPNT-ENTR-LST')
  @SectionIdPattern('EPNT-ENTR-xxx')
  List<EntryPointEntry> entryPoints = [];

  /// Contains 0+× ScreenResponsiveRule.
  @SectionId('SRRE-RESP-LST')
  @SectionIdPattern('SRRE-RESP-xxx')
  List<ScreenResponsiveRuleEntry> responsiveRules = [];
}

/// Classification and routing metadata.
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
  String? content;
}

/// Access control settings.
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
  String? content;
}

/// Traceability metadata.
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
  String? content;
}

/// Presentation metadata.
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
  String? content;
}

// ---------------------------------------------------------------------------
// 10.2.1.n.1 Screen Sections (Zones)
// ---------------------------------------------------------------------------

/// 10.2.1.n.1. Screen Sections.
///
/// Logical zones within a screen that group related elements.
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
  String? content;

  /// Contains 0+× ScreenSection.
  @SectionId('SCRSC-ITEM-LST')
  @SectionIdPattern('SCRSC-ITEM-xxx')
  List<ScreenSectionEntry> items = [];
}

/// A screen section entry (form).
///
/// A logical zone within a screen: header, toolbar, content area, sidebar, etc.
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
  String? content;

  /// Layout and ordering for the section.
  ScreenSectionEntryLayout layout = ScreenSectionEntryLayout();

  /// Visibility and collapse behavior.
  ScreenSectionEntryBehavior behavior = ScreenSectionEntryBehavior();

  /// Contains 0+× ScreenElement within this section.
  @SectionId('SCREL-ELEM-LST')
  @SectionIdPattern('SCREL-ELEM-xxx')
  List<ScreenElementEntry> elements = [];
}

/// Layout and ordering for the section.
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
    String? content;
}

/// Visibility and collapse behavior.
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
    String? content;
}

/// A screen element entry (form).
///
/// Any interactive or display element within a screen section: buttons, fields,
/// data displays, icons, labels, status indicators.
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
  String? content;

  /// Labels and icon resources.
  ScreenElementEntryResources resources = ScreenElementEntryResources();

  /// Placement and layout settings.
  ScreenElementEntryLayout layout = ScreenElementEntryLayout();

  /// Visibility and permission rules.
  ScreenElementEntryBehavior behavior = ScreenElementEntryBehavior();

  /// Styling and data binding.
  ScreenElementEntryPresentation presentation =
      ScreenElementEntryPresentation();

  /// 10.2.1.n.m.k.1. Element Action.
  ScreenElementAction? elementAction;

  /// 10.2.1.n.m.k.2. Element Field Spec.
  ScreenElementFieldSpec? fieldSpec;

  /// 10.2.1.n.m.k.3. Element Data Display.
  ScreenElementDataDisplay? dataDisplay;

  /// Contains 0+× ElementValidationRule.
  @SectionId('EVRE-VALI-LST')
  @SectionIdPattern('EVRE-VALI-xxx')
  List<ElementValidationRuleEntry> validationRules = [];
}

/// Labels and icon resources for screen element.
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
  String? content;
}

/// Placement and layout settings for screen element.
@SectionId('SEEL2')
class ScreenElementEntryLayout {
  @Form([
    Field('placementOrder', int, 'Placement Order',
        hint: 'Order within parent section'),
    Field('width', String, 'Width',
        hint: 'Fill/Auto/Fixed(200)/Proportion(1/3)'),
    Field('alignment', String, 'Alignment',
        hint: 'Start/Center/End/Stretch'),
  ])
  String? content;
}

/// Visibility and permission rules for screen element.
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
  String? content;
}

/// Styling and data binding for screen element.
@SectionId('SEEP1')
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
  String? content;
}

/// Action specification for an action-type element (form).
///
/// Defines button/link behavior: action reference, confirmation, navigation.
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
  String? content;

  /// Confirmation and execution feedback behavior.
  ScreenElementActionExecution execution = ScreenElementActionExecution();

  /// Post-action navigation rules.
  ScreenElementActionNavigation navigation = ScreenElementActionNavigation();
}

/// Confirmation and execution feedback behavior.
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
  String? content;
}

/// Post-action navigation rules.
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
  String? content;
}

/// Field specification for an input-type element (form).
///
/// Defines input behavior: data type, constraints, validation trigger, masks.
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
  String? content;

  /// Prefix, suffix, and formatting.
  ScreenElementFieldSpecFormatting formatting =
      ScreenElementFieldSpecFormatting();

  /// Length and value constraints.
  ScreenElementFieldSpecConstraints constraints =
      ScreenElementFieldSpecConstraints();

  /// Validation behavior.
  ScreenElementFieldSpecValidation validation =
      ScreenElementFieldSpecValidation();

  /// Selection and input assistance.
  ScreenElementFieldSpecSelection selection =
      ScreenElementFieldSpecSelection();
}

/// Prefix, suffix, and formatting for field spec.
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
  String? content;
}

/// Length and value constraints for field spec.
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
  String? content;
}

/// Validation behavior for field spec.
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
  String? content;
}

/// Selection and input assistance for field spec.
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
  String? content;
}

/// Data display specification for display-type elements (form).
///
/// Defines how data is presented: format, empty state, refresh, drill-down.
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
  String? content;

  /// Refresh and drill-down behavior.
  ScreenElementDataDisplayBehavior behavior =
      ScreenElementDataDisplayBehavior();

  /// Table/list interaction controls.
  ScreenElementDataDisplayOptions options = ScreenElementDataDisplayOptions();
}

/// Refresh and drill-down behavior.
@SectionId('SEDDB')
class ScreenElementDataDisplayBehavior {
  @Form([
    Field('refreshMode', String, 'Refresh Mode',
        hint: 'Auto/Manual/Interval(seconds)'),
    Field('drillDownTarget', String, 'Drill-Down Target',
        hint: 'Screen ID navigated to on click/tap'),
  ])
  String? content;
}

/// Table/list interaction controls.
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
  String? content;
}

/// A validation rule entry (form).
@SectionId('EVRE1')
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
  String? content;
}

// ---------------------------------------------------------------------------
// 10.2.1.n.2 Screen Actions
// ---------------------------------------------------------------------------

/// 10.2.1.n.2. Screen Actions.
///
/// Top-level actions available on the screen (toolbar, app bar, FAB).
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
  String? content;

  /// Contains 0+× ScreenAction.
  @SectionId('SCRAC-ITEM-LST')
  @SectionIdPattern('SCRAC-ITEM-xxx')
  List<ScreenActionEntry> items = [];
}

/// A screen action entry (form).
///
/// A top-level action available on the screen via toolbar, app bar, or FAB.
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
  String? content;

  /// Visual presentation of the action.
  ScreenActionEntryVisual visual = ScreenActionEntryVisual();

  /// Visibility, enablement, and permission rules.
  ScreenActionEntryConditions conditions = ScreenActionEntryConditions();

  /// Confirmation, navigation, and feedback behavior.
  ScreenActionEntryBehavior behavior = ScreenActionEntryBehavior();
}

/// Visual presentation of the action.
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
  String? content;
}

/// Visibility, enablement, and permission rules.
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
  String? content;
}

/// Confirmation, navigation, and feedback behavior.
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
  String? content;
}

// ---------------------------------------------------------------------------
// 10.2.1.n.3 Screen States
// ---------------------------------------------------------------------------

/// 10.2.1.n.3. Screen States.
///
/// Different visual/behavioral states the screen can be in.
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
  String? content;

  /// Contains 0+× ScreenState.
  @SectionId('SCRST-ITEM-LST')
  @SectionIdPattern('SCRST-ITEM-xxx')
  List<ScreenStateEntry> items = [];
}

/// A screen state entry (form).
///
/// A specific state the screen can be in: loading, empty, error, permission-denied.
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
  String? content;
}

/// A user category entry (form).
@SectionId('SUCE')
class ScreenUserCategoryEntry {
  @Form([
    Field('categoryName', String, 'Category Name', required: true),
    Field('description', String, 'Description',
        hint: 'What this user category sees/can do'),
    Field('contentVariations', String, 'Content Variations',
        hint: 'How screen content differs for this category'),
  ])
  String? content;
}

/// An entry point entry (form).
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
  String? content;
}

/// A responsive rule entry (form).
///
/// How the screen adapts at different breakpoints.
@SectionId('SRRE1')
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
@SectionId('INAR1')
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
  String? content;

  /// Site map overview.
  TextSection siteMap = TextSection();

  /// Content hierarchy description.
  TextSection contentHierarchy = TextSection();

  /// Navigation structure.
  TextSection navigationStructure = TextSection();

  /// Global entry points.
  @SectionId('GLOBA-GLOB-LST')
  @SectionIdPattern('GLOBA-GLOB-xxx')
  List<GlobalEntryPointEntry> globalEntryPoints = [];

  /// 10.2.2.5. Information Architecture Diagram.
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
  String? content;

  /// 10.3.1. Navigation Model.
  NavigationModel navigationModel = NavigationModel();

  /// 10.3.2. Screen Flow Diagram (mermaid-flow).
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
  String? content;

  /// 10.3.1.1. Navigation Overview.
  NavigationOverview overview = NavigationOverview();

  /// 10.3.1.2. Navigation Hierarchy.
  NavigationHierarchy hierarchy = NavigationHierarchy();

  /// 10.3.1.3. Primary Navigation.
  PrimaryNavigation primaryNavigation = PrimaryNavigation();

  /// 10.3.1.4. Secondary Navigation.
  SecondaryNavigation secondaryNavigation = SecondaryNavigation();

  /// 10.3.1.5. Utility Navigation.
  UtilityNavigation utilityNavigation = UtilityNavigation();

  /// 10.3.1.6. Contextual Navigation.
  ContextualNavigation contextualNavigation = ContextualNavigation();

  /// 10.3.1.7. Deep Linking.
  DeepLinking deepLinking = DeepLinking();

  /// 10.3.1.8. Navigation Guards.
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
  String? content;

  /// Design rationale and open questions.
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
  String? content;

  /// Overview of the navigation hierarchy structure.
  TextSection overview = TextSection();

  /// Contains 0+× NavigationGroup.
  @SectionId('NAVGRP-GROU-LST')
  @SectionIdPattern('NAVGRP-GROU-xxx')
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
  String? content;

  /// Display and expansion behavior.
  NavigationGroupEntryDisplay display = NavigationGroupEntryDisplay();

  /// Access-control settings.
  NavigationGroupEntryAccess access = NavigationGroupEntryAccess();

  /// Badge and hierarchy settings.
  NavigationGroupEntryStructure structure = NavigationGroupEntryStructure();

  /// Contains 0+× NavigationItem.
  @SectionId('NAVIIT-ITEM-LST')
  @SectionIdPattern('NAVIIT-ITEM-xxx')
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
  String? content;

  /// Display properties: icons, labels, descriptions.
  NavigationItemEntryDisplay display = NavigationItemEntryDisplay();

  /// Routing configuration.
  NavigationItemEntryRouting routing = NavigationItemEntryRouting();

  /// Access control settings.
  NavigationItemEntryAccess access = NavigationItemEntryAccess();

  /// Badge configuration.
  NavigationItemEntryBadge badge = NavigationItemEntryBadge();

  /// Interaction settings.
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
  String? content;

  /// Drawer and rail behavior.
  PrimaryNavigationDrawer drawer = PrimaryNavigationDrawer();

  /// Bottom navigation rules.
  PrimaryNavigationBottomNav bottomNav = PrimaryNavigationBottomNav();

  /// Sidebar sizing and selection behavior.
  PrimaryNavigationSidebar sidebar = PrimaryNavigationSidebar();

  /// Design notes and tradeoffs.
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
  String? content;

  /// Overview of secondary navigation patterns.
  TextSection overview = TextSection();

  /// Contains 0+× TabBarDefinition.
  @SectionId('TBDE-TABB-LST')
  @SectionIdPattern('TBDE-TABB-xxx')
  List<TabBarDefinitionEntry> tabBars = [];
}

/// A tab bar definition entry (form).
///
/// Defines a tab bar or segmented control on a specific screen.
@SectionId('TBDE1')
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
  String? content;

  /// Position and selection behavior.
  TabBarDefinitionEntryBehavior behavior = TabBarDefinitionEntryBehavior();

  /// Visibility and loading profile.
  TabBarDefinitionEntryLoading loading = TabBarDefinitionEntryLoading();

  /// Contains 1+× TabItem.
  @SectionId('TAITEN-TABS-LST')
  @SectionIdPattern('TAITEN-TABS-xxx')
  @Min(1)
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
  String? content;

  /// Contains 0+× UtilityNavigationItem.
  @SectionId('UNIE-ITEM-LST')
  @SectionIdPattern('UNIE-ITEM-xxx')
  List<UtilityNavigationItemEntry> items = [];
}

/// A utility navigation item entry (form).
///
/// A persistent utility element in the app bar: user avatar, notifications bell,
/// help icon, settings.
@SectionId('UNIE1')
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
  String? content;

  /// Ordering, rendering, and access rules.
  UtilityNavigationItemEntryDisplay display =
      UtilityNavigationItemEntryDisplay();

  /// Badge and interaction behavior.
  UtilityNavigationItemEntryBehavior behavior =
      UtilityNavigationItemEntryBehavior();

    /// Contains 0+× UtilityMenuItem.
    @SectionId('UMIE-MENU-LST')
    @SectionIdPattern('UMIE-MENU-xxx')
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
  String? content;
}

/// A utility menu item entry (form).
///
/// Entry in a utility popup/dropdown menu (e.g., user menu items).
@SectionId('UMIE1')
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
  String? content;

  /// Routing and action references.
  UtilityMenuItemEntryAction action = UtilityMenuItemEntryAction();

  /// Visibility and confirmation behavior.
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
  String? content;

  /// 10.3.1.6.1. Breadcrumb Configuration.
  BreadcrumbConfiguration breadcrumbs = BreadcrumbConfiguration();

  /// Back navigation behavior.
  TextSection backNavigation = TextSection();

  /// Related links behavior.
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
  String? content;

  /// Deep linking strategy overview.
  TextSection strategy = TextSection();

  /// Contains 0+× DeepLinkPattern.
  @SectionId('DELNPT-PATT-LST')
  @SectionIdPattern('DELNPT-PATT-xxx')
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
  String? content;

  /// Overview of navigation guard strategy.
  TextSection overview = TextSection();

  /// Contains 0+× NavigationGuard.
  @SectionId('NAVGRD-GUAR-LST')
  @SectionIdPattern('NAVGRD-GUAR-xxx')
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
  String? content;

  /// Covered routes and dialog resources.
  NavigationGuardEntryDialog dialog = NavigationGuardEntryDialog();

  /// Redirect routing and evaluation priority.
  NavigationGuardEntryRouting routing = NavigationGuardEntryRouting();
}

/// Covered routes and dialog resources.
@SectionId('NGED1')
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
  String? content;

  /// Page margins and setup.
  PrintLayoutPageSetup pageSetup = PrintLayoutPageSetup();

  /// Branding configuration.
  PrintLayoutBranding branding = PrintLayoutBranding();

  /// Watermark and confidentiality.
  PrintLayoutWatermark watermark = PrintLayoutWatermark();

  /// Header and footer settings.
  PrintLayoutHeaderFooter headerFooter = PrintLayoutHeaderFooter();

  /// Archive and batch settings.
  PrintLayoutArchive archive = PrintLayoutArchive();

  /// 10.4.1. Reports — contains 0+× Report.
  @SectionId('REEN-REPO-LST')
  @SectionIdPattern('REEN-REPO-xxx')
  List<ReportEntry> reports = [];

  /// 10.4.2. Export Formats — contains 0+× Export Format.
  @SectionId('EXFOEN-EXPO-LST')
  @SectionIdPattern('EXFOEN-EXPO-xxx')
  List<ExportFormatEntry> exportFormats = [];

  /// 10.4.3. Export Templates — contains 0+× Export
  /// Template.
  @SectionId('EXTEEN-EXPO-LST')
  @SectionIdPattern('EXTEEN-EXPO-xxx')
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
  String? content;
}

// ---------------------------------------------------------------------------
// 10.4.1 Reports
// ---------------------------------------------------------------------------

/// A report entry (form).
@SectionId('RE2')
class ReportEntry {
  @Form([
    Field('reportId', String, 'Report ID',
        hint: 'Unique identifier, e.g. RPT-001', required: true),
    Field('reportName', String, 'Report Name',
        hint: 'Human-readable report title', required: true),
    Field('reportType', String, 'Report Type',
        hint: 'Tabular / Summary / Dashboard / KPI-Card / Chart-Only / Mixed'),
  ])
  String? content;

  /// Identity and context.
  ReportIdentity identity = ReportIdentity();

  /// Data source configuration.
  ReportDataSource dataSource = ReportDataSource();

  /// Output format options.
  ReportFormat format = ReportFormat();

  /// Page layout settings.
  ReportLayout layout = ReportLayout();

  /// Header and footer templates.
  ReportHeaderFooter headerFooter = ReportHeaderFooter();

  /// Sorting and grouping.
  ReportGrouping grouping = ReportGrouping();

  /// Conditional formatting.
  ReportFormatting formatting = ReportFormatting();

  /// Interactivity and parameters.
  ReportInteractivity interactivity = ReportInteractivity();

  /// Pagination settings.
  ReportPagination pagination = ReportPagination();

  /// Security and access.
  ReportSecurity security = ReportSecurity();

  /// Lifecycle and archiving.
  ReportLifecycle lifecycle = ReportLifecycle();

  /// Contains 0+× Report Section.
  @SectionId('RESEE1-SECT-LST')
  @SectionIdPattern('RESEE1-SECT-xxx')
  List<ReportSectionEntry> sections = [];

  /// Contains 0+× Report Filter.
  @SectionId('REFIEN-FILT-LST')
  @SectionIdPattern('REFIEN-FILT-xxx')
  List<ReportFilterEntry> filters = [];

  /// Contains 0+× Report Schedule.
  @SectionId('RESCEN-SCHE-LST')
  @SectionIdPattern('RESCEN-SCHE-xxx')
  List<ReportScheduleEntry> schedules = [];

  /// Contains 0+× Report Distribution.
  @SectionId('REDIEN-DIST-LST')
  @SectionIdPattern('REDIEN-DIST-xxx')
  List<ReportDistributionEntry> distributions = [];

  /// Contains 0+× Recipient.
  @SectionId('REREEN-RECI-LST')
  @SectionIdPattern('REREEN-RECI-xxx')
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
  String? content;
}

/// Report conditional formatting.
@SectionId('REFO1')
class ReportFormatting {
  @Form([
    Field('conditionalFormatting', String, 'Conditional Formatting',
        hint: 'Description of conditional formatting rules'),
    Field('highlightRules', String, 'Highlight Rules',
        hint: 'Row/cell highlight rules, e.g. overdue items in red'),
  ])
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
  String? content;

  /// Data source configuration.
  ReportSectionData data = ReportSectionData();

  /// Layout and page settings.
  ReportSectionLayout layout = ReportSectionLayout();

  /// Sorting and grouping.
  ReportSectionSorting sorting = ReportSectionSorting();

  /// Aggregation and limits.
  ReportSectionAggregation aggregation = ReportSectionAggregation();

  /// Contains 0+× Report Column.
  @SectionId('RECOE1-COLU-LST')
  @SectionIdPattern('RECOE1-COLU-xxx')
  List<ReportColumnEntry> columns = [];

  /// Contains 0+× Report Chart.
  @SectionId('RECHEN-CHAR-LST')
  @SectionIdPattern('RECHEN-CHAR-xxx')
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
  String? content;
}

/// A column in a tabular report section
/// (form).
@SectionId('RCE1')
class ReportColumnEntry {
  @Form([
    Field('columnId', String, 'Column ID',
        hint: 'Unique within section, e.g. COL-01', required: true),
    Field('columnName', String, 'Column Name',
        hint: 'Internal field reference', required: true),
    Field('displayLabel', String, 'Display Label',
        hint: 'Column header text shown in report', required: true),
  ])
  String? content;

  /// Data source and type.
  ReportColumnDataSource dataSource = ReportColumnDataSource();

  /// Display formatting.
  ReportColumnFormatting formatting = ReportColumnFormatting();

  /// Aggregation settings.
  ReportColumnAggregation aggregation = ReportColumnAggregation();

  /// Interaction options.
  ReportColumnInteraction interaction = ReportColumnInteraction();

  /// Visibility and layout.
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
  String? content;
}

/// A chart/visualization in a report
/// (form).
@SectionId('RCE2')
class ReportChartEntry {
  @Form([
    Field('chartId', String, 'Chart ID',
        hint: 'Unique within section, e.g. CHT-01', required: true),
    Field('title', String, 'Title',
        hint: 'Chart title', required: true),
    Field('chartType', String, 'Chart Type',
        hint: 'Bar / Line / Pie / Donut / Scatter / Gauge / Heatmap'),
  ])
  String? content;

  /// Axes configuration.
  @SectionId('RECHAX-AXES-LST')
  @SectionIdPattern('RECHAX-AXES-xxx')
  List<ReportChartAxes> axes = [];

  /// Series and colors.
  ReportChartSeries series = ReportChartSeries();

  /// Display options.
  ReportChartDisplay display = ReportChartDisplay();

  /// Interaction.
  ReportChartInteraction interaction = ReportChartInteraction();

  /// Layout.
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
  String? content;

  /// Input and value configuration.
  ReportFilterEntryInput input = ReportFilterEntryInput();

  /// Scope and validation behavior.
  ReportFilterEntryBehavior behavior = ReportFilterEntryBehavior();

  /// Presentation options.
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
  String? content;
}

/// Scheduling rules for report generation
/// (form).
@SectionId('RSE1')
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
  String? content;

  /// Timing configuration.
  ReportScheduleEntryTiming timing = ReportScheduleEntryTiming();

  /// Retry configuration.
  ReportScheduleEntryRetry retry = ReportScheduleEntryRetry();

  /// Notification settings.
  ReportScheduleEntryNotifications notifications =
      ReportScheduleEntryNotifications();

  /// Output configuration.
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
  String? content;

  /// Recipient and format settings.
  ReportDistributionEntryRecipients recipients =
      ReportDistributionEntryRecipients();

  /// Message and attachment content.
  ReportDistributionEntryContent contentSettings =
      ReportDistributionEntryContent();

  /// Delivery conditions and lifecycle settings.
  ReportDistributionEntryDelivery delivery =
      ReportDistributionEntryDelivery();
}

/// Recipient and format settings for report distribution.
@SectionId('RDER2')
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
  String? content;
}

/// Message and attachment content for report distribution.
@SectionId('RDEC1')
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
  String? content;

  /// Recipient business context.
  ReportRecipientEntryContext context = ReportRecipientEntryContext();

  /// Delivery preferences.
  ReportRecipientEntryDelivery delivery = ReportRecipientEntryDelivery();

  /// Lifecycle settings.
  ReportRecipientEntryLifecycle lifecycle = ReportRecipientEntryLifecycle();
}

/// Recipient business context.
@SectionId('RREC1')
class ReportRecipientEntryContext {
  @Form([
    Field('role', String, 'Role',
        hint:
            'Business role of this recipient, e.g. Department Head, Controller'),
    Field('dataScopeRestriction', String, 'Data Scope Restriction',
        hint: 'Data visibility restriction, e.g. own-department-only'),
  ])
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
  String? content;

  /// Identity and data source.
  ExportIdentity identity = ExportIdentity();

  /// File format settings.
  ExportFileFormat fileFormat = ExportFileFormat();

  /// Delimiter and quoting.
  ExportDelimiter delimiter = ExportDelimiter();

  /// Data formatting.
  ExportDataFormat dataFormat = ExportDataFormat();

  /// Size and splitting.
  @SectionId('EXSISE-SIZE-LST')
  @SectionIdPattern('EXSISE-SIZE-xxx')
  List<ExportSizeSettings> sizeSettings = [];

  /// Security settings.
  ExportSecurity security = ExportSecurity();

  /// Output and scheduling.
  ExportOutput output = ExportOutput();

  /// Access and audit.
  ExportAccess access = ExportAccess();

  /// Contains 0+× Export Field Mapping.
  @SectionId('EFME-FIEL-LST')
  @SectionIdPattern('EFME-FIEL-xxx')
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
  String? content;
}

/// A field mapping within an export (form).
@SectionId('EFME1')
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
  String? content;

  /// Ordering and formatting settings.
  ExportFieldMappingEntryFormatting formatting =
      ExportFieldMappingEntryFormatting();

  /// Transformation rules.
  ExportFieldMappingEntryTransformation transformation =
      ExportFieldMappingEntryTransformation();

  /// Inclusion and defaults.
  ExportFieldMappingEntryInclusion inclusion =
      ExportFieldMappingEntryInclusion();

  /// Fixed-width and quoting rules.
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
  String? content;

  /// Format configuration.
  ExportTemplateEntryFormat format = ExportTemplateEntryFormat();

  /// Field and filter settings.
  ExportTemplateEntryFields fields = ExportTemplateEntryFields();

  /// Layout configuration.
  ExportTemplateEntryLayout layout = ExportTemplateEntryLayout();

  /// Access and metadata.
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
  String? content;
}

/// Field and filter settings for export template.
@SectionId('ETEF1')
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
  String? errorPhilosophyContent;

  /// Error categorization and display priority.
  ErrorHandlingClassification classification =
      ErrorHandlingClassification();

  /// Accessibility and inclusive error cues.
  ErrorHandlingAccessibility accessibility =
      ErrorHandlingAccessibility();

  /// Localization and analytics behavior.
  ErrorHandlingOperations operations =
      ErrorHandlingOperations();

  /// Error handling overview and strategy.
  @ContentHelp('Executive summary of error handling approach, '
      'key principles, and user experience goals.')
  TextSection errorHandlingOverview = TextSection();

  /// 10.7.1. Validation Feedback.
  ValidationFeedback validationFeedback = ValidationFeedback();

  /// 10.7.2. System Error Display.
  SystemErrorDisplay systemErrorDisplay = SystemErrorDisplay();

  /// 10.7.3. Error Recovery.
  ErrorRecovery errorRecovery = ErrorRecovery();

  /// Error message catalog.
  @ContentHelp('Centralized catalog of error message templates '
      'with consistent formatting and tone.')
  TextSection errorMessageCatalog = TextSection();

  /// Error state visual design.
  @ContentHelp('Visual design specifications for error states '
      'including colors, icons, animations.')
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
    String? content;
}

/// Accessibility and inclusive error cues.
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
  String? validationDisplayContent;

  /// Display placement details.
  ValidationFeedbackPlacement placement = ValidationFeedbackPlacement();

  /// Message formatting details.
  ValidationFeedbackMessages messages = ValidationFeedbackMessages();

  /// Guidance settings.
  ValidationFeedbackGuidance guidance = ValidationFeedbackGuidance();

  /// Animation and focus behavior.
  ValidationFeedbackBehavior behavior = ValidationFeedbackBehavior();

  /// Validation feedback narrative.
  @ContentHelp('Detailed specification of validation feedback behavior '
      'and user experience considerations.')
  TextSection validationNarrative = TextSection();

  /// Validation message templates.
  @SectionId('VAMETE-MESS-LST')
  @SectionIdPattern('VAMETE-MESS-xxx')
  List<ValidationMessageTemplate> messageTemplates = [];

  /// Field validation rules by type.
  @SectionId('FIELD-FIEL-LST')
  @SectionIdPattern('FIELD-FIEL-xxx')
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
  String? systemErrorContent;

  /// Error type handling configuration.
  SystemErrorDisplayErrorTypes errorTypes = SystemErrorDisplayErrorTypes();

  /// Display method settings.
  SystemErrorDisplayMethods displayMethods = SystemErrorDisplayMethods();

  /// Content options.
  SystemErrorDisplayContent displayContent = SystemErrorDisplayContent();

  /// Fallback behavior.
  SystemErrorDisplayFallback fallback = SystemErrorDisplayFallback();

  /// System error display narrative.
  @ContentHelp('Detailed specification of system error presentation '
      'and user communication approach.')
  TextSection systemErrorNarrative = TextSection();

  /// Error page designs.
  @SectionId('ERROR1-ERRO-LST')
  @SectionIdPattern('ERROR1-ERRO-xxx')
  List<ErrorPageDesignEntry> errorPageDesigns = [];

  /// Error codes catalog.
  @SectionId('SECE-ERRO-LST')
  @SectionIdPattern('SECE-ERRO-xxx')
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
  String? content;
}

/// A system error code entry.
@SectionId('SECE1')
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
  String? content;

  /// Recovery and display guidance.
  SystemErrorCodeEntryHandling handling = SystemErrorCodeEntryHandling();

  /// Operational support and logging controls.
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
  String? recoveryMechanismsContent;

  /// Data preservation: draft auto-save settings.
  ErrorRecoveryDataPreservation dataPreservation =
      ErrorRecoveryDataPreservation();

  /// Retry mechanisms configuration.
  ErrorRecoveryRetryMechanisms retryMechanisms =
      ErrorRecoveryRetryMechanisms();

  /// Guided recovery options.
  ErrorRecoveryGuidedRecovery guidedRecovery = ErrorRecoveryGuidedRecovery();

  /// Support contact details.
  ErrorRecoverySupportContact supportContact = ErrorRecoverySupportContact();

  /// Session handling configuration.
  ErrorRecoverySessionHandling sessionHandling =
      ErrorRecoverySessionHandling();

  /// Error recovery narrative.
  @ContentHelp('Detailed specification of error recovery flows '
      'and user empowerment strategies.')
  TextSection recoveryNarrative = TextSection();

  /// Recovery flow diagrams.
  @SectionId('RECOV-RECO-LST')
  @SectionIdPattern('RECOV-RECO-xxx')
  List<RecoveryFlowEntry> recoveryFlows = [];

  /// Common recovery scenarios.
  @SectionId('RCVSCN-RECO-LST')
  @SectionIdPattern('RCVSCN-RECO-xxx')
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
  String? content;

  /// Detailed recovery flow.
  @ContentHelp('Detailed recovery flow for this scenario.')
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
  String? helpOverviewContent;

  /// Content stewardship and help affordances.
  UserAssistanceDelivery delivery = UserAssistanceDelivery();

  /// Analytics and improvement feedback.
  UserAssistanceInsights insights = UserAssistanceInsights();

  /// Help system overview narrative.
  @ContentHelp('Executive summary of help system approach, '
      'content strategy, and user empowerment goals.')
  TextSection helpOverview = TextSection();

  /// 10.8.1. Contextual Help.
  ContextualHelp contextualHelp = ContextualHelp();

  /// 10.8.2. Onboarding.
  OnboardingHelp onboarding = OnboardingHelp();

  /// 10.8.3. Support Access.
  SupportAccess supportAccess = SupportAccess();

  /// Help content inventory.
  @ContentHelp('Inventory of all help content by feature area.')
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
  String? contextualHelpContent;

  /// Inline help behavior.
  ContextualHelpInline inline = ContextualHelpInline();

  /// Help panel behavior.
  ContextualHelpPanels panels = ContextualHelpPanels();

  /// What's-this mode settings.
  ContextualHelpWhatsThis whatsThis = ContextualHelpWhatsThis();

  /// Rich help media settings.
  ContextualHelpRich rich = ContextualHelpRich();

  /// Contextual help narrative.
  TextSection contextualHelpNarrative = TextSection();

  /// Field help catalog.
  @SectionId('FLDHP-FIEL-LST')
  @SectionIdPattern('FLDHP-FIEL-xxx')
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
  String? onboardingContent;

  /// Feature tour settings.
  OnboardingHelpTours tours = OnboardingHelpTours();

  /// Sample data settings.
  OnboardingHelpSampleData sampleData = OnboardingHelpSampleData();

  /// Getting started checklist configuration.
  OnboardingHelpChecklist checklist = OnboardingHelpChecklist();

  /// Progressive disclosure configuration.
  OnboardingHelpDisclosure disclosure = OnboardingHelpDisclosure();

  /// Returning user experience.
  OnboardingHelpReengagement reengagement = OnboardingHelpReengagement();

  /// Onboarding narrative.
  TextSection onboardingNarrative = TextSection();

  /// Feature tour definitions.
  @SectionId('FTRTUR-FEAT-LST')
  @SectionIdPattern('FTRTUR-FEAT-xxx')
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
  String? content;

  /// Tour steps.
  @SectionId('TURST-STEP-LST')
  @SectionIdPattern('TURST-STEP-xxx')
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
  String? supportAccessContent;

  /// Help center configuration.
  SupportAccessHelpCenter helpCenter = SupportAccessHelpCenter();

  /// Live support settings.
  SupportAccessLiveSupport liveSupport = SupportAccessLiveSupport();

  /// Ticket system configuration.
  SupportAccessTickets tickets = SupportAccessTickets();

  /// Contact methods.
  SupportAccessContactMethods contactMethods = SupportAccessContactMethods();

  /// Self-service and feedback options.
  SupportAccessSelfService selfService = SupportAccessSelfService();

  /// Support access narrative.
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
  String? accessibilityOverviewContent;

  /// Ownership and inclusive design philosophy.
  AccessibilityStrategy strategy = AccessibilityStrategy();

  /// Accessibility testing approach.
  AccessibilityTesting testing = AccessibilityTesting();

  /// Supported assistive technologies and platform features.
  AccessibilitySupport support = AccessibilitySupport();

  /// Accessibility overview narrative.
  @ContentHelp('Executive summary of accessibility approach, '
      'compliance targets, and inclusive design principles.')
  TextSection accessibilityOverview = TextSection();

  /// 10.9.1. WCAG Compliance Level.
  WcagCompliance wcagComplianceLevel = WcagCompliance();

  /// 10.9.2. Accessibility Checklist.
  AccessibilityChecklist accessibilityChecklist = AccessibilityChecklist();

  /// Keyboard navigation specification.
  @ContentHelp('Keyboard navigation patterns, focus management, '
      'and keyboard shortcuts.')
  TextSection keyboardNavigation = TextSection();

  /// Screen reader support specification.
  @ContentHelp('Screen reader support: ARIA labels, landmarks, '
      'live regions, and announcements.')
  TextSection screenReaderSupport = TextSection();

  /// Color and contrast specification.
  @ContentHelp('Color contrast requirements, color-blind-friendly '
      'design, and non-color indicators.')
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
  String? wcagComplianceContent;

  /// Operable principles.
  WcagComplianceOperable operable = WcagComplianceOperable();

  /// Understandable principles.
  WcagComplianceUnderstandable understandable =
      WcagComplianceUnderstandable();

  /// Robustness requirements.
  WcagComplianceRobust robust = WcagComplianceRobust();

  /// WCAG compliance narrative.
  TextSection wcagNarrative = TextSection();

  /// WCAG success criteria mapping.
  @SectionId('WSCE-SUCC-LST')
  @SectionIdPattern('WSCE-SUCC-xxx')
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
    String? content;
}

/// Robustness requirements.
@SectionId('WCCORO')
class WcagComplianceRobust {
    @Form([
        Field('compatible', String, 'Compatible (4.1)',
                hint: 'Parsing, name/role/value'),
    ])
    String? content;
}

/// A WCAG success criterion entry.
@SectionId('WSCE1')
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
  String? checklistOverviewContent;

  /// Accessibility checklist overview.
  TextSection checklistOverview = TextSection();

  /// Contains 0+× AccessibilityCheck.
  @SectionId('ACCH-ITEM-LST')
  @SectionIdPattern('ACCH-ITEM-xxx')
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
  String? content;

  /// WCAG mapping and compliance classification.
  AccessibilityCheckEntryCompliance compliance =
      AccessibilityCheckEntryCompliance();

  /// Testing execution ownership and status.
  AccessibilityCheckEntryExecution execution =
      AccessibilityCheckEntryExecution();

  /// Issue tracking and remediation details.
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
  String? responsiveOverview;

  /// Responsive design narrative.
  @ContentHelp('Overview of responsive design approach, '
      'key decisions, and implementation strategy.')
  TextSection responsiveNarrative = TextSection();

  /// 10.10.1. Breakpoints.
  BreakpointConfiguration breakpointConfig = BreakpointConfiguration();

  /// 10.10.2. Responsive Behavior.
  ResponsiveBehavior responsiveBehavior = ResponsiveBehavior();
}

/// 10.10.1. Breakpoints.
///
/// Breakpoint definitions for responsive layouts.
@SectionId('BRCO1')
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
  String? breakpointOverview;

  /// Breakpoint entries.
  @SectionId('BRE-BREA-LST')
  @SectionIdPattern('BRE-BREA-xxx')
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
  String? content;

  /// Grid and layout rules for this breakpoint.
  BreakpointEntryLayout layout = BreakpointEntryLayout();

  /// Navigation and visual scaling rules.
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
  String? layoutAdaptation;

  /// Navigation patterns per device class.
  ResponsiveBehaviorNavigation navigation = ResponsiveBehaviorNavigation();

  /// Visibility rules.
  ResponsiveBehaviorVisibility visibility = ResponsiveBehaviorVisibility();

  /// Touch and interaction optimizations.
  ResponsiveBehaviorTouch touch = ResponsiveBehaviorTouch();

  /// Content reflow rules.
  ResponsiveBehaviorContent content = ResponsiveBehaviorContent();

  /// Responsive behavior narrative.
  @ContentHelp('Detailed description of responsive behavior '
      'across all breakpoints and device types.')
  TextSection behaviorNarrative = TextSection();

  /// Screen-specific responsive rules.
  @SectionId('RESPSR-SCRE-LST')
  @SectionIdPattern('RESPSR-SCRE-xxx')
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
  String? componentLibraryOverview;

  /// Visual language and brand alignment.
  ComponentVisualLanguage visualLanguage = ComponentVisualLanguage();

  /// Component naming and documentation approach.
  ComponentApproach componentApproach =
      ComponentApproach();

  /// Extension and theming boundaries.
  ComponentCustomization customization = ComponentCustomization();

  /// 10.11.1. Component Library.
  ComponentLibrary componentLibrary = ComponentLibrary();

  /// 10.11.2. Component Specifications — contains 0+×.
  @SectionId('UICOEN-COMP-LST')
  @SectionIdPattern('UICOEN-COMP-xxx')
  List<UiComponentEntry> componentSpecs = [];

  /// 10.11.3. Component Families — contains 0+×.
  @SectionId('CMFA-COMP-LST')
  @SectionIdPattern('CMFA-COMP-xxx')
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
    String? content;
}

/// 10.11.1. Component Library.
///
/// Design system and component catalog specification.
@SectionId('COLI')
class ComponentLibrary {
  @SectionId('DESIG-DESI-LST')
  @SectionIdPattern('DESIG-DESI-xxx')
  List<DesignFoundationEntry> designFoundations = [];

  /// Color system.
  ComponentLibraryColors colors = ComponentLibraryColors();

  /// Typography system.
  ComponentLibraryTypography typography = ComponentLibraryTypography();

  /// Spacing and elevation.
  ComponentLibrarySpacing spacing = ComponentLibrarySpacing();

  /// Borders and corners.
  ComponentLibraryBorders borders = ComponentLibraryBorders();

  /// Icons and animation.
  ComponentLibraryVisuals visuals = ComponentLibraryVisuals();

  /// Design system narrative.
  @ContentHelp('Comprehensive description of the design system foundations, '
      'visual language, and component philosophy.')
  TextSection designSystemNarrative = TextSection();

  /// Design token catalog.
  @ContentHelp('Catalog of all design tokens: colors, typography, spacing, '
      'elevation, borders, and animation values.')
  TextSection designTokenCatalog = TextSection();

  /// Color palette specification.
  @SectionId('COPA-COLO-LST')
  @SectionIdPattern('COPA-COLO-xxx')
  List<ColorPaletteEntry> colorPalettes = [];

  /// Typography styles.
  @SectionId('TYST-TYPO-LST')
  @SectionIdPattern('TYST-TYPO-xxx')
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
  String? content;

  /// Family narrative.
  TextSection familyNarrative = TextSection();

  /// Components in this family.
  @SectionId('FAMREF-COMP-LST')
  @SectionIdPattern('FAMREF-COMP-xxx')
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
  String? content;
}

/// A UI component entry.
///
/// Comprehensive specification for a single UI component covering identity,
/// visual design, behavior, states, responsiveness, accessibility,
/// authorization, and data binding.
@SectionId('UCE1')
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
  String? identity;

  /// Wrapper mapping and business purpose.
  UiComponentEntryPurpose purposeProfile = UiComponentEntryPurpose();

  /// Classification details.
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
  String? visualDesign;

  /// Visual dimensions.
  UiComponentEntryDimensions dimensions = UiComponentEntryDimensions();

  /// Spacing rules.
  UiComponentEntrySpacing spacing = UiComponentEntrySpacing();

  /// Surface treatment.
  UiComponentEntrySurface surface = UiComponentEntrySurface();

  /// Visual design diagram.
  @ContentHelp('Visual diagram or mockup of the component.')
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
  String? interactiveBehavior;

  /// Focus and keyboard behavior.
  UiComponentEntryInputBehavior inputBehavior = UiComponentEntryInputBehavior();

  /// Animation behavior.
  UiComponentEntryAnimation animation = UiComponentEntryAnimation();

  /// Scrolling behavior.
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
  String? dataBinding;

  /// Component behavior narrative.
  @ContentHelp('Detailed description of component behavior, '
      'user interactions, and edge cases.')
  TextSection behaviorNarrative = TextSection();

  /// Contains 0+× ComponentState.
  @SectionId('CMST-STAT-LST')
  @SectionIdPattern('CMST-STAT-xxx')
  List<ComponentStateEntry> states = [];

  /// Contains 0+× ComponentVariant.
  @SectionId('CMVN-VARI-LST')
  @SectionIdPattern('CMVN-VARI-xxx')
  List<ComponentVariantEntry> variants = [];

  /// Contains 0+× ComponentAction.
  @SectionId('CMAC-ACTI-LST')
  @SectionIdPattern('CMAC-ACTI-xxx')
  List<ComponentActionEntry> actions = [];

  /// Contains 0+× ComponentSlot.
  @SectionId('CMSL-SLOT-LST')
  @SectionIdPattern('CMSL-SLOT-xxx')
  List<ComponentSlotEntry> slots = [];

  /// Contains 0+× ComponentProperty.
  @SectionId('CMPR-PROP-LST')
  @SectionIdPattern('CMPR-PROP-xxx')
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
    String? content;
}

/// Surface treatment.
@SectionId('UCES1')
class UiComponentEntrySurface {
    @Form([
        Field('borderStyle', String, 'Border Style'),
        Field('cornerRadius', String, 'Corner Radius'),
        Field('elevation', String, 'Elevation'),
        Field('shadowStyle', String, 'Shadow Style'),
    ])
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
    String? content;
}

/// Scrolling behavior.
@SectionId('UCES2')
class UiComponentEntryScroll {
    @Form([
        Field('scrollBehavior', String, 'Scroll Behavior',
                hint: 'If component is scrollable'),
        Field('stickyBehavior', String, 'Sticky Behavior',
                hint: 'Headers, columns that stick'),
    ])
    String? content;
}

/// A component state entry.
///
/// Defines a visual/functional state of the component.
@SectionId('CSE1')
class ComponentStateEntry {
  @Form([
    Field('stateId', String, 'State ID', required: true,
        hint: 'Unique state identifier'),
    Field('stateName', String, 'State Name', required: true,
        hint: 'Loading, Empty, Error, Disabled, etc.'),
    Field('stateDescription', String, 'State Description'),
  ])
  String? content;

    /// Visual appearance in this state.
    ComponentStateEntryVisual visual = ComponentStateEntryVisual();

    /// Behavior and accessibility changes in this state.
    ComponentStateEntryBehavior behavior = ComponentStateEntryBehavior();

    /// Entry and exit transition rules.
    ComponentStateEntryTransitions transitions =
            ComponentStateEntryTransitions();

  /// State visual mockup.
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
  String? content;

  /// Visual styling details.
  ComponentVariantEntryVisual visual = ComponentVariantEntryVisual();

  /// Behavioral and implementation notes.
  ComponentVariantEntryBehavior behavior = ComponentVariantEntryBehavior();

  /// Variant visual mockup.
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
  String? content;

    /// Authorization and confirmation behavior.
    ComponentActionEntryGovernance governance =
            ComponentActionEntryGovernance();

    /// Async execution and feedback behavior.
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
  String? multiLanguageOverview;

  /// Multi-language overview narrative.
  @ContentHelp('Executive summary of internationalization and '
      'localization approach for the system.')
  TextSection overviewNarrative = TextSection();

  /// 10.12.4. Language and Country Selection.
  LanguageCountrySelection languageCountrySelection = LanguageCountrySelection();

  /// Supported locale entries.
  @SectionId('SULOEN-SUPP-LST')
  @SectionIdPattern('SULOEN-SUPP-xxx')
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
    String? content;
}

/// Rollout sequencing by region and time.
@SectionId('MLARP')
class LocaleRolloutPlan {
    @Form([
        Field('rolloutStrategy', String, 'Rollout Strategy',
                hint: 'Big bang, phased, pilot'),
        Field('rolloutTimeline', String, 'Rollout Timeline',
                hint: 'High-level rollout schedule'),
        Field('rolloutRegions', String, 'Rollout Regions',
                hint: 'Geographic rollout order'),
    ])
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
  String? localizationProcessContent;

  /// Review process.
  LocalizationReview review = LocalizationReview();

  /// Formatting rules.
  LocalizationFormatting formatting = LocalizationFormatting();

  /// Deployment settings.
  LocalizationDeployment deployment = LocalizationDeployment();

  /// Localization process narrative.
  TextSection localizationNarrative = TextSection();

  /// Localization workflow diagram.
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
  String? translationProcessContent;

  /// Translation workflow.
  TranslationWorkflow workflow = TranslationWorkflow();

  /// Quality assurance.
  TranslationQuality quality = TranslationQuality();

  /// Terminology and voice management.
  TranslationTerminology terminology =
      TranslationTerminology();

  /// Ongoing localization operations.
  TranslationOngoing ongoing = TranslationOngoing();

  /// Translation process narrative.
  TextSection translationNarrative = TextSection();

  /// Translation vendor entries.
  @SectionId('TRVEEN-VEND-LST')
  @SectionIdPattern('TRVEEN-VEND-xxx')
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
  String? documentationContent;

  /// Documentation deliverables provided to users.
  DocumentationAndTrainingDeliverables deliverables =
      DocumentationAndTrainingDeliverables();

  /// Documentation localization approach.
  DocumentationAndTrainingLocalization localization =
      DocumentationAndTrainingLocalization();

  /// Documentation narrative.
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
  String? trainingContent;

  /// Training narrative.
  TextSection trainingNarrative = TextSection();

  /// Training module entries.
  @SectionId('TRMOEN-TRAI-LST')
  @SectionIdPattern('TRMOEN-TRAI-xxx')
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
  String? languageSelectionContent;

  /// Default locale behavior.
  LanguageCountrySelectionDefaults defaults =
      LanguageCountrySelectionDefaults();

  /// Persistence rules.
  LanguageCountrySelectionPersistence persistence =
      LanguageCountrySelectionPersistence();

  /// Fallback behavior.
  LanguageCountrySelectionFallback fallback =
      LanguageCountrySelectionFallback();

  /// Switching UX behavior.
  LanguageCountrySelectionUx ux = LanguageCountrySelectionUx();

  /// Language selection narrative.
  TextSection languageSelectionNarrative = TextSection();

  /// Language selection mockup.
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
    String? content;
}

/// 10.12.5. Translation Handling Requirements.
///
/// Technical requirements for internationalization framework.
@SectionId('TRRE1')
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
  String? translationRequirementsContent;

  /// RTL and bidirectional support.
  TranslationRequirementsRtl rtl = TranslationRequirementsRtl();

  /// Locale-specific formatting rules.
  TranslationRequirementsFormatting formatting =
      TranslationRequirementsFormatting();

  /// Pluralization and variants.
  TranslationRequirementsVariants variants = TranslationRequirementsVariants();

  /// Technical text and font support.
  TranslationRequirementsTechnical technical =
      TranslationRequirementsTechnical();

  /// Translation requirements narrative.
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
  String? content;
}

/// A supported locale entry.
@SectionId('SLE2')
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
  String? content;

  /// Formatting and direction rules for the locale.
  SupportedLocaleEntryFormatting formatting = SupportedLocaleEntryFormatting();

  /// Launch readiness and locale ownership.
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
  String? content;
}

/// Launch readiness and locale ownership.
@SectionId('SLER1')
class SupportedLocaleEntryRollout {
  @Form([
    Field('launchPhase', String, 'Launch Phase',
        hint: 'When locale will be available'),
    Field('translationCoverage', String, 'Translation Coverage',
        hint: 'Percentage translated'),
    Field('localeOwner', String, 'Locale Owner',
        hint: 'Person responsible for locale'),
  ])
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
  String? prototypeOverview;

  /// Prototype timing commitments.
  PrototypeTimeline timeline = PrototypeTimeline();

  /// Prototype staffing and environment.
  PrototypeResources resources = PrototypeResources();

  /// Approval and progression criteria.
  PrototypeGovernance governance = PrototypeGovernance();

  /// Prototype overview narrative.
  @ContentHelp('Executive summary of prototype approach, '
      'objectives, and expected outcomes.')
  TextSection overviewNarrative = TextSection();

  /// 10.13.1. Prototype Goals.
  PrototypeGoals prototypeGoals = PrototypeGoals();

  /// 10.13.2. Selected Feature Subset.
  PrototypeFeatureSubset featureSubset = PrototypeFeatureSubset();

  /// 10.13.3. Prototype Type.
  PrototypeType prototypeType = PrototypeType();

  /// Prototype schedule.
  @ContentHelp('Detailed timeline for prototype development and evaluation.')
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
    String? content;
}

/// Prototype staffing and environment.
@SectionId('PRRE2')
class PrototypeResources {
    @Form([
        Field('prototypeTeam', String, 'Prototype Team',
                hint: 'Who builds the prototype'),
        Field('prototypeBudget', String, 'Prototype Budget',
                hint: 'Budget allocation'),
        Field('prototypeEnvironment', String, 'Prototype Environment',
                hint: 'Where prototype is deployed'),
    ])
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
    String? content;
}

/// 10.13.1. Prototype Goals.
///
/// What the prototype should validate.
@SectionId('PRGO1')
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
  String? goalsContent;

  /// Risk reduction and assumption testing.
  PrototypeGoalsRisk riskProfile = PrototypeGoalsRisk();

  /// User feedback objectives and intake.
  PrototypeGoalsFeedback feedbackProfile = PrototypeGoalsFeedback();

  /// Prototype goals narrative.
  TextSection goalsNarrative = TextSection();

  /// Individual goal entries.
  @SectionId('PRGOEN-GOAL-LST')
  @SectionIdPattern('PRGOEN-GOAL-xxx')
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
  String? featureSubsetContent;

  /// Included and excluded feature scope.
  PrototypeFeatureSubsetScope scope = PrototypeFeatureSubsetScope();

  /// Fidelity expectations for the prototype.
  PrototypeFeatureSubsetFidelity fidelity =
      PrototypeFeatureSubsetFidelity();

  /// Feature subset narrative.
  TextSection featureNarrative = TextSection();

  /// Prototype feature entries.
  @SectionId('PRFEEN-FEAT-LST')
  @SectionIdPattern('PRFEEN-FEAT-xxx')
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
  String? prototypeTypeOverview;

  /// 10.13.3.1. Reusable Prototype.
  ReusablePrototype reusablePrototype = ReusablePrototype();

  /// 10.13.3.2. Training Prototype.
  TrainingPrototype trainingPrototype = TrainingPrototype();

  /// 10.13.3.3. Throwaway Prototype.
  ThrowawayPrototype throwawayPrototype = ThrowawayPrototype();
}

/// 10.13.3.1. Reusable Prototype.
///
/// Prototype that becomes part of the final product.
@SectionId('REPR3')
class ReusablePrototype {
  @Form([
    Field('codeQualityRequirements', String, 'Code Quality Requirements',
        hint: 'Standards prototype code must meet'),
    Field('testCoverageRequirement', String, 'Test Coverage Requirement',
        hint: 'Required test coverage'),
    Field('codeReviewRequired', bool, 'Code Review Required'),
    Field('documentationRequired', bool, 'Documentation Required'),
  ])
  String? reusableContent;

  /// Architecture alignment and refactoring expectations.
  ReusablePrototypeArchitecture architecture =
      ReusablePrototypeArchitecture();

  /// Integration and merge strategy.
  ReusablePrototypeIntegration integration =
      ReusablePrototypeIntegration();

  /// Transition and handoff planning.
  ReusablePrototypeTransition transition = ReusablePrototypeTransition();

  /// Reusable prototype narrative.
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
    String? content;
}

/// 10.13.3.2. Training Prototype.
///
/// Prototype where concepts are reused but not code.
@SectionId('TRPR1')
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
  String? trainingContent;

  /// Code disposition and reimplementation planning.
  TrainingPrototypeDisposition disposition = TrainingPrototypeDisposition();

  /// Documentation outputs and team learning.
  TrainingPrototypeOutputs outputs = TrainingPrototypeOutputs();

  /// Training prototype narrative.
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
  String? throwawayContent;

  /// Findings and decisions captured from evaluation.
  ThrowawayPrototypeFindings findings = ThrowawayPrototypeFindings();

  /// Disposal and follow-up handling.
  ThrowawayPrototypeDisposition disposition = ThrowawayPrototypeDisposition();

  /// Long-term value retained from the prototype.
  ThrowawayPrototypeValue value = ThrowawayPrototypeValue();

  /// Throwaway prototype narrative.
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
  String? content;
}

/// A single recovery flow entry.
@SectionId('RECOV')
class RecoveryFlowEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  String? content;
}

/// A single global entry point entry.
@SectionId('GLOBA')
class GlobalEntryPointEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  String? content;
}

/// A single error page design entry.
@SectionId('ERROR1')
class ErrorPageDesignEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  String? content;
}

/// A single field validation rule entry.
@SectionId('FIELD')
class FieldValidationRuleEntry {
  @ContentType('text', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  String? content;
}
