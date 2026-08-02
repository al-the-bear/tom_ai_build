/// Section 10: Experience & Interface Design.
///
/// Seeds → XDS, TRP, ATS depending on subsection.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../document_stubs.dart';

/// The closed set of screen-element kinds (CE-EL).
///
/// The catalogue is `codespecs_mapping.md` §5.18.
///
/// The discriminator enum for the `ScreenElementEntry` `@OneOf` group: it picks
/// which element facet applies — an action element carries `elementAction`, an
/// input element `fieldSpec`, a display element `dataDisplay`; structural kinds
/// (divider/spacer/tabBar) carry only the common subsections. Replaces the
/// former free-text `elementType` so the choice is a real closed set.
enum ScreenElementKind {
  // Action facet.
  actionButton,
  link,
  // Input facet.
  textField,
  numberField,
  dateField,
  selectField,
  checkbox,
  toggle,
  // Display facet.
  dataDisplay,
  dataTable,
  card,
  chart,
  statusIndicator,
  icon,
  label,
  image,
  badge,
  // Structural (no facet subsection).
  divider,
  spacer,
  tabBar,
}

/// The closed set of input field data-kinds (CE-EL field kind).
///
/// The catalogue is `codespecs_mapping.md` §5.18.
///
/// The discriminator enum for the `ScreenElementFieldSpec` `@OneOf` group: it
/// picks the promoted, kind-specific options subsection — `numberOptions`,
/// `dateOptions`, `selectOptions`, or `textOptions` — so a Date field no longer
/// carries `decimalPlaces` and a Number field no longer carries `optionsSource`.
/// Replaces the former free-text `dataType`.
enum ScreenElementFieldKind {
  string,
  integer,
  decimal,
  currency,
  date,
  dateTime,
  time,
  boolean,
  enumeration,
  email,
  phone,
  url,
  password,
  richText,
  color,
  file,
}

/// The closed set of report-column value types (`ReportColumnEntry`, csra4).
///
/// The discriminator enum for the `ReportColumnEntry` `@OneOf` group: it picks
/// which formatting subsection applies — a numeric column carries
/// `numericFormat`, a currency column `currencyFormat`, a temporal column
/// `dateFormat`, a boolean column `booleanFormat`, a text column `textFormat`.
/// Replaces the former free-text `dataType`.
enum ReportColumnKind {
  string,
  integer,
  decimal,
  currency,
  date,
  boolean,
}

/// The closed set of export-field value types (`ExportFieldMappingEntry`,
/// csra4).
///
/// The discriminator enum for the `ExportFieldMappingEntry` `@OneOf` group: it
/// picks which per-type serialization subsection applies. Replaces the former
/// free-text `dataType`.
enum ExportFieldKind {
  string,
  integer,
  decimal,
  date,
  dateTime,
  boolean,
  enumeration,
}

/// The closed set of report-filter value types (`ReportFilterEntry`, csra4).
///
/// The discriminator enum for the `ReportFilterEntry` `@OneOf` group: it picks
/// which input-control and value-bound subsection applies — a numeric filter
/// carries `numericFilterOptions`, a temporal one `dateFilterOptions`, a
/// selection one `selectFilterOptions`, a text one `textFilterOptions`.
/// Replaces the former free-text `dataType` / `inputType` pair, whose
/// combination was previously unconstrained — a Date filter could be given a
/// Multi-Select control and nothing objected.
///
/// The former free-text `DateRange` value is not a separate kind: a range is a
/// choice of *control* on a temporal filter, so it is expressed by
/// `dateFilterOptions.inputType`.
enum ReportFilterValueKind {
  string,
  integer,
  decimal,
  date,
  dateTime,
  boolean,
  enumeration,
  entityRef,
}

/// The closed set of screen presentation modes (CE-NV).
///
/// How a target screen is put in front of the user when it is reached: either
/// it *replaces* the current screen in the navigation stack, or it is shown as
/// a *popup overlay* on top of the screen the user came from, which therefore
/// stays alive underneath and is revealed again when the overlay closes.
///
/// `popupOverlay` is the specification-side name for the code-side
/// `TomScreenPresentation.popup`; the longer name states that the overlay
/// nature — not merely the popup chrome — is what the mode selects.
enum ScreenPresentationMode {
  replace,
  popupOverlay,
}

/// The closed set of screen-flow outcomes (CE-NV).
///
/// The condition under which a transition out of a screen is taken. A single
/// action may lead to different screens depending on how it ended, so the
/// outcome is part of the transition's identity rather than a property of the
/// action: `success` is the completed path, `error` the processing-failure path
/// (CE-ER), and `validationError` the input-rejected path (CE-VA), which
/// typically keeps the user on the source screen.
enum ScreenFlowOutcome {
  success,
  error,
  validationError,
}

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
class ExperienceAndInterfaceDesign extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// 10.1. Experience CodeSpecs — the CodeSpecs (UI-generation) subtree.
  @SerializationOrder(1)
  ExperienceCodeSpecs experienceCodeSpecs = ExperienceCodeSpecs();

  /// 10.2. Report Definitions — the CE-RP CodeSpecs subtree.
  @SerializationOrder(2)
  ReportDefinitions reportDefinitions = ReportDefinitions();

  /// 10.3. Experience Design — DOC follow-up subtree.
  @SerializationOrder(3)
  ExperienceDesignFollowUp designFollowUp = ExperienceDesignFollowUp();

  /// 10.4. Experience Localization — L10N follow-up subtree.
  @SerializationOrder(4)
  ExperienceLocalizationFollowUp localizationFollowUp =
      ExperienceLocalizationFollowUp();

  /// 10.5. Authorization Compliance — CMP follow-up subtree.
  @SerializationOrder(5)
  AuthorizationComplianceFollowUp authorizationComplianceFollowUp =
      AuthorizationComplianceFollowUp();
}

/// SBP.13 Experience & Interface Design — Report Definitions (CE-RP subtree).
///
/// Groups the report definitions CodeSpecs consumes as the CE-RP generation
/// input (`codespecs_mapping.md` §8.3): each report's grouped projection over
/// the domain model — its sections, output columns, charts, filters, schedule
/// and distribution. The container itself carries no `@CodeSpecKind` — the
/// mapped part lives on `ReportEntry` — but the whole subtree is CE-RP, kept
/// separate from the environment-wide print and export *settings* that remain
/// in `PrintAndExportLayout` and are CE-CF (`codespecs_mapping.md` §5.28).
@StandardReferences(
  [
    'ISO/IEC/IEEE 26514:2022 — designs and develops report information for use',
    'ISO 9241-125:2017 — provides guidance on the visual presentation of printed report content',
  ],
  'The CE-RP reporting seed: the report definitions projected over the domain '
  'model, with their sections, columns, charts, filters and distribution.',
)
@SectionId('REDF')
class ReportDefinitions extends DocSpecsSection {
  @ContentType('description', 'Summarize the report definitions: which reports '
      'exist, what each projects over the domain model, and how they are '
      'delivered.')
  @override
  @SerializationOrder(0)
  String? content;

  /// 10.2.1. Reports — contains 0+× Report.
  @StandardReferences([
    'ISO/IEC/IEEE 26514:2022 — designs and develops report information for use',
    'ISO 9241-125:2017 — provides guidance on the visual presentation of printed report content',
  ], 'The collection of report entries available for printing.')
  @SectionId('REEN-REPO-LST')
  @SectionIdPattern('REEN-REPO-xxx')
  @ContentHelp('Add one entry per report.')
  @SerializationOrder(1)
  List<ReportEntry> reports = [];
}

/// SBP.13 Experience & Interface Design — Experience CodeSpecs subtree.
///
/// Groups the UI concerns CodeSpecs generates (`codespecs_mapping.md` §8.3):
/// screen descriptions (CE-EL/CE-FM/CE-LO/CE-VA/ CE-AC), screen-flow navigation
/// (CE-NV), data-structure alignment (CE-DB cross-ref), error handling
/// (CE-ER/CE-VA), responsive design (CE-LO), and the reusable UI component
/// library (CE-EL/CE-LO). The container itself carries no `@CodeSpecKind` — the
/// mapped parts live on the child sections — but the whole subtree is the
/// CodeSpecs-relevant portion, kept separate from the DOC/L10N/CMP follow-up
/// subtrees.
@StandardReferences(
  [
    'ISO 9241-210:2019 — human-centred design for interactive systems',
    'ISO/IEC 25010:2023 — interaction capability as a product-quality characteristic',
  ],
  'The CodeSpecs UI-generation seed: screens, screen flow, data-structure '
  'alignment, error handling, responsive design, and the UI component library.',
)
@SectionId('XCS')
class ExperienceCodeSpecs extends DocSpecsSection {
  @ContentType('description', 'Summarize the CodeSpecs UI-generation subtree: '
      'screens, navigation, error handling, responsive design, and components.')
  @override
  @SerializationOrder(0)
  String? content;

  /// 10.1.1. Screen Descriptions. Seeds → XDS.
  @SerializationOrder(1)
  ScreenDescriptions screens = ScreenDescriptions();

  /// 10.1.2. Screen Flow Structure. Seeds → XDS.
  @SerializationOrder(2)
  ScreenFlowStructure screenFlow = ScreenFlowStructure();

  /// 10.1.3. Data Structure Alignment.
  @SerializationOrder(3)
  TextSection dataStructureAlignment = TextSection();

  /// 10.1.4. Error Handling. Seeds → XDS.
  @SerializationOrder(4)
  ErrorHandling errorHandling = ErrorHandling();

  /// 10.1.5. Responsive Design. Seeds → XDS.
  @SerializationOrder(5)
  ResponsiveDesign responsiveDesign = ResponsiveDesign();

  /// 10.1.6. UI Components. Seeds → XDS.
  @SerializationOrder(6)
  UiComponents uiComponents = UiComponents();
}

/// SBP.13 Experience & Interface Design — design DOC follow-up subtree.
///
/// Groups the design / documentation concerns that are **follow-up** (design
/// vision, print & export layout, user assistance, accessibility, prototype,
/// wireframes & mockups), not CodeSpecs-generated UI (`codespecs_mapping.md`
/// §8.3). Carries no `@CodeSpecKind` — the whole subtree is
/// generation-owned-out. Accessibility's operational (OPS) facet is a secondary
/// concern refined by the follow-up taxonomy pass.
@StandardReferences(
  [
    'ISO 9241-210:2019 — human-centred design for interactive systems',
    'ISO/IEC/IEEE 26514 — designing and developing user documentation',
    'W3C WCAG 2.2 — accessibility',
  ],
  'The DOC design follow-up: design vision, print / export layout, user '
  'assistance, accessibility, prototype, and wireframes & mockups.',
)
@FollowUpKind([FollowUpProcess.doc])
@SectionId('XDFU')
class ExperienceDesignFollowUp extends DocSpecsSection {
  @ContentType('description', 'Summarize the design follow-up: vision, print '
      'layout, user assistance, accessibility, prototype, and wireframes.')
  @override
  @SerializationOrder(0)
  String? content;

  /// 10.3.1. Design Vision. Seeds → XDS.
  @SerializationOrder(1)
  DesignVision designVision = DesignVision();

  /// 10.3.2. Print & Export Layout. Seeds → XDS.
  @SerializationOrder(2)
  PrintAndExportLayout printLayout = PrintAndExportLayout();

  /// 10.3.3. User Assistance. Seeds → XDS.
  @SerializationOrder(3)
  UserAssistance userAssistance = UserAssistance();

  /// 10.3.4. Accessibility. Seeds → XDS.
  @SerializationOrder(4)
  Accessibility accessibility = Accessibility();

  /// 10.3.5. Prototype. Seeds → XDS.
  @SerializationOrder(5)
  Prototype prototype = Prototype();

  /// 10.3.6. Wireframes and Mockups.
  ///
  /// One whole-catalog content section; collapsed from
  /// `List<WireframesAndMockups>` (L34C-12 SR-52).
  @SerializationOrder(6)
  WireframesAndMockups wireframesAndMockups = WireframesAndMockups();
}

/// SBP.13 Experience & Interface Design — localization L10N follow-up subtree.
///
/// Groups the internationalization concern, a **follow-up** (L10N) rather than
/// CodeSpecs-generated UI (`codespecs_mapping.md` §8.3). Carries no
/// `@CodeSpecKind` — the whole subtree is generation-owned-out.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — portability / adaptability',
    'Unicode CLDR — locale data',
  ],
  'The L10N follow-up: the multi-language support / internationalization '
  'approach for the user interface.',
)
@FollowUpKind([FollowUpProcess.l10n])
@SectionId('XLFU')
class ExperienceLocalizationFollowUp extends DocSpecsSection {
  @ContentType('description', 'Summarize the localization follow-up: the '
      'multi-language / internationalization approach.')
  @override
  @SerializationOrder(0)
  String? content;

  /// 10.4.1. Multi-language Support.
  @SerializationOrder(1)
  MultiLanguageSupport multiLanguageSupport = MultiLanguageSupport();
}

/// SBP.13 Experience & Interface Design — authorization-compliance CMP
/// follow-up subtree.
///
/// Groups the UI authorization-compliance concern (how the interface adapts to
/// roles and permissions as a compliance obligation), a **follow-up** (CMP)
/// rather than CodeSpecs-generated UI (`codespecs_mapping.md` §8.3).
/// Carries no `@CodeSpecKind` — the whole subtree is generation-owned-out.
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — information security management',
    'SOC 2 — trust services criteria',
  ],
  'The CMP follow-up: UI authorization compliance — how the interface adapts to '
  'user roles and permissions as a compliance obligation.',
)
@FollowUpKind([FollowUpProcess.cmp])
@SectionId('XCFU')
class AuthorizationComplianceFollowUp extends DocSpecsSection {
  @ContentType('description', 'Summarize the authorization-compliance follow-up: '
      'UI adaptation to roles and permissions.')
  @override
  @SerializationOrder(0)
  String? content;

  /// 10.5.1. Authorization Compliance.
  @SerializationOrder(1)
  TextSection authorizationCompliance = TextSection();
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
class DesignVision extends DocSpecsSection {
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
  @override
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
class DesignGoals extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of the design goal framework and prioritization approach.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× DesignGoal.
  @StandardReferences([
    'ISO 9241-11:2018 — measurable usability objectives for the interface',
    'ISO 9241-210:2019 — human-centred design sets and tracks usability goals',
  ], 'The collection of individual design-goal entries for the interface.')
  @SectionId('DGOEN-ITEM-LST')
  @SectionIdPattern('DGOEN-ITEM-xxx')
  @ContentHelp('Add one entry per design goal.')
  @SerializationOrder(2)
  List<DesignGoalEntry> items = [];
}

/// A design goal entry (form).
///
/// Each goal represents a measurable UI objective with success criteria.
@StandardReferences([
  'ISO 9241-11:2018 — usability objectives are stated as measurable effectiveness and efficiency targets',
  'ISO 9241-210:2019 — human-centred design sets measurable usability goals',
], 'A single measurable UI objective with success criteria and a target metric.')
@SectionId('DGOEN')
class DesignGoalEntry extends DocSpecsSection {
  @Form([
    Field(
      'goalName',
      String,
      'Goal Name',
      required: true,
      hint: 'A concise label for the design goal',
    ),
    Field(
      'description',
      String,
      'Goal Description',
      hint: 'What this goal means for the UI',
    ),
    Field('priority', String, 'Priority', hint: 'Critical/High/Medium/Low'),
    Field(
      'category',
      String,
      'Category',
      hint: 'Usability/Performance/Accessibility/Aesthetics/Engagement',
    ),
    Field(
      'measurementCriteria',
      String,
      'Measurement Criteria',
      hint: 'How we verify goal achievement',
    ),
    Field(
      'targetMetric',
      String,
      'Target Metric',
      hint: 'Quantifiable target if applicable',
    ),
    Field(
      'relatedPrinciples',
      String,
      'Related Principles',
      hint: 'Design principles that support this goal',
    ),
  ])
  @override
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
class DesignPrinciples extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of the design principle framework.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× UiDesignPrinciple.
  @StandardReferences([
    'ISO 9241-110:2020 — the set of interaction principles guiding dialogue design',
    'ISO 9241-210:2019 — human-centred design applies established interaction principles',
  ], 'The collection of individual design-principle entries for the interface.')
  @SectionId('DPEN-ITEM-LST')
  @SectionIdPattern('DPEN-ITEM-xxx')
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
@SectionId('DPEN')
class DesignPrincipleEntry extends DocSpecsSection {
  @Form([
    Field(
      'principleName',
      String,
      'Principle Name',
      required: true,
      hint: 'A clear name for the design principle',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What this principle means',
    ),
    Field('rationale', String, 'Rationale', hint: 'Why this principle matters'),
    Field(
      'category',
      String,
      'Category',
      hint: 'Visual/Interaction/Accessibility/Information/Navigation',
    ),
    Field(
      'examples',
      String,
      'Examples',
      hint: 'How the principle manifests in the UI',
    ),
    Field(
      'exceptions',
      String,
      'Exceptions',
      hint: 'When deviation is acceptable',
    ),
    Field(
      'sourceReference',
      String,
      'Source Reference',
      hint: 'Design system or external reference',
    ),
    Field(
      'relatedGoals',
      String,
      'Related Goals',
      hint: 'Design goals this principle supports',
    ),
  ])
  @override
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
@StandardReferences([
  'ISO 9241-210:2019 — understand and specify the context of use including user characteristics',
  'ISO 9241-11:2018 — context of use comprises users goals and operating environment',
], 'The set of distinct user archetypes the interface is designed to serve.')
@SectionId('USPER')
class UserPersonas extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of persona research methodology and usage.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 1+× Persona.
  @StandardReferences([
    'ISO 9241-210:2019 — the characteristics of users form part of the context of use',
    'ISO 9241-11:2018 — usability is defined relative to specified users',
  ], 'The collection of individual user-persona entries for the interface.')
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
class PersonaEntry extends DocSpecsSection {
  @Form([
    Field(
      'personaName',
      String,
      'Persona Name',
      required: true,
      hint: 'Name and title, e.g., "Marco, Finance Manager"',
    ),
    Field('age', String, 'Age', hint: 'Age or age range'),
    Field('role', String, 'Role', hint: 'Job title and responsibilities'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Background and capability profile.
  @SectionId('PEPRF')
  @StandardReferences(
    [
      'ISO 9241-210:2019 — user characteristics such as knowledge and skills form the context of use',
      'ISO 9241-11:2018 — usability depends on the capabilities of specified users',
    ],
    'The background, technical proficiency, and accessibility profile of a persona.',
  )
  @Form([
    Field('bio', String, 'Background', hint: 'Brief biographical context'),
    Field(
      'technicalProficiency',
      String,
      'Technical Proficiency',
      hint: 'Beginner/Intermediate/Advanced — with context',
    ),
    Field(
      'accessibilityNeeds',
      String,
      'Accessibility Needs',
      hint: 'Visual/Motor/Cognitive/None',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? profile;

  /// Usage environment and device context.
  @SectionId('PECTX')
  @StandardReferences(
    [
      'ISO 9241-210:2019 — context of use includes the technical and physical environment',
      'ISO 9241-11:2018 — operating environment is part of the context in which usability is achieved',
    ],
    'The usage environment and device context in which a persona interacts with the system.',
  )
  @Form([
    Field(
      'typicalUsage',
      String,
      'Typical Usage',
      hint: 'Frequency, duration, and primary activities',
    ),
    Field(
      'primaryDevice',
      String,
      'Primary Device',
      hint: 'Desktop/Laptop/Tablet/Mobile',
    ),
    Field(
      'additionalDevices',
      String,
      'Additional Devices',
      hint: 'Secondary devices used',
    ),
    Field(
      'workEnvironment',
      String,
      'Work Environment',
      hint: 'Office/Remote/Field/Hybrid',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? context;

  /// Motivations, frustrations, and success markers.
  @SectionId('PENDS')
  @StandardReferences(
    [
      'ISO 9241-11:2018 — usability accounts for the needs and satisfaction of specified users',
      'ISO 9241-210:2019 — user characteristics form part of the context of use',
    ],
    'The motivations, frustrations, and success markers that characterise what a persona needs.',
  )
  @Form([
    Field(
      'motivations',
      String,
      'Motivations',
      hint: 'What drives their behavior',
    ),
    Field(
      'frustrationsWithCurrent',
      String,
      'Current Frustrations',
      hint: 'Issues with existing solutions',
    ),
    Field(
      'successCriteria',
      String,
      'Success Criteria',
      hint: 'How they measure success',
    ),
    Field(
      'quote',
      String,
      'Representative Quote',
      hint: 'A quote that captures their perspective',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? needs;

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

/// 10.1.3.n.1. Persona Goals.
@StandardReferences(
  [
    'ISO 9241-11:2018 — usability is defined relative to specified users and their goals',
    'ISO 9241-210:2019 — specify the context of use including the goals users pursue',
  ],
  'The set of specific goals a persona pursues that drive feature requirements.',
)
@SectionId('PERGL')
class PersonaGoals extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× PersonaGoal.
  @StandardReferences([
    'ISO 9241-11:2018 — usability is measured against the goals of specified users',
    'ISO 9241-210:2019 — context of use records the goals users pursue',
  ], 'The collection of individual goal entries for a persona.')
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
class PersonaGoalEntry extends DocSpecsSection {
  @Form([
    Field(
      'goal',
      String,
      'Goal',
      required: true,
      hint: 'The concrete action or outcome the persona wants to achieve',
    ),
    Field('priority', String, 'Priority', hint: 'Critical/High/Medium/Low'),
    Field('frequency', String, 'Frequency', hint: 'How often this goal arises'),
    Field(
      'currentApproach',
      String,
      'Current Approach',
      hint: 'How they achieve this today',
    ),
    Field(
      'desiredOutcome',
      String,
      'Desired Outcome',
      hint: 'What success looks like',
    ),
  ])
  @override
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
class PersonaPainPoints extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× PersonaPainPoint.
  @StandardReferences([
    'ISO 9241-210:2019 — context of use records the problems and constraints users face',
    'ISO 9241-11:2018 — usability considers obstacles to users goals and environment',
  ], 'The collection of individual pain-point entries for a persona.')
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
class PersonaPainPointEntry extends DocSpecsSection {
  @Form([
    Field(
      'painPoint',
      String,
      'Pain Point',
      required: true,
      hint: 'The specific frustration or obstacle the persona encounters',
    ),
    Field('severity', String, 'Severity', hint: 'Critical/High/Medium/Low'),
    Field('frequency', String, 'Frequency', hint: 'How often this occurs'),
    Field(
      'impact',
      String,
      'Impact',
      hint: 'Effect on productivity/satisfaction',
    ),
    Field(
      'workaround',
      String,
      'Current Workaround',
      hint: 'How they cope today',
    ),
    Field(
      'desiredSolution',
      String,
      'Desired Solution',
      hint: 'What would help',
    ),
  ])
  @override
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
class PersonaScenarios extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× PersonaScenario.
  @StandardReferences([
    'ISO 9241-210:2019 — context of use is described through representative task scenarios',
    'ISO 9241-11:2018 — scenarios ground usability in users goals and environment',
  ], 'The collection of individual usage-scenario entries for a persona.')
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
class PersonaScenarioEntry extends DocSpecsSection {
  @Form([
    Field(
      'scenarioName',
      String,
      'Scenario Name',
      required: true,
      hint: 'A short action-oriented name for the scenario',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What the persona is trying to accomplish',
    ),
    Field(
      'frequency',
      String,
      'Frequency',
      hint: 'Daily/Weekly/Monthly/Occasional',
    ),
    Field('urgency', String, 'Urgency', hint: 'Time-sensitive nature'),
    Field(
      'context',
      String,
      'Context',
      hint: 'Where/when this scenario occurs',
    ),
    Field(
      'requiredScreens',
      String,
      'Required Screens',
      hint: 'Screens needed for this scenario',
    ),
    Field(
      'successMetric',
      String,
      'Success Metric',
      hint: 'How we measure scenario success',
    ),
  ])
  @override
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
class ScreenDescriptions extends DocSpecsSection {
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
  @override
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
class ScreenInventory extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of the screen inventory structure and conventions.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 1+× Screen.
  @StandardReferences([
    'ISO 9241-151:2008 — the catalogue of screens that make up the user interface',
    'ISO 9241-210:2019 — the full set of screens supporting the user tasks',
  ], 'The catalogue of individual screen entries that make up the application.')
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
@CodeSpecKind([
  CodeSpecPart.layout,
  CodeSpecPart.navigation,
], note: 'CE-LO + CE-NV — a screen is a routable, laid-out page.')
class ScreenEntry extends DocSpecsSection {
  @Form([
    Field(
      'screenId',
      String,
      'Screen ID',
      required: true,
      hint: 'Unique identifier, e.g., SCR-001',
    ),
    Field(
      'screenName',
      String,
      'Screen Name',
      required: true,
      hint: 'Human-readable screen title',
    ),
    Field(
      'purpose',
      String,
      'Purpose',
      hint: 'Business purpose — what the user accomplishes here',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Classification and routing metadata.
  @SectionId('SCECL')
  @StandardReferences(
    [
      'ISO 9241-151:2008 — navigation structure and routing within the user interface',
      'ISO 9241-112:2017 — categorisation of information for structured presentation',
    ],
    'The classification and routing metadata that categorises a screen and locates it in the navigation structure.',
  )
  @Form([
    Field(
      'screenCategory',
      String,
      'Screen Category',
      hint: 'List/Detail/Form/Dashboard/Settings/Wizard/Dialog/Report/Landing',
    ),
    Field(
      'parentScreenId',
      String,
      'Parent Screen ID',
      hint: 'Parent screen if this is a sub-screen or drill-down',
    ),
    Field(
      'routePattern',
      String,
      'Route Pattern',
      hint: 'Route ID (SCRTEN registry) this screen is reached by — the path '
          'itself is declared once in the screen route map',
      refersTo: ['SCRTEN.routeId'],
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? classification;

  /// Access control settings.
  @SectionId('SCEAC')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — controllability governing who may access an interface',
      'ISO/IEC 25010:2023 — interaction capability constrained by authorization',
    ],
    'The access-control settings that determine which roles and permissions may reach a screen.',
  )
  @Form([
    Field(
      'accessLevel',
      String,
      'Access Level',
      hint: 'Public/Authenticated/Role-specific',
    ),
    Field(
      'requiredRoles',
      String,
      'Required Roles',
      hint: 'Authorization roles that may access this screen',
    ),
    Field(
      'requiredPermissions',
      String,
      'Required Permissions',
      hint: 'Specific permissions needed',
    ),
    Field(
      'permissionEffect',
      String,
      'Permission Effect',
      hint: 'Hide-Screen/Show-Readonly/Show-With-Restrictions',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? access;

  /// Traceability metadata.
  @SectionId('SCETR')
  @StandardReferences(
    [
      'ISO 9241-210:2019 — linkage of screens to the user tasks and requirements they serve',
      'ISO/IEC 25010:2023 — interaction capability traced to product requirements',
    ],
    'The traceability metadata linking a screen to the use cases, requirements, and data entities it serves.',
  )
  @Form([
    Field(
      'relatedUseCases',
      String,
      'Related Use Cases',
      hint: 'ISC references this screen serves',
    ),
    Field(
      'relatedRequirements',
      String,
      'Related Requirements',
      hint: 'RSP references this screen satisfies',
    ),
    Field(
      'relatedBusinessProcesses',
      String,
      'Related Business Processes',
      hint: 'TOM references where this screen appears',
    ),
    Field(
      'dataEntities',
      String,
      'Data Entities',
      hint: 'IFM entity references displayed/edited',
    ),
    Field(
      'primaryAction',
      String,
      'Primary Action',
      hint: 'Main user action on this screen',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? traceability;

  /// Presentation metadata.
  @SectionId('SCENPR')
  @StandardReferences(
    [
      'ISO 9241-112:2017 — presentation of screen titles, icons, and identifying information',
      'ISO 9241-125:2017 — visual presentation and layout of the screen',
    ],
    'The presentation metadata such as title, icon, and layout that defines how a screen appears.',
  )
  @Form([
    Field(
      'pageTitleResource',
      String,
      'Page Title Resource',
      hint: 'Message key (MSGKR registry) for the screen title text',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'pageIconResource',
      String,
      'Page Icon Resource',
      hint: 'Resource key for the screen icon',
    ),
    Field(
      'helpTopicId',
      String,
      'Help Topic ID',
      hint: 'Link to help/documentation topic',
    ),
    Field(
      'layout',
      String,
      'Layout',
      hint:
          'Layout description, e.g., Responsive grid — 3 col desktop, 1 col mobile',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? presentation;

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
class ScreenSections extends DocSpecsSection {
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
  @override
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
@CodeSpecKind(
  [CodeSpecPart.layout],
  note:
      'CE-LO — screen/region layout (unblocked by csm-2-2 layout-node + dsb6 tom_flutter_ui basis).',
)
class ScreenSectionEntry extends DocSpecsSection {
  @Form([
    Field(
      'sectionId',
      String,
      'Section ID',
      required: true,
      hint: 'Unique within screen, e.g., header, filter-bar, main-content',
    ),
    Field(
      'sectionName',
      String,
      'Section Name',
      required: true,
      hint: 'Human label, e.g., "Filter Bar", "Order Details"',
    ),
    Field('purpose', String, 'Purpose', hint: 'What this zone contains'),
    Field(
      'sectionType',
      String,
      'Section Type',
      hint:
          'Header/Toolbar/Filter-Bar/Content-Primary/Content-Secondary/Sidebar/Footer/Tab-Panel/Accordion-Panel/Drawer/Action-Bar/Form-Group',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Layout and ordering for the section.
  @SectionId('SSEL')
  @StandardReferences(
    [
      'ISO 9241-125:2017 — spatial layout and ordering of presented information',
      'ISO 9241-112:2017 — organisation of information within a display area',
    ],
    'The layout direction, order, and border styling that arrange a screen section within its screen.',
  )
  @Form([
    Field(
      'layoutDirection',
      String,
      'Layout Direction',
      hint: 'Horizontal/Vertical/Wrap/Grid',
    ),
    Field(
      'displayOrder',
      int,
      'Display Order',
      hint: 'Position in reading order',
    ),
    Field(
      'titleResource',
      String,
      'Title Resource',
      hint: 'Message key (MSGKR registry) for section header text',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'borderStyle',
      String,
      'Border Style',
      hint: 'Named style or resource key',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? layout;

  /// Visibility and collapse behavior.
  @SectionId('SSEB')
  @StandardReferences(
    [
      'ISO 9241-161:2016 — collapsible and expandable states of user-interface containers',
      'ISO 9241-110:2020 — controllability over the visibility of interface zones',
    ],
    'The visibility and collapse behavior that governs when and how a screen section is shown.',
  )
  @Form([
    Field(
      'collapsible',
      String,
      'Collapsible',
      hint: 'Yes/No — can the user collapse this section?',
    ),
    Field(
      'initiallyCollapsed',
      String,
      'Initially Collapsed',
      hint: 'Yes/No — default collapsed state',
    ),
    Field(
      'visibilityCondition',
      String,
      'Visibility Condition',
      hint: 'When this section is shown, e.g., role==Admin',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? behavior;

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
@OneOf(
  discriminator: 'elementType',
  note:
      'CE-EL closed choice: the element kind selects its facet subsection '
      '(action / input / display); structural kinds carry only common ones.',
)
@CodeSpecKind(
  [CodeSpecPart.screenElement],
  note:
      'CE-EL — a screen element by semantic type then concrete implementation.',
)
class ScreenElementEntry extends DocSpecsSection {
  @Form([
    Field(
      'elementId',
      String,
      'Element ID',
      required: true,
      hint: 'Unique within screen, e.g., btn-submit, fld-customer-name',
    ),
    Field(
      'elementName',
      String,
      'Element Name',
      required: true,
      hint: 'Human-readable label',
    ),
    Field(
      'elementType',
      ScreenElementKind,
      'Element Type',
      required: true,
      hint: 'The semantic element kind — selects the facet subsection.',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Labels and icon resources.
  @SectionId('SEER')
  @StandardReferences(
    [
      'ISO 9241-161:2016 — labels, icons, and tooltips associated with user-interface elements',
      'ISO 9241-112:2017 — presentation of labels and identifying information to the user',
    ],
    'The label, hint, description, and icon resources that identify a screen element to the user.',
  )
  @Form([
    Field(
      'labelResource',
      String,
      'Label Resource',
      hint: 'Message key (MSGKR registry) for display label',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'hintResource',
      String,
      'Hint Resource',
      hint: 'Message key (MSGKR registry) for tooltip/helper text',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'descriptionResource',
      String,
      'Description Resource',
      hint: 'Message key (MSGKR registry) for extended description',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'iconResource',
      String,
      'Icon Resource',
      hint: 'Resource key for icon',
    ),
    Field(
      'iconPosition',
      String,
      'Icon Position',
      hint: 'Leading/Trailing/Above/Below/Only',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? resources;

  /// Placement and layout settings.
  @SectionId('SCELENLA')
  @StandardReferences(
    [
      'ISO 9241-161:2016 — placement and layout of visual user-interface elements',
      'ISO 9241-125:2017 — spatial arrangement of information for visual presentation',
    ],
    'The placement, sizing, and alignment settings that position a screen element within its section.',
  )
  @Form([
    Field(
      'placementOrder',
      int,
      'Placement Order',
      hint: 'Order within parent section',
    ),
    Field(
      'width',
      String,
      'Width',
      hint: 'Fill/Auto/Fixed(200)/Proportion(1/3)',
    ),
    Field('alignment', String, 'Alignment', hint: 'Start/Center/End/Stretch'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? layout;

  /// Visibility and permission rules.
  @SectionId('SEEB')
  @StandardReferences(
    [
      'ISO 9241-161:2016 — states of user-interface elements such as visible, enabled, and read-only',
      'ISO 9241-110:2020 — controllability governing when an element is interactive',
    ],
    'The visibility, enablement, and permission rules that determine when a screen element can be seen or used.',
  )
  @Form([
    Field(
      'visibilityCondition',
      String,
      'Visibility Condition',
      hint: 'When this element is shown',
    ),
    Field(
      'enabledCondition',
      String,
      'Enabled Condition',
      hint: 'When this element is interactive',
    ),
    Field(
      'readonlyCondition',
      String,
      'Readonly Condition',
      hint: 'When this element is read-only',
    ),
    Field(
      'requiredPermission',
      String,
      'Required Permission',
      hint: 'Permission needed to see/interact',
    ),
    Field(
      'permissionEffect',
      String,
      'Permission Effect',
      hint: 'Hide/Disable/Readonly',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? behavior;

  /// Styling and data binding.
  @SectionId('SCELENPR')
  @StandardReferences(
    [
      'ISO 9241-125:2017 — visual presentation attributes such as style and colour of information',
      'ISO 9241-112:2017 — coding of information through visual style variants',
    ],
    'The styling and data-binding attributes that govern how a screen element appears and connects to data.',
  )
  @Form([
    Field(
      'styleVariant',
      String,
      'Style Variant',
      hint: 'Primary/Secondary/Danger/Subtle/Custom',
    ),
    Field(
      'accessibilityLabel',
      String,
      'Accessibility Label',
      hint: 'Override for screen readers',
    ),
    Field(
      'dataBinding',
      String,
      'Data Binding',
      hint: 'Path to bound data field, e.g., order.customerName',
    ),
    Field(
      'defaultValue',
      String,
      'Default Value',
      hint: 'Default value or expression',
    ),
    Field(
      'notes',
      String,
      'Design Notes',
      hint: 'Design rationale or open questions',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? presentation;

  /// 10.2.1.n.m.k.1. Element Action.
  ///
  /// Present only for action-kind elements (`@OneOf` case, csmb6).
  @Case(ScreenElementKind.actionButton)
  @Case(ScreenElementKind.link)
  @SerializationOrder(5)
  ScreenElementAction? elementAction;

  /// 10.2.1.n.m.k.2. Element Field Spec.
  ///
  /// Present only for input-kind elements (`@OneOf` case, csmb6).
  @Case(ScreenElementKind.textField)
  @Case(ScreenElementKind.numberField)
  @Case(ScreenElementKind.dateField)
  @Case(ScreenElementKind.selectField)
  @Case(ScreenElementKind.checkbox)
  @Case(ScreenElementKind.toggle)
  @SerializationOrder(6)
  ScreenElementFieldSpec? fieldSpec;

  /// 10.2.1.n.m.k.3. Element Data Display.
  ///
  /// Present only for display-kind elements (`@OneOf` case, csmb6).
  @Case(ScreenElementKind.dataDisplay)
  @Case(ScreenElementKind.dataTable)
  @Case(ScreenElementKind.card)
  @Case(ScreenElementKind.chart)
  @Case(ScreenElementKind.statusIndicator)
  @Case(ScreenElementKind.icon)
  @Case(ScreenElementKind.label)
  @Case(ScreenElementKind.image)
  @Case(ScreenElementKind.badge)
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
@CodeSpecKind([CodeSpecPart.action], note: 'CE-AC — an action and its trigger.')
class ScreenElementAction extends DocSpecsSection {
  @Form([
    Field(
      'actionId',
      String,
      'Action ID',
      hint: 'Reference to action system action',
    ),
    Field(
      'actionType',
      String,
      'Action Type',
      hint:
          'Submit/Save/Cancel/Delete/Navigate/Export/Import/Print/Refresh/Custom',
    ),
    Field(
      'buttonStyle',
      String,
      'Button Style',
      hint:
          'Primary/Secondary/Tertiary/Danger/Text-Only/Icon-Only/Outlined/Floating',
    ),
    Field(
      'actionTrigger',
      String,
      'Action Trigger',
      hint: 'User interaction that triggers execution',
    ),
    Field(
      'actionPayload',
      String,
      'Action Payload',
      hint: 'Data passed when the action fires',
    ),
    Field(
      'keyboardShortcut',
      String,
      'Keyboard Shortcut',
      hint: 'Shortcut binding, e.g., Ctrl+S',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Confirmation and execution feedback behavior.
  @SectionId('SEAE')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — use error tolerance and feedback during action execution',
      'ISO 9241-161:2016 — user-interface elements for confirmation and progress feedback',
    ],
    'The confirmation and execution-feedback behavior that governs how an action element runs and reports.',
  )
  @Form([
    Field(
      'confirmationRequired',
      String,
      'Confirmation Required',
      hint: 'Yes/No — show confirmation dialog?',
    ),
    Field(
      'confirmationMessageResource',
      String,
      'Confirmation Message Resource',
      hint: 'Message key (MSGKR registry) for confirmation prompt',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'loadingLabelResource',
      String,
      'Loading Label Resource',
      hint: 'Message key (MSGKR registry) for label during async execution',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'successMessageResource',
      String,
      'Success Message Resource',
      hint: 'Message key (MSGKR registry) for success notification',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'errorHandling',
      String,
      'Error Handling',
      hint: 'Inline/Toast/Dialog/Banner',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? execution;

  /// Post-action navigation rules.
  @SectionId('SEAN')
  @StandardReferences(
    [
      'ISO 9241-151:2008 — navigation between screens following an action',
      'ISO 9241-110:2020 — conformity with user expectations for post-action navigation',
    ],
    'The navigation rules that determine where the user is taken after an action completes.',
  )
  @Form([
    Field(
      'navigateTo',
      String,
      'Navigate To',
      hint: 'Target screen ID or route after action',
      refersTo: ['SCREN.screenId', 'SCRTEN.routeId'],
    ),
    Field(
      'navigateParams',
      String,
      'Navigate Params',
      hint: 'Parameters to pass to navigation target',
    ),
    Field(
      'doubleClickPrevention',
      String,
      'Double-Click Prevention',
      hint: 'Yes/No — disable during execution?',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? navigation;
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
@OneOf(
  discriminator: 'dataType',
  note:
      'CE-EL field kind closed choice: the data type selects its promoted '
      'options subsection (number / date / select / text / file); boolean and '
      'color kinds carry only the common formatting + validation subsections.',
)
@CodeSpecKind([
  CodeSpecPart.form,
], note: 'CE-FM — a form field / input specification.')
class ScreenElementFieldSpec extends DocSpecsSection {
  @Form([
    Field(
      'fieldName',
      String,
      'Field Name',
      hint: 'Logical form field name, maps to data model attribute',
    ),
    Field(
      'dataType',
      ScreenElementFieldKind,
      'Data Type',
      hint: 'The input data kind — selects the promoted options subsection.',
    ),
    Field(
      'placeholderResource',
      String,
      'Placeholder Resource',
      hint: 'Message key (MSGKR registry) for placeholder text',
      refersTo: ['MSGKE.key'],
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Prefix, suffix, and formatting.
  @SectionId('SEFSF')
  @StandardReferences(
    [
      'ISO 9241-143:2012 — formatting and affordances for form-field input',
      'ISO 9241-112:2017 — presentation of formatted information such as masks and prefixes',
    ],
    'The prefix, suffix, and formatting that shape how a form field displays and accepts input.',
  )
  @Form([
    Field(
      'prefixResource',
      String,
      'Prefix Resource',
      hint: 'Prefix text/icon resource, e.g., currency symbol',
    ),
    Field(
      'suffixResource',
      String,
      'Suffix Resource',
      hint: 'Suffix text/icon resource, e.g., unit label',
    ),
    Field('inputMask', String, 'Input Mask', hint: 'Pattern, e.g., ##/##/####'),
    Field(
      'displayFormat',
      String,
      'Display Format',
      hint: 'Format pattern, e.g., #,##0.00',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? formatting;

  /// Number-kind options — a promoted `@OneOf` case (csmb6).
  ///
  /// Present only for numeric field kinds; carries only numeric constraints
  /// (no length or option-source attributes).
  @SectionId('SEFSN')
  @StandardReferences([
    'ISO 9241-143:2012 — constraints on numeric form-field input such as value ranges and precision',
    'ISO 9241-110:2020 — use error tolerance through bounded numeric input',
  ], 'The value range and precision constraints for a numeric input field.')
  @Case(ScreenElementFieldKind.integer)
  @Case(ScreenElementFieldKind.decimal)
  @Case(ScreenElementFieldKind.currency)
  @Form([
    Field(
      'minValue',
      String,
      'Min Value',
      hint: 'Minimum allowed numeric value',
    ),
    Field(
      'maxValue',
      String,
      'Max Value',
      hint: 'Maximum allowed numeric value',
    ),
    Field(
      'decimalPlaces',
      int,
      'Decimal Places',
      hint: 'Number of decimal places',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? numberOptions;

  /// Date-kind options — a promoted `@OneOf` case (csmb6).
  ///
  /// Present only for date/time field kinds; carries only temporal
  /// constraints (no numeric precision or length attributes).
  @SectionId('SEFSD')
  @StandardReferences([
    'ISO 9241-143:2012 — constraints on date and time form-field input',
    'ISO 8601-1:2019 — representation of dates and times',
  ], 'The date/time range and format constraints for a temporal input field.')
  @Case(ScreenElementFieldKind.date)
  @Case(ScreenElementFieldKind.dateTime)
  @Case(ScreenElementFieldKind.time)
  @Form([
    Field(
      'firstDate',
      String,
      'First Date',
      hint: 'Earliest selectable date/time',
    ),
    Field('lastDate', String, 'Last Date', hint: 'Latest selectable date/time'),
    Field(
      'dateFormat',
      String,
      'Date Format',
      hint: 'Display/parse pattern, e.g., yyyy-MM-dd',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? dateOptions;

  /// Text-kind options — a promoted `@OneOf` case (csmb6).
  ///
  /// Present only for free-text field kinds; carries only length constraints.
  @SectionId('SEFST')
  @StandardReferences([
    'ISO 9241-143:2012 — length constraints on text form-field input',
    'ISO 9241-110:2020 — use error tolerance through bounded text input',
  ], 'The length constraints for a free-text input field.')
  @Case(ScreenElementFieldKind.string)
  @Case(ScreenElementFieldKind.email)
  @Case(ScreenElementFieldKind.phone)
  @Case(ScreenElementFieldKind.url)
  @Case(ScreenElementFieldKind.password)
  @Case(ScreenElementFieldKind.richText)
  @Form([
    Field('maxLength', int, 'Max Length', hint: 'Character limit'),
    Field('minLength', int, 'Min Length', hint: 'Minimum length'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? textOptions;

  /// Validation behavior.
  @SectionId('SEFSV')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — use error tolerance through input validation and error display',
      'ISO 9241-143:2012 — validation behavior for form fields',
    ],
    'The validation behavior for a form field including trigger, required rules, and error display.',
  )
  @Form([
    Field(
      'validationTrigger',
      String,
      'Validation Trigger',
      hint: 'On-Change/On-Blur/On-Submit/Debounced',
    ),
    Field(
      'errorDisplayMode',
      String,
      'Error Display Mode',
      hint: 'Below-Field/Tooltip/Inline/Banner',
    ),
    Field('required', String, 'Required', hint: 'Yes/No/Conditional'),
    Field(
      'requiredCondition',
      String,
      'Required Condition',
      hint: 'Condition when field becomes required',
    ),
    Field(
      'clearButton',
      String,
      'Clear Button',
      hint: 'Yes/No — show clear/reset affordance',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? validation;

  /// Select-kind options — a promoted `@OneOf` case (csmb6).
  ///
  /// Present only for the enumeration (select) field kind; carries only the
  /// option-source and selection-mode attributes.
  @SectionId('SEFSS')
  @StandardReferences([
    'ISO 9241-143:2012 — form fields with selection and input assistance',
    'ISO 9241-161:2016 — selection controls such as dropdowns and radio groups',
  ], 'The option source and selection-mode attributes for a select input field.')
  @Case(ScreenElementFieldKind.enumeration)
  @Form([
    Field(
      'autocompleteSource',
      String,
      'Autocomplete Source',
      hint: 'Source reference for autocomplete suggestions',
    ),
    Field(
      'optionsSource',
      String,
      'Options Source',
      hint: 'For select fields: static list, API endpoint, or entity query',
    ),
    Field('selectMode', String, 'Select Mode', hint: 'Single/Multi'),
    Field(
      'displayMode',
      String,
      'Display Mode',
      hint:
          'Dropdown/Radio-Group/Chip-Group/Segmented-Button/Autocomplete/'
          'Dialog-Picker',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? selectOptions;

  /// File-kind options — a promoted `@OneOf` case (csrb8).
  ///
  /// Present only for the file field kind; carries what may be chosen and how
  /// the chosen file is shown. The **storage group** is deliberately absent: a
  /// file's group is authored once on its CE-DB file-reference column
  /// (`codespecs_mapping.md` §5.13.1) and derived here, so the two can never
  /// name different groups. So is a download affordance, which follows from the
  /// field being wired for transfer and the file being stored (§5.18).
  @SectionId('SEFSU')
  @StandardReferences([
    'ISO 9241-143:2012 — form fields with input assistance such as file selection',
    'ISO/IEC 2382:2015 — content and media type terminology',
  ], 'What a file input accepts and how the chosen file is presented.')
  @Case(ScreenElementFieldKind.file)
  @Form([
    Field(
      'acceptedContentKinds',
      String,
      'Accepted Content Kinds',
      hint:
          'What may be chosen: a content-kind family (any/image/video/audio) '
          'and/or the accepted file extensions',
    ),
    Field(
      'maxFileSize',
      String,
      'Maximum File Size',
      hint: 'Largest file the field accepts, e.g. 10 MB',
    ),
    Field(
      'presentation',
      String,
      'Presentation (link, dropzone, thumbnail)',
      hint:
          'How the file is shown: link (name with affordances), dropzone '
          '(drop surface), or thumbnail (inline preview)',
    ),
    Field(
      'uploadOnPick',
      String,
      'Upload On Pick',
      hint:
          'Yes/No — whether choosing a file uploads it immediately or the form '
          'uploads it on save',
    ),
  ])
  @SerializationOrder(7)
  DocSpecsSection? fileOptions;
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
@CodeSpecKind(
  [CodeSpecPart.viewState],
  note:
      'CE-ST — view-model / UI state (data-bound display, screen/component state).',
)
class ScreenElementDataDisplay extends DocSpecsSection {
  @Form([
    Field(
      'dataSource',
      String,
      'Data Source',
      hint: 'Data entity or query reference',
    ),
    Field(
      'displayFormat',
      String,
      'Display Format',
      hint: 'How data is formatted for display',
    ),
    Field(
      'emptyStateMessageResource',
      String,
      'Empty State Message',
      hint: 'Message key (MSGKR registry) for message when no data',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'emptyStateIconResource',
      String,
      'Empty State Icon',
      hint: 'Resource key for icon when no data',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Refresh and drill-down behavior.
  @SectionId('SEDDB')
  @StandardReferences(
    [
      'ISO 9241-112:2017 — presentation of information as it refreshes and updates',
      'ISO 9241-151:2008 — navigation such as drill-down between related views',
    ],
    'The refresh and drill-down behavior that governs how displayed data updates and navigates deeper.',
  )
  @Form([
    Field(
      'refreshMode',
      String,
      'Refresh Mode',
      hint: 'Auto/Manual/Interval(seconds)',
    ),
    Field(
      'drillDownTarget',
      String,
      'Drill-Down Target',
      hint: 'Screen ID navigated to on click/tap',
      refersTo: ['SCREN.screenId'],
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? behavior;

  /// Table/list interaction controls.
  @SectionId('SEDDO')
  @StandardReferences(
    [
      'ISO 9241-143:2012 — form and table interaction controls such as sorting and filtering',
      'ISO 9241-112:2017 — presentation of tabular and list information',
    ],
    'The interaction controls for tables and lists such as sorting, filtering, pagination, and selection.',
  )
  @Form([
    Field('sortable', String, 'Sortable', hint: 'Yes/No — for table columns'),
    Field(
      'filterable',
      String,
      'Filterable',
      hint: 'Yes/No — for table columns',
    ),
    Field(
      'paginated',
      String,
      'Paginated',
      hint: 'Yes/No — for lists and tables',
    ),
    Field('pageSize', int, 'Page Size', hint: 'Default items per page'),
    Field(
      'selectable',
      String,
      'Selectable',
      hint: 'None/Single/Multi — row selection mode',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? options;
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
@CodeSpecKind([
  CodeSpecPart.validation,
], note: 'CE-VA — per-field / per-element validation rule.')
class ElementValidationRuleEntry extends DocSpecsSection {
  @Form([
    Field(
      'ruleType',
      String,
      'Rule Type',
      required: true,
      hint:
          'Required/Min-Length/Max-Length/Pattern/Range/Custom/Cross-Field/'
          'Async/Unique',
    ),
    Field(
      'ruleExpression',
      String,
      'Rule Expression',
      hint: 'Validation expression or pattern',
    ),
    Field(
      'errorCode',
      String,
      'Error Code',
      hint:
          'The error code emitted on failure — reference into the error-code '
          'registry (ERCRG / ErrorCodeEntry.code), shared with CE-ER and CE-TX',
      refersTo: ['ERCEN.code'],
    ),
    Field(
      'errorMessageResource',
      String,
      'Error Message Resource',
      hint: 'Message key (MSGKR registry) for validation error message',
      refersTo: ['MSGKE.key'],
    ),
    Field('severity', String, 'Severity', hint: 'Error/Warning/Info'),
    Field(
      'validateOn',
      String,
      'Validate On',
      hint: 'On-Change/On-Blur/On-Submit',
    ),
  ])
  @override
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
class ScreenActions extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× ScreenAction.
  @StandardReferences([
    'ISO 9241-110:2020 — controllability over the set of available screen actions',
    'ISO 9241-161:2016 — command and action user-interface elements',
  ], 'The collection of individual screen-action entries for this screen.')
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
@CodeSpecKind([CodeSpecPart.action], note: 'CE-AC — an action and its trigger.')
class ScreenActionEntry extends DocSpecsSection {
  @Form([
    Field(
      'actionId',
      String,
      'Action ID',
      required: true,
      hint: 'Unique action identifier',
    ),
    Field(
      'actionName',
      String,
      'Action Name',
      required: true,
      hint: 'Human-readable action name',
    ),
    Field(
      'actionType',
      String,
      'Action Type',
      hint: 'Submit/Save/Cancel/Delete/Navigate/Export/Import/Print/Refresh',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Visual presentation of the action.
  @SectionId('SAEV')
  @StandardReferences(
    [
      'ISO 9241-161:2016 — visual presentation of command and action elements',
      'ISO 9241-125:2017 — visual presentation of information such as labels and icons',
    ],
    'The visual presentation of a screen action including its label, icon, placement, and style.',
  )
  @Form([
    Field(
      'labelResource',
      String,
      'Label Resource',
      hint: 'Message key (MSGKR registry) for button label',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'iconResource',
      String,
      'Icon Resource',
      hint: 'Resource key for action icon',
    ),
    Field(
      'placement',
      String,
      'Placement',
      hint: 'App-Bar/Toolbar/FAB/Context-Menu/Overflow-Menu',
    ),
    Field(
      'buttonStyle',
      String,
      'Button Style',
      hint: 'Primary/Secondary/Tertiary/Danger/Icon-Only/Text-Only',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? visual;

  /// Visibility, enablement, and permission rules.
  @SectionId('SAEC')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — controllability over when an action is available to the user',
      'ISO 9241-161:2016 — states of command and action elements such as enabled or hidden',
    ],
    'The visibility, enablement, and permission rules that determine when a screen action is available.',
  )
  @Form([
    Field(
      'visibilityCondition',
      String,
      'Visibility Condition',
      hint: 'When this action is shown',
    ),
    Field(
      'enabledCondition',
      String,
      'Enabled Condition',
      hint: 'When this action is active',
    ),
    Field(
      'requiredPermission',
      String,
      'Required Permission',
      hint: 'Permission needed to use this action',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? conditions;

  /// Confirmation, navigation, and feedback behavior.
  @SectionId('SAEB')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — controllability and use error tolerance for action execution',
      'ISO 9241-161:2016 — command and action user-interface elements',
    ],
    'The confirmation, navigation, and feedback behavior that governs how a screen action executes.',
  )
  @Form([
    Field(
      'confirmationRequired',
      String,
      'Confirmation Required',
      hint: 'Yes/No',
    ),
    Field(
      'confirmationMessageResource',
      String,
      'Confirmation Message',
      hint: 'Message key (MSGKR registry) for confirmation dialog',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'keyboardShortcut',
      String,
      'Keyboard Shortcut',
      hint: 'Shortcut binding, e.g., Ctrl+N',
    ),
    Field(
      'navigateTo',
      String,
      'Navigate To',
      hint: 'Route ID (SCRTEN registry) reached after the action succeeds — '
          'when the target depends on the outcome, declare the edges in the '
          'screen route map instead',
      refersTo: ['SCRTEN.routeId'],
    ),
    Field(
      'successMessageResource',
      String,
      'Success Message',
      hint: 'Message key (MSGKR registry) for success notification',
      refersTo: ['MSGKE.key'],
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? behavior;
}

// ---------------------------------------------------------------------------
// 10.2.1.n.3 Screen States
// ---------------------------------------------------------------------------

/// 10.2.1.n.3. Screen States.
///
/// Different visual/behavioral states the screen can be in.
@StandardReferences([
  'ISO 9241-110:2020 — self-descriptiveness and use error tolerance across interface states',
  'ISO 9241-161:2016 — visual user-interface elements and their states',
], 'The set of visual and behavioral states the screen can present to the user.')
@SectionId('SCST')
class ScreenStates extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× ScreenState.
  @StandardReferences([
    'ISO 9241-110:2020 — self-descriptiveness of the available screen states',
    'ISO 9241-161:2016 — visual elements representing interface states',
  ], 'The collection of individual screen-state entries for this screen.')
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
@CodeSpecKind(
  [CodeSpecPart.viewState],
  note:
      'CE-ST — view-model / UI state (data-bound display, screen/component state).',
)
class ScreenStateEntry extends DocSpecsSection {
  @Form([
    Field(
      'stateName',
      String,
      'State Name',
      required: true,
      hint: 'Loading/Empty/Error/Permission-Denied/First-Use/Offline/Success',
    ),
    Field('description', String, 'Description', hint: 'When this state occurs'),
    Field(
      'messageResource',
      String,
      'Message Resource',
      hint: 'Message key (MSGKR registry) for state message',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'iconResource',
      String,
      'Icon Resource',
      hint: 'Resource key for state icon',
    ),
    Field(
      'illustrationResource',
      String,
      'Illustration Resource',
      hint: 'Resource key for state illustration/image',
    ),
    Field(
      'primaryActionLabel',
      String,
      'Primary Action Label',
      hint: 'Message key (MSGKR registry) for recovery action, e.g., Try Again',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'primaryActionTarget',
      String,
      'Primary Action Target',
      hint: 'Action or navigation on recovery',
    ),
    Field(
      'secondaryActionLabel',
      String,
      'Secondary Action Label',
      hint: 'Message key (MSGKR registry) for alternative action',
      refersTo: ['MSGKE.key'],
    ),
  ])
  @override
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
class ScreenUserCategoryEntry extends DocSpecsSection {
  @Form([
    Field(
      'categoryName',
      String,
      'Category Name',
      required: true,
      hint: 'The name of this user category',
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'What this user category sees/can do',
    ),
    Field(
      'contentVariations',
      String,
      'Content Variations',
      hint: 'How screen content differs for this category',
    ),
  ])
  @override
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
@CodeSpecKind([
  CodeSpecPart.navigation,
], note: 'CE-NV — navigation / routing structure.')
class EntryPointEntry extends DocSpecsSection {
  @Form([
    Field(
      'entryPoint',
      String,
      'Entry Point',
      required: true,
      hint: 'Where the user comes from',
    ),
    Field(
      'source',
      String,
      'Source',
      hint: 'Source screen, navigation item, or external link',
    ),
    Field(
      'contextPassed',
      String,
      'Context Passed',
      hint: 'Data or parameters passed from source',
    ),
  ])
  @override
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
@CodeSpecKind(
  [CodeSpecPart.layout],
  note:
      'CE-LO — screen/region layout (unblocked by csm-2-2 layout-node + dsb6 tom_flutter_ui basis).',
)
class ScreenResponsiveRuleEntry extends DocSpecsSection {
  @Form([
    Field(
      'breakpoint',
      String,
      'Breakpoint',
      required: true,
      hint: 'Mobile/Tablet/Desktop/Large-Desktop',
    ),
    Field(
      'layoutChanges',
      String,
      'Layout Changes',
      hint: 'How layout adapts, e.g., 3-col → 1-col',
    ),
    Field(
      'hiddenElements',
      String,
      'Hidden Elements',
      hint: 'Elements hidden at this breakpoint',
    ),
    Field(
      'collapsedSections',
      String,
      'Collapsed Sections',
      hint: 'Sections that collapse at this breakpoint',
    ),
    Field(
      'navigationMode',
      String,
      'Navigation Mode',
      hint: 'Sidebar/Bottom-Nav/Drawer/Hamburger',
    ),
  ])
  @override
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
class InformationArchitecture extends DocSpecsSection {
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
  @override
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
  List<DocSpecsSection> globalEntryPoints = [];

  /// 10.2.2.5. Information Architecture Diagram.
  @SerializationOrder(5)
  FlowDiagramSection architectureDiagram = FlowDiagramSection();
}

// ---------------------------------------------------------------------------
// 10.3 Screen Flow Structure
// ---------------------------------------------------------------------------

/// 10.3. Screen Flow Structure.
@StandardReferences(
  [
    'ISO 9241-151:2008 — describes the conceptual structure and navigation of a web application',
    'ISO 9241-110:2020 — conformity with user expectations keeps screen flow predictable',
  ],
  'The screen-flow structure describing how screens connect and how users move between them.',
)
@SectionId('SCFLST')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
class ScreenFlowStructure extends DocSpecsSection {
  @ContentHelp('''
## Screen Flow Structure (10.3)

Navigation model and screen flow diagrams.

### Subsections
- **10.3.1 Navigation Model** — Comprehensive navigation structure
- **10.3.2 Screen Flow Diagram** — Mermaid flowchart
- **10.3.3 Screen Route Map** — Routes, form placement, and transitions

### Tom UI Integration
Screen flow drives:
- Router configuration (go_router)
- Transition animations
- Navigation stack management
- Deep link handling
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// 10.3.1. Navigation Model.
  @SerializationOrder(1)
  NavigationModel navigationModel = NavigationModel();

  /// 10.3.2. Screen Flow Diagram (mermaid-flow).
  @SerializationOrder(2)
  FlowDiagramSection screenFlowDiagram = FlowDiagramSection();

  /// 10.3.3. Screen Route Map.
  @SerializationOrder(3)
  ScreenRouteMap screenRouteMap = ScreenRouteMap();
}

// ---------------------------------------------------------------------------
// 10.3.3 Screen Route Map
// ---------------------------------------------------------------------------

/// 10.3.3. Screen Route Map.
///
/// The screen map: which routes the application has, which form each route
/// shows, and which screen an action leads to once it has finished. It is the
/// result of combining the interaction scenarios into screens — the scenarios
/// say what a user does, this section says where each step lands.
///
/// Where the navigation model (10.3.1) describes the *menus and structures* a
/// user browses with, the route map describes the *addressable targets* those
/// structures and the screens' own actions point at, so every navigation
/// target in the specification resolves to a declared route.
@StandardReferences(
  [
    'ISO 9241-151:2008 — the conceptual structure of a web application and the addressability of its content',
    'ISO 9241-110:2020 — conformity with user expectations keeps transitions between screens predictable',
    'ISO 9241-143:2012 — form transitions and the navigation between forms in a task',
  ],
  'The registry of application routes, the placement of forms on them, and the action-triggered transitions between them.',
)
@SectionId('SCRTMP')
class ScreenRouteMap extends DocSpecsSection {
  @ContentHelp('''
## Screen Route Map (10.3.3)

The addressable screens of the application and the movement between them.

### Subsections
- **Routes** — One entry per addressable screen, each with a stable route ID
- **Form Placement** — Which form is shown on which route, and how
- **Transitions** — Which screen an action leads to, per outcome

### Why route IDs
Routes are referenced by ID, not by path. A path is presentation (and changes);
the ID is the stable handle that form placement, transitions, navigation
targets, and deep links all point at. Every navigation target elsewhere in the
specification must name a route ID declared here.
''')
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of the route map and its conventions.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× ScreenRouteEntry.
  @StandardReferences(
    [
      'ISO 9241-151:2008 — addressable content units and the conceptual structure of the application',
    ],
    'The registry of addressable application routes, each identified by a stable route ID.',
  )
  @SectionId('SCRTEN-ROUT-LST')
  @SectionIdPattern('SCRTEN-ROUT-xxx')
  @ContentHelp('Add one entry per addressable route.')
  @SerializationOrder(2)
  List<ScreenRouteEntry> routes = [];

  /// Contains 0+× FormScreenAssignmentEntry.
  @StandardReferences(
    [
      'ISO 9241-143:2012 — the presentation of forms and the context in which they are shown',
    ],
    'The assignment of forms to routes, stating which form each screen shows and whether it replaces the screen or overlays it.',
  )
  @SectionId('FMSCAS-FORM-LST')
  @SectionIdPattern('FMSCAS-FORM-xxx')
  @ContentHelp('Add one entry per form placed on a route.')
  @SerializationOrder(3)
  List<FormScreenAssignmentEntry> formPlacement = [];

  /// Contains 0+× ScreenTransitionEntry.
  @StandardReferences(
    [
      'ISO 9241-110:2020 — conformity with user expectations and self-descriptiveness of where an action leads',
      'ISO 9241-143:2012 — navigation between forms as a task progresses',
    ],
    'The action-triggered transitions between routes, with a separate target per outcome.',
  )
  @SectionId('SCTREN-TRAN-LST')
  @SectionIdPattern('SCTREN-TRAN-xxx')
  @ContentHelp(
    'Add one entry per (source route, action, outcome) — an action with '
    'different targets for success and failure needs one entry per outcome.',
  )
  @SerializationOrder(4)
  List<ScreenTransitionEntry> transitions = [];
}

/// A route entry (form).
@StandardReferences(
  [
    'ISO 9241-151:2008 — addressable content units identified independently of their presentation',
  ],
  'A single addressable route: its stable identifier, its path, its title, and the screen it renders.',
)
@SectionId('SCRTEN')
@CodeSpecKind(
  [CodeSpecPart.navigation],
  note: 'CE-NV — a route definition: the stable target of every navigation.',
)
class ScreenRouteEntry extends DocSpecsSection {
  @Form([
    Field(
      'routeId',
      String,
      'Route ID',
      required: true,
      hint: 'Stable identifier referenced by every navigation target, '
          'e.g., order-edit',
    ),
    Field(
      'routePath',
      String,
      'Route Path',
      hint: 'URL path pattern, e.g., /orders/:id/edit — presentation only, '
          'never used as a reference',
    ),
    Field(
      'routeTitle',
      String,
      'Route Title',
      hint: 'Human-readable screen title shown in the title bar and history',
    ),
    Field(
      'screenId',
      String,
      'Screen ID',
      hint: 'ID of the screen (SCREN registry) this route renders',
      refersTo: ['SCREN.screenId'],
    ),
    Field(
      'routeParameters',
      String,
      'Route Parameters',
      hint: 'Comma-separated parameter names carried by the route, '
          'e.g., orderId,mode',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A form-to-route assignment entry (form).
@StandardReferences(
  [
    'ISO 9241-143:2012 — the presentation and context of forms',
    'ISO 9241-110:2020 — controllability over whether the previous screen is kept or left',
  ],
  'A single assignment of a form to a route, including whether the form replaces the current screen or overlays it.',
)
@SectionId('FMSCAS')
@CodeSpecKind(
  [CodeSpecPart.navigation, CodeSpecPart.layout],
  note:
      'CE-NV + CE-LO — which form a route shows, and how it is put on screen.',
)
class FormScreenAssignmentEntry extends DocSpecsSection {
  @Form([
    Field(
      'formId',
      String,
      'Form ID',
      required: true,
      hint: 'ID of the form shown on this route',
    ),
    Field(
      'routeId',
      String,
      'Route ID',
      required: true,
      hint: 'Route ID (SCRTEN registry) that hosts the form',
      refersTo: ['SCRTEN.routeId'],
    ),
    Field(
      'presentationMode',
      ScreenPresentationMode,
      'Presentation Mode',
      required: true,
      hint: 'replace — the form takes over the screen; popupOverlay — the '
          'form is shown over the calling screen, which stays underneath',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A screen-transition entry (form).
@StandardReferences(
  [
    'ISO 9241-110:2020 — self-descriptiveness about where an action leads and use error tolerance when it fails',
    'ISO 9241-143:2012 — navigation between forms as a task progresses',
  ],
  'A single action-triggered transition: the screen reached from a source route when an action ends with a given outcome.',
)
@SectionId('SCTREN')
@CodeSpecKind(
  [CodeSpecPart.navigation],
  note:
      'CE-NV — a conditional navigation edge keyed by (source route, action, '
      'outcome).',
)
class ScreenTransitionEntry extends DocSpecsSection {
  @Form([
    Field(
      'sourceRouteId',
      String,
      'Source Route ID',
      required: true,
      hint: 'Route ID (SCRTEN registry) the user is on when the action runs',
      refersTo: ['SCRTEN.routeId'],
    ),
    Field(
      'actionId',
      String,
      'Action ID',
      required: true,
      hint: 'ID of the triggering action (SCRAC registry) or of the screen '
          'element that raises it',
      refersTo: ['SCRAC.actionId'],
    ),
    Field(
      'outcome',
      ScreenFlowOutcome,
      'Outcome',
      required: true,
      hint: 'success — the action completed; error — processing failed; '
          'validationError — the input was rejected',
    ),
    Field(
      'targetRouteId',
      String,
      'Target Route ID',
      required: true,
      hint: 'Route ID (SCRTEN registry) reached for this outcome — name the '
          'source route itself when the user stays put',
      refersTo: ['SCRTEN.routeId'],
    ),
    Field(
      'presentationMode',
      ScreenPresentationMode,
      'Presentation Mode',
      required: true,
      hint: 'replace — the target takes over the screen; popupOverlay — the '
          'target is shown over the source screen, which stays underneath',
    ),
    Field(
      'outcomeReference',
      String,
      'Outcome Reference',
      hint: 'For error, the system error code (SYERCOEN registry); for '
          'validationError, the validation message template (VMT registry) — '
          'empty for success',
      refersTo: ['SYERCOEN.errorCode', 'VMT.messageId'],
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.3.1 Navigation Model
// ---------------------------------------------------------------------------

/// 10.3.1. Navigation Model.
///
/// Comprehensive navigation structure: primary, secondary, utility, contextual
/// navigation, deep linking, navigation guards, and platform adaptation.
@StandardReferences(
  [
    'ISO 9241-151:2008 — describes the conceptual structure and navigation of a web application',
    'ISO 9241-110:2020 — conformity with user expectations keeps the navigation model predictable',
  ],
  'The comprehensive navigation structure covering primary, secondary, utility, and contextual navigation, deep linking, and guards.',
)
@SectionId('NAMO')
class NavigationModel extends DocSpecsSection {
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
  @override
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
@StandardReferences(
  [
    'ISO 9241-151:2008 — an overall navigation strategy shapes how users move through the application',
    'ISO 9241-110:2020 — conformity with user expectations depends on a coherent navigation approach',
  ],
  'The overall navigation strategy, routing approach, and landing-screen decisions.',
)
@SectionId('NAOV')
@CodeSpecKind([
  CodeSpecPart.navigation,
], note: 'CE-NV — navigation / routing structure.')
class NavigationOverview extends DocSpecsSection {
  @Form([
    Field(
      'navigationStrategy',
      String,
      'Navigation Strategy',
      hint: 'URL-based/State-based/Hybrid',
    ),
    Field(
      'maxNavigationDepth',
      int,
      'Max Navigation Depth',
      hint: 'Maximum levels of nesting the user encounters',
    ),
    Field(
      'defaultLandingScreen',
      String,
      'Default Landing Screen',
      hint: 'Screen ID the user sees after login',
      refersTo: ['SCREN.screenId'],
    ),
    Field(
      'unauthenticatedLanding',
      String,
      'Unauthenticated Landing',
      hint: 'Screen ID for unauthenticated users',
      refersTo: ['SCREN.screenId'],
    ),
    Field(
      'navigationPersistence',
      String,
      'Navigation Persistence',
      hint: 'Whether navigation state survives app restart: Yes/No/Partial',
    ),
    Field(
      'historyManagement',
      String,
      'History Management',
      hint: 'Browser-like-stack/Flat/Tab-specific-stacks',
    ),
    Field(
      'backBehavior',
      String,
      'Back Button Behavior',
      hint: 'System-back/In-app-back/Both',
    ),
  ])
  @override
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
@StandardReferences(
  [
    'ISO 9241-151:2008 — the navigation structure reflects the information architecture as a hierarchy',
    'ISO 9241-14:1997 — hierarchical menu structure arranges destinations into nested levels',
    'ISO 9241-13:1998 — a consistent hierarchy supports wayfinding through the application',
  ],
  'The full navigation tree of groups and items forming the application navigation structure.',
)
@SectionId('NAHI')
class NavigationHierarchy extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of the navigation hierarchy structure.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× NavigationGroup.
  @StandardReferences([
    'ISO 9241-151:2008 — navigation is organised into logical groups of related destinations',
    'ISO 9241-14:1997 — the top level of a menu hierarchy is a set of named groups',
  ], 'The collection of navigation-group entries.')
  @SectionId('NAVGRP-GROU-LST')
  @SectionIdPattern('NAVGRP-GROU-xxx')
  @ContentHelp('Add one entry per navigation group.')
  @SerializationOrder(2)
  List<NavigationGroupEntry> groups = [];
}

/// A navigation group entry (form).
///
/// Logical grouping of navigation items (e.g., "Sales", "Administration").
@StandardReferences([
  'ISO 9241-151:2008 — related destinations are organised into logical navigation groups',
  'ISO 9241-14:1997 — a menu group collects related options under a common heading',
], 'A logical grouping of related navigation items.')
@SectionId('NAVGRP')
@CodeSpecKind([
  CodeSpecPart.navigation,
], note: 'CE-NV — navigation / routing structure.')
class NavigationGroupEntry extends DocSpecsSection {
  @Form([
    Field(
      'groupId',
      String,
      'Group ID',
      required: true,
      hint: 'Unique identifier, e.g., nav-grp-sales',
    ),
    Field(
      'groupLabel',
      String,
      'Label Resource',
      required: true,
      hint: 'Message key (MSGKR registry) for display label',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'groupIcon',
      String,
      'Icon Resource',
      hint: 'Resource key for group icon',
    ),
    Field(
      'groupDescription',
      String,
      'Description Resource',
      hint: 'Message key (MSGKR registry) for tooltip/subtitle',
      refersTo: ['MSGKE.key'],
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Display and expansion behavior.
  @SectionId('NGED')
  @StandardReferences([
    'ISO 9241-14:1997 — collapsible menu groups let users manage the visible extent of the hierarchy',
    'ISO 9241-110:2020 — controllability improves when users can expand or collapse navigation groups',
  ], 'Display order and expansion behavior for a navigation group.')
  @Form([
    Field(
      'displayOrder',
      int,
      'Display Order',
      hint: 'Sort position among siblings',
    ),
    Field(
      'collapsible',
      String,
      'Collapsible',
      hint: 'Yes/No — can the group be collapsed?',
    ),
    Field(
      'initiallyExpanded',
      String,
      'Initially Expanded',
      hint: 'Yes/No — default expanded state',
    ),
    Field(
      'visibilityCondition',
      String,
      'Visibility Condition',
      hint: 'Business rule for visibility',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? display;

  /// Access-control settings.
  @SectionId('NGEA')
  @StandardReferences(
    [
      'ISO 9241-151:2008 — navigation presents only groups appropriate to the user role and context',
      'ISO 9241-110:2020 — controllability is maintained when access rules govern group visibility',
    ],
    'Access-control settings such as required roles and permission behavior for a navigation group.',
  )
  @Form([
    Field(
      'requiredRoles',
      String,
      'Required Roles',
      hint: 'Comma-separated role IDs',
    ),
    Field(
      'requiredPermissions',
      String,
      'Required Permissions',
      hint: 'Specific permissions required',
    ),
    Field(
      'permissionBehavior',
      String,
      'Permission Behavior',
      hint: 'Hide/Disable/Collapse when unauthorized',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? access;

  /// Badge and hierarchy settings.
  @SectionId('NGES')
  @StandardReferences(
    [
      'ISO 9241-14:1997 — hierarchical menu structure organises groups into nested levels',
      'ISO/IEC 25010:2023 — appropriateness recognisability is aided by aggregated badges on groups',
    ],
    'Badge aggregation and hierarchy placement settings for a navigation group.',
  )
  @Form([
    Field(
      'badgeType',
      String,
      'Badge Type',
      hint: 'None/Count/Dot/Text — aggregate from children',
    ),
    Field(
      'badgeSource',
      String,
      'Badge Source',
      hint: 'Data source for badge value',
    ),
    Field(
      'navigationLevel',
      String,
      'Navigation Level',
      hint: 'Primary/Secondary/Tertiary',
    ),
    Field(
      'parentGroupId',
      String,
      'Parent Group ID',
      hint: 'For nested groups, null = top-level',
    ),
    Field(
      'dividerBefore',
      String,
      'Divider Before',
      hint: 'Yes/No — show divider above',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? structure;

  /// Contains 0+× NavigationItem.
  @StandardReferences([
    'ISO 9241-14:1997 — a menu group lists the discrete options it contains',
    'ISO 9241-151:2008 — navigation items enumerate the destinations reachable within a group',
  ], 'The collection of navigation-item entries within a group.')
  @SectionId('NAVIIT-ITEM-LST')
  @SectionIdPattern('NAVIIT-ITEM-xxx')
  @ContentHelp('Add one entry per navigation item in this group.')
  @SerializationOrder(4)
  List<NavigationItemEntry> items = [];
}

/// A navigation item entry (form).
///
/// A single navigable destination within a group.
@StandardReferences([
  'ISO 9241-151:2008 — each navigation item represents a distinct destination in the information architecture',
  'ISO 9241-14:1997 — menu options correspond to discrete, selectable destinations',
], 'A single navigable destination within a navigation group.')
@SectionId('NAVIIT')
@CodeSpecKind([
  CodeSpecPart.navigation,
], note: 'CE-NV — navigation / routing structure.')
class NavigationItemEntry extends DocSpecsSection {
  @Form([
    Field(
      'itemId',
      String,
      'Item ID',
      required: true,
      hint: 'Unique identifier, e.g., nav-customers',
    ),
    Field(
      'label',
      String,
      'Label Resource',
      required: true,
      hint: 'Message key (MSGKR registry) for display label',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'targetRoute',
      String,
      'Target Route',
      hint: 'Route path, e.g., /customers',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Display properties: icons, labels, descriptions.
  @SectionId('NIED')
  @StandardReferences(
    [
      'ISO 9241-151:2008 — clear labels and icons help users recognise navigation destinations',
      'ISO/IEC 25010:2023 — appropriateness recognisability improves with meaningful item labels and icons',
    ],
    'Display properties such as labels, icons, and descriptions for a navigation item.',
  )
  @Form([
    Field(
      'shortLabel',
      String,
      'Short Label Resource',
      hint: 'Abbreviated label for bottom nav/compact mode',
    ),
    Field('icon', String, 'Icon Resource', hint: 'Primary icon resource key'),
    Field(
      'activeIcon',
      String,
      'Active Icon Resource',
      hint: 'Icon variant when selected (filled vs outlined)',
    ),
    Field(
      'description',
      String,
      'Description Resource',
      hint: 'Tooltip or subtitle text',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? display;

  /// Routing configuration.
  @SectionId('NIER')
  @StandardReferences(
    [
      'ISO 9241-151:2008 — routes map navigation destinations onto the underlying information architecture',
      'ISO 9241-110:2020 — conformity with user expectations depends on predictable target routing',
    ],
    'Routing configuration such as target screen, route parameters, and ordering for a navigation item.',
  )
  @Form([
    Field(
      'targetScreenId',
      String,
      'Target Screen ID',
      hint: 'Reference to Screen Inventory SCR-xxx',
    ),
    Field(
      'targetRouteParams',
      String,
      'Route Parameters',
      hint: 'Default params, e.g., {status: active}',
    ),
    Field(
      'displayOrder',
      int,
      'Display Order',
      hint: 'Position within parent group',
    ),
    Field(
      'isDefault',
      String,
      'Is Default',
      hint: 'Yes/No — default selected item in group',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? routing;

  /// Access control settings.
  @SectionId('NIEA')
  @StandardReferences(
    [
      'ISO 9241-151:2008 — navigation exposes only destinations appropriate to the user context',
      'ISO/IEC 25010:2023 — controllability is preserved when access rules govern item visibility',
    ],
    'Access-control settings such as roles, permissions, and visibility conditions for a navigation item.',
  )
  @Form([
    Field(
      'visibilityCondition',
      String,
      'Visibility Condition',
      hint: 'Business condition for visibility',
    ),
    Field(
      'enabledCondition',
      String,
      'Enabled Condition',
      hint: 'When item is visible but non-interactive',
    ),
    Field(
      'requiredRoles',
      String,
      'Required Roles',
      hint: 'Comma-separated roles',
    ),
    Field(
      'requiredPermissions',
      String,
      'Required Permissions',
      hint: 'Specific permissions',
    ),
    Field(
      'permissionBehavior',
      String,
      'Permission Behavior',
      hint: 'Hide/Disable/Show-Locked-Icon',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? access;

  /// Badge configuration.
  @SectionId('NIEB')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — self-descriptiveness is aided by badges that convey status at a glance',
      'ISO/IEC 25010:2023 — appropriateness recognisability improves when counts and indicators are visible',
    ],
    'Badge configuration such as type, source, and color for a navigation item.',
  )
  @Form([
    Field('badgeType', String, 'Badge Type', hint: 'None/Count/Dot/Text/Icon'),
    Field(
      'badgeSource',
      String,
      'Badge Source',
      hint: 'Data binding for badge, e.g., inbox.unreadCount',
    ),
    Field(
      'badgeColor',
      String,
      'Badge Color',
      hint: 'Error/Warning/Info/Success/Neutral',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? badge;

  /// Interaction settings.
  @SectionId('NIEI')
  @StandardReferences(
    [
      'ISO 9241-14:1997 — supports rapid menu selection through accelerators and shortcuts',
      'ISO/IEC 25010:2023 — operability improves when destinations respond to search and keyboard input',
    ],
    'Interaction settings such as keyboard shortcuts, search keywords, and open behavior for a navigation item.',
  )
  @Form([
    Field(
      'keyboardShortcut',
      String,
      'Keyboard Shortcut',
      hint: 'Global shortcut, e.g., Ctrl+Shift+C',
    ),
    Field(
      'searchKeywords',
      String,
      'Search Keywords',
      hint: 'Keywords for global search matching',
    ),
    Field(
      'openBehavior',
      String,
      'Open Behavior',
      hint: 'Replace/Push/New-Tab/Dialog',
    ),
    Field(
      'highlightRules',
      String,
      'Highlight Rules',
      hint: 'Routes that keep this item highlighted',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? interaction;
}

// ---------------------------------------------------------------------------
// 10.3.1.3 Primary Navigation
// ---------------------------------------------------------------------------

/// 10.3.1.3. Primary Navigation.
///
/// How the main navigation appears across platforms: drawer, sidebar, bottom nav.
@StandardReferences(
  [
    'ISO 9241-151:2008 — provides guidance on navigation and the structure of links in the interface',
    'ISO 9241-110:2020 — conformity with user expectations makes navigation predictable and consistent',
  ],
  'The primary-navigation configuration defining the top-level entry points across platforms.',
)
@SectionId('PRNA')
@CodeSpecKind([
  CodeSpecPart.navigation,
], note: 'CE-NV — navigation / routing structure.')
class PrimaryNavigation extends DocSpecsSection {
  @Form([
    Field(
      'mobilePattern',
      String,
      'Mobile Pattern',
      hint: 'Drawer/Bottom-Nav/Bottom-Nav+Drawer',
    ),
    Field(
      'tabletPattern',
      String,
      'Tablet Pattern',
      hint: 'Rail/Collapsible-Sidebar/Drawer',
    ),
    Field(
      'desktopPattern',
      String,
      'Desktop Pattern',
      hint: 'Sidebar/Sidebar-Collapsible/Top-Nav+Sidebar',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Drawer and rail behavior.
  @SectionId('PRNADR')
  @StandardReferences(
    [
      'ISO 9241-14:1997 — a menu panel presenting the top-level navigation options',
      'ISO 9241-110:2020 — controllability lets the user open and dismiss the navigation drawer',
    ],
    'The drawer and rail behavior for primary navigation, including width, header, and footer.',
  )
  @Form([
    Field(
      'drawerBehavior',
      String,
      'Drawer Behavior',
      hint: 'Modal-Overlay/Push-Content/Persistent',
    ),
    Field(
      'drawerWidth',
      String,
      'Drawer Width',
      hint: 'Width specification, e.g., 280dp/25%',
    ),
    Field(
      'drawerHeaderContent',
      String,
      'Drawer Header',
      hint: 'User-Avatar/App-Logo/User-Card/Custom',
    ),
    Field(
      'drawerFooterContent',
      String,
      'Drawer Footer',
      hint: 'Version-Info/Settings-Link/Logout/None',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? drawer;

  /// Bottom navigation rules.
  @SectionId('PNBN')
  @StandardReferences(
    [
      'ISO 9241-14:1997 — a bounded menu of top-level navigation options for the interface',
      'ISO/IEC 25010:2023 — a small, labelled option set supports operability and learnability',
    ],
    'The bottom-navigation rules limiting and styling the primary entry points on compact layouts.',
  )
  @Form([
    Field(
      'bottomNavMaxItems',
      int,
      'Bottom Nav Max Items',
      hint: 'Maximum items (Material guideline: 3-5)',
    ),
    Field(
      'bottomNavStyle',
      String,
      'Bottom Nav Style',
      hint: 'Fixed/Shifting/Labeled/Icon-Only',
    ),
    Field(
      'bottomNavShowLabels',
      String,
      'Show Labels',
      hint: 'Always/Selected-Only/Never',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? bottomNav;

  /// Sidebar sizing and selection behavior.
  @SectionId('PRNASI')
  @StandardReferences([
    'ISO 9241-14:1997 — sidebar menus present the top-level navigation options',
    'ISO 9241-110:2020 — self-descriptiveness makes the selected sidebar item clearly recognisable',
  ], 'The sidebar sizing and selected-item styling for primary navigation.')
  @Form([
    Field(
      'sidebarCollapsedWidth',
      String,
      'Collapsed Width',
      hint: 'Rail/icon width when collapsed',
    ),
    Field(
      'sidebarExpandedWidth',
      String,
      'Expanded Width',
      hint: 'Full sidebar width',
    ),
    Field(
      'selectedItemStyle',
      String,
      'Selected Item Style',
      hint: 'Background-Highlight/Indicator-Bar/Bold/Color-Change',
    ),
    Field(
      'overflowBehavior',
      String,
      'Overflow Behavior',
      hint: 'Scroll/More-Menu/Paginated',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? sidebar;

  /// Design notes and tradeoffs.
  @SerializationOrder(4)
  TextSection designNotes = TextSection();
}

// ---------------------------------------------------------------------------
// 10.3.1.4 Secondary Navigation
// ---------------------------------------------------------------------------

/// 10.3.1.4. Secondary Navigation.
///
/// In-page navigation: tab bars, segmented controls.
@StandardReferences(
  [
    'ISO 9241-151:2008 — in-page navigation links related content within a single screen',
    'ISO 9241-143:2012 — tab bars and segmented controls group selectable in-page views',
  ],
  'The secondary-navigation configuration providing in-page tab bars and segmented controls.',
)
@SectionId('SENA')
class SecondaryNavigation extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of secondary navigation patterns.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× TabBarDefinition.
  @StandardReferences(
    [
      'ISO 9241-143:2012 — grouped selectable navigation controls presented as tab bars',
    ],
    'The collection of tab-bar definitions used for in-page secondary navigation.',
  )
  @SectionId('TBDE-TABB-LST')
  @SectionIdPattern('TBDE-TABB-xxx')
  @ContentHelp('Add one entry per tab bar or segmented control.')
  @SerializationOrder(2)
  List<TabBarDefinitionEntry> tabBars = [];
}

/// A tab bar definition entry (form).
///
/// Defines a tab bar or segmented control on a specific screen.
@StandardReferences([
  'ISO 9241-143:2012 — a grouped set of selectable controls forming a tab bar',
  'ISO 9241-151:2008 — in-page navigation structures link the user to related content',
], 'A tab bar or segmented control definition bound to a specific host screen.')
@SectionId('TABADEEN')
@CodeSpecKind([
  CodeSpecPart.navigation,
], note: 'CE-NV — navigation / routing structure.')
class TabBarDefinitionEntry extends DocSpecsSection {
  @Form([
    Field(
      'tabBarId',
      String,
      'Tab Bar ID',
      required: true,
      hint: 'Unique identifier, e.g., tabs-customer-detail',
    ),
    Field(
      'tabBarName',
      String,
      'Tab Bar Name',
      required: true,
      hint: 'Human label',
    ),
    Field(
      'hostScreenId',
      String,
      'Host Screen ID',
      hint: 'Screen that contains this tab bar',
    ),
    Field(
      'tabBarStyle',
      String,
      'Style',
      hint: 'Material-Tabs/Segmented-Control/Pill-Tabs/Scrollable-Tabs',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Position and selection behavior.
  @SectionId('TBDEB')
  @StandardReferences([
    'ISO 9241-143:2012 — the arrangement and default selection of grouped tab controls',
    'ISO 9241-110:2020 — conformity with user expectations makes tab selection predictable',
  ], 'The positioning and default-selection behavior of a tab bar.')
  @Form([
    Field('tabBarPosition', String, 'Position', hint: 'Top/Bottom/Left'),
    Field(
      'isScrollable',
      String,
      'Scrollable',
      hint: 'Yes/No — scrollable when tabs exceed width',
    ),
    Field(
      'defaultTabIndex',
      int,
      'Default Tab',
      hint: 'Zero-based index of initially selected tab',
    ),
    Field(
      'persistSelection',
      String,
      'Persist Selection',
      hint: 'Yes/No — remember last selected tab',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? behavior;

  /// Visibility and loading profile.
  @SectionId('TBDEL')
  @StandardReferences(
    [
      'ISO 9241-151:2008 — controlled loading of navigation content supports responsive interaction',
      'ISO 9241-110:2020 — controllability lets the user govern how and when content is presented',
    ],
    'The visibility and loading behavior governing when and how tab content is shown.',
  )
  @Form([
    Field(
      'swipeEnabled',
      String,
      'Swipe Navigation',
      hint: 'Yes/No — swipe between tabs on mobile',
    ),
    Field(
      'lazyLoading',
      String,
      'Lazy Loading',
      hint: 'Yes/No — load tab content when first selected',
    ),
    Field(
      'visibilityCondition',
      String,
      'Visibility Condition',
      hint: 'When entire tab bar is shown',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? loading;

  /// Contains 1+× TabItem.
  @StandardReferences([
    'ISO 9241-143:2012 — a group of selectable tab entries presented within a tab bar',
  ], 'The collection of individual tab items belonging to this tab bar.')
  @SectionId('TAITEN-TABS-LST')
  @SectionIdPattern('TAITEN-TABS-xxx')
  @ContentHelp('Add one entry per tab item in the tab bar.')
  @Min(1)
  @SerializationOrder(3)
  List<TabItemEntry> tabs = [];
}

/// A tab item entry (form).
@StandardReferences(
  [
    'ISO 9241-143:2012 — a single selectable control within a grouped set of tab entries',
    'ISO 9241-13:1998 — labels and icons guide the user toward the intended content',
  ],
  'A single tab item defining its label, icon, target content, and visibility rules.',
)
@SectionId('TIE')
@CodeSpecKind([
  CodeSpecPart.navigation,
], note: 'CE-NV — navigation / routing structure.')
class TabItemEntry extends DocSpecsSection {
  @Form([
    Field(
      'tabId',
      String,
      'Tab ID',
      required: true,
      hint: 'Unique within tab bar',
    ),
    Field(
      'label',
      String,
      'Label Resource',
      required: true,
      hint: 'Message key (MSGKR registry) for tab label',
      refersTo: ['MSGKE.key'],
    ),
    Field('icon', String, 'Icon Resource', hint: 'Tab icon'),
    Field('displayOrder', int, 'Display Order', hint: 'Position in tab bar'),
    Field(
      'contentScreenId',
      String,
      'Content Screen ID',
      hint: 'Screen/fragment loaded in tab',
    ),
    Field(
      'visibilityCondition',
      String,
      'Visibility Condition',
      hint: 'Business rule for visibility',
    ),
    Field(
      'requiredPermissions',
      String,
      'Required Permissions',
      hint: 'Tab-level access control',
    ),
    Field(
      'permissionBehavior',
      String,
      'Permission Behavior',
      hint: 'Hide/Disable',
    ),
    Field('badgeType', String, 'Badge Type', hint: 'None/Count/Dot'),
    Field('badgeSource', String, 'Badge Source', hint: 'Data source for badge'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.3.1.5 Utility Navigation
// ---------------------------------------------------------------------------

/// 10.3.1.5. Utility Navigation.
///
/// Always-visible utility items: user menu, notifications, help, settings.
@StandardReferences(
  [
    'ISO 9241-14:1997 — menu dialogues describe persistent utility menus for help, settings, and account access',
    'ISO 9241-151:2008 — navigation aids provide consistent entry points to cross-cutting functions',
  ],
  'The utility-navigation configuration for always-visible entry points such as help, settings, and the user menu.',
)
@SectionId('UTNA')
class UtilityNavigation extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Contains 0+× UtilityNavigationItem.
  @StandardReferences(
    [
      'ISO 9241-14:1997 — menu dialogues cover the set of always-visible utility entry points',
      'ISO 9241-151:2008 — navigation aids give consistent access to cross-cutting functions',
    ],
    'The collection of utility navigation items shown persistently in the app bar or drawer.',
  )
  @SectionId('UNIE-ITEM-LST')
  @SectionIdPattern('UNIE-ITEM-xxx')
  @ContentHelp('Add one entry per utility navigation item.')
  @SerializationOrder(1)
  List<UtilityNavigationItemEntry> items = [];
}

/// A utility navigation item entry (form).
///
/// A persistent utility element in the app bar: user avatar, notifications bell,
/// help icon, settings.
@StandardReferences(
  [
    'ISO 9241-14:1997 — menu dialogues cover persistent utility entry points such as user and help menus',
    'ISO 9241-13:1998 — user guidance uses recognisable icons and labels for always-visible controls',
  ],
  'A single persistent utility element in the app bar, such as the user avatar or notifications bell.',
)
@SectionId('UTNAITEN')
@CodeSpecKind([
  CodeSpecPart.navigation,
], note: 'CE-NV — navigation / routing structure.')
class UtilityNavigationItemEntry extends DocSpecsSection {
  @Form([
    Field(
      'utilityId',
      String,
      'Utility ID',
      required: true,
      hint: 'e.g., util-user-menu, util-notifications',
    ),
    Field(
      'label',
      String,
      'Label Resource',
      hint: 'Display label (may be hidden)',
    ),
    Field(
      'icon',
      String,
      'Icon Resource',
      required: true,
      hint: 'Primary icon',
    ),
    Field(
      'position',
      String,
      'Position',
      hint: 'AppBar-Leading/AppBar-Trailing/Drawer-Footer',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Ordering, rendering, and access rules.
  @SectionId('UNIED')
  @StandardReferences(
    [
      'ISO 9241-14:1997 — menu dialogues address the ordering and grouping of selectable options',
      'ISO/IEC 27001:2022 — Annex A access-control measures restrict utility items to required roles',
    ],
    'The display order, presentation kind, and access rules governing a utility navigation item.',
  )
  @Form([
    Field('displayOrder', int, 'Display Order', hint: 'Sort position'),
    Field(
      'displayKind',
      String,
      'Display Kind',
      hint: 'Icon-Button/Avatar/Dropdown/Popup-Menu/Badge-Icon',
    ),
    Field(
      'visibilityCondition',
      String,
      'Visibility Condition',
      hint: 'When shown',
    ),
    Field('requiredRoles', String, 'Required Roles', hint: 'Access control'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? display;

  /// Badge and interaction behavior.
  @SectionId('UNIEB')
  @StandardReferences(
    [
      'ISO 9241-14:1997 — menu dialogues define how selecting a utility item opens a menu, drawer, or sheet',
      'ISO/IEC 25010:2023 — appropriateness recognisability lets users read status from a badge before acting',
    ],
    'The badge display and interaction behavior triggered when a utility navigation item is used.',
  )
  @Form([
    Field('badgeType', String, 'Badge Type', hint: 'None/Count/Dot'),
    Field(
      'badgeSource',
      String,
      'Badge Source',
      hint: 'Data binding for badge',
    ),
    Field(
      'interactionType',
      String,
      'Interaction Type',
      hint: 'Navigate/Open-Popup/Open-Drawer/Open-Bottom-Sheet/Open-Dialog',
    ),
    Field(
      'targetScreenId',
      String,
      'Target Screen ID',
      hint: 'Navigation target',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? behavior;

  /// Contains 0+× UtilityMenuItem.
  @StandardReferences(
    [
      'ISO 9241-14:1997 — menu dialogues structure the nested options within a utility popup or dropdown',
    ],
    'The collection of nested menu item entries belonging to a utility navigation item.',
  )
  @SectionId('UMIE-MENU-LST')
  @SectionIdPattern('UMIE-MENU-xxx')
  @ContentHelp('Add one entry per utility menu item.')
  @SerializationOrder(3)
  List<UtilityMenuItemEntry> menuItems = [];
}

/// A utility menu item entry (form).
///
/// Entry in a utility popup/dropdown menu (e.g., user menu items).
@StandardReferences(
  [
    'ISO 9241-14:1997 — menu dialogues structure selectable options within utility and popup menus',
    'ISO 9241-13:1998 — user guidance labels and icons help users recognise each option',
  ],
  'A single entry within a utility popup or dropdown menu, such as a user-menu option.',
)
@SectionId('UTMEITEN')
@CodeSpecKind([
  CodeSpecPart.navigation,
], note: 'CE-NV — navigation / routing structure.')
class UtilityMenuItemEntry extends DocSpecsSection {
  @Form([
    Field(
      'menuItemId',
      String,
      'Menu Item ID',
      required: true,
      hint: 'Unique identifier, e.g., menu-item-logout',
    ),
    Field(
      'label',
      String,
      'Label Resource',
      required: true,
      hint: 'Display text',
    ),
    Field('icon', String, 'Icon Resource', hint: 'Leading icon'),
    Field('displayOrder', int, 'Display Order', hint: 'Position in menu'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Routing and action references.
  @SectionId('UMIEA')
  @StandardReferences(
    [
      'ISO 9241-14:1997 — menu dialogues associate each option with a defined action or destination',
      'ISO 9241-151:2008 — links direct users to further interface locations in a predictable way',
    ],
    'The routing target and action reference invoked when a utility menu item is selected.',
  )
  @Form([
    Field(
      'actionType',
      String,
      'Action Type',
      hint: 'Navigate/Action/External-Link/Divider',
    ),
    Field('targetRoute', String, 'Target Route', hint: 'Navigation target'),
    Field(
      'actionId',
      String,
      'Action ID',
      hint: 'Action system reference, e.g., logout',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? action;

  /// Visibility and confirmation behavior.
  @SectionId('UMIEB')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — use-error tolerance calls for confirmation before potentially destructive actions',
      'ISO/IEC 27001:2022 — Annex A access-control measures restrict menu actions by required permissions',
    ],
    'The visibility conditions, permission checks, and confirmation behavior for a utility menu item.',
  )
  @Form([
    Field(
      'visibilityCondition',
      String,
      'Visibility Condition',
      hint: 'When shown',
    ),
    Field(
      'requiredPermissions',
      String,
      'Required Permissions',
      hint: 'Access control',
    ),
    Field(
      'isDangerous',
      String,
      'Is Dangerous',
      hint: 'Yes/No — show in danger style',
    ),
    Field(
      'confirmationRequired',
      String,
      'Confirmation Required',
      hint: 'Yes/No — show confirmation dialog',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? behavior;
}

// ---------------------------------------------------------------------------
// 10.3.1.6 Contextual Navigation
// ---------------------------------------------------------------------------

/// 10.3.1.6. Contextual Navigation.
///
/// Breadcrumbs, back navigation, related links.
@StandardReferences(
  [
    'ISO 9241-13:1998 — user guidance provides wayfinding and contextual cues for the current location',
    'ISO 9241-151:2008 — navigation and links help users orient within the information architecture',
  ],
  'The contextual-navigation configuration for breadcrumbs, back navigation, and related links.',
)
@SectionId('CONA')
@CodeSpecKind([
  CodeSpecPart.navigation,
], note: 'CE-NV — navigation / routing structure.')
class ContextualNavigation extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// 10.3.1.6.1. Breadcrumb Configuration.
  @SectionId('BRCO')
  @StandardReferences(
    [
      'ISO 9241-13:1998 — user guidance covers wayfinding cues that help users know their location',
      'ISO 9241-151:2008 — supports orientation within the information architecture through navigation aids',
    ],
    'The breadcrumb-trail configuration governing visibility, collapse behavior, and styling of location crumbs.',
  )
  @Form([
    Field(
      'enabled',
      String,
      'Enabled',
      hint: 'Yes/No — whether breadcrumbs are shown',
    ),
    Field(
      'platformVisibility',
      String,
      'Platform Visibility',
      hint: 'All/Desktop-Only/Tablet-Up',
    ),
    Field(
      'maxVisibleItems',
      int,
      'Max Visible Items',
      hint: 'Items before collapsing with ellipsis',
    ),
    Field(
      'collapseBehavior',
      String,
      'Collapse Behavior',
      hint: 'Ellipsis-Menu/Hide-Middle/Truncate',
    ),
    Field(
      'showHomeItem',
      String,
      'Show Home',
      hint: 'Yes/No — include root/home as first crumb',
    ),
    Field(
      'homeLabel',
      String,
      'Home Label Resource',
      hint: 'Message key (MSGKR registry) for home crumb',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'homeIcon',
      String,
      'Home Icon Resource',
      hint: 'Icon for home crumb',
    ),
    Field(
      'separator',
      String,
      'Separator',
      hint: 'Visual separator: / , > , chevron-icon',
    ),
    Field(
      'currentItemStyle',
      String,
      'Current Item Style',
      hint: 'Bold/Muted/Normal — style of last item',
    ),
    Field(
      'position',
      String,
      'Position',
      hint: 'Below-AppBar/Inside-Content/Top-Of-Page',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? breadcrumbs;

  /// Back navigation behavior.
  @SerializationOrder(2)
  TextSection backNavigation = TextSection();

  /// Related links behavior.
  @SerializationOrder(3)
  TextSection relatedLinks = TextSection();
}

// ---------------------------------------------------------------------------
// 10.3.1.7 Deep Linking
// ---------------------------------------------------------------------------

/// 10.3.1.7. Deep Linking.
///
/// External entry points, URL patterns, share links.
@StandardReferences(
  [
    'IETF RFC 3986 — defines the URI syntax used for external, shareable deep-link URLs',
    'ISO 9241-151:2008 — provides guidance on links and addressability in web user interfaces',
  ],
  'The deep-linking configuration for external entry points, URL patterns, and shareable links.',
)
@SectionId('DELI')
class DeepLinking extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Deep linking strategy overview.
  @SerializationOrder(1)
  TextSection strategy = TextSection();

  /// Contains 0+× DeepLinkPattern.
  @StandardReferences(
    [
      'IETF RFC 3986 — the URI syntax underpins each addressable deep-link URL pattern',
      'ISO 9241-151:2008 — supports predictable addressing of interface locations by links',
    ],
    'The collection of deep-link pattern entries defining external entry points into the application.',
  )
  @SectionId('DELNPT-PATT-LST')
  @SectionIdPattern('DELNPT-PATT-xxx')
  @ContentHelp('Add one entry per deep-link URL pattern.')
  @SerializationOrder(2)
  List<DeepLinkPatternEntry> patterns = [];
}

/// A deep link pattern entry (form).
@StandardReferences(
  [
    'IETF RFC 3986 — defines the URI syntax that deep-link patterns follow for addressable resources',
    'ISO 9241-151:2008 — supports predictable addressing of interface locations through links',
  ],
  'A single deep-link pattern mapping an external URL to a target screen with its access rules.',
)
@SectionId('DELNPT')
@CodeSpecKind([
  CodeSpecPart.navigation,
], note: 'CE-NV — navigation / routing structure.')
class DeepLinkPatternEntry extends DocSpecsSection {
  @Form([
    Field(
      'patternId',
      String,
      'Pattern ID',
      required: true,
      hint: 'Unique identifier, e.g., pattern-order-detail',
    ),
    Field(
      'urlPattern',
      String,
      'URL Pattern',
      required: true,
      hint: 'Route pattern, e.g., /orders/:orderId',
    ),
    Field('targetScreenId', String, 'Target Screen ID', hint: 'Screen to open'),
    Field(
      'description',
      String,
      'Description',
      hint: 'When/why this link is used',
    ),
    Field(
      'authenticationRequired',
      String,
      'Authentication Required',
      hint: 'Yes/No — redirect to login if unauthenticated',
    ),
    Field(
      'requiredPermissions',
      String,
      'Required Permissions',
      hint: 'Permissions needed to access via deep link',
    ),
    Field(
      'fallbackRoute',
      String,
      'Fallback Route',
      hint: 'Where to go if target is unavailable',
    ),
    Field(
      'shareEnabled',
      String,
      'Share Enabled',
      hint: 'Yes/No — can users share this link',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.3.1.8 Navigation Guards
// ---------------------------------------------------------------------------

/// 10.3.1.8. Navigation Guards.
///
/// Route guards: unsaved changes, authentication redirects, permission checks.
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — Annex A access-control measures enforce authorization before navigation proceeds',
    'ISO 9241-110:2020 — use-error tolerance protects users from losing unsaved work during transitions',
  ],
  'The navigation-guard configuration that protects routes for unsaved changes, authentication, and permissions.',
)
@SectionId('NAGU')
class NavigationGuards extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;

  /// Overview of navigation guard strategy.
  @SerializationOrder(1)
  TextSection overview = TextSection();

  /// Contains 0+× NavigationGuard.
  @StandardReferences(
    [
      'ISO/IEC 27001:2022 — Annex A access-control measures gate protected routes behind guard evaluation',
      'ISO 9241-110:2020 — controllability keeps the user in charge of transitions the guards mediate',
    ],
    'The collection of route-guard rules protecting navigation across the application.',
  )
  @SectionId('NAVGRD-GUAR-LST')
  @SectionIdPattern('NAVGRD-GUAR-xxx')
  @ContentHelp('Add one entry per navigation guard rule.')
  @SerializationOrder(2)
  List<NavigationGuardEntry> guards = [];
}

/// A navigation guard entry (form).
@StandardReferences(
  [
    'ISO/IEC 27001:2022 — Annex A access-control measures restrict navigation to authorized users and contexts',
    'ISO 9241-110:2020 — use-error tolerance guards the user against unintended or unsafe transitions',
  ],
  'A single route-guard rule that intercepts navigation for authentication, permission, or unsaved-change checks.',
)
@SectionId('NAVGRD')
@CodeSpecKind(
  [CodeSpecPart.navigation, CodeSpecPart.authorization],
  note:
      'CE-NV + CE-AZ — a route guard: navigation redirect plus an authorization / permission check.',
)
class NavigationGuardEntry extends DocSpecsSection {
  @Form([
    Field(
      'guardId',
      String,
      'Guard ID',
      required: true,
      hint: 'Unique identifier, e.g., guard-unsaved-changes',
    ),
    Field(
      'guardName',
      String,
      'Guard Name',
      required: true,
      hint: 'Human-readable name',
    ),
    Field(
      'guardType',
      String,
      'Guard Type',
      hint:
          'Unsaved-Changes/Authentication/Permission/Feature-Flag/'
          'Onboarding/Maintenance',
    ),
    Field(
      'triggerCondition',
      String,
      'Trigger Condition',
      hint: 'When this guard activates, e.g., form.isDirty',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Covered routes and dialog resources.
  @SectionId('NAGUENDI')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — use-error tolerance keeps users informed before a navigation guard discards their work',
      'ISO 9241-13:1998 — user guidance provides prompts and messages that explain the current situation',
    ],
    'The routes covered by a guard together with the dialog resources shown when it intervenes.',
  )
  @Form([
    Field(
      'appliesTo',
      String,
      'Applies To',
      hint: 'Route patterns or screen IDs this guard covers',
      refersTo: ['SCRTEN.routeId', 'SCREN.screenId'],
    ),
    Field(
      'dialogTitleResource',
      String,
      'Dialog Title Resource',
      hint: 'Message key (MSGKR registry) for confirmation dialog title',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'dialogMessageResource',
      String,
      'Dialog Message Resource',
      hint: 'Message key (MSGKR registry) for confirmation dialog message',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'confirmActionResource',
      String,
      'Confirm Action Resource',
      hint: 'Message key (MSGKR registry) for confirm button, e.g., Discard',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'cancelActionResource',
      String,
      'Cancel Action Resource',
      hint: 'Message key (MSGKR registry) for cancel button, e.g., Stay',
      refersTo: ['MSGKE.key'],
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? dialog;

  /// Redirect routing and evaluation priority.
  @SectionId('NGER')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — controllability lets users initiate and direct navigation, including redirected routes',
      'ISO/IEC 25010:2023 — operability covers how predictably guards steer the interaction flow',
    ],
    'The redirect target and evaluation priority applied when a navigation guard blocks a route.',
  )
  @Form([
    Field(
      'redirectTo',
      String,
      'Redirect To',
      hint: 'Route to redirect to if guard blocks navigation',
    ),
    Field(
      'priority',
      int,
      'Priority',
      hint: 'Execution order when multiple guards apply',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? routing;
}

// ---------------------------------------------------------------------------
// 10.4 Print Layout
// ---------------------------------------------------------------------------

/// 10.4. Print Layout.
@StandardReferences(
  [
    'ISO 216:2007 — specifies trimmed sizes of writing paper and certain classes of printed matter',
    'W3C CSS Paged Media Level 3 — describes pagination and page boxes for printed output',
    'ISO 32000-2:2020 — specifies the PDF format used as the target for server-side print output',
  ],
  'The print-layout configuration governing page setup, branding, watermarks, headers, footers and export output.',
)
@SectionId('PRLA')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@CodeSpecKind(
  [CodeSpecPart.serverConfiguration],
  note:
      'CE-CF — the environment-wide print and export settings the renderer '
      'uses: print strategy, paper size, orientation, page setup, branding, '
      'watermark, header/footer, archive policy, plus the export format, size '
      'and template catalogue. Deployment settings on the renderer, the same '
      'boundary CE-LG draws between an audit declaration and its sink '
      '(codespecs_mapping.md §5.28). The report definitions themselves are '
      'CE-RP and live in the sibling ReportDefinitions subtree.',
)
class PrintAndExportLayout extends DocSpecsSection {
  @Form([
    Field(
      'printStrategy',
      String,
      'Print Strategy',
      hint: 'Browser-native / Server-side-PDF / Hybrid / Third-party-service',
    ),
    Field(
      'defaultPaperSize',
      String,
      'Default Paper Size',
      hint: 'A4 / Letter / Legal / A3 / Custom',
    ),
    Field(
      'defaultOrientation',
      String,
      'Default Orientation',
      hint: 'Portrait / Landscape',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Page margins and setup.
  @SectionId('PLPS')
  @StandardReferences(
    [
      'ISO 216:2007 — specifies trimmed sizes of writing paper such as A4 and A3 used to define the printable page',
      'W3C CSS Paged Media Level 3 — describes page boxes and the margins that surround printed content',
    ],
    'The default page margins and setup governing the printable area of each report page.',
  )
  @Form([
    Field(
      'defaultMarginTop',
      String,
      'Default Margin Top',
      hint: 'Top margin, e.g. 20mm',
    ),
    Field(
      'defaultMarginBottom',
      String,
      'Default Margin Bottom',
      hint: 'Bottom margin, e.g. 20mm',
    ),
    Field(
      'defaultMarginLeft',
      String,
      'Default Margin Left',
      hint: 'Left margin, e.g. 15mm',
    ),
    Field(
      'defaultMarginRight',
      String,
      'Default Margin Right',
      hint: 'Right margin, e.g. 15mm',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? pageSetup;

  /// Branding configuration.
  @SectionId('PRLABR')
  @StandardReferences(
    [
      'ISO 9241-125:2017 — provides guidance on the visual presentation of information including colour and typography',
      'ISO/IEC 25010:2023 — defines appropriateness recognisability as the degree to which output suits the intended purpose',
    ],
    'The branding configuration setting logo, colours, fonts and base sizing applied to printed reports.',
  )
  @Form([
    Field(
      'brandingLogoResource',
      String,
      'Branding Logo Resource',
      hint: 'Resource key or path for company logo',
    ),
    Field(
      'brandingColorPrimary',
      String,
      'Branding Primary Color',
      hint: 'Primary brand color, e.g. #003366',
    ),
    Field(
      'brandingColorSecondary',
      String,
      'Branding Secondary Color',
      hint: 'Secondary brand color for subheadings',
    ),
    Field(
      'brandingFontFamily',
      String,
      'Branding Font Family',
      hint: 'Font family, e.g. Helvetica, Arial',
    ),
    Field(
      'brandingFontSizeBase',
      String,
      'Branding Base Font Size',
      hint: 'Base font size, e.g. 10pt',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? branding;

  /// Watermark and confidentiality.
  @SectionId('PRLAWA')
  @StandardReferences(
    [
      'W3C CSS Paged Media Level 3 — describes overlaid content and page-box decoration for printed output',
      'ISO 9241-125:2017 — provides guidance on the visual presentation of overlaid textual information',
    ],
    'The watermark and confidentiality marking applied across printed pages to signal document sensitivity.',
  )
  @Form([
    Field(
      'watermarkText',
      String,
      'Watermark Text',
      hint: 'Text watermark, e.g. DRAFT, CONFIDENTIAL',
    ),
    Field(
      'watermarkImageResource',
      String,
      'Watermark Image Resource',
      hint: 'Resource key for image watermark',
    ),
    Field(
      'watermarkOpacity',
      String,
      'Watermark Opacity',
      hint: 'Watermark opacity, e.g. 0.1',
    ),
    Field(
      'confidentialityMarking',
      String,
      'Confidentiality Marking',
      hint: 'Internal / Confidential / Public',
    ),
    Field(
      'confidentialityPosition',
      String,
      'Confidentiality Position',
      hint: 'Header / Footer / Both / Watermark',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? watermark;

  /// Header and footer settings.
  @SectionId('PLHF')
  @StandardReferences(
    [
      'W3C CSS Paged Media Level 3 — describes running headers and footers placed in the margin boxes of printed pages',
      'ISO 9241-125:2017 — provides guidance on the visual presentation of information such as page-level annotations',
    ],
    'The default header and footer content, along with date, number, currency, timezone and locale formatting for printed output.',
  )
  @Form([
    Field(
      'defaultHeaderContent',
      String,
      'Default Header Content',
      hint: 'Header template, e.g. {logo} {reportTitle} {date}',
    ),
    Field(
      'defaultFooterContent',
      String,
      'Default Footer Content',
      hint: 'Footer template, e.g. {companyName} — Page {page}/{pages}',
    ),
    Field(
      'defaultDateFormat',
      String,
      'Default Date Format',
      hint: 'Date format, e.g. dd.MM.yyyy',
    ),
    Field(
      'defaultNumberFormat',
      String,
      'Default Number Format',
      hint: 'Number format, e.g. #,##0.00',
    ),
    Field(
      'defaultCurrencyFormat',
      String,
      'Default Currency Format',
      hint: 'Currency format, e.g. €#,##0.00',
    ),
    Field(
      'defaultTimezone',
      String,
      'Default Timezone',
      hint: 'Timezone, e.g. Europe/Berlin',
    ),
    Field(
      'defaultLocale',
      String,
      'Default Locale',
      hint: 'Locale, e.g. de-DE',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? headerFooter;

  /// Archive and batch settings.
  @SectionId('PRLAAR')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26515:2018 — manages information for use produced within an agile development lifecycle',
      'ISO/IEC 25010:2023 — defines functional suitability as coverage of specified tasks and objectives',
    ],
    'The archival and batch-generation settings governing how printed reports are retained and produced in bulk.',
  )
  @Form([
    Field(
      'archivePolicy',
      String,
      'Archive Policy',
      hint: 'None / 30-days / 1-year / Permanent',
    ),
    Field(
      'reportNamingConvention',
      String,
      'Report Naming Convention',
      hint: 'File naming pattern, e.g. {reportId}_{date}_{version}',
    ),
    Field(
      'batchGenerationSupport',
      String,
      'Batch Generation Support',
      hint: 'Yes / No — support batch report generation',
    ),
    Field(
      'maxConcurrentReports',
      int,
      'Max Concurrent Reports',
      hint: 'Maximum concurrent reports',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? archive;

  /// 10.4.1. Export Formats — contains 0+× Export Format.
  @StandardReferences(
    [
      'ISO 32000-2:2020 — specifies the PDF format frequently offered as a report export option',
      'ISO/IEC 25010:2023 — defines functional suitability including coverage of specified output tasks',
    ],
    'The collection of export formats in which printed reports can be produced.',
  )
  @SectionId('EXFOEN-EXPO-LST')
  @SectionIdPattern('EXFOEN-EXPO-xxx')
  @ContentHelp('Add one entry per export format.')
  @SerializationOrder(6)
  List<ExportFormatEntry> exportFormats = [];

  /// 10.4.2. Export Templates — contains 0+× Export
  /// Template.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26514:2022 — designs and develops the layout of report information for use',
      'ISO 32000-2:2020 — specifies the PDF document format used as an export target for printed output',
    ],
    'The collection of reusable export templates available for producing formatted output.',
  )
  @SectionId('EXTEEN-EXPO-LST')
  @SectionIdPattern('EXTEEN-EXPO-xxx')
  @ContentHelp('Add one entry per export template.')
  @SerializationOrder(7)
  List<ExportTemplateEntry> exportTemplates = [];
}

// ---------------------------------------------------------------------------
// 10.2.1 Reports
// ---------------------------------------------------------------------------

/// A report entry (form).
@StandardReferences(
  [
    'ISO/IEC/IEEE 26514:2022 — designs and develops information for use as a report',
    'ISO 9241-125:2017 — presentation of information organises the report layout',
  ],
  'A single report definition describing its data source layout sections and output.',
)
@SectionId('REPENT')
@CodeSpecKind(
  [CodeSpecPart.reporting],
  note:
      'CE-RP — a grouped projection over the domain model. Active (codespecs_mapping.md §4.1): '
      '@CsReport with @CsReportColumn / @CsReportChart / @CsReportParameter; '
      'server (definition + execution) + shared (result envelope, parameter '
      'shapes). All three delivery channels (apiResponse | email | '
      'fileExport) are reused tom_core_server transports; a named schedule is '
      'realised as a CE-JB job and email delivery resolves through CE-NT '
      '(codespecs_mapping.md §5.28).',
)
class ReportEntry extends DocSpecsSection {
  @Form([
    Field(
      'reportId',
      String,
      'Report ID',
      hint: 'Unique identifier, e.g. RPT-001',
      required: true,
    ),
    Field(
      'reportName',
      String,
      'Report Name',
      hint: 'Human-readable report title',
      required: true,
    ),
    Field(
      'reportType',
      String,
      'Report Type',
      hint: 'Tabular / Summary / Dashboard / KPI-Card / Chart-Only / Mixed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Identity and context.
  @SectionId('REID')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26514:2022 — identifies and describes information for use as a report',
      'ISO/IEC/IEEE 29148:2018 — traces the report to the requirements it satisfies',
    ],
    'Identity and context describing the report purpose category and related references.',
  )
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'Business purpose and summary of the report',
    ),
    Field(
      'reportCategory',
      String,
      'Report Category',
      hint: 'Operational / Analytical / Compliance / Financial / Audit',
    ),
    Field(
      'relatedUseCases',
      String,
      'Related Use Cases',
      hint: 'ISC references this report serves',
    ),
    Field(
      'relatedBusinessProcesses',
      String,
      'Related Business Processes',
      hint: 'TOM references where this report is used',
    ),
    Field(
      'relatedDataEntities',
      String,
      'Related Data Entities',
      hint: 'IFM entity references used as data sources',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identity;

  /// Data source configuration.
  @SectionId('REDASO')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148:2018 — specifies the data-source requirements feeding the report',
      'ISO/IEC 25010:2023 — functional suitability ties report output to its source data',
    ],
    'Data source configuration covering source scope currency and generation trigger.',
  )
  @Form([
    Field(
      'dataSource',
      String,
      'Data Source',
      hint: 'Primary data source or query reference',
    ),
    Field(
      'dataScope',
      String,
      'Data Scope',
      hint: 'What data is included, e.g. All orders for current fiscal year',
    ),
    Field(
      'dataCurrency',
      String,
      'Data Currency',
      hint: 'Real-time / Near-real-time / Daily-snapshot / As-of-date',
    ),
    Field(
      'generationTrigger',
      String,
      'Generation Trigger',
      hint: 'On-demand / Scheduled / Event-triggered / Batch',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? dataSource;

  /// Output format options.
  @SectionId('REFO')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26515:2018 — produces information for use in multiple output formats',
      'ISO 216 — standard paper sizes govern the page size of rendered output',
    ],
    'Output format options covering file format interactivity page size and orientation.',
  )
  @Form([
    Field(
      'format',
      String,
      'Output Format',
      hint: 'PDF / Excel / CSV / HTML / Word / Print / Multi-format',
    ),
    Field(
      'interactivity',
      String,
      'Interactivity',
      hint: 'Static / Interactive / Drill-down / Parameterized',
    ),
    Field(
      'pageSize',
      String,
      'Page Size',
      hint: 'Override: A4 / Letter / Legal / A3 / Custom',
    ),
    Field(
      'orientation',
      String,
      'Orientation',
      hint: 'Override: Portrait / Landscape / Auto',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? format;

  /// Page layout settings.
  @SectionId('RELA')
  @StandardReferences(
    [
      'ISO 216 — standard paper sizes constrain report page dimensions and margins',
      'W3C CSS Paged Media — sets page margin boxes for printed output',
    ],
    'Page layout settings covering top bottom left and right margins of the report.',
  )
  @Form([
    Field('marginTop', String, 'Margin Top', hint: 'Override top margin'),
    Field(
      'marginBottom',
      String,
      'Margin Bottom',
      hint: 'Override bottom margin',
    ),
    Field('marginLeft', String, 'Margin Left', hint: 'Override left margin'),
    Field('marginRight', String, 'Margin Right', hint: 'Override right margin'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? layout;

  /// Header and footer templates.
  @SectionId('REHEFO')
  @StandardReferences([
    'W3C CSS Paged Media — defines page header and footer margin content',
    'ISO/IEC/IEEE 26514:2022 — designs recurring page elements for information for use',
  ], 'Header footer and cover-page templates applied to each report page.')
  @Form([
    Field(
      'headerTemplate',
      String,
      'Header Template',
      hint: 'Page header override, e.g. {logo} {reportTitle}',
    ),
    Field(
      'footerTemplate',
      String,
      'Footer Template',
      hint: 'Page footer override',
    ),
    Field(
      'coverPage',
      String,
      'Cover Page',
      hint: 'Yes / No — include a cover page',
    ),
    Field(
      'coverPageTemplate',
      String,
      'Cover Page Template',
      hint: 'Cover page content template',
    ),
    Field(
      'tableOfContents',
      String,
      'Table of Contents',
      hint: 'Yes / No — include TOC for multi-section reports',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? headerFooter;

  /// Sorting and grouping.
  @SectionId('REGR')
  @StandardReferences(
    [
      'ISO 9241-125:2017 — presentation of information groups related content for comprehension',
      'ISO 9241-112:2017 — presentation of tabular data orders and aggregates rows',
    ],
    'Sorting and grouping settings covering default order group-by and subtotal display.',
  )
  @Form([
    Field(
      'defaultSortField',
      String,
      'Default Sort Field',
      hint: 'Default sort column or field',
    ),
    Field(
      'defaultSortDirection',
      String,
      'Default Sort Direction',
      hint: 'Ascending / Descending',
    ),
    Field(
      'defaultGroupBy',
      String,
      'Default Group By',
      hint: 'Default grouping field',
    ),
    Field(
      'groupSummary',
      String,
      'Group Summary',
      hint: 'Yes / No — show subtotals per group',
    ),
    Field(
      'grandTotal',
      String,
      'Grand Total',
      hint: 'Yes / No — show grand total row',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? grouping;

  /// Conditional formatting.
  @SectionId('RF')
  @StandardReferences([
    'ISO 9241-125:2017 — presentation of information uses visual coding to emphasise content',
    'ISO 9241-112:2017 — presentation of tabular data highlights values by condition',
  ], 'Conditional formatting rules governing highlighting of report values.')
  @Form([
    Field(
      'conditionalFormatting',
      String,
      'Conditional Formatting',
      hint: 'Description of conditional formatting rules',
    ),
    Field(
      'highlightRules',
      String,
      'Highlight Rules',
      hint: 'Row/cell highlight rules, e.g. overdue items in red',
    ),
  ])
  @SerializationOrder(7)
  DocSpecsSection? formatting;

  /// Interactivity and parameters.
  @SectionId('REIN')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — appropriateness recognisability supports interactive report navigation',
      'ISO 9241-125:2017 — presentation of information enables drill-down exploration of content',
    ],
    'Interactivity settings covering drill-down targets parameter forms and empty-data handling.',
  )
  @Form([
    Field(
      'drillDownTarget',
      String,
      'Drill-Down Target',
      hint: 'Report or screen navigated to on row click',
    ),
    Field(
      'drillThroughReports',
      String,
      'Drill-Through Reports',
      hint: 'Comma-separated report IDs reachable from this report',
    ),
    Field(
      'parameterForm',
      String,
      'Parameter Form',
      hint: 'Description of user input form shown before generation',
    ),
    Field(
      'emptyDataMessage',
      String,
      'Empty Data Message',
      hint: 'Message to display when report has no data',
    ),
  ])
  @SerializationOrder(8)
  DocSpecsSection? interactivity;

  /// Pagination settings.
  @SectionId('REPA')
  @StandardReferences(
    [
      'W3C CSS Paged Media — controls page breaks and pagination of rendered content',
      'ISO 216 — standard paper sizes frame the pagination of printed reports',
    ],
    'Pagination settings covering row limits page-break style and rows per page.',
  )
  @Form([
    Field(
      'maxRows',
      int,
      'Maximum Rows',
      hint: 'Row limit for performance; 0 = unlimited',
    ),
    Field(
      'paginationStyle',
      String,
      'Pagination Style',
      hint: 'Page-break / Continuous / Scrollable',
    ),
    Field(
      'rowsPerPage',
      int,
      'Rows Per Page',
      hint: 'For paginated tabular reports',
    ),
  ])
  @SerializationOrder(9)
  DocSpecsSection? pagination;

  /// Security and access.
  @SectionId('RESE')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — confidentiality restricts report access to authorised parties',
      'ISO/IEC/IEEE 29148:2018 — captures data-access requirements for reported information',
    ],
    'Security settings covering access levels roles and data-level restrictions for the report.',
  )
  @Form([
    Field(
      'localization',
      String,
      'Localization',
      hint: 'Locales supported, e.g. de-DE, en-US, fr-FR',
    ),
    Field(
      'brandingOverride',
      String,
      'Branding Override',
      hint: 'Override branding for this report',
    ),
    Field(
      'accessLevel',
      String,
      'Access Level',
      hint: 'Public / Authenticated / Role-specific / Confidential',
    ),
    Field(
      'requiredRoles',
      String,
      'Required Roles',
      hint: 'Roles permitted to generate this report',
    ),
    Field(
      'dataLevelSecurity',
      String,
      'Data-Level Security',
      hint: 'Row/column level security rules',
    ),
  ])
  @SerializationOrder(10)
  DocSpecsSection? security;

  /// Lifecycle and archiving.
  @SectionId('RELI')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26515:2018 — governs retention and management of produced information',
      'ISO/IEC 25010:2023 — functional suitability supports controlled report distribution',
    ],
    'Lifecycle settings covering retention signature approval and archiving of the report.',
  )
  @Form([
    Field(
      'archiveRetention',
      String,
      'Archive Retention',
      hint: 'Retention policy for generated instances, e.g. 90 days',
    ),
    Field(
      'signatureRequired',
      String,
      'Signature Required',
      hint: 'Yes / No — does the report require a digital signature',
    ),
    Field(
      'approvalWorkflow',
      String,
      'Approval Workflow',
      hint: 'Approval steps before distribution, if any',
    ),
    Field(
      'notes',
      String,
      'Notes',
      hint: 'Additional design notes or open questions',
    ),
  ])
  @SerializationOrder(11)
  DocSpecsSection? lifecycle;

  /// Contains 0+× Report Section.
  @StandardReferences(
    [
      'ISO 9241-125:2017 — presentation of information groups related content in sections',
      'ISO/IEC/IEEE 26514:2022 — structures information for use into identifiable units',
    ],
    'The collection of report-section entries composing the body of the report.',
  )
  @SectionId('RESEE1-SECT-LST')
  @SectionIdPattern('RESEE1-SECT-xxx')
  @ContentHelp('Add one entry per report section.')
  @SerializationOrder(12)
  List<ReportSectionEntry> sections = [];

  /// Contains 0+× Report Filter.
  @StandardReferences([
    'ISO/IEC/IEEE 29148:2018 — captures the filter criteria constraining reported data',
  ], 'The collection of filters that restrict the data included in the report.')
  @SectionId('REFIEN-FILT-LST')
  @SectionIdPattern('REFIEN-FILT-xxx')
  @ContentHelp('Add one entry per report data filter.')
  @SerializationOrder(13)
  List<ReportFilterEntry> filters = [];

  /// Contains 0+× Report Schedule.
  @StandardReferences(
    [
      'ISO 8601-1:2019 — expresses the dates and times at which the report is generated',
      'ISO/IEC 25010:2023 — functional suitability supports scheduled report production',
    ],
    'The collection of schedules controlling automated generation of the report.',
  )
  @SectionId('RESCEN-SCHE-LST')
  @SectionIdPattern('RESCEN-SCHE-xxx')
  @ContentHelp('Add one entry per report generation schedule.')
  @SerializationOrder(14)
  List<ReportScheduleEntry> schedules = [];

  /// Contains 0+× Report Distribution.
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26515:2018 — governs delivery of produced information to its audience',
    ],
    'The collection of distribution channels through which the report is delivered.',
  )
  @SectionId('REDIEN-DIST-LST')
  @SectionIdPattern('REDIEN-DIST-xxx')
  @ContentHelp('Add one entry per report distribution channel.')
  @SerializationOrder(15)
  List<ReportDistributionEntry> distributions = [];

  /// Contains 0+× Recipient.
  @StandardReferences([
    'ISO/IEC/IEEE 26515:2018 — identifies the audience receiving produced information',
  ], 'The collection of recipients who receive the generated report.')
  @SectionId('REREEN-RECI-LST')
  @SectionIdPattern('REREEN-RECI-xxx')
  @ContentHelp('Add one entry per report recipient.')
  @SerializationOrder(16)
  List<ReportRecipientEntry> recipients = [];
}

/// A section within a report (form).
@StandardReferences(
  [
    'ISO 9241-125:2017 — presentation of information groups related content into sections',
    'ISO/IEC/IEEE 26514:2022 — structures information for use into identifiable units',
  ],
  'A single section within a report describing its data layout sorting and content.',
)
@SectionId('RSE')
@CodeSpecKind(
  [CodeSpecPart.reporting],
  note:
      'CE-RP — a grouped projection over the domain model. Active (codespecs_mapping.md §4.1): '
      '@CsReport with @CsReportColumn / @CsReportChart / @CsReportParameter; '
      'server (definition + execution) + shared (result envelope, parameter '
      'shapes). All three delivery channels (apiResponse | email | '
      'fileExport) are reused tom_core_server transports; a named schedule is '
      'realised as a CE-JB job and email delivery resolves through CE-NT '
      '(codespecs_mapping.md §5.28).',
)
class ReportSectionEntry extends DocSpecsSection {
  @Form([
    Field(
      'sectionId',
      String,
      'Section ID',
      hint: 'Unique within report, e.g. SEC-01',
      required: true,
    ),
    Field(
      'title',
      String,
      'Title',
      hint: 'Section heading displayed in the report',
      required: true,
    ),
    Field(
      'sectionType',
      String,
      'Section Type',
      hint: 'Table / Chart / Summary / Text / KPI-Card / Mixed',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Data source configuration.
  @SectionId('RESEDA')
  @StandardReferences([
    'ISO 9241-112:2017 — presentation of information relates displayed content to its data source',
    'ISO/IEC 25010:2023 — functional suitability requires the section data source to be defined',
  ], 'Data source and scope configuration for a report section.')
  @Form([
    Field('purpose', String, 'Purpose', hint: 'What this section communicates'),
    Field(
      'dataSource',
      String,
      'Data Source',
      hint: 'Data source or query for this section',
    ),
    Field(
      'dataScope',
      String,
      'Data Scope',
      hint: 'Scope filter applied to the section data',
    ),
    Field(
      'textContent',
      String,
      'Text Content',
      hint: 'Static text or template for text-type sections',
    ),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? data;

  /// Layout and page settings.
  @SectionId('RESELA')
  @StandardReferences(
    [
      'ISO 9241-125:2017 — visual presentation of information governs page layout and grouping',
    ],
    'Layout and page settings for a report section such as page breaks and orientation.',
  )
  @Form([
    Field(
      'displayOrder',
      int,
      'Display Order',
      hint: 'Position within the report',
    ),
    Field(
      'pageBreakBefore',
      String,
      'Page Break Before',
      hint: 'Yes / No — force page break before this section',
    ),
    Field(
      'pageBreakAfter',
      String,
      'Page Break After',
      hint: 'Yes / No — force page break after this section',
    ),
    Field(
      'repeatOnNewPage',
      String,
      'Repeat on New Page',
      hint: 'Yes / No — repeat section header on each new page',
    ),
    Field(
      'orientation',
      String,
      'Orientation',
      hint: 'Override: Portrait / Landscape',
    ),
    Field(
      'conditionalVisibility',
      String,
      'Conditional Visibility',
      hint: 'Condition when section is shown',
    ),
    Field(
      'backgroundColor',
      String,
      'Background Color',
      hint: 'Background color or shading',
    ),
    Field(
      'borderStyle',
      String,
      'Border Style',
      hint: 'None / Thin / Medium / Thick / Custom',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? layout;

  /// Sorting and grouping.
  @SectionId('RESESO')
  @StandardReferences(
    [
      'ISO 9241-125:2017 — visual presentation of information supports grouping of related data',
      'ISO/IEC 25010:2023 — functional suitability supports sorting and grouping of section rows',
    ],
    'Sorting and grouping settings for a report section such as sort field and group subtotals.',
  )
  @Form([
    Field(
      'sortField',
      String,
      'Sort Field',
      hint: 'Default sort for this section data',
    ),
    Field(
      'sortDirection',
      String,
      'Sort Direction',
      hint: 'Ascending / Descending',
    ),
    Field(
      'groupByField',
      String,
      'Group By Field',
      hint: 'Field used for grouping rows',
    ),
    Field(
      'showGroupSubtotals',
      String,
      'Show Group Subtotals',
      hint: 'Yes / No',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? sorting;

  /// Aggregation and limits.
  @SectionId('RESEAG')
  @StandardReferences(
    [
      'ISO 80000-1:2022 — general principles for quantities units and their symbols',
      'ISO/IEC 25010:2023 — functional suitability supports section totals and row limits',
    ],
    'Aggregation and row-limit settings for a report section such as totals and overflow behaviour.',
  )
  @Form([
    Field(
      'showSectionTotal',
      String,
      'Show Section Total',
      hint: 'Yes / No — show totals row at section end',
    ),
    Field(
      'aggregationFields',
      String,
      'Aggregation Fields',
      hint: 'Comma-separated fields with aggregation',
    ),
    Field(
      'maxRows',
      int,
      'Max Rows',
      hint: 'Row limit for this section; 0 = unlimited',
    ),
    Field(
      'overflowBehavior',
      String,
      'Overflow Behavior',
      hint: 'Truncate / Continue-next-page / Scroll',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? aggregation;

  /// Contains 0+× Report Column.
  @StandardReferences(
    [
      'ISO 9241-112:2017 — presentation of information organises tabular data into columns',
    ],
    'The collection of column entries defining the tabular layout of this report section.',
  )
  @SectionId('RECOE1-COLU-LST')
  @SectionIdPattern('RECOE1-COLU-xxx')
  @ContentHelp('Add one entry per column in the section table.')
  @SerializationOrder(5)
  List<ReportColumnEntry> columns = [];

  /// Contains 0+× Report Chart.
  @StandardReferences([
    'ISO 9241-125:2017 — presentation of information conveys quantitative data through graphical form',
  ], 'The collection of chart entries rendered within this report section.')
  @SectionId('RECHEN-CHAR-LST')
  @SectionIdPattern('RECHEN-CHAR-xxx')
  @ContentHelp('Add one entry per chart shown in the section.')
  @SerializationOrder(6)
  List<ReportChartEntry> charts = [];
}

/// A column in a tabular report section
/// (form).
@StandardReferences([
  'ISO 9241-112:2017 — presentation of information organises data into tabular columns',
  'ISO 9241-13:1998 — user guidance covers column header labels',
], 'A single column definition within a tabular report section.')
@SectionId('REPCOLENT')
@OneOf(
  discriminator: 'dataType',
  note:
      'Report-column value-type closed choice (csra4): the column data type '
      'selects its promoted formatting subsection (numeric / currency / date / '
      'boolean / text), so a Date column no longer carries booleanTrueDisplay '
      'and an Integer column no longer carries currencyCode.',
)
@CodeSpecKind(
  [CodeSpecPart.reporting],
  note:
      'CE-RP — a grouped projection over the domain model. Active (codespecs_mapping.md §4.1): '
      '@CsReport with @CsReportColumn / @CsReportChart / @CsReportParameter; '
      'server (definition + execution) + shared (result envelope, parameter '
      'shapes). All three delivery channels (apiResponse | email | '
      'fileExport) are reused tom_core_server transports; a named schedule is '
      'realised as a CE-JB job and email delivery resolves through CE-NT '
      '(codespecs_mapping.md §5.28).',
)
class ReportColumnEntry extends DocSpecsSection {
  @Form([
    Field(
      'columnId',
      String,
      'Column ID',
      hint: 'Unique within section, e.g. COL-01',
      required: true,
    ),
    Field(
      'columnName',
      String,
      'Column Name',
      hint: 'Internal field reference',
      required: true,
    ),
    Field(
      'displayLabel',
      String,
      'Display Label',
      hint: 'Column header text shown in report',
      required: true,
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Data source and type.
  @SectionId('RCDS')
  @StandardReferences([
    'ISO 9241-112:2017 — presentation of information relates displayed data to its source field',
    'ISO/IEC 25010:2023 — functional suitability requires the column value data type to be defined',
  ], 'Data source field and data type binding for a report column.')
  @Form([
    Field(
      'dataSourceField',
      String,
      'Data Source Field',
      hint: 'Path to the data field, e.g. order.customer.name',
    ),
    Field(
      'dataType',
      ReportColumnKind,
      'Data Type',
      hint: 'The column value type — selects the promoted format subsection.',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? dataSource;

  /// Display formatting.
  @SectionId('RECOFO')
  @StandardReferences(
    [
      'ISO 9241-125:2017 — visual presentation of information governs width alignment and formatting',
      'ISO 80000-1:2022 — general principles for quantities units and their symbols',
    ],
    'Display formatting settings for a report column such as width, alignment and value formats.',
  )
  @Form([
    Field(
      'displayOrder',
      int,
      'Display Order',
      hint: 'Column position left to right',
    ),
    Field(
      'width',
      String,
      'Width',
      hint: 'Auto / Fixed(120px) / Proportion(25%)',
    ),
    Field('alignment', String, 'Alignment', hint: 'Left / Center / Right'),
    Field(
      'verticalAlignment',
      String,
      'Vertical Alignment',
      hint: 'Top / Middle / Bottom',
    ),
    Field(
      'nullDisplay',
      String,
      'Null Display',
      hint: 'What to show for null/empty values',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? formatting;

  /// Numeric-kind column format — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for integer and decimal columns; carries only the numeric
  /// display pattern (no currency code, no boolean labels).
  @SectionId('RECOFN')
  @StandardReferences([
    'ISO 80000-1:2022 — general principles for quantities units and their symbols',
    'ISO 31-0 — presentation of numbers including grouping and decimal marks',
  ], 'The numeric display pattern for an integer or decimal report column.')
  @Case(ReportColumnKind.integer)
  @Case(ReportColumnKind.decimal)
  @Form([
    Field(
      'formatPattern',
      String,
      'Format Pattern',
      hint: 'Numeric display format, e.g. #,##0.00',
    ),
    Field(
      'negativeDisplay',
      String,
      'Negative Display',
      hint: 'Minus-Sign / Parentheses / Red',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? numericFormat;

  /// Currency-kind column format — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for currency columns; this is the only case in which a
  /// currency code is meaningful.
  @SectionId('RECOFC')
  @StandardReferences([
    'ISO 4217:2015 — codes for the representation of currencies',
    'ISO 80000-1:2022 — general principles for quantities units and their symbols',
  ], 'The currency code and monetary display pattern for a currency report column.')
  @Case(ReportColumnKind.currency)
  @Form([
    Field(
      'formatPattern',
      String,
      'Format Pattern',
      hint: 'Monetary display format, e.g. #,##0.00',
    ),
    Field(
      'currencyCode',
      String,
      'Currency Code',
      hint: 'ISO 4217 code, e.g. EUR / USD',
    ),
    Field(
      'symbolPosition',
      String,
      'Symbol Position',
      hint: 'Prefix / Suffix / None',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? currencyFormat;

  /// Date-kind column format — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for date columns; carries only the temporal display pattern.
  @SectionId('RECOFD')
  @StandardReferences([
    'ISO 8601-1:2019 — representation of dates and times',
    'ISO 9241-112:2017 — presentation of information for temporal values',
  ], 'The temporal display pattern for a date report column.')
  @Case(ReportColumnKind.date)
  @Form([
    Field(
      'formatPattern',
      String,
      'Format Pattern',
      hint: 'Date display format, e.g. yyyy-MM-dd',
    ),
    Field(
      'timezoneDisplay',
      String,
      'Timezone Display',
      hint: 'UTC / Local / With-Offset',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? dateFormat;

  /// Boolean-kind column format — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for boolean columns; this is the only case in which the
  /// true/false display labels are meaningful.
  @SectionId('RECOFB')
  @StandardReferences([
    'ISO 9241-112:2017 — presentation of information for two-valued indicators',
  ], 'The true and false display labels for a boolean report column.')
  @Case(ReportColumnKind.boolean)
  @Form([
    Field(
      'booleanTrueDisplay',
      String,
      'Boolean True Display',
      hint: 'Display for true, e.g. Yes / ✓',
    ),
    Field(
      'booleanFalseDisplay',
      String,
      'Boolean False Display',
      hint: 'Display for false, e.g. No / —',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? booleanFormat;

  /// Text-kind column format — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for text columns; carries only the overflow handling a
  /// variable-length string column needs.
  @SectionId('RECOFT')
  @StandardReferences([
    'ISO 9241-112:2017 — presentation of information governs truncation and wrapping of text',
  ], 'The overflow handling for a text report column.')
  @Case(ReportColumnKind.string)
  @Form([
    Field(
      'overflowBehavior',
      String,
      'Overflow Behavior',
      hint: 'Truncate / Ellipsis / Wrap / Clip',
    ),
    Field(
      'maxDisplayLength',
      int,
      'Max Display Length',
      hint: 'Character limit before overflow handling applies',
    ),
  ])
  @SerializationOrder(7)
  DocSpecsSection? textFormat;

  /// Aggregation settings.
  @SectionId('RECOAG')
  @StandardReferences(
    [
      'ISO 80000-1:2022 — general principles for quantities units and their symbols',
      'ISO/IEC 25010:2023 — functional suitability supports summing and averaging of column values',
    ],
    'Aggregation settings for a report column such as sum, average and conditional formatting.',
  )
  @Form([
    Field(
      'aggregation',
      String,
      'Aggregation',
      hint: 'None / Sum / Average / Count / Min / Max',
    ),
    Field(
      'aggregationLabel',
      String,
      'Aggregation Label',
      hint: 'Custom label for the aggregation row',
    ),
    Field(
      'conditionalFormattingRules',
      String,
      'Conditional Formatting Rules',
      hint: 'Rules for value-based formatting',
    ),
    Field(
      'hyperlinkTarget',
      String,
      'Hyperlink Target',
      hint: 'Make column values clickable',
    ),
  ])
  @SerializationOrder(8)
  DocSpecsSection? aggregation;

  /// Interaction options.
  @SectionId('RECOIN')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — functional suitability supports sorting and filtering by a column',
    ],
    'Interaction options for a report column such as sortable and filterable behaviour.',
  )
  @Form([
    Field(
      'sortable',
      String,
      'Sortable',
      hint: 'Yes / No — can user sort by this column',
    ),
    Field(
      'filterable',
      String,
      'Filterable',
      hint: 'Yes / No — can user filter by this column',
    ),
  ])
  @SerializationOrder(9)
  DocSpecsSection? interaction;

  /// Visibility and layout.
  @SectionId('RECOLA')
  @StandardReferences(
    [
      'ISO 9241-125:2017 — visual presentation of information governs column visibility and layout',
    ],
    'Visibility and layout settings for a report column such as word wrap and truncation.',
  )
  @Form([
    Field('visible', String, 'Visible', hint: 'Yes / No / Conditional'),
    Field(
      'visibilityCondition',
      String,
      'Visibility Condition',
      hint: 'When this column is shown',
    ),
    Field('wordWrap', String, 'Word Wrap', hint: 'Yes / No — wrap long text'),
    Field(
      'truncateAt',
      int,
      'Truncate At',
      hint: 'Character limit before truncation',
    ),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(10)
  DocSpecsSection? layout;
}

/// A chart/visualization in a report
/// (form).
@StandardReferences([
  'ISO 9241-125:2017 — visual presentation of information guides layout of a chart',
  'ISO/IEC 25010:2023 — appropriateness recognisability supports comprehension of charts',
], 'A single chart definition describing how report data is visualised.')
@SectionId('REPCHAENT')
@CodeSpecKind(
  [CodeSpecPart.reporting],
  note:
      'CE-RP — a grouped projection over the domain model. Active (codespecs_mapping.md §4.1): '
      '@CsReport with @CsReportColumn / @CsReportChart / @CsReportParameter; '
      'server (definition + execution) + shared (result envelope, parameter '
      'shapes). All three delivery channels (apiResponse | email | '
      'fileExport) are reused tom_core_server transports; a named schedule is '
      'realised as a CE-JB job and email delivery resolves through CE-NT '
      '(codespecs_mapping.md §5.28).',
)
class ReportChartEntry extends DocSpecsSection {
  @Form([
    Field(
      'chartId',
      String,
      'Chart ID',
      hint: 'Unique within section, e.g. CHT-01',
      required: true,
    ),
    Field('title', String, 'Title', hint: 'Chart title', required: true),
    Field(
      'chartType',
      String,
      'Chart Type',
      hint: 'Bar / Line / Pie / Donut / Scatter / Gauge / Heatmap',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Axes configuration.
  @StandardReferences([
    'ISO 9241-112:2017 — presentation of information organises displayed data along axes',
  ], 'The collection of axis configurations for the chart.')
  @SectionId('RECHAX-AXES-LST')
  @SectionIdPattern('RECHAX-AXES-xxx')
  @ContentHelp('Add one entry per chart axis configuration.')
  @SerializationOrder(1)
  List<ReportChartAxes> axes = [];

  /// Series and colors.
  @SectionId('RECHSE')
  @StandardReferences(
    [
      'W3C WCAG 2.2 — do not use colour as the only visual means of conveying information',
      'ISO 9241-13:1998 — user guidance covers legends and their placement',
    ],
    'Series, colour and legend settings that split chart data into distinguishable groups.',
  )
  @Form([
    Field(
      'seriesField',
      String,
      'Series Field',
      hint: 'Field used to split data into series',
    ),
    Field(
      'seriesColors',
      String,
      'Series Colors',
      hint: 'Comma-separated color assignments',
    ),
    Field(
      'colorScheme',
      String,
      'Color Scheme',
      hint: 'Named palette, e.g. Corporate / Pastel / Sequential-Blue',
    ),
    Field(
      'legendPosition',
      String,
      'Legend Position',
      hint: 'Top / Bottom / Left / Right / None',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? series;

  /// Display options.
  @SectionId('RECHDI')
  @StandardReferences(
    [
      'ISO 9241-13:1998 — user guidance covers data labels and informational messages',
      'ISO/IEC 25010:2023 — appropriateness recognisability supports comprehension of displayed values',
    ],
    'Display settings for a report chart such as data labels and threshold lines.',
  )
  @Form([
    Field(
      'showDataLabels',
      String,
      'Show Data Labels',
      hint: 'Yes / No / On-Hover',
    ),
    Field(
      'dataLabelFormat',
      String,
      'Data Label Format',
      hint: 'Format for data labels',
    ),
    Field(
      'thresholdLines',
      String,
      'Threshold Lines',
      hint: 'Reference lines, e.g. Target:500000:green',
    ),
    Field(
      'trendLine',
      String,
      'Trend Line',
      hint: 'None / Linear / Moving-Average / Polynomial',
    ),
    Field(
      'goalValue',
      String,
      'Goal Value',
      hint: 'Target/goal value for gauge/KPI charts',
    ),
    Field(
      'emptyDataMessage',
      String,
      'Empty Data Message',
      hint: 'Message when chart has no data',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? display;

  /// Interaction.
  @SectionId('RECHIN')
  @StandardReferences([
    'ISO/IEC 25010:2023 — functional suitability supports interactive drill-down and navigation from charts',
    'ISO 9241-13:1998 — user guidance covers tooltips and feedback on chart elements',
  ], 'Interaction settings for a report chart such as tooltips and drill-down.')
  @Form([
    Field(
      'interactive',
      String,
      'Interactive',
      hint: 'Yes / No — tooltips, zoom, click events',
    ),
    Field(
      'drillDownTarget',
      String,
      'Drill-Down Target',
      hint: 'Report or screen navigated to on chart element click',
    ),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? interaction;

  /// Layout.
  @SectionId('RECHLA')
  @StandardReferences([
    'ISO 9241-125:2017 — visual presentation of information governs sizing and placement of content',
  ], 'Width and height layout settings for a report chart.')
  @Form([
    Field(
      'width',
      String,
      'Width',
      hint: 'Chart width: Full / Half / Third / Custom(400px)',
    ),
    Field('height', String, 'Height', hint: 'Chart height, e.g. 300px / Auto'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? layout;
}

/// Axes for report chart.
@StandardReferences(
  [
    'ISO 9241-112:2017 — presentation of information organises displayed data along axes',
    'ISO 8601-1:2019 — representation of dates and times informs axis value formatting',
  ],
  'Axis configuration mapping data fields to chart X-axis and Y-axis dimensions.',
)
@SectionId('RECHAX')
@CodeSpecKind(
  [CodeSpecPart.reporting],
  note:
      'CE-RP — a grouped projection over the domain model. Active (codespecs_mapping.md §4.1): '
      '@CsReport with @CsReportColumn / @CsReportChart / @CsReportParameter; '
      'server (definition + execution) + shared (result envelope, parameter '
      'shapes). All three delivery channels (apiResponse | email | '
      'fileExport) are reused tom_core_server transports; a named schedule is '
      'realised as a CE-JB job and email delivery resolves through CE-NT '
      '(codespecs_mapping.md §5.28).',
)
class ReportChartAxes extends DocSpecsSection {
  @Form([
    Field(
      'dataSource',
      String,
      'Data Source',
      hint: 'Data source or query if different from section',
    ),
    Field(
      'xAxisField',
      String,
      'X-Axis Field',
      hint: 'Field mapped to X-axis / category axis',
    ),
    Field('xAxisLabel', String, 'X-Axis Label', hint: 'Axis label text'),
    Field(
      'xAxisFormat',
      String,
      'X-Axis Format',
      hint: 'Format for axis values, e.g. MMM yyyy',
    ),
    Field(
      'yAxisField',
      String,
      'Y-Axis Field',
      hint: 'Field mapped to Y-axis / value axis',
    ),
    Field('yAxisLabel', String, 'Y-Axis Label', hint: 'Axis label text'),
    Field(
      'yAxisFormat',
      String,
      'Y-Axis Format',
      hint: 'Format for axis values, e.g. #,##0',
    ),
    Field(
      'yAxisMin',
      String,
      'Y-Axis Min',
      hint: 'Minimum axis value; Auto or fixed',
    ),
    Field(
      'yAxisMax',
      String,
      'Y-Axis Max',
      hint: 'Maximum axis value; Auto or fixed',
    ),
    Field(
      'secondaryYAxisField',
      String,
      'Secondary Y-Axis Field',
      hint: 'Field for dual-axis charts',
    ),
    Field(
      'secondaryYAxisLabel',
      String,
      'Secondary Y-Axis Label',
      hint: 'Label for secondary axis',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

// ---------------------------------------------------------------------------
// 10.4.1 Report Filters, Schedules, Distribution, Recipients
// ---------------------------------------------------------------------------

/// A filter parameter for a report (form).
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148:2018 — captures the requirement for a report filter parameter',
    'ISO 9241-110:2020 — represents the filter as a controllable parameter in the report interface',
  ],
  'A single report-filter entry defining one parameter by which report content is filtered.',
)
@SectionId('RFE')
@OneOf(
  discriminator: 'dataType',
  note:
      'Report-filter value-type closed choice (csra4): the filter value type '
      'selects both its input control and its value bounds (text / numeric / '
      'date / boolean / select / entity-reference). This replaces the former '
      'unconstrained `dataType` + `inputType` free-text pair, in which a Date '
      'filter could be given a Multi-Select control.',
)
@CodeSpecKind(
  [CodeSpecPart.reporting],
  note:
      'CE-RP — a grouped projection over the domain model. Active (codespecs_mapping.md §4.1): '
      '@CsReport with @CsReportColumn / @CsReportChart / @CsReportParameter; '
      'server (definition + execution) + shared (result envelope, parameter '
      'shapes). All three delivery channels (apiResponse | email | '
      'fileExport) are reused tom_core_server transports; a named schedule is '
      'realised as a CE-JB job and email delivery resolves through CE-NT '
      '(codespecs_mapping.md §5.28).',
)
class ReportFilterEntry extends DocSpecsSection {
  @Form([
    Field(
      'filterId',
      String,
      'Filter ID',
      hint: 'Unique within report, e.g. FLT-01',
      required: true,
    ),
    Field(
      'filterName',
      String,
      'Filter Name',
      hint: 'Internal reference name',
      required: true,
    ),
    Field(
      'displayLabel',
      String,
      'Display Label',
      hint: 'Label shown in parameter form',
      required: true,
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Input and value configuration.
  @SectionId('RFEI')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148:2018 — specifies the input data type and value source for a filter parameter',
      'ISO 9241-110:2020 — matches the input control to the filter data the user provides',
    ],
    'The data type, input control, and value source that configure how a report filter accepts input.',
  )
  @Form([
    Field(
      'dataType',
      ReportFilterValueKind,
      'Data Type',
      hint:
          'The filter value type — selects the promoted input-control and '
          'value-bound subsection.',
    ),
    Field(
      'defaultValue',
      String,
      'Default Value',
      hint: 'Default filter value, e.g. current_month, today, *',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? input;

  /// Text-kind filter options — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for text filters; carries the free-text control and its
  /// match semantics (no value source, no date bounds).
  @SectionId('RFEIT')
  @StandardReferences([
    'ISO 9241-143:2012 — form-based interaction and free-text input',
    'ISO 9241-110:2020 — matches the input control to the filter data the user provides',
  ], 'The input control and match semantics for a text report filter.')
  @Case(ReportFilterValueKind.string)
  @Form([
    Field(
      'inputType',
      String,
      'Input Type',
      hint: 'Text-Field / Autocomplete',
    ),
    Field(
      'matchMode',
      String,
      'Match Mode',
      hint: 'Contains / Starts-With / Exact / Regex',
    ),
    Field('maxLength', int, 'Max Length', hint: 'Character limit on the input'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? textFilterOptions;

  /// Numeric-kind filter options — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for numeric filters; carries the numeric control and its
  /// value bounds.
  @SectionId('RFEIN')
  @StandardReferences([
    'ISO 9241-143:2012 — constraints on numeric form-field input such as value ranges',
    'ISO 80000-1:2022 — general principles for quantities units and their symbols',
  ], 'The input control and value bounds for a numeric report filter.')
  @Case(ReportFilterValueKind.integer)
  @Case(ReportFilterValueKind.decimal)
  @Form([
    Field(
      'inputType',
      String,
      'Input Type',
      hint: 'Number-Field / Slider / Range-Slider',
    ),
    Field('minValue', String, 'Min Value', hint: 'Lowest accepted value'),
    Field('maxValue', String, 'Max Value', hint: 'Highest accepted value'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? numericFilterOptions;

  /// Temporal-kind filter options — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for date/date-time filters; carries the temporal control —
  /// including the range picker that the former free-text `DateRange` type
  /// stood for — and the selectable window.
  @SectionId('RFEID')
  @StandardReferences([
    'ISO 8601-1:2019 — representation of dates and times',
    'ISO 9241-143:2012 — constraints on date and time form-field input',
  ], 'The input control and selectable window for a date report filter.')
  @Case(ReportFilterValueKind.date)
  @Case(ReportFilterValueKind.dateTime)
  @Form([
    Field(
      'inputType',
      String,
      'Input Type',
      hint: 'Date-Picker / Date-Range-Picker / Relative-Period',
    ),
    Field(
      'earliestDate',
      String,
      'Earliest Date',
      hint: 'Earliest selectable date/time',
    ),
    Field(
      'latestDate',
      String,
      'Latest Date',
      hint: 'Latest selectable date/time',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? dateFilterOptions;

  /// Boolean-kind filter options — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for boolean filters; carries only the two-valued control.
  @SectionId('RFEIB')
  @StandardReferences([
    'ISO 9241-161:2016 — selection controls such as checkboxes and radio groups',
  ], 'The two-valued input control for a boolean report filter.')
  @Case(ReportFilterValueKind.boolean)
  @Form([
    Field(
      'inputType',
      String,
      'Input Type',
      hint: 'Checkbox / Toggle / Radio-Pair',
    ),
    Field(
      'includeIndeterminate',
      String,
      'Include Indeterminate',
      hint: 'Yes / No — offer an "any" third state',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? booleanFilterOptions;

  /// Selection-kind filter options — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for enumeration filters; this is the only case in which a
  /// value source, static value list, cascade parent and multi-select are
  /// meaningful.
  @SectionId('RFEIS')
  @StandardReferences([
    'ISO 9241-161:2016 — selection controls such as dropdowns and radio groups',
    'ISO/IEC 11179 — permissible values of a data element',
  ], 'The selection control and value source for an enumeration report filter.')
  @Case(ReportFilterValueKind.enumeration)
  @Form([
    Field(
      'inputType',
      String,
      'Input Type',
      hint: 'Select / Multi-Select / Radio-Group / Cascading-Select',
    ),
    Field(
      'availableValuesSource',
      String,
      'Available Values Source',
      hint:
          'Source for dropdown/select values: static list, entity query, API endpoint',
    ),
    Field(
      'staticValues',
      String,
      'Static Values',
      hint:
          'Comma-separated values if source is static, e.g. Active,Inactive,All',
    ),
    Field(
      'cascadeParent',
      String,
      'Cascade Parent',
      hint: 'Filter ID of parent filter for cascading dropdowns',
    ),
    Field(
      'multiSelect',
      String,
      'Multi-Select',
      hint: 'Yes / No — allow selecting multiple values',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? selectFilterOptions;

  /// Entity-reference filter options — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for entity-reference filters; carries the lookup control and
  /// the entity query that backs it. Distinct from the enumeration case
  /// because the value set is resolved from an entity, not a declared list.
  @SectionId('RFEIE')
  @StandardReferences([
    'ISO 9241-143:2012 — form fields with input assistance and lookup',
    'ER modeling (Chen / Barker notation)',
  ], 'The lookup control and backing entity query for an entity-reference report filter.')
  @Case(ReportFilterValueKind.entityRef)
  @Form([
    Field(
      'inputType',
      String,
      'Input Type',
      hint: 'Autocomplete / Dialog-Picker / Tree-Picker',
    ),
    Field(
      'entityType',
      String,
      'Entity Type',
      hint: 'Referenced entity, e.g. Customer',
    ),
    Field(
      'queryFilter',
      String,
      'Query Filter',
      hint: 'Restriction applied to the lookup query',
    ),
    Field(
      'displayAttribute',
      String,
      'Display Attribute',
      hint: 'Entity attribute shown to the user, e.g. name',
    ),
  ])
  @SerializationOrder(7)
  DocSpecsSection? entityFilterOptions;

  /// Scope and validation behavior.
  @SectionId('RFEB')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148:2018 — specifies the required and validation constraints on a filter parameter',
      'ISO 9241-110:2020 — supports error prevention through filter validation and dependency rules',
    ],
    'The scope, requiredness, and validation rules that govern how a report filter behaves.',
  )
  @Form([
    Field(
      'required',
      String,
      'Required',
      hint: 'Yes / No — must user provide a value',
    ),
    Field(
      'appliedScope',
      String,
      'Applied Scope',
      hint: 'Whole-Report / Section:{sectionId} — where the filter applies',
    ),
    Field(
      'displayOrder',
      int,
      'Display Order',
      hint: 'Position in parameter form',
    ),
    Field(
      'groupName',
      String,
      'Group Name',
      hint: 'Group related filters visually, e.g. Date Filters, Entity Filters',
    ),
    Field(
      'validationRule',
      String,
      'Validation Rule',
      hint: 'Validation expression, e.g. startDate <= endDate',
    ),
    Field(
      'dependsOn',
      String,
      'Depends On',
      hint: 'Other filter IDs this filter depends on',
    ),
  ])
  @SerializationOrder(8)
  DocSpecsSection? behavior;

  /// Presentation options.
  @SectionId('RFEP')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — presents filter controls in a form that suits the user task',
      'ISO/IEC/IEEE 26514:2022 — designs how filter parameters are shown to the user',
    ],
    'The presentation options that control how a report filter appears to and is remembered for the user.',
  )
  @Form([
    Field(
      'hiddenFilter',
      String,
      'Hidden Filter',
      hint: 'Yes / No — filter applied programmatically, not shown to user',
    ),
    Field(
      'quickFilterBar',
      String,
      'Quick Filter Bar',
      hint: 'Yes / No — show in report quick filter bar',
    ),
    Field(
      'rememberLastValue',
      String,
      'Remember Last Value',
      hint: 'Yes / No — persist user last selection',
    ),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(9)
  DocSpecsSection? presentation;
}

/// Scheduling rules for report generation
/// (form).
@StandardReferences(
  [
    'ISO 8601-1:2019 — represents dates, times, and recurrence for scheduling in an unambiguous form',
    'ISO/IEC/IEEE 29148:2018 — captures the requirement for when and how often a report runs',
  ],
  'A single report-schedule entry defining when and how often a report is generated.',
)
@SectionId('REPSCHENT')
@CodeSpecKind(
  [CodeSpecPart.reporting],
  note:
      'CE-RP — a grouped projection over the domain model. Active (codespecs_mapping.md §4.1): '
      '@CsReport with @CsReportColumn / @CsReportChart / @CsReportParameter; '
      'server (definition + execution) + shared (result envelope, parameter '
      'shapes). All three delivery channels (apiResponse | email | '
      'fileExport) are reused tom_core_server transports; a named schedule is '
      'realised as a CE-JB job and email delivery resolves through CE-NT '
      '(codespecs_mapping.md §5.28).',
)
class ReportScheduleEntry extends DocSpecsSection {
  @Form([
    Field(
      'scheduleId',
      String,
      'Schedule ID',
      hint: 'Unique within report, e.g. SCH-01',
      required: true,
    ),
    Field(
      'scheduleName',
      String,
      'Schedule Name',
      hint: 'Human-readable name, e.g. Monthly Financial Close',
      required: true,
    ),
    Field(
      'frequency',
      String,
      'Frequency',
      hint:
          'Daily / Weekly / Bi-weekly / Monthly / Quarterly / Semi-annually / Annually / On-demand / Event-triggered',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Timing configuration.
  @SectionId('RSET')
  @StandardReferences(
    [
      'ISO 8601-1:2019 — represents start dates, end dates, and generation windows in an unambiguous form',
      'ISO/IEC 25010:2023 — reliability of running generation within the configured time window and timeout',
    ],
    'The cron expression, timezone, and window that determine exactly when a report is generated.',
  )
  @Form([
    Field(
      'scheduleExpression',
      String,
      'Schedule Expression',
      hint:
          'Cron-like expression or recurrence rule, e.g. 0 6 1 * * (1st of month at 06:00)',
    ),
    Field(
      'timezone',
      String,
      'Timezone',
      hint: 'Timezone for schedule, e.g. Europe/Berlin',
    ),
    Field(
      'startDate',
      String,
      'Start Date',
      hint: 'Schedule effective start date',
    ),
    Field(
      'endDate',
      String,
      'End Date',
      hint: 'Schedule expiry date; empty = no expiry',
    ),
    Field(
      'generationWindow',
      String,
      'Generation Window',
      hint: 'Time window for generation, e.g. 02:00–06:00 (off-peak)',
    ),
    Field(
      'generationTimeout',
      String,
      'Generation Timeout',
      hint: 'Max duration before timeout, e.g. 30min',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? timing;

  /// Retry configuration.
  @SectionId('RSER')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — reliability and recoverability of a scheduled run through retry on failure',
    ],
    'The retry policy that governs re-attempts when a scheduled report run fails.',
  )
  @Form([
    Field('retryOnFailure', String, 'Retry On Failure', hint: 'Yes / No'),
    Field('maxRetries', int, 'Max Retries', hint: 'Number of retry attempts'),
    Field(
      'retryDelay',
      String,
      'Retry Delay',
      hint: 'Delay between retries, e.g. 5min / 15min / Exponential',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? retry;

  /// Notification settings.
  @SectionId('RSEN')
  @StandardReferences(
    [
      'ISO 21502:2020 — communications management notifies stakeholders on completion and failure events',
      'ISO/IEC 25010:2023 — reliability requires alerting on generation failure of a scheduled run',
    ],
    'The completion and failure notifications sent to interested parties for a scheduled run.',
  )
  @Form([
    Field(
      'notifyOnCompletion',
      String,
      'Notify On Completion',
      hint: 'Yes / No — send notification when report is ready',
    ),
    Field(
      'completionRecipients',
      String,
      'Completion Recipients',
      hint:
          'Recipients for completion notification (if different from report recipients)',
    ),
    Field(
      'notifyOnFailure',
      String,
      'Notify On Failure',
      hint: 'Yes / No — send alert on generation failure',
    ),
    Field(
      'failureRecipients',
      String,
      'Failure Recipients',
      hint: 'Recipients for failure alerts',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? notifications;

  /// Output configuration.
  @SectionId('RSEO')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 29148:2018 — specifies the output content and destination required from a scheduled run',
      'ISO/IEC 25010:2023 — reliability of producing the scheduled output at the requested priority',
    ],
    'The format, destination, and priority applied to the output of a scheduled report run.',
  )
  @Form([
    Field(
      'filterOverrides',
      String,
      'Filter Overrides',
      hint: 'Parameter values for scheduled run, e.g. dateRange=last_month',
    ),
    Field(
      'outputFormat',
      String,
      'Output Format',
      hint: 'Override format for this schedule, e.g. PDF',
    ),
    Field(
      'outputDestination',
      String,
      'Output Destination',
      hint:
          'Where to store generated output: Archive / File-Share / Dashboard / S3-Bucket',
    ),
    Field(
      'priority',
      String,
      'Priority',
      hint: 'Low / Normal / High / Critical — queue priority',
    ),
    Field(
      'enabled',
      String,
      'Enabled',
      hint: 'Yes / No — is this schedule active',
    ),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? output;
}

/// Distribution channel configuration (form).
@StandardReferences(
  [
    'ISO 21502:2020 — communications management plans the channels by which information reaches stakeholders',
    'ISO/IEC/IEEE 29148:2018 — captures the distribution requirements for report output',
  ],
  'A single distribution-channel entry defining how a report is delivered over one channel.',
)
@SectionId('RDE')
@CodeSpecKind(
  [CodeSpecPart.reporting],
  note:
      'CE-RP — a grouped projection over the domain model. Active (codespecs_mapping.md §4.1): '
      '@CsReport with @CsReportColumn / @CsReportChart / @CsReportParameter; '
      'server (definition + execution) + shared (result envelope, parameter '
      'shapes). All three delivery channels (apiResponse | email | '
      'fileExport) are reused tom_core_server transports; a named schedule is '
      'realised as a CE-JB job and email delivery resolves through CE-NT '
      '(codespecs_mapping.md §5.28).',
)
class ReportDistributionEntry extends DocSpecsSection {
  @Form([
    Field(
      'distributionId',
      String,
      'Distribution ID',
      hint: 'Unique within report, e.g. DST-01',
      required: true,
    ),
    Field(
      'channel',
      String,
      'Channel',
      hint:
          'Email / Dashboard / File-Share / API / Print / Push-Notification / Webhook / SFTP',
      required: true,
    ),
    Field(
      'description',
      String,
      'Description',
      hint: 'Purpose of this distribution channel',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Recipient and format settings.
  @SectionId('REDIENRE')
  @StandardReferences(
    [
      'ISO 21502:2020 — communications management distributes information to the identified stakeholders',
      'ISO/IEC 27001:2022 — access control governs which roles and lists may receive the report',
    ],
    'The recipient sourcing and per-channel format that determine who receives the distribution and in what form.',
  )
  @Form([
    Field(
      'formatPerChannel',
      String,
      'Format Per Channel',
      hint:
          'Output format for this channel, e.g. PDF for email, Excel for file-share',
    ),
    Field(
      'recipientSource',
      String,
      'Recipient Source',
      hint: 'Static-List / Role-Based / Query / Report-Filter',
    ),
    Field(
      'recipientList',
      String,
      'Recipient List',
      hint: 'Comma-separated recipient IDs or addresses',
    ),
    Field(
      'recipientRoles',
      String,
      'Recipient Roles',
      hint: 'Roles whose members receive the report',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? recipients;

  /// Message and attachment content.
  @SectionId('REDIENCO')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26514:2022 — designs the message and attachment content delivered to users',
      'IETF RFC 5322 — defines the subject and body of the email message carrying the report',
    ],
    'The subject, body, and attachment templates that shape the delivered report message.',
  )
  @Form([
    Field(
      'subjectTemplate',
      String,
      'Subject Template',
      hint: 'Email/notification subject, e.g. {reportName} — {dateRange}',
    ),
    Field(
      'bodyTemplate',
      String,
      'Body Template',
      hint: 'Email/notification body template',
    ),
    Field(
      'attachmentOption',
      String,
      'Attachment Option',
      hint: 'Inline / Attachment / Link-Only / Embedded-Preview',
    ),
    Field(
      'attachmentFileNamePattern',
      String,
      'Attachment File Name Pattern',
      hint: 'Pattern for attachment filename, e.g. {reportName}_{date}.pdf',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? contentSettings;

  /// Delivery conditions and lifecycle settings.
  @SectionId('RDED')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — reliability of scheduled delivery under conditional and timed sending rules',
      'ISO/IEC 27001:2022 — protects distributed output through compression and password encryption controls',
    ],
    'The conditions, security, and timing that govern whether and when a report is distributed.',
  )
  @Form([
    Field(
      'compressionEnabled',
      String,
      'Compression Enabled',
      hint: 'Yes / No — compress attachment (ZIP)',
    ),
    Field(
      'passwordProtect',
      String,
      'Password Protect',
      hint: 'Yes / No — encrypt attachment with password',
    ),
    Field(
      'conditionalDistribution',
      String,
      'Conditional Distribution',
      hint:
          'Condition for sending, e.g. data.rows > 0 or totalAmount > threshold',
    ),
    Field(
      'suppressIfEmpty',
      String,
      'Suppress If Empty',
      hint: 'Yes / No — skip distribution if report has no data',
    ),
    Field(
      'fileSharePath',
      String,
      'File Share Path',
      hint: 'Network/cloud path for file-share distribution',
    ),
    Field(
      'retainCopy',
      String,
      'Retain Copy',
      hint: 'Yes / No — keep a copy in the archive',
    ),
    Field(
      'sendTime',
      String,
      'Send Time',
      hint:
          'When to distribute after generation: Immediately / Delay(1h) / Scheduled-Window',
    ),
    Field(
      'enabled',
      String,
      'Enabled',
      hint: 'Yes / No — is this channel active',
    ),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? delivery;
}

/// A recipient entry (form).
@StandardReferences(
  [
    'ISO/IEC/IEEE 26515:2018 — identifies the audience that receives information for use',
    'ISO 21502:2020 — communications management plans stakeholder information distribution',
    'IETF RFC 5322 — addresses recipients where the reference is an email address',
  ],
  'A single report-recipient entry identifying who receives a report and how they are referenced.',
)
@SectionId('RRE')
@CodeSpecKind(
  [CodeSpecPart.reporting],
  note:
      'CE-RP — a grouped projection over the domain model. Active (codespecs_mapping.md §4.1): '
      '@CsReport with @CsReportColumn / @CsReportChart / @CsReportParameter; '
      'server (definition + execution) + shared (result envelope, parameter '
      'shapes). All three delivery channels (apiResponse | email | '
      'fileExport) are reused tom_core_server transports; a named schedule is '
      'realised as a CE-JB job and email delivery resolves through CE-NT '
      '(codespecs_mapping.md §5.28).',
)
class ReportRecipientEntry extends DocSpecsSection {
  @Form([
    Field(
      'recipientId',
      String,
      'Recipient ID',
      hint: 'Unique within report, e.g. REC-01',
      required: true,
    ),
    Field(
      'recipientName',
      String,
      'Recipient Name',
      hint: 'Display name',
      required: true,
    ),
    Field(
      'recipientType',
      String,
      'Recipient Type',
      hint:
          'User / Role / Group / Email / Distribution-List / External-Contact / System-Account',
    ),
    Field(
      'recipientReference',
      String,
      'Recipient Reference',
      hint: 'User ID, role name, group name, or email address',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Recipient business context.
  @SectionId('REREENCO')
  @StandardReferences(
    [
      'ISO/IEC 27001:2022 — access control determines the data scope a recipient is permitted to receive',
      'ISO 21502:2020 — communications management identifies stakeholders by business role',
    ],
    'The business role and data-scope restriction that qualify what a recipient is entitled to see.',
  )
  @Form([
    Field(
      'role',
      String,
      'Role',
      hint: 'Business role of this recipient, e.g. Department Head, Controller',
    ),
    Field(
      'dataScopeRestriction',
      String,
      'Data Scope Restriction',
      hint: 'Data visibility restriction, e.g. own-department-only',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? context;

  /// Delivery preferences.
  @SectionId('RRED')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26515:2018 — describes how information for use is delivered to recipients in their preferred form',
      'ISO 21502:2020 — communications management adapts channel and format to stakeholder preferences',
    ],
    'The per-recipient preferences for channel, format, locale, and schedule of report delivery.',
  )
  @Form([
    Field(
      'deliveryPreference',
      String,
      'Delivery Preference',
      hint: 'Email / Dashboard / Print / File-Share / API — preferred channel',
    ),
    Field(
      'formatPreference',
      String,
      'Format Preference',
      hint: 'PDF / Excel / HTML — preferred output format',
    ),
    Field(
      'localePreference',
      String,
      'Locale Preference',
      hint: 'Preferred locale for this recipient, e.g. en-US',
    ),
    Field(
      'scheduleOverride',
      String,
      'Schedule Override',
      hint:
          'Override schedule for this recipient, e.g. Weekly instead of Monthly',
    ),
    Field(
      'notifyOnReady',
      String,
      'Notify On Ready',
      hint: 'Yes / No — send notification when report is available',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? delivery;

  /// Lifecycle settings.
  @SectionId('RREL')
  @StandardReferences(
    [
      'ISO 21502:2020 — communications management plans stakeholder information distribution over time',
      'ISO 8601-1:2019 — represents the effective-from and effective-to dates in an unambiguous form',
    ],
    'The activation window that governs when a recipient starts and stops receiving reports.',
  )
  @Form([
    Field(
      'active',
      String,
      'Active',
      hint: 'Yes / No — is this recipient currently receiving reports',
    ),
    Field(
      'effectiveFrom',
      String,
      'Effective From',
      hint: 'Date this recipient is added',
    ),
    Field(
      'effectiveTo',
      String,
      'Effective To',
      hint: 'Date this recipient is removed; empty = indefinite',
    ),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(3)
  DocSpecsSection? lifecycle;
}

// ---------------------------------------------------------------------------
// 10.4.2 Export Formats
// ---------------------------------------------------------------------------

/// An export format entry (form).
@StandardReferences(
  [
    'IETF RFC 4180 — the comma-separated format defines a common interchange for tabular data',
    'ISO 32000-2:2020 — PDF defines a page-oriented portable document format for output',
    'ISO/IEC 25010:2023 — portability is the degree of transferability across environments',
  ],
  'A single export-format definition describing how report output is rendered, delimited, sized, and secured.',
)
@SectionId('EFE')
@CodeSpecKind(
  [CodeSpecPart.serverConfiguration],
  note:
      'CE-CF — renderer settings, not CE-RP. The codespecs_mapping.md §5.28 scope boundary puts '
      'the rendering engine and its per-format mechanics on the '
      'implementation side: what a specification authors about an export is '
      'the projection (CE-RP), while the format catalogue, page geometry and '
      'template assets are deployment settings on the renderer.',
)
class ExportFormatEntry extends DocSpecsSection {
  @Form([
    Field(
      'exportId',
      String,
      'Export ID',
      hint: 'Unique identifier, e.g. EXP-001',
      required: true,
    ),
    Field(
      'formatName',
      String,
      'Format Name',
      hint: 'Human-readable name, e.g. Monthly Orders CSV',
      required: true,
    ),
    Field(
      'formatType',
      String,
      'Format Type',
      hint: 'CSV / Excel / PDF / JSON / XML / HTML / Fixed-Width',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Identity and data source.
  @SectionId('EXID')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — functional appropriateness ensures the exported data source matches the intended task',
      'ISO/IEC 11179 — a data element is identified and described by its source and scope metadata',
    ],
    'Identity and data-source metadata describing the purpose, related entities, and scope of an export.',
  )
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'Business purpose of this export',
    ),
    Field(
      'relatedDataEntities',
      String,
      'Related Data Entities',
      hint: 'IFM entity references included in export',
    ),
    Field(
      'dataSource',
      String,
      'Data Source',
      hint: 'Data source or query reference',
    ),
    Field('dataScope', String, 'Data Scope', hint: 'Scope of exported data'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? identity;

  /// File format settings.
  @SectionId('EXFIFO')
  @StandardReferences(
    [
      'IETF RFC 4180 — records are separated by a line break represented as CRLF in a comma-separated file',
      'ISO/IEC 25010:2023 — interoperability requires a well-defined character encoding for the output file',
    ],
    'File-level settings such as naming pattern, character encoding, and line ending for the export output.',
  )
  @Form([
    Field(
      'fileNamingPattern',
      String,
      'File Naming Pattern',
      hint: 'Output filename pattern, e.g. orders_{date}.csv',
    ),
    Field(
      'encoding',
      String,
      'Encoding',
      hint: 'UTF-8 / UTF-16 / ISO-8859-1 / ASCII',
    ),
    Field('lineEnding', String, 'Line Ending', hint: 'CRLF / LF / CR'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? fileFormat;

  /// Delimiter and quoting.
  @SectionId('EXDE')
  @StandardReferences(
    [
      'IETF RFC 4180 — fields are separated by commas and may be enclosed in double quotes, with an optional header line',
      'ISO/IEC 25010:2023 — interoperability depends on the delimiter and quoting matching the consumer expectations',
    ],
    'Delimiter, quote character, and header-row settings that define the CSV structure of an export.',
  )
  @Form([
    Field(
      'delimiter',
      String,
      'Delimiter',
      hint: 'Column delimiter: Comma / Semicolon / Tab / Pipe',
    ),
    Field(
      'quoteCharacter',
      String,
      'Quote Character',
      hint: 'Field quote character',
    ),
    Field(
      'headerRow',
      String,
      'Header Row',
      hint: 'Yes / No — include column header row',
    ),
    Field(
      'headerStyle',
      String,
      'Header Style',
      hint: 'Display-Labels / Field-Names / Custom-Mapping',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? delimiter;

  /// Data formatting.
  @SectionId('EXDAFO')
  @StandardReferences(
    [
      'ISO 8601-1:2019 — a standardized calendar and clock representation governs how dates and times are written',
      'ISO/IEC 25010:2023 — interoperability requires numeric and boolean values to render in the expected form',
    ],
    'Formatting rules for dates, numbers, currency, boolean, and null values in exported data.',
  )
  @Form([
    Field(
      'dateFormat',
      String,
      'Date Format',
      hint: 'Date format, e.g. yyyy-MM-dd / ISO-8601',
    ),
    Field(
      'numberFormat',
      String,
      'Number Format',
      hint: 'Locale-default / US / EU / Raw',
    ),
    Field('decimalSeparator', String, 'Decimal Separator', hint: '. or ,'),
    Field(
      'currencyFormat',
      String,
      'Currency Format',
      hint: 'Symbol-prefix / Code-suffix / Raw-number',
    ),
    Field(
      'booleanTrueValue',
      String,
      'Boolean True Value',
      hint: 'String value for true, e.g. 1, true, Yes',
    ),
    Field(
      'booleanFalseValue',
      String,
      'Boolean False Value',
      hint: 'String value for false, e.g. 0, false, No',
    ),
    Field(
      'nullHandling',
      String,
      'Null Handling',
      hint: 'Empty-string / Null-literal / Custom-value',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? dataFormat;

  /// Size and splitting.
  @StandardReferences(
    [
      'IETF RFC 4180 — a comma-separated file may be divided into multiple records or files to bound its size',
      'ISO/IEC 25010:2023 — capacity is the degree to which limits on a product parameter meet requirements',
    ],
    'The collection of export size-and-splitting settings applied to this export format.',
  )
  @SectionId('EXSISE-SIZE-LST')
  @SectionIdPattern('EXSISE-SIZE-xxx')
  @ContentHelp('Add one entry per size-and-splitting setting.')
  @SerializationOrder(5)
  List<ExportSizeSettings> sizeSettings = [];

  /// Security settings.
  @SectionId('EXSE')
  @StandardReferences(
    [
      'ISO/IEC 27001 — cryptographic controls protect confidentiality of exported information at rest and in transit',
      'ISO/IEC 25010:2023 — confidentiality ensures exported data is accessible only to those authorized',
    ],
    'Compression and encryption settings that protect the confidentiality of export output.',
  )
  @Form([
    Field(
      'compressionFormat',
      String,
      'Compression Format',
      hint: 'None / ZIP / GZIP / BZIP2',
    ),
    Field('encryptionEnabled', String, 'Encryption Enabled', hint: 'Yes / No'),
    Field(
      'encryptionMethod',
      String,
      'Encryption Method',
      hint: 'AES-256 / Password-Protected-ZIP / PGP / None',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? security;

  /// Output and scheduling.
  @SectionId('EXOU')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — portability includes the ease of transferring output to a target environment',
      'ISO 8601-1:2019 — a standardized time representation underpins scheduling of automated exports',
    ],
    'Output destination and scheduling settings that control where export files are delivered and when they run.',
  )
  @Form([
    Field(
      'outputDestination',
      String,
      'Output Destination',
      hint: 'Download / File-Share / S3 / SFTP / API / Email',
    ),
    Field(
      'outputPath',
      String,
      'Output Path',
      hint: 'Path or URL for destination',
    ),
    Field(
      'schedulingEnabled',
      String,
      'Scheduling Enabled',
      hint: 'Yes / No — can this export be scheduled',
    ),
    Field(
      'schedulingExpression',
      String,
      'Scheduling Expression',
      hint: 'Cron-like expression for automated export',
    ),
  ])
  @SerializationOrder(7)
  DocSpecsSection? output;

  /// Access and audit.
  @SectionId('EXAC')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — accountability records the actions of an entity so they can be traced',
      'ISO/IEC 27001 — access control restricts export execution to authorized roles and logs the activity',
    ],
    'Access levels, required roles, and audit-logging settings governing who may run an export.',
  )
  @Form([
    Field(
      'accessLevel',
      String,
      'Access Level',
      hint: 'Public / Authenticated / Role-specific',
    ),
    Field(
      'requiredRoles',
      String,
      'Required Roles',
      hint: 'Roles permitted to run this export',
    ),
    Field(
      'auditLogging',
      String,
      'Audit Logging',
      hint: 'Yes / No — log export executions',
    ),
    Field(
      'previewAvailable',
      String,
      'Preview Available',
      hint: 'Yes / No — allow user to preview',
    ),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(8)
  DocSpecsSection? access;

  /// Contains 0+× Export Field Mapping.
  @StandardReferences(
    [
      'IETF RFC 4180 — each field in a record corresponds to a named column defined by the header line',
      'ISO/IEC 29500-1:2016 — Office Open XML defines document markup for exchanging structured field data',
    ],
    'The collection of export field-mapping entries that bind source fields to output columns.',
  )
  @SectionId('EFME-FIEL-LST')
  @SectionIdPattern('EFME-FIEL-xxx')
  @ContentHelp('Add one entry per export field mapping.')
  @SerializationOrder(9)
  List<ExportFieldMappingEntry> fieldMappings = [];
}

/// Export size settings.
@StandardReferences(
  [
    'IETF RFC 4180 — a comma-separated file is a sequence of records that may be split across multiple files',
    'ISO/IEC 25010:2023 — capacity is the degree to which limits on a product parameter meet requirements',
  ],
  'Row limits and file-splitting settings that bound the size of generated export files.',
)
@SectionId('EXSISE')
@CodeSpecKind(
  [CodeSpecPart.serverConfiguration],
  note:
      'CE-CF — renderer settings, not CE-RP. The codespecs_mapping.md §5.28 scope boundary puts '
      'the rendering engine and its per-format mechanics on the '
      'implementation side: what a specification authors about an export is '
      'the projection (CE-RP), while the format catalogue, page geometry and '
      'template assets are deployment settings on the renderer.',
)
class ExportSizeSettings extends DocSpecsSection {
  @Form([
    Field('maxRows', int, 'Maximum Rows', hint: 'Row limit; 0 = unlimited'),
    Field(
      'splitLargeFiles',
      String,
      'Split Large Files',
      hint: 'Yes / No — split into chunks',
    ),
    Field(
      'splitThreshold',
      String,
      'Split Threshold',
      hint: 'Split point, e.g. 100000 rows or 50MB',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A field mapping within an export (form).
@StandardReferences(
  [
    'IETF RFC 4180 — each field in a record maps to a named column identified by the header line',
    'ISO/IEC 25010:2023 — interoperability depends on correctly mapping source fields to target fields',
  ],
  'A single mapping that binds one source data field to one target field in the export output.',
)
@SectionId('EXFIMAEN')
@OneOf(
  discriminator: 'dataType',
  note:
      'Export-field value-type closed choice (csra4): the field data type '
      'selects its promoted output subsection (numeric / temporal / boolean / '
      'enumeration / text), so a single `formatPattern` no longer has to mean '
      'both "dd.MM.yyyy" and "#,##0.00" depending on a free-text type.',
)
@CodeSpecKind(
  [CodeSpecPart.serverConfiguration],
  note:
      'CE-CF — the column layout of one export-format catalogue entry, not a '
      'standalone projection. It is reachable only through ExportFormatEntry, '
      'whose format catalogue codespecs_mapping.md §5.28 places in CE-CF; a '
      'CE-RP leaf inside a CE-CF container could be neither projected (its '
      'container is not CE-RP) nor hoisted (a mapping is meaningless apart '
      'from the format it maps). The projection a specification authors is '
      'ReportColumnEntry, under ReportEntry.',
)
class ExportFieldMappingEntry extends DocSpecsSection {
  @Form([
    Field(
      'mappingId',
      String,
      'Mapping ID',
      hint: 'Unique within export, e.g. FLD-01',
      required: true,
    ),
    Field(
      'sourceField',
      String,
      'Source Field',
      hint: 'Data model field path, e.g. order.customer.name',
      required: true,
    ),
    Field(
      'targetFieldName',
      String,
      'Target Field Name',
      hint: 'Column/field name in output file',
      required: true,
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Ordering and formatting settings.
  @SectionId('EFMEF')
  @StandardReferences(
    [
      'IETF RFC 4180 — the order of fields within each record is fixed and consistent across the file',
      'ISO 8601-1:2019 — a standardized date representation governs how date-typed fields are formatted',
    ],
    'Column ordering, data typing, and output format pattern applied to a mapped export field.',
  )
  @Form([
    Field(
      'displayOrder',
      int,
      'Display Order',
      hint: 'Position in the export output (column order)',
    ),
    Field(
      'dataType',
      ExportFieldKind,
      'Data Type',
      hint: 'The field value type — selects the promoted output subsection.',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? formatting;

  /// Numeric-kind output format — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for integer and decimal fields; carries only the numeric
  /// output pattern and separators.
  @SectionId('EFMEFN')
  @StandardReferences([
    'ISO 80000-1:2022 — general principles for quantities units and their symbols',
    'IETF RFC 4180 — numeric field values are emitted as text within the record structure',
  ], 'The numeric output pattern and separators for an exported numeric field.')
  @Case(ExportFieldKind.integer)
  @Case(ExportFieldKind.decimal)
  @Form([
    Field(
      'formatPattern',
      String,
      'Format Pattern',
      hint: 'Numeric output format, e.g. #,##0.00',
    ),
    Field(
      'decimalSeparator',
      String,
      'Decimal Separator',
      hint: 'Character used as the decimal mark, e.g. . or ,',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? numericOutput;

  /// Temporal-kind output format — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for date and date-time fields; carries only the temporal
  /// output pattern and timezone handling.
  @SectionId('EFMEFD')
  @StandardReferences([
    'ISO 8601-1:2019 — representation of dates and times',
    'ISO 8601-2:2019 — extensions including time-zone offsets',
  ], 'The temporal output pattern and timezone handling for an exported date field.')
  @Case(ExportFieldKind.date)
  @Case(ExportFieldKind.dateTime)
  @Form([
    Field(
      'formatPattern',
      String,
      'Format Pattern',
      hint: 'Temporal output format, e.g. dd.MM.yyyy',
    ),
    Field(
      'timezoneHandling',
      String,
      'Timezone Handling',
      hint: 'UTC / Local / With-Offset',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? temporalOutput;

  /// Boolean-kind output format — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for boolean fields; this is the only case in which the
  /// emitted true/false literals are meaningful.
  @SectionId('EFMEFB')
  @StandardReferences([
    'IETF RFC 4180 — boolean field values are emitted as text literals within the record',
  ], 'The emitted true and false literals for an exported boolean field.')
  @Case(ExportFieldKind.boolean)
  @Form([
    Field(
      'trueLiteral',
      String,
      'True Literal',
      hint: 'Emitted for true, e.g. true / Y / 1',
    ),
    Field(
      'falseLiteral',
      String,
      'False Literal',
      hint: 'Emitted for false, e.g. false / N / 0',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? booleanOutput;

  /// Enumeration-kind output format — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for enumeration fields; carries which face of the value set
  /// is emitted and what happens to a value outside it.
  @SectionId('EFMEFE')
  @StandardReferences([
    'ISO/IEC 11179 — permissible values of a data element and their representation',
  ], 'The emitted representation of an exported enumeration field and its unmapped-value behaviour.')
  @Case(ExportFieldKind.enumeration)
  @Form([
    Field(
      'emittedForm',
      String,
      'Emitted Form',
      hint: 'Value-Id / Display-Label / Numeric-Ordinal',
    ),
    Field(
      'unmappedValueBehavior',
      String,
      'Unmapped Value Behavior',
      hint: 'Emit-Raw / Emit-Empty / Fail-Export',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? enumerationOutput;

  /// Text-kind output format — a promoted `@OneOf` case (csra4).
  ///
  /// Present only for text fields; carries the character-length truncation
  /// that only a string field can have. Moved out of `inclusion`, where it sat
  /// beside type-independent default and inclusion rules.
  @SectionId('EFMEFT')
  @StandardReferences([
    'IETF RFC 4180 — text field values are emitted within the record structure',
    'ISO/IEC 25010:2023 — functional correctness of length-bounded output',
  ], 'The character-length truncation and padding for an exported text field.')
  @Case(ExportFieldKind.string)
  @Form([
    Field(
      'maxLength',
      int,
      'Max Length',
      hint: 'Truncate output to this character length',
    ),
    Field(
      'padding',
      String,
      'Padding',
      hint: 'None / Left-Pad / Right-Pad for fixed-width output',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? textOutput;

  /// Transformation rules.
  @SectionId('EFMET')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — functional correctness requires transformed values to match the specified rules',
      'IETF RFC 4180 — transformed field values are emitted as text within the record structure',
    ],
    'Value transformation and substitution rules applied to a mapped field before it is written to the export.',
  )
  @Form([
    Field(
      'transformationRule',
      String,
      'Transformation Rule',
      hint:
          'Value transformation: None / Uppercase / Lowercase / Trim / Truncate(n) / Map / Concatenate / Calculate / Custom',
    ),
    Field(
      'transformationExpression',
      String,
      'Transformation Expression',
      hint: 'Expression for transform, e.g. firstName + lastName',
    ),
    Field(
      'valueMapping',
      String,
      'Value Mapping',
      hint: 'Value substitution map, e.g. ACTIVE→A, INACTIVE→I',
    ),
  ])
  @SerializationOrder(7)
  DocSpecsSection? transformation;

  /// Inclusion and defaults.
  @SectionId('EFMEI')
  @StandardReferences(
    [
      'IETF RFC 4180 — a record is a sequence of fields where empty fields are represented by adjacent delimiters',
      'ISO/IEC 25010:2023 — functional correctness ensures default and inclusion rules produce the expected output',
    ],
    'Inclusion conditions and default values determining whether and how a mapped field appears in the export.',
  )
  @Form([
    Field(
      'defaultValue',
      String,
      'Default Value',
      hint: 'Value to use when source is null/empty',
    ),
    Field(
      'includeInExport',
      String,
      'Include In Export',
      hint: 'Yes / No / Conditional',
    ),
    Field(
      'inclusionCondition',
      String,
      'Inclusion Condition',
      hint: 'Condition for conditional inclusion',
    ),
  ])
  @SerializationOrder(8)
  DocSpecsSection? inclusion;

  /// Fixed-width and quoting rules.
  @SectionId('EFMEL')
  @StandardReferences(
    [
      'IETF RFC 4180 — fields containing special characters are enclosed in double quotes',
      'ISO/IEC 25010:2023 — interoperability requires field layout to match the consuming system expectations',
    ],
    'Fixed-width padding and CSV quoting rules controlling how a mapped field is laid out in the output.',
  )
  @Form([
    Field(
      'paddingChar',
      String,
      'Padding Char',
      hint: 'For fixed-width: padding character, e.g. space or 0',
    ),
    Field(
      'paddingDirection',
      String,
      'Padding Direction',
      hint: 'Left / Right for fixed-width formats',
    ),
    Field(
      'fixedWidth',
      int,
      'Fixed Width',
      hint: 'Column width for fixed-width format exports',
    ),
    Field(
      'quoteAlways',
      String,
      'Quote Always',
      hint: 'Yes / No — always quote this field in CSV',
    ),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(9)
  DocSpecsSection? layout;
}

// ---------------------------------------------------------------------------
// 10.4.3 Export Templates
// ---------------------------------------------------------------------------

/// A reusable export template (form).
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — reusability is the degree to which an asset can be used in more than one system',
    'ISO/IEC 29500-1:2016 — Office Open XML supports document templates for repeatable output',
  ],
  'A reusable export template that bundles format, field, layout, and access settings for repeated exports.',
)
@SectionId('ETE')
@CodeSpecKind(
  [CodeSpecPart.serverConfiguration],
  note:
      'CE-CF — renderer settings, not CE-RP. The codespecs_mapping.md §5.28 scope boundary puts '
      'the rendering engine and its per-format mechanics on the '
      'implementation side: what a specification authors about an export is '
      'the projection (CE-RP), while the format catalogue, page geometry and '
      'template assets are deployment settings on the renderer.',
)
class ExportTemplateEntry extends DocSpecsSection {
  @Form([
    Field(
      'templateId',
      String,
      'Template ID',
      hint: 'Unique identifier, e.g. TPL-001',
      required: true,
    ),
    Field(
      'templateName',
      String,
      'Template Name',
      hint: 'Human-readable name, e.g. Standard Customer Export',
      required: true,
    ),
    Field(
      'baseFormatType',
      String,
      'Base Format Type',
      hint: 'CSV / Excel / PDF / JSON / XML / HTML',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Format configuration.
  @SectionId('ETEF')
  @StandardReferences(
    [
      'IETF RFC 4180 — a comma-separated file uses a delimiter and optional header line to structure records',
      'ISO 8601-1:2019 — a standardized date representation governs the default date format for exported values',
    ],
    'Default format configuration such as encoding, delimiter, header, and value formatting for an export template.',
  )
  @Form([
    Field(
      'description',
      String,
      'Description',
      hint: 'Purpose and use cases for this template',
    ),
    Field(
      'encoding',
      String,
      'Encoding',
      hint: 'Default encoding for this template',
    ),
    Field('delimiter', String, 'Delimiter', hint: 'Default delimiter'),
    Field('headerRow', String, 'Header Row', hint: 'Yes / No'),
    Field('dateFormat', String, 'Date Format', hint: 'Default date format'),
    Field(
      'numberFormat',
      String,
      'Number Format',
      hint: 'Default number format',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? format;

  /// Field and filter settings.
  @SectionId('EXTEENFI')
  @StandardReferences(
    [
      'IETF RFC 4180 — a comma-separated file arranges records into fields selected for output',
      'ISO/IEC 25010:2023 — functional appropriateness ensures the selected fields serve the intended task',
    ],
    'The selection, filtering, and default sorting of fields applied by an export template.',
  )
  @Form([
    Field(
      'fieldSet',
      String,
      'Field Set',
      hint: 'Comma-separated field names included in this template',
    ),
    Field(
      'defaultFilters',
      String,
      'Default Filters',
      hint: 'Pre-applied filters, e.g. status=active',
    ),
    Field(
      'defaultSortField',
      String,
      'Default Sort Field',
      hint: 'Default sort column',
    ),
    Field(
      'defaultSortDirection',
      String,
      'Default Sort Direction',
      hint: 'Ascending / Descending',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? fields;

  /// Layout configuration.
  @SectionId('ETEL')
  @StandardReferences(
    [
      'ISO 32000-2:2020 — PDF describes page-level header and footer artifacts for printed output',
      'ISO/IEC 29500-1:2016 — Office Open XML defines header and footer structures for documents',
      'W3C CSS Paged Media — page margin boxes carry running headers and footers in paged rendering',
    ],
    'Layout configuration defining header, footer, branding, and compression for a rendered export template.',
  )
  @Form([
    Field(
      'headerConfig',
      String,
      'Header Config',
      hint: 'Header content template for PDF/Excel exports',
    ),
    Field(
      'footerConfig',
      String,
      'Footer Config',
      hint: 'Footer content template for PDF/Excel exports',
    ),
    Field(
      'brandingOverride',
      String,
      'Branding Override',
      hint: 'Template-specific branding (for PDF)',
    ),
    Field(
      'compressionFormat',
      String,
      'Compression Format',
      hint: 'None / ZIP / GZIP',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? layout;

  /// Access and metadata.
  @SectionId('ETEA')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — reusability supports transfer of assets across products and contexts',
      'ISO 8601-1:2019 — a standardized calendar representation supports template version dating',
    ],
    'Access-control and metadata settings governing who may use an export template and how it is versioned.',
  )
  @Form([
    Field(
      'accessLevel',
      String,
      'Access Level',
      hint: 'Public / Authenticated / Role-specific',
    ),
    Field(
      'requiredRoles',
      String,
      'Required Roles',
      hint: 'Roles permitted to use this template',
    ),
    Field(
      'reusableAcrossReports',
      String,
      'Reusable Across Reports',
      hint: 'Yes / No — can this template be used by multiple reports/exports',
    ),
    Field('version', String, 'Version', hint: 'Template version, e.g. 1.0'),
    Field('notes', String, 'Notes', hint: 'Design notes'),
  ])
  @SerializationOrder(4)
  DocSpecsSection? access;
}

// ---------------------------------------------------------------------------
// 10.7 Error Handling
// ---------------------------------------------------------------------------

/// 10.7. Error Handling.
///
/// Comprehensive error handling user experience framework covering validation
/// feedback, system error presentation, and error recovery flows. Follows
/// UX best practices for error prevention, detection, and graceful recovery.
@StandardReferences(
  [
    'ISO 9241-110:2020 — use-error tolerance and error management help users prevent, detect, and recover from errors',
    'ISO 9241-13:1998 — user guidance provides feedback and error messages throughout interaction',
    'ISO/IEC 25010:2023 — fault tolerance and recoverability underpin graceful error recovery',
  ],
  'The error-handling configuration governing validation feedback, system errors, and recovery flows.',
)
@SectionId('ERHACO')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@CodeSpecKind(
  [CodeSpecPart.errorResult],
  note:
      'CE-ER — error-result display over the canonical structured error envelope.',
)
class ErrorHandling extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Error Handling Philosophy
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('ERHACO-ERRO')
  @Form([
    // Philosophy and approach
    Field(
      'errorPhilosophy',
      String,
      'Error Handling Philosophy',
      hint: 'Prevention-first, graceful degradation, user empowerment',
    ),
    Field(
      'errorToneOfVoice',
      String,
      'Error Tone of Voice',
      hint: 'Friendly, professional, apologetic, neutral',
    ),
    Field(
      'errorLanguageStyle',
      String,
      'Error Language Style',
      hint: 'Plain language, technical, user-focused',
    ),
    Field(
      'blameAvoidance',
      String,
      'Blame Avoidance Approach',
      hint: 'Never blame user, focus on solutions',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? errorPhilosophyContent;

  /// Error categorization and display priority.
  @SectionId('EHCC')
  @StandardReferences(
    [
      'ISO 9241-13:1998 — user guidance orders feedback so the most important errors are noticed first',
      'ISO/IEC 25010:2023 — fault tolerance benefits from classifying errors by category and severity',
    ],
    'The error-handling classification configuration governing categories and display priority.',
  )
  @Form([
    Field(
      'errorCategories',
      String,
      'Error Categories',
      hint: 'Validation, network, server, permission, data',
    ),
    Field(
      'errorSeverityLevels',
      String,
      'Severity Levels',
      hint: 'Critical, warning, info, success',
    ),
    Field(
      'errorPriorityDisplay',
      String,
      'Priority Display Order',
      hint: 'Most severe first, chronological, by field',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? classification;

  /// Accessibility and inclusive error cues.
  @SectionId('EHCA')
  @StandardReferences(
    [
      'ISO 9241-125:2017 — visual presentation ensures error cues remain perceivable through non-colour indicators',
      'ISO/IEC 25010:2023 — appropriateness recognisability supports inclusive error cues for all users',
    ],
    'The error-handling accessibility configuration governing inclusive error cues.',
  )
  @Form([
    Field(
      'errorAccessibility',
      String,
      'Error Accessibility',
      hint: 'Screen reader announcements, ARIA live regions',
    ),
    Field(
      'colorContrastCompliance',
      String,
      'Color Contrast Compliance',
      hint: 'WCAG AA, AAA for error states',
    ),
    Field(
      'nonColorIndicators',
      String,
      'Non-Color Indicators',
      hint: 'Icons, text, patterns for colorblind users',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? accessibility;

  /// Localization and analytics behavior.
  @SectionId('EHCO')
  @StandardReferences(
    [
      'ISO 9241-13:1998 — user guidance presents error messages in the language and terms of the user',
      'ISO/IEC 25010:2023 — user error protection and reliability inform the tracking of recurring input errors',
    ],
    'The error-handling operations configuration governing localisation and error analytics.',
  )
  @Form([
    Field(
      'errorLocalization',
      String,
      'Error Localization',
      hint: 'All messages localized, fallback language',
    ),
    Field(
      'dynamicContentHandling',
      String,
      'Dynamic Content Handling',
      hint: 'How dynamic values are inserted into messages',
    ),
    Field(
      'errorTrackingApproach',
      String,
      'Error Tracking Approach',
      hint: 'Analytics for user errors, trend analysis',
    ),
    Field(
      'userFrustrationDetection',
      String,
      'User Frustration Detection',
      hint: 'Rage click detection, repeated errors',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? operations;

  /// Error handling overview and strategy.
  @ContentHelp(
    'Executive summary of error handling approach, '
    'key principles, and user experience goals.',
  )
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
  @ContentHelp(
    'Centralized catalog of error message templates '
    'with consistent formatting and tone.',
  )
  @SerializationOrder(8)
  TextSection errorMessageCatalog = TextSection();

  /// Error state visual design.
  @ContentHelp(
    'Visual design specifications for error states '
    'including colors, icons, animations.',
  )
  @SerializationOrder(9)
  TextSection errorVisualDesign = TextSection();
}

/// 10.7.1. Validation Feedback.
///
/// Field validation error display and feedback mechanisms.
@StandardReferences(
  [
    'ISO 9241-110:2020 — use-error tolerance helps users avoid and correct input errors',
    'ISO 9241-143:2012 — forms give feedback that guides correction of invalid input',
  ],
  'The validation-feedback configuration governing how input errors are surfaced.',
)
@SectionId('VAFE')
@CodeSpecKind([
  CodeSpecPart.validation,
], note: 'CE-VA — per-field / per-element validation rule.')
class ValidationFeedback extends DocSpecsSection {
  @SectionId('VAFE-VALI')
  @Form([
    Field(
      'validationTiming',
      String,
      'Validation Timing',
      hint: 'Real-time, on-blur, on-submit, debounced',
    ),
    Field(
      'debounceDelay',
      String,
      'Debounce Delay',
      hint: 'Milliseconds before validation triggers',
    ),
    Field(
      'validationSequence',
      String,
      'Validation Sequence',
      hint: 'Field-by-field, all-at-once, progressive',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? validationDisplayContent;

  /// Display placement details.
  @SectionId('VAFEPL')
  @StandardReferences(
    [
      'ISO 9241-125:2017 — visual presentation governs the placement of feedback near the relevant field',
      'ISO 9241-143:2012 — forms position validation feedback where users can readily associate it with a field',
    ],
    'The validation-feedback placement configuration governing where error indicators appear.',
  )
  @Form([
    Field(
      'errorMessagePlacement',
      String,
      'Error Message Placement',
      hint: 'Inline below field, above field, tooltip, summary',
    ),
    Field(
      'summaryPosition',
      String,
      'Error Summary Position',
      hint: 'Top of form, bottom of form, modal',
    ),
    Field(
      'fieldHighlighting',
      String,
      'Field Highlighting',
      hint: 'Border color, background color, icon',
    ),
    Field(
      'fieldErrorIcon',
      String,
      'Field Error Icon',
      hint: 'Icon displayed on invalid fields',
    ),
    Field(
      'fieldErrorIconPosition',
      String,
      'Icon Position',
      hint: 'Leading, trailing, inside field, outside',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? placement;

  /// Message formatting details.
  @SectionId('VAFEME')
  @StandardReferences(
    [
      'ISO 9241-143:2012 — forms present specific validation messages for input fields',
      'ISO 9241-13:1998 — user guidance provides clear and concise error messages',
    ],
    'The validation-feedback message configuration governing formatting of error messages.',
  )
  @Form([
    Field(
      'messageFormat',
      String,
      'Message Format',
      hint: 'Text only, icon + text, structured',
    ),
    Field(
      'maxMessageLength',
      String,
      'Max Message Length',
      hint: 'Character limit for inline messages',
    ),
    Field(
      'multipleErrorsDisplay',
      String,
      'Multiple Errors Display',
      hint: 'First only, all, expandable list',
    ),
    Field(
      'errorPersistence',
      String,
      'Error Persistence',
      hint: 'Until fixed, until field accessed, timed',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? messages;

  /// Guidance settings.
  @SectionId('VAFEGU')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — self-descriptiveness helps users understand what valid input looks like',
      'ISO 9241-143:2012 — forms offer requirements and examples that guide correct entry',
    ],
    'The validation-feedback guidance configuration governing requirements, suggestions, and examples.',
  )
  @Form([
    Field(
      'showRequirements',
      bool,
      'Show Requirements',
      hint: 'Display field requirements before error',
    ),
    Field(
      'showSuggestions',
      bool,
      'Show Suggestions',
      hint: 'Suggest corrections for common errors',
    ),
    Field(
      'showExamples',
      bool,
      'Show Examples',
      hint: 'Show example valid input',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? guidance;

  /// Animation and focus behavior.
  @SectionId('VAFEBE')
  @StandardReferences(
    [
      'ISO 9241-143:2012 — forms move focus toward fields that need correction after validation',
      'ISO 9241-13:1998 — user guidance draws attention to the location of an input error',
    ],
    'The validation-feedback behaviour configuration governing animation and focus on errors.',
  )
  @Form([
    Field(
      'errorAnimation',
      String,
      'Error Animation',
      hint: 'Shake, fade-in, bounce, none',
    ),
    Field(
      'clearAnimation',
      String,
      'Clear Animation',
      hint: 'Animation when error is resolved',
    ),
    Field(
      'scrollToError',
      bool,
      'Scroll to Error',
      hint: 'Auto-scroll to first error on submit',
    ),
    Field(
      'focusOnError',
      bool,
      'Focus on Error',
      hint: 'Move focus to first invalid field',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? behavior;

  /// Validation feedback narrative.
  @ContentHelp(
    'Detailed specification of validation feedback behavior '
    'and user experience considerations.',
  )
  @SerializationOrder(5)
  TextSection validationNarrative = TextSection();

  /// Validation message templates.
  @StandardReferences([
    'ISO 9241-143:2012 — forms present specific validation messages for input fields',
  ], 'The collection of validation-message template entries.')
  @SectionId('VAMETE-MESS-LST')
  @SectionIdPattern('VAMETE-MESS-xxx')
  @ContentHelp('Add one entry per validation message template.')
  @SerializationOrder(6)
  List<ValidationMessageTemplate> messageTemplates = [];

  /// Field validation rules by type.
  @StandardReferences([
    'ISO 9241-143:2012 — forms apply validation rules that determine acceptable input per field',
    'ISO/IEC 27001:2022 — input validation controls guard against malformed or malicious data',
  ], 'The collection of field validation rule entries organised by field type.')
  @SectionId('FIELD-FIEL-LST')
  @SectionIdPattern('FIELD-FIEL-xxx')
  @ContentHelp('Add one entry per field validation rule.')
  @SerializationOrder(7)
  List<DocSpecsSection> fieldValidationRules = [];
}

/// A validation message template.
@StandardReferences(
  [
    'ISO 9241-143:2012 — forms present specific validation messages that guide correction of invalid input',
    'ISO 9241-13:1998 — user guidance provides clear and constructive error messages',
  ],
  'The validation-message template configuration defining reusable error message content.',
)
@SectionId('VMT')
@CodeSpecKind(
  [CodeSpecPart.text],
  note:
      'CE-TX — UI text / i18n copy (help, placeholder, message templates, locale handling).',
)
class ValidationMessageTemplate extends DocSpecsSection {
  @Form([
    Field(
      'messageId',
      String,
      'Message ID',
      required: true,
      hint: 'Unique identifier (e.g., VAL-REQ-001)',
    ),
    Field(
      'validationType',
      String,
      'Validation Type',
      required: true,
      hint: 'Required, format, range, length, custom',
    ),
    Field(
      'fieldTypes',
      String,
      'Applicable Field Types',
      hint: 'Text, email, number, date, select',
    ),
    Field(
      'messageTemplate',
      String,
      'Message Template',
      required: true,
      hint:
          'Template with {field}, {value} placeholders. Author the copy once '
          'in the CE-TX Message Key Registry (MSGKR) and reference it via '
          'localizationKey; this field carries the resolved default copy',
    ),
    Field(
      'shortMessage',
      String,
      'Short Message',
      hint: 'Brief version for space-constrained contexts',
    ),
    Field(
      'helpText',
      String,
      'Help Text',
      hint: 'Extended guidance for complex errors',
    ),
    Field(
      'exampleCorrection',
      String,
      'Example Correction',
      hint: 'Example of valid input',
    ),
    Field('severity', String, 'Severity', hint: 'Error, warning, info'),
    Field(
      'iconCode',
      String,
      'Icon Code',
      hint: 'Icon to display with message',
    ),
    Field(
      'localizationKey',
      String,
      'Localization Key',
      hint:
          'MessageKeyEntry.key into the CE-TX Message Key Registry (MSGKR) — '
          'the single author-once home for this validation copy and its '
          'locale variants',
      refersTo: ['MSGKE.key'],
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 10.7.2. System Error Display.
///
/// System error presentation including server errors, network issues,
/// and timeouts.
@StandardReferences(
  [
    'ISO 9241-125:2017 — presentation of information governs how system errors are shown to users',
    'ISO 9241-13:1998 — user guidance presents clear and specific system error messages',
    'ISO/IEC 25010:2023 — fault tolerance and recoverability shape graceful degradation on failure',
  ],
  'The system-error display configuration governing how errors are shown to users.',
)
@SectionId('SYERDI')
@CodeSpecKind(
  [CodeSpecPart.errorResult],
  note:
      'CE-ER — error-result display over the canonical structured error envelope.',
)
class SystemErrorDisplay extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // System Error Handling
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('SYERDI-SYST')
  @Form([
    Field(
      'networkErrorHandling',
      String,
      'Network Error Handling',
      hint: 'How connectivity issues are displayed',
    ),
    Field(
      'systemErrorDisplayMethod',
      String,
      'Display Method',
      hint: 'Modal, snackbar, banner, full-page',
    ),
    Field(
      'gracefulDegradation',
      String,
      'Graceful Degradation',
      hint: 'How features degrade on partial failure',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? systemErrorContent;

  /// Error type handling configuration.
  @SectionId('SEDET')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — fault tolerance defines how each class of system fault is handled',
      'ISO 9241-13:1998 — user guidance tailors clear feedback to each type of error condition',
    ],
    'The per-type handling configuration for different classes of system error.',
  )
  @Form([
    Field(
      'serverErrorHandling',
      String,
      'Server Error Handling',
      hint: 'How 5xx errors are presented',
    ),
    Field(
      'timeoutHandling',
      String,
      'Timeout Handling',
      hint: 'How request timeouts are displayed',
    ),
    Field(
      'authenticationErrorHandling',
      String,
      'Authentication Error',
      hint: 'Session expired, unauthorized',
    ),
    Field(
      'permissionErrorHandling',
      String,
      'Permission Error',
      hint: 'Forbidden access display',
    ),
    Field(
      'maintenanceModeHandling',
      String,
      'Maintenance Mode',
      hint: 'Scheduled downtime display',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? errorTypes;

  /// Display method settings.
  @SectionId('SEDM')
  @StandardReferences(
    [
      'ISO 9241-125:2017 — visual presentation of information governs how error modals, banners, and pages are laid out',
      'ISO 9241-13:1998 — user guidance ensures error feedback is presented in a noticeable and readable way',
    ],
    'The display-method settings that decide how a system error is shown on screen.',
  )
  @Form([
    Field(
      'errorModalStyle',
      String,
      'Error Modal Style',
      hint: 'Dialog design for error modals',
    ),
    Field(
      'snackbarPosition',
      String,
      'Snackbar Position',
      hint: 'Bottom, top, bottom-left, top-right',
    ),
    Field(
      'snackbarDuration',
      String,
      'Snackbar Duration',
      hint: 'Auto-dismiss time or persistent',
    ),
    Field(
      'bannerPosition',
      String,
      'Banner Position',
      hint: 'Top of page, top of content',
    ),
    Field(
      'fullPageErrorTemplate',
      String,
      'Full Page Error Template',
      hint: 'Design for full-page errors (500, 503)',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? displayMethods;

  /// Content options.
  @SectionId('SEDC')
  @StandardReferences(
    [
      'ISO 9241-13:1998 — user guidance presents clear and specific error message content',
      'ISO 9241-125:2017 — presentation of information governs which error details are shown to users',
    ],
    'The content options that decide what information an error display presents.',
  )
  @Form([
    Field(
      'showTechnicalDetails',
      bool,
      'Show Technical Details',
      hint: 'Display error codes, request IDs',
    ),
    Field(
      'showRetryOption',
      bool,
      'Show Retry Option',
      hint: 'Offer a retry button on the error',
    ),
    Field(
      'showContactSupport',
      bool,
      'Show Contact Support',
      hint: 'Show a link to contact support',
    ),
    Field(
      'showStatusPageLink',
      bool,
      'Show Status Page Link',
      hint: 'Show a link to the service status page',
    ),
    Field(
      'offlineModeMessage',
      String,
      'Offline Mode Message',
      hint: 'Message when app detects offline state',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? displayContent;

  /// Fallback behavior.
  @SectionId('SEDF')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — fault tolerance keeps the system operating through cached data and retry fallbacks',
      'ISO 9241-110:2020 — use-error tolerance sustains a workable state when a system error occurs',
    ],
    'The fallback behaviour applied when a system error prevents normal operation.',
  )
  @Form([
    Field(
      'cachedDataFallback',
      String,
      'Cached Data Fallback',
      hint: 'Show stale data with indicator',
    ),
    Field(
      'retryStrategy',
      String,
      'Retry Strategy',
      hint: 'Automatic retry with backoff',
    ),
    Field(
      'maxRetryAttempts',
      int,
      'Max Retry Attempts',
      hint: 'Number of retries before giving up',
    ),
    Field(
      'retryDelaySeconds',
      int,
      'Retry Delay (seconds)',
      hint: 'Seconds to wait between retries',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? fallback;

  /// System error display narrative.
  @ContentHelp(
    'Detailed specification of system error presentation '
    'and user communication approach.',
  )
  @SerializationOrder(5)
  TextSection systemErrorNarrative = TextSection();

  /// Error page designs.
  @StandardReferences([
    'ISO 9241-125:2017 — visual presentation of information governs the layout of full-page error designs',
    'ISO 9241-13:1998 — user guidance ensures each error page conveys clear and specific feedback',
  ], 'The collection of error-page design entries.')
  @SectionId('EPDE-ERRO-LST')
  @SectionIdPattern('EPDE-ERRO-xxx')
  @ContentHelp('Add one entry per error page design.')
  @SerializationOrder(6)
  List<DocSpecsSection> errorPageDesigns = [];

  /// Error codes catalog.
  @StandardReferences([
    'ISO/IEC 27001:2022 — error codes classify events so they can be logged and correlated',
    'ISO 9241-13:1998 — user guidance links each error code to a clear and specific user message',
  ], 'The collection of catalogued system error code entries.')
  @SectionId('SECE-ERRO-LST')
  @SectionIdPattern('SECE-ERRO-xxx')
  @ContentHelp('Add one entry per system error code.')
  @SerializationOrder(7)
  List<SystemErrorCodeEntry> errorCodes = [];
}

/// A system error code entry.
@StandardReferences([
  'ISO/IEC 27001:2022 — error codes classify events so they can be logged and correlated',
  'ISO 9241-13:1998 — user guidance maps each error to a clear and specific user message',
], 'A single catalogued system error code with its user message and handling.')
@SectionId('SYERCOEN')
@CodeSpecKind(
  [CodeSpecPart.errorResult],
  note:
      'CE-ER — error-result display over the canonical structured error envelope.',
)
class SystemErrorCodeEntry extends DocSpecsSection {
  @Form([
    Field(
      'errorCode',
      String,
      'Error Code',
      required: true,
      hint: 'System error code (e.g., ERR-NET-001)',
    ),
    Field(
      'httpStatus',
      int,
      'HTTP Status',
      hint: 'Associated HTTP status code',
    ),
    Field(
      'errorCategory',
      String,
      'Error Category',
      hint: 'Network, server, authentication, data',
    ),
    Field(
      'userMessage',
      String,
      'User Message',
      required: true,
      hint: 'User-friendly error message',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Recovery and display guidance.
  @SectionId('SECEH')
  @StandardReferences([
    'ISO 9241-13:1998 — user guidance offers clear suggested actions for recovering from an error',
    'ISO/IEC 25010:2023 — fault tolerance keeps the system usable through retry and recovery guidance',
  ], 'The recovery and display guidance for a system error code.')
  @Form([
    Field(
      'technicalDescription',
      String,
      'Technical Description',
      hint: 'Developer-facing description',
    ),
    Field(
      'suggestedAction',
      String,
      'Suggested Action',
      hint: 'What user should do',
    ),
    Field(
      'retryable',
      bool,
      'Retryable',
      hint: 'Whether retry is likely to help',
    ),
    Field(
      'autoRetry',
      bool,
      'Auto Retry',
      hint: 'System automatically retries',
    ),
    Field(
      'displayMethod',
      String,
      'Display Method',
      hint: 'How this error is displayed',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? handling;

  /// Operational support and logging controls.
  @SectionId('SECEO')
  @StandardReferences([
    'ISO/IEC 27001:2022 — event logging records error events at the appropriate severity level',
    'ISO/IEC 20000-1:2018 — incident handling routes error notifications to support functions',
  ], 'The operational support and logging controls for a system error code.')
  @Form([
    Field(
      'notifySupport',
      bool,
      'Notify Support',
      hint: 'Auto-notify support team',
    ),
    Field('logLevel', String, 'Log Level', hint: 'Error, warning, info'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? operations;
}

/// 10.7.3. Error Recovery.
///
/// Error recovery flows including data preservation, retry mechanisms,
/// and guided recovery steps.
@StandardReferences(
  [
    'ISO 9241-110:2020 — use-error tolerance lets users recover from errors with minimal effort',
    'ISO/IEC 25010:2023 — recoverability restores state and recovers affected data after a failure',
  ],
  'The error-recovery configuration covering data preservation, retry, and guided recovery.',
)
@SectionId('ERRE')
@CodeSpecKind(
  [CodeSpecPart.errorResult],
  note:
      'CE-ER — error-result display over the canonical structured error envelope.',
)
class ErrorRecovery extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Recovery Mechanisms
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('ERRE-RECO')
  @Form([
    Field(
      'formDataPreservation',
      String,
      'Form Data Preservation',
      hint: 'How unsaved form data is preserved on error',
    ),
    Field(
      'sessionRecovery',
      String,
      'Session Recovery',
      hint: 'How expired sessions are handled',
    ),
    Field(
      'supportContactMethod',
      String,
      'Support Contact Method',
      hint: 'Chat, email, phone, ticket',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? recoveryMechanismsContent;

  /// Data preservation: draft auto-save settings.
  @SectionId('ERDP')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — recoverability restores affected data after a failure so user work is not lost',
      'ISO 9241-110:2020 — use-error tolerance preserves user input so recovery requires minimal effort',
    ],
    'The data-preservation configuration describing draft auto-save so user input survives failures.',
  )
  @Form([
    Field(
      'draftAutoSave',
      bool,
      'Draft Auto-Save',
      hint: 'Automatic draft saving before submission',
    ),
    Field(
      'draftSaveInterval',
      String,
      'Draft Save Interval',
      hint: 'How often drafts are auto-saved',
    ),
    Field(
      'draftStorageMethod',
      String,
      'Draft Storage Method',
      hint: 'LocalStorage, IndexedDB, server-side',
    ),
    Field(
      'draftRetentionPeriod',
      String,
      'Draft Retention Period',
      hint: 'How long drafts are kept',
    ),
    Field(
      'draftRecoveryPrompt',
      String,
      'Draft Recovery Prompt',
      hint: 'How users are notified of recoverable drafts',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? dataPreservation;

  /// Retry mechanisms configuration.
  @SectionId('ERRM')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — fault tolerance keeps the system operating as intended despite faults by retrying failed operations',
      'ISO 9241-110:2020 — use-error tolerance allows users to reattempt an operation after a transient failure',
    ],
    'The retry-mechanism configuration describing automatic and manual reattempts after a failed operation.',
  )
  @Form([
    Field(
      'automaticRetryEnabled',
      bool,
      'Automatic Retry Enabled',
      hint: 'Whether failed operations are retried automatically',
    ),
    Field(
      'retryBackoffStrategy',
      String,
      'Retry Backoff Strategy',
      hint: 'Exponential, linear, fixed',
    ),
    Field(
      'maxAutomaticRetries',
      int,
      'Max Automatic Retries',
      hint: 'Maximum number of automatic retry attempts',
    ),
    Field(
      'manualRetryButton',
      bool,
      'Manual Retry Button',
      hint: 'Whether a user-triggered retry button is shown',
    ),
    Field(
      'retryButtonLabel',
      String,
      'Retry Button Label',
      hint: 'Button text (e.g., "Try Again")',
    ),
    Field(
      'retryFeedback',
      String,
      'Retry Feedback',
      hint: 'How retry attempts are indicated',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? retryMechanisms;

  /// Guided recovery options.
  @SectionId('ERGR')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — use-error tolerance guides users through corrective steps with minimal effort',
      'ISO 9241-13:1998 — user guidance offers constructive suggestions for recovering from an error',
    ],
    'The guided-recovery configuration describing step-by-step assistance and alternative actions after a failure.',
  )
  @Form([
    Field(
      'stepByStepRecovery',
      bool,
      'Step-by-Step Recovery',
      hint: 'Guided recovery wizard',
    ),
    Field(
      'alternativeActions',
      String,
      'Alternative Actions',
      hint: 'What else user can do',
    ),
    Field(
      'skipOption',
      bool,
      'Skip Option',
      hint: 'Allow skipping failed operation',
    ),
    Field(
      'cancelOption',
      bool,
      'Cancel Option',
      hint: 'Allow canceling and returning',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? guidedRecovery;

  /// Support contact details.
  @SectionId('ERSC')
  @StandardReferences(
    [
      'ISO/IEC 27001:2022 — Annex A controls require reporting and logging of events for incident escalation',
      'ISO 9241-13:1998 — user guidance provides a path to further help when an error cannot be self-resolved',
    ],
    'The support-contact configuration describing availability and error-report submission to reach assistance.',
  )
  @Form([
    Field(
      'supportAvailability',
      String,
      'Support Availability',
      hint: 'When support is available',
    ),
    Field(
      'errorReportSubmission',
      bool,
      'Error Report Submission',
      hint: 'Allow user to submit error report',
    ),
    Field(
      'includeDebugInfo',
      bool,
      'Include Debug Info',
      hint: 'Include technical details in report',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? supportContact;

  /// Session handling configuration.
  @SectionId('ERSH')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — recoverability restores data and state after a session interruption or failure',
      'ISO 9241-110:2020 — controllability lets users continue an interrupted task without loss of context',
    ],
    'The session-handling configuration describing reauthentication and context preservation after errors.',
  )
  @Form([
    Field(
      'reauthenticationFlow',
      String,
      'Reauthentication Flow',
      hint: 'Inline login, redirect, modal',
    ),
    Field(
      'preserveContextOnReauth',
      bool,
      'Preserve Context on Reauth',
      hint: 'Return to original location after reauth',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? sessionHandling;

  /// Error recovery narrative.
  @ContentHelp(
    'Detailed specification of error recovery flows '
    'and user empowerment strategies.',
  )
  @SerializationOrder(6)
  TextSection recoveryNarrative = TextSection();

  /// Recovery flow diagrams.
  @StandardReferences([
    'ISO 9241-110:2020 — use-error tolerance provides guided recovery steps after an error occurs',
    'ISO/IEC 25010:2023 — recoverability re-establishes a desired state and recovers affected data',
  ], 'The collection of recovery-flow entries.')
  @SectionId('RECOV-RECO-LST')
  @SectionIdPattern('RECOV-RECO-xxx')
  @ContentHelp('Add one entry per recovery flow.')
  @SerializationOrder(7)
  List<DocSpecsSection> recoveryFlows = [];

  /// Common recovery scenarios.
  @StandardReferences([
    'ISO 9241-110:2020 — use-error tolerance guides users through common failure situations toward recovery',
    'ISO/IEC 25010:2023 — recoverability restores a desired state after an interruption or failure',
  ], 'The collection of common recovery-scenario entries.')
  @SectionId('RCVSCN-RECO-LST')
  @SectionIdPattern('RCVSCN-RECO-xxx')
  @ContentHelp('Add one entry per common recovery scenario.')
  @SerializationOrder(8)
  List<RecoveryScenarioEntry> recoveryScenarios = [];
}

/// A recovery scenario entry.
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — recoverability restores affected data and re-establishes the desired system state after a failure',
    'ISO 9241-110:2020 — use-error tolerance helps users recover from errors with minimal effort',
  ],
  'The configuration for a single recovery scenario describing its trigger, impact, and recovery steps.',
)
@SectionId('RCVSCN')
@CodeSpecKind(
  [CodeSpecPart.errorResult],
  note:
      'CE-ER — error-result display over the canonical structured error envelope.',
)
class RecoveryScenarioEntry extends DocSpecsSection {
  @Form([
    Field(
      'scenarioId',
      String,
      'Scenario ID',
      required: true,
      hint: 'Unique identifier for this recovery scenario',
    ),
    Field(
      'scenarioName',
      String,
      'Scenario Name',
      required: true,
      hint: 'Descriptive name',
    ),
    Field(
      'triggerCondition',
      String,
      'Trigger Condition',
      hint: 'What error triggers this scenario',
    ),
    Field('userImpact', String, 'User Impact', hint: 'How user is affected'),
    Field(
      'recoverySteps',
      String,
      'Recovery Steps',
      hint: 'Step-by-step recovery process',
    ),
    Field(
      'dataAtRisk',
      String,
      'Data at Risk',
      hint: 'What data might be lost',
    ),
    Field(
      'preventionMeasures',
      String,
      'Prevention Measures',
      hint: 'How scenario can be prevented',
    ),
    Field(
      'timeToRecover',
      String,
      'Time to Recover',
      hint: 'Expected recovery duration',
    ),
    Field(
      'supportEscalation',
      String,
      'Support Escalation',
      hint: 'When to escalate to support',
    ),
  ])
  @override
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
@StandardReferences([
  'ISO 9241-13:1998 — user guidance provides help prompts and feedback on request',
  'ISO/IEC/IEEE 26514:2022 — designs and develops embedded user assistance',
  'ISO/IEC 25010:2023 — learnability and operability let users get help and succeed',
], 'The user-assistance configuration root for the in-app help system.')
@SectionId('USAS')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@CodeSpecKind(
  [CodeSpecPart.text],
  note:
      'CE-TX — UI text / i18n copy (help, placeholder, message templates, locale handling).',
)
class UserAssistance extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Help System Overview
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('USAS-HELP')
  @Form([
    // Help philosophy
    Field(
      'helpPhilosophy',
      String,
      'Help Philosophy',
      hint: 'Self-service first, guided, on-demand',
    ),
    Field(
      'helpAccessibility',
      String,
      'Help Accessibility',
      hint: 'Always visible, contextual, searchable',
    ),
    Field(
      'helpPersonalization',
      String,
      'Help Personalization',
      hint: 'Role-based, skill-based, contextual',
    ),
    // Help content
    Field(
      'helpContentStrategy',
      String,
      'Help Content Strategy',
      hint: 'Video, text, interactive, mixed',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? helpOverviewContent;

  /// Content stewardship and help affordances.
  @SectionId('USASDE')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26514:2022 — user assistance content is owned, maintained, and kept current',
      'ISO 9241-13:1998 — user guidance uses consistent help icons and tooltips',
    ],
    'The delivery settings covering help-content stewardship and help affordances.',
  )
  @Form([
    Field(
      'helpContentOwnership',
      String,
      'Help Content Ownership',
      hint: 'Who maintains help content',
    ),
    Field(
      'helpUpdateProcess',
      String,
      'Help Update Process',
      hint: 'How help content is kept current',
    ),
    Field(
      'helpIconStandard',
      String,
      'Help Icon Standard',
      hint: 'Question mark, info icon, custom',
    ),
    Field(
      'helpIconPlacement',
      String,
      'Help Icon Placement',
      hint: 'By field labels, in headers, floating',
    ),
    Field(
      'helpTooltipStyle',
      String,
      'Help Tooltip Style',
      hint: 'Tooltip design and behavior',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? delivery;

  /// Analytics and improvement feedback.
  @SectionId('USASIN')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26515:2018 — agile user assistance improves from usage feedback',
      'ISO/IEC 25010:2023 — learnability and operability are refined through analytics',
    ],
    'The insights settings that track help usage and gather improvement feedback.',
  )
  @Form([
    Field(
      'helpAnalytics',
      String,
      'Help Analytics',
      hint: 'Track help usage, identify gaps',
    ),
    Field(
      'helpFeedback',
      String,
      'Help Feedback',
      hint: 'Rate help articles, suggest improvements',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? insights;

  /// Help system overview narrative.
  @ContentHelp(
    'Executive summary of help system approach, '
    'content strategy, and user empowerment goals.',
  )
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

/// 10.8.1. Contextual Help.
@StandardReferences(
  [
    'ISO 9241-13:1998 — user guidance provides help prompts and feedback in context',
    'ISO/IEC/IEEE 26514:2022 — designs and develops embedded user assistance',
    'ISO 9241-110:2020 — self-descriptiveness lets the interface explain itself in place',
  ],
  'The contextual-help configuration providing on-screen assistance in context.',
)
@SectionId('COHE')
@CodeSpecKind(
  [CodeSpecPart.text],
  note:
      'CE-TX — UI text / i18n copy (help, placeholder, message templates, locale handling).',
)
class ContextualHelp extends DocSpecsSection {
  @SectionId('COHE-CONT')
  @Form([
    Field(
      'tooltipTrigger',
      String,
      'Tooltip Trigger',
      hint: 'Hover, click, focus, icon click',
    ),
    Field(
      'tooltipDelay',
      String,
      'Tooltip Delay',
      hint: 'Milliseconds before showing',
    ),
    Field(
      'tooltipDuration',
      String,
      'Tooltip Duration',
      hint: 'How long tooltip stays visible',
    ),
    Field(
      'tooltipMaxWidth',
      String,
      'Tooltip Max Width',
      hint: 'Maximum width in pixels',
    ),
    Field(
      'tooltipPosition',
      String,
      'Tooltip Position',
      hint: 'Above, below, auto-position',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? contextualHelpContent;

  /// Inline help behavior.
  @SectionId('COHEIN')
  @StandardReferences(
    [
      'ISO 9241-13:1998 — user guidance embeds prompts alongside the input elements',
      'ISO 9241-110:2020 — self-descriptiveness places explanatory text near the controls',
    ],
    'The inline-help settings that place explanatory text next to fields and labels.',
  )
  @Form([
    Field(
      'inlineHelpPlacement',
      String,
      'Inline Help Placement',
      hint: 'Below labels, below fields, expandable',
    ),
    Field(
      'inlineHelpVisibility',
      String,
      'Inline Help Visibility',
      hint: 'Always visible, on demand, progressive',
    ),
    Field(
      'inlineHelpLength',
      String,
      'Inline Help Length',
      hint: 'Max characters for inline help',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? inline;

  /// Help panel behavior.
  @SectionId('COHEPA')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26514:2022 — embedded user assistance presents help in a dedicated pane',
      'ISO 9241-125:2017 — visual presentation positions help panels relative to content',
    ],
    'The help-panel settings that govern a slide-out pane of contextual assistance.',
  )
  @Form([
    Field(
      'helpPanelAvailable',
      bool,
      'Help Panel Available',
      hint: 'Slide-out help panel',
    ),
    Field(
      'helpPanelPosition',
      String,
      'Help Panel Position',
      hint: 'Right side, bottom, overlay',
    ),
    Field(
      'helpPanelContent',
      String,
      'Help Panel Content',
      hint: 'Field help, page help, related articles',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? panels;

  /// What's-this mode settings.
  @SectionId('CHWT')
  @StandardReferences(
    [
      'ISO 9241-13:1998 — user guidance supplies point-and-ask help on request',
      'ISO 9241-110:2020 — self-descriptiveness lets the interface explain its elements on demand',
    ],
    'The what-this help-mode settings that let users ask about any element directly.',
  )
  @Form([
    Field(
      'whatsThisMode',
      bool,
      'What\'s This Mode',
      hint: 'Click-anywhere help mode',
    ),
    Field(
      'whatsThisActivation',
      String,
      'What\'s This Activation',
      hint: 'Keyboard shortcut, toolbar button',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? whatsThis;

  /// Rich help media settings.
  @SectionId('COHERI')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26514:2022 — embedded user assistance uses illustrations and multimedia',
      'ISO 9241-125:2017 — visual presentation governs images and rich media in help',
    ],
    'The rich-media settings that add screenshots, videos, and animations to help.',
  )
  @Form([
    Field(
      'helpScreenshots',
      bool,
      'Help Screenshots',
      hint: 'Include screenshots in help',
    ),
    Field('helpVideos', bool, 'Help Videos', hint: 'Include video tutorials'),
    Field(
      'helpAnimations',
      bool,
      'Help Animations',
      hint: 'Animated demonstrations',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? rich;

  /// Contextual help narrative.
  @SerializationOrder(5)
  TextSection contextualHelpNarrative = TextSection();

  /// Field help catalog.
  @StandardReferences(
    [
      'ISO 9241-143:2012 — forms provide field help for input controls',
      'ISO 9241-13:1998 — user guidance offers field-level help for input elements',
    ],
    'The collection of field-help entries for the input fields in the interface.',
  )
  @SectionId('FLDHP-FIEL-LST')
  @SectionIdPattern('FLDHP-FIEL-xxx')
  @ContentHelp('Add one entry per field that needs contextual help.')
  @SerializationOrder(6)
  List<FieldHelpEntry> fieldHelpCatalog = [];
}

/// A field help entry.
@StandardReferences([
  'ISO 9241-143:2012 — forms provide help for individual input fields',
  'ISO 9241-13:1998 — user guidance offers field-level help for input elements',
], 'A single field-help entry describing the assistance for one input field.')
@SectionId('FLDHP')
@CodeSpecKind(
  [CodeSpecPart.text],
  note:
      'CE-TX — UI text / i18n copy (help, placeholder, message templates, locale handling).',
)
class FieldHelpEntry extends DocSpecsSection {
  @Form([
    Field(
      'fieldId',
      String,
      'Field ID',
      required: true,
      hint: 'Unique identifier of the field',
    ),
    Field(
      'fieldLabel',
      String,
      'Field Label',
      required: true,
      hint: 'Display label of the field',
    ),
    Field('tooltipText', String, 'Tooltip Text', hint: 'Brief tooltip content'),
    Field(
      'inlineHelpText',
      String,
      'Inline Help Text',
      hint: 'Longer inline help',
    ),
    Field(
      'extendedHelp',
      String,
      'Extended Help',
      hint: 'Full help panel content',
    ),
    Field(
      'relatedArticles',
      String,
      'Related Articles',
      hint: 'Links to related help articles',
    ),
    Field(
      'exampleValues',
      String,
      'Example Values',
      hint: 'Examples of valid input',
    ),
    Field(
      'commonMistakes',
      String,
      'Common Mistakes',
      hint: 'Frequently made errors',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 10.8.2. Onboarding Help.
@StandardReferences(
  [
    'ISO/IEC/IEEE 26514:2022 — designs and develops user assistance and onboarding content',
    'ISO/IEC 25010:2023 — learnability lets users learn to operate the system with ease',
  ],
  'A single onboarding-help configuration guiding new users through the interface.',
)
@SectionId('ONHE')
@CodeSpecKind(
  [CodeSpecPart.text],
  note:
      'CE-TX — UI text / i18n copy (help, placeholder, message templates, locale handling).',
)
class OnboardingHelp extends DocSpecsSection {
  @SectionId('ONHE-ONBO')
  @Form([
    Field(
      'welcomeFlowEnabled',
      bool,
      'Welcome Flow Enabled',
      hint: 'Whether the welcome flow is enabled',
    ),
    Field(
      'welcomeFlowStyle',
      String,
      'Welcome Flow Style',
      hint: 'Modal wizard, full-page, inline',
    ),
    Field(
      'welcomeFlowSkippable',
      bool,
      'Welcome Flow Skippable',
      hint: 'Whether users can skip the welcome flow',
    ),
    Field(
      'welcomeFlowDuration',
      String,
      'Welcome Flow Duration',
      hint: 'Expected completion time',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? onboardingContent;

  /// Feature tour settings.
  @SectionId('ONHETO')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26514:2022 — configures guided feature tours as a form of interactive user assistance',
      'ISO 9241-13:1998 — presents guidance and prompts that orient users to available features',
    ],
    'The feature-tour settings controlling tour style, trigger, and progress display.',
  )
  @Form([
    Field(
      'featureToursEnabled',
      bool,
      'Feature Tours Enabled',
      hint: 'Whether feature tours are enabled',
    ),
    Field(
      'featureTourStyle',
      String,
      'Feature Tour Style',
      hint: 'Spotlight, coach marks, carousel',
    ),
    Field(
      'featureTourTrigger',
      String,
      'Feature Tour Trigger',
      hint: 'First visit, after action, manual',
    ),
    Field(
      'featureTourProgress',
      bool,
      'Feature Tour Progress',
      hint: 'Show progress indicator',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? tours;

  /// Sample data settings.
  @SectionId('OHSD')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26514:2022 — supplies example data so users can learn the system through hands-on exploration',
      'ISO/IEC 25010:2023 — supports learnability by letting users practise with representative sample content',
    ],
    'The sample-data settings that let new users explore the system with example content.',
  )
  @Form([
    Field(
      'sampleDataAvailable',
      bool,
      'Sample Data Available',
      hint: 'Whether sample data is provided',
    ),
    Field(
      'sampleDataScope',
      String,
      'Sample Data Scope',
      hint: 'What sample data is provided',
    ),
    Field(
      'sampleDataClear',
      String,
      'Sample Data Clear',
      hint: 'How users remove sample data',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? sampleData;

  /// Getting started checklist configuration.
  @SectionId('ONHECH')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26514:2022 — presents onboarding tasks as a checklist that guides new users to completion',
      'ISO/IEC 25010:2023 — supports learnability by tracking progress through initial setup tasks',
    ],
    'The getting-started checklist configuration guiding new users through setup tasks.',
  )
  @Form([
    Field(
      'gettingStartedChecklist',
      bool,
      'Getting Started Checklist',
      hint: 'Show a getting-started checklist to new users',
    ),
    Field(
      'checklistItems',
      String,
      'Checklist Items',
      hint: 'Setup tasks to complete',
    ),
    Field(
      'checklistProgress',
      String,
      'Checklist Progress',
      hint: 'How progress is shown',
    ),
    Field(
      'checklistRewards',
      String,
      'Checklist Rewards',
      hint: 'Gamification elements',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? checklist;

  /// Progressive disclosure configuration.
  @SectionId('ONHEDI')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — reveals functionality progressively to keep the interface suitable for learning',
      'ISO/IEC 25010:2023 — adapts to user skill level to improve learnability and operability',
    ],
    'The progressive-disclosure configuration that reveals features as users gain skill.',
  )
  @Form([
    Field(
      'progressiveDisclosure',
      String,
      'Progressive Disclosure',
      hint: 'How features are revealed over time',
    ),
    Field(
      'skillLevelAdaptation',
      String,
      'Skill Level Adaptation',
      hint: 'Adapt to user skill level',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? disclosure;

  /// Returning user experience.
  @SectionId('ONHERE')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26514:2022 — provides ongoing assistance that re-engages returning users with new content',
      'ISO/IEC 25010:2023 — supports appropriateness recognisability so returning users recognise what changed',
    ],
    'The re-engagement experience shown to returning users, including new-feature highlights.',
  )
  @Form([
    Field(
      'returnUserWelcome',
      String,
      'Return User Welcome',
      hint: 'Message for returning users',
    ),
    Field(
      'whatsNewFeature',
      bool,
      'What\'s New Feature',
      hint: 'Show new features to returning users',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? reengagement;

  /// Onboarding narrative.
  @SerializationOrder(6)
  TextSection onboardingNarrative = TextSection();

  /// Feature tour definitions.
  @StandardReferences([
    'ISO/IEC/IEEE 26514:2022 — develops a set of guided tutorials that introduce product features',
  ], 'The collection of feature-tour definitions offered during onboarding.')
  @SectionId('FTRTUR-FEAT-LST')
  @SectionIdPattern('FTRTUR-FEAT-xxx')
  @ContentHelp('Add one entry per feature tour.')
  @SerializationOrder(7)
  List<FeatureTourEntry> featureTours = [];
}

/// A feature tour entry.
@StandardReferences([
  'ISO/IEC/IEEE 26514:2022 — develops guided tutorials that walk users through product features',
  'ISO/IEC 25010:2023 — supports learnability so users can learn to operate the feature with ease',
], 'A single feature-tour definition, including audience, trigger, and steps.')
@SectionId('FTRTUR')
@CodeSpecKind(
  [CodeSpecPart.text],
  note:
      'CE-TX — UI text / i18n copy (help, placeholder, message templates, locale handling).',
)
class FeatureTourEntry extends DocSpecsSection {
  @Form([
    Field(
      'tourId',
      String,
      'Tour ID',
      required: true,
      hint: 'Unique identifier for this tour',
    ),
    Field(
      'tourName',
      String,
      'Tour Name',
      required: true,
      hint: 'Display name of the tour',
    ),
    Field(
      'tourDescription',
      String,
      'Tour Description',
      hint: 'Short summary of what the tour covers',
    ),
    Field(
      'targetAudience',
      String,
      'Target Audience',
      hint: 'New users, specific role, all',
    ),
    Field(
      'triggerCondition',
      String,
      'Trigger Condition',
      hint: 'When tour is shown',
    ),
    Field('stepCount', int, 'Step Count', hint: 'Number of steps in the tour'),
    Field(
      'estimatedDuration',
      String,
      'Estimated Duration',
      hint: 'Expected time to complete the tour',
    ),
    Field(
      'skippable',
      bool,
      'Skippable',
      hint: 'Whether users can skip the tour',
    ),
    Field(
      'repeatPolicy',
      String,
      'Repeat Policy',
      hint: 'Once only, on request, periodic',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Tour steps.
  @StandardReferences([
    'ISO/IEC/IEEE 26514:2022 — organises assistance into sequential guided steps',
  ], 'The collection of guided-tour step entries for this feature tour.')
  @SectionId('TURST-STEP-LST')
  @SectionIdPattern('TURST-STEP-xxx')
  @ContentHelp('Add one entry per guided-tour step.')
  @SerializationOrder(1)
  List<TourStepEntry> steps = [];
}

/// A tour step entry.
@StandardReferences(
  [
    'ISO/IEC/IEEE 26514:2022 — presents guided assistance as ordered steps that highlight interface elements',
    'ISO 9241-13:1998 — delivers context-sensitive prompts and guidance at each step of a task',
  ],
  'A single step within a guided feature tour, targeting one interface element.',
)
@SectionId('TURST')
@CodeSpecKind(
  [CodeSpecPart.text],
  note:
      'CE-TX — UI text / i18n copy (help, placeholder, message templates, locale handling).',
)
class TourStepEntry extends DocSpecsSection {
  @Form([
    Field(
      'stepOrder',
      int,
      'Step Order',
      required: true,
      hint: 'Sequence position of this step',
    ),
    Field(
      'targetElement',
      String,
      'Target Element',
      hint: 'Element to highlight',
    ),
    Field(
      'stepTitle',
      String,
      'Step Title',
      hint: 'Short title shown for this step',
    ),
    Field(
      'stepContent',
      String,
      'Step Content',
      required: true,
      hint: 'Explanatory text shown for this step',
    ),
    Field('placement', String, 'Placement', hint: 'Position of coach mark'),
    Field(
      'actionRequired',
      String,
      'Action Required',
      hint: 'User action to proceed',
    ),
    Field(
      'spotlightShape',
      String,
      'Spotlight Shape',
      hint: 'Circle, rectangle, custom',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 10.8.3. Support Access.
@StandardReferences(
  [
    'ISO/IEC 20000-1:2018 — establishes the support channels through which users request assistance and report incidents',
    'ISO/IEC/IEEE 26511:2018 — manages the assistance and support made available to users of the system',
  ],
  'The overall support-access configuration spanning help centre, live support, tickets, contacts, and self-service.',
)
@SectionId('SUAC')
class SupportAccess extends DocSpecsSection {
  @SectionId('SUAC-SUPP')
  @Form([
    Field(
      'helpCenterAvailable',
      bool,
      'Help Center Available',
      hint: 'Whether a help centre is provided',
    ),
    Field(
      'liveChatAvailable',
      bool,
      'Live Chat Available',
      hint: 'Whether live chat support is provided',
    ),
    Field(
      'ticketSubmission',
      bool,
      'Ticket Submission',
      hint: 'Whether users can submit support tickets',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? supportAccessContent;

  /// Help center configuration.
  @SectionId('SAHC')
  @StandardReferences(
    [
      'ISO/IEC/IEEE 26514:2022 — organises user assistance into a searchable, categorised help repository',
      'ISO/IEC 20000-1:2018 — offers a knowledge base as a self-service support channel',
    ],
    'The help-centre configuration covering location, search, and article categories.',
  )
  @Form([
    Field(
      'helpCenterLocation',
      String,
      'Help Center Location',
      hint: 'In-app, external, hybrid',
    ),
    Field(
      'helpCenterSearch',
      bool,
      'Help Center Search',
      hint: 'Searchable knowledge base',
    ),
    Field(
      'helpArticleCategories',
      String,
      'Article Categories',
      hint: 'How help is organized',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? helpCenter;

  /// Live support settings.
  @SectionId('SALS')
  @StandardReferences([
    'ISO/IEC 20000-1:2018 — provides interactive support channels staffed within defined availability hours',
    'ISO/IEC/IEEE 26514:2022 — supplements documented assistance with real-time support interactions',
  ], 'The live-support settings covering chat hours and chatbot handling.')
  @Form([
    Field(
      'liveChatHours',
      String,
      'Live Chat Hours',
      hint: 'Availability hours',
    ),
    Field(
      'chatbotFirstLine',
      bool,
      'Chatbot First Line',
      hint: 'Chatbot before human',
    ),
    Field(
      'chatbotCapabilities',
      String,
      'Chatbot Capabilities',
      hint: 'What chatbot can handle',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? liveSupport;

  /// Ticket system configuration.
  @SectionId('SUACTI')
  @StandardReferences(
    [
      'ISO/IEC 20000-1:2018 — records requests and incidents as tickets and manages them to resolution within agreed targets',
    ],
    'The support-ticket system configuration for submitting and tracking requests.',
  )
  @Form([
    Field(
      'ticketFormFields',
      String,
      'Ticket Form Fields',
      hint: 'Required ticket information',
    ),
    Field(
      'ticketAttachments',
      bool,
      'Ticket Attachments',
      hint: 'Allow file attachments',
    ),
    Field(
      'ticketResponseSla',
      String,
      'Ticket Response SLA',
      hint: 'Expected response time',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? tickets;

  /// Contact methods.
  @SectionId('SACM')
  @StandardReferences([
    'ISO/IEC 20000-1:2018 — makes support contact channels available so users can reach the service provider',
    'ISO/IEC/IEEE 26511:2018 — identifies the channels through which users obtain assistance',
  ], 'The contact methods through which users can reach support.')
  @Form([
    Field(
      'emailSupport',
      bool,
      'Email Support',
      hint: 'Offer support by email',
    ),
    Field(
      'phoneSupport',
      bool,
      'Phone Support',
      hint: 'Offer support by phone',
    ),
    Field(
      'phoneNumber',
      String,
      'Phone Number',
      hint: 'Published support phone number',
    ),
    Field(
      'communityForum',
      bool,
      'Community Forum',
      hint: 'Offer a community forum for peer support',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? contactMethods;

  /// Self-service and feedback options.
  @SectionId('SASS')
  @StandardReferences([
    'ISO/IEC 20000-1:2018 — provides self-service channels so users can resolve requests without agent involvement',
    'ISO/IEC/IEEE 26514:2022 — supplies self-help assistance content such as FAQs and troubleshooting guides',
  ], 'The self-service and feedback options offered alongside assisted support.')
  @Form([
    Field(
      'faqSection',
      bool,
      'FAQ Section',
      hint: 'Offer a frequently asked questions section',
    ),
    Field(
      'troubleshootingGuides',
      bool,
      'Troubleshooting Guides',
      hint: 'Provide step-by-step troubleshooting guides',
    ),
    Field(
      'videoTutorials',
      bool,
      'Video Tutorials',
      hint: 'Offer instructional video tutorials',
    ),
    Field(
      'releaseNotes',
      bool,
      'Release Notes',
      hint: 'Publish release notes for updates',
    ),
    Field(
      'feedbackButton',
      bool,
      'Feedback Button',
      hint: 'Always-visible feedback option',
    ),
    Field(
      'featureRequests',
      bool,
      'Feature Requests',
      hint: 'Submit feature requests',
    ),
    Field('bugReporting', bool, 'Bug Reporting', hint: 'Report bugs from app'),
  ])
  @SerializationOrder(5)
  DocSpecsSection? selfService;

  /// Support access narrative.
  @SerializationOrder(6)
  TextSection supportAccessNarrative = TextSection();
}

// ---------------------------------------------------------------------------
// 10.9 Accessibility
// ---------------------------------------------------------------------------

/// 10.9. Accessibility.
///
/// Comprehensive accessibility requirements for the user interface following
/// WCAG guidelines and inclusive design principles.
@StandardReferences(
  [
    'W3C WCAG 2.2 — content is perceivable, operable, understandable, and robust for all users',
    'EN 301 549 — European ICT accessibility requirements apply to the interactive product',
  ],
  'The accessibility configuration describing how the interface serves users with disabilities.',
)
@SectionId('ACCESS')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
class Accessibility extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Accessibility Overview
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('ACCESS-ACCE')
  @Form([
    Field(
      'wcagComplianceTarget',
      String,
      'WCAG Compliance Target',
      hint: 'A, AA, AAA',
    ),
    Field('wcagVersion', String, 'WCAG Version', hint: '2.0, 2.1, 2.2'),
    Field(
      'additionalStandards',
      String,
      'Additional Standards',
      hint: 'Section 508, EN 301 549, ADA',
    ),
    Field(
      'accessibilityStatement',
      bool,
      'Accessibility Statement',
      hint: 'Publish accessibility statement',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? accessibilityOverviewContent;

  /// Ownership and inclusive design philosophy.
  @SectionId('ACSTGY')
  @StandardReferences(
    [
      'ISO 30071-1:2019 — accessibility is embedded into the organization through defined ownership and inclusive design practices',
      'W3C WCAG 2.2 — an inclusive design strategy delivers an equivalent experience for users with disabilities',
    ],
    'The organizational strategy for accessibility including ownership, philosophy, and team training.',
  )
  @Form([
    Field(
      'accessibilityPhilosophy',
      String,
      'Accessibility Philosophy',
      hint: 'Inclusive design, equivalent experience',
    ),
    Field(
      'accessibilityOwnership',
      String,
      'Accessibility Ownership',
      hint: 'Who is responsible for accessibility',
    ),
    Field(
      'accessibilityTraining',
      String,
      'Accessibility Training',
      hint: 'Team training requirements',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? strategy;

  /// Accessibility testing approach.
  @SectionId('ACTE')
  @StandardReferences(
    [
      'W3C WCAG 2.2 — conformance is evaluated by testing each success criterion with automated and manual methods',
      'EN 301 549 — accessibility is verified through testing including evaluation with assistive technologies',
    ],
    'The approach for testing accessibility through automated tools, manual review, and user testing.',
  )
  @Form([
    Field(
      'automatedTestingTools',
      String,
      'Automated Testing Tools',
      hint: 'axe, WAVE, Lighthouse',
    ),
    Field(
      'manualTestingProcess',
      String,
      'Manual Testing Process',
      hint: 'How manual testing is performed',
    ),
    Field(
      'assistiveTechTesting',
      String,
      'Assistive Tech Testing',
      hint: 'Screen readers, switch devices',
    ),
    Field(
      'userTestingWithDisabilities',
      bool,
      'User Testing with Disabilities',
      hint: 'Include users with disabilities',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? testing;

  /// Supported assistive technologies and platform features.
  @SectionId('ACSU')
  @StandardReferences(
    [
      'W3C WAI-ARIA — user interface semantics are exposed so screen readers and other assistive technologies can convey them',
      'ISO 9241-171:2008 — software provides support for assistive technologies and platform accessibility features',
    ],
    'The assistive technologies and platform accessibility features the interface supports.',
  )
  @Form([
    Field(
      'targetScreenReaders',
      String,
      'Target Screen Readers',
      hint: 'NVDA, JAWS, VoiceOver, TalkBack',
    ),
    Field(
      'targetBrowserAccessibility',
      String,
      'Target Browser Accessibility',
      hint: 'Browser accessibility features used',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? support;

  /// Accessibility overview narrative.
  @ContentHelp(
    'Executive summary of accessibility approach, '
    'compliance targets, and inclusive design principles.',
  )
  @SerializationOrder(4)
  TextSection accessibilityOverview = TextSection();

  /// 10.9.1. WCAG Compliance Level.
  @SerializationOrder(5)
  WcagCompliance wcagComplianceLevel = WcagCompliance();

  /// 10.9.2. Accessibility Checklist.
  @SerializationOrder(6)
  AccessibilityChecklist accessibilityChecklist = AccessibilityChecklist();

  /// Keyboard navigation specification.
  @ContentHelp(
    'Keyboard navigation patterns, focus management, '
    'and keyboard shortcuts.',
  )
  @SerializationOrder(7)
  TextSection keyboardNavigation = TextSection();

  /// Screen reader support specification.
  @ContentHelp(
    'Screen reader support: ARIA labels, landmarks, '
    'live regions, and announcements.',
  )
  @SerializationOrder(8)
  TextSection screenReaderSupport = TextSection();

  /// Color and contrast specification.
  @ContentHelp(
    'Color contrast requirements, color-blind-friendly '
    'design, and non-color indicators.',
  )
  @SerializationOrder(9)
  TextSection colorAndContrast = TextSection();
}

/// 10.9.1. WCAG Compliance Level.
@StandardReferences(
  [
    'W3C WCAG 2.2 — conformance is claimed at level A, AA, or AAA against the success criteria',
    'ISO/IEC 40500:2012 — WCAG adopted as an international standard for web content accessibility',
  ],
  'The overall WCAG conformance level and the mapping of success criteria for the interface.',
)
@SectionId('WCCO')
class WcagCompliance extends DocSpecsSection {
  @SectionId('WCCO-WCAG')
  @Form([
    Field(
      'textAlternatives',
      String,
      'Text Alternatives (1.1)',
      hint: 'Alt text for non-text content',
    ),
    Field(
      'timeBasedMedia',
      String,
      'Time-Based Media (1.2)',
      hint: 'Captions, audio descriptions',
    ),
    Field(
      'adaptableContent',
      String,
      'Adaptable Content (1.3)',
      hint: 'Structure, sequence, sensory',
    ),
    Field(
      'distinguishableContent',
      String,
      'Distinguishable (1.4)',
      hint: 'Color, contrast, resize, audio',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? wcagComplianceContent;

  /// Operable principles.
  @SectionId('WCCOOP')
  @StandardReferences(
    [
      'W3C WCAG 2.2 — user interface components and navigation are operable by all users',
      'EN 301 549 — the interactive product supports keyboard operation, adjustable timing, and safe input modalities',
    ],
    'The WCAG operable principle requirements covering keyboard access, timing, navigation, and input modalities.',
  )
  @Form([
    Field(
      'keyboardAccessible',
      String,
      'Keyboard Accessible (2.1)',
      hint: 'Full keyboard operation',
    ),
    Field(
      'enoughTime',
      String,
      'Enough Time (2.2)',
      hint: 'Adjustable timing, pause',
    ),
    Field(
      'seizureSafe',
      String,
      'Seizure Safe (2.3)',
      hint: 'No flashing content',
    ),
    Field(
      'navigable',
      String,
      'Navigable (2.4)',
      hint: 'Skip links, page titles, focus',
    ),
    Field(
      'inputModalities',
      String,
      'Input Modalities (2.5)',
      hint: 'Pointer, motion, touch',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? operable;

  /// Understandable principles.
  @SectionId('WCCOUN')
  @StandardReferences(
    [
      'W3C WCAG 2.2 — information and the operation of the user interface are understandable to all users',
      'EN 301 549 — the interactive product presents readable, predictable content with input assistance',
    ],
    'The WCAG understandable principle requirements covering readability, predictability, and input assistance.',
  )
  @Form([
    Field(
      'readable',
      String,
      'Readable (3.1)',
      hint: 'Language, abbreviations',
    ),
    Field(
      'predictable',
      String,
      'Predictable (3.2)',
      hint: 'Consistent navigation, identification',
    ),
    Field(
      'inputAssistance',
      String,
      'Input Assistance (3.3)',
      hint: 'Error prevention, labels, suggestions',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? understandable;

  /// Robustness requirements.
  @SectionId('WCCORO')
  @StandardReferences(
    [
      'W3C WCAG 2.2 — content is robust enough to be interpreted reliably by a wide variety of user agents including assistive technologies',
      'W3C WAI-ARIA — name, role, and value are exposed so assistive technologies can interpret user interface components',
    ],
    'The WCAG robust principle requirements ensuring compatibility with assistive technologies.',
  )
  @Form([
    Field(
      'compatible',
      String,
      'Compatible (4.1)',
      hint: 'Parsing, name/role/value',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? robust;

  /// WCAG compliance narrative.
  @SerializationOrder(4)
  TextSection wcagNarrative = TextSection();

  /// WCAG success criteria mapping.
  @StandardReferences([
    'W3C WCAG 2.2 — each success criterion states a testable accessibility requirement',
    'ISO/IEC 40500:2012 — the WCAG success criteria adopted as an international standard',
  ], 'The collection of WCAG success-criterion entries.')
  @SectionId('WSCE-SUCC-LST')
  @SectionIdPattern('WSCE-SUCC-xxx')
  @ContentHelp('Add one entry per WCAG success criterion.')
  @SerializationOrder(5)
  List<WcagSuccessCriterionEntry> successCriteria = [];
}

/// A WCAG success criterion entry.
@StandardReferences(
  [
    'W3C WCAG 2.2 — each success criterion states a single testable requirement at level A, AA, or AAA',
    'ISO/IEC 40500:2012 — the WCAG success criteria adopted as an international standard',
  ],
  'A single WCAG success criterion with its level, applicability, and conformance status.',
)
@SectionId('WCSUCREN')
class WcagSuccessCriterionEntry extends DocSpecsSection {
  @Form([
    Field(
      'criterionId',
      String,
      'Criterion ID',
      required: true,
      hint: 'WCAG SC ID (e.g., 1.4.3)',
    ),
    Field(
      'criterionName',
      String,
      'Criterion Name',
      required: true,
      hint: 'Name of the success criterion (e.g., Contrast Minimum)',
    ),
    Field('level', String, 'Level', hint: 'A, AA, AAA'),
    Field(
      'applicability',
      String,
      'Applicability',
      hint: 'Where this applies in the app',
    ),
    Field(
      'implementation',
      String,
      'Implementation',
      hint: 'How we meet this criterion',
    ),
    Field(
      'testingMethod',
      String,
      'Testing Method',
      hint: 'How compliance is verified',
    ),
    Field(
      'status',
      String,
      'Status',
      hint: 'Not started, in progress, compliant, not applicable',
    ),
    Field(
      'exceptions',
      String,
      'Exceptions',
      hint: 'Any documented exceptions',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 10.9.2. Accessibility Checklist.
///
/// Comprehensive accessibility verification checklist.
@StandardReferences([
  'W3C WCAG 2.2 — the checklist covers the success criteria across the four POUR principles',
  'EN 301 549 — accessibility verification follows the applicable European ICT requirements',
], 'The comprehensive checklist used to verify accessibility conformance.')
@SectionId('ACCHLS')
class AccessibilityChecklist extends DocSpecsSection {
  @SectionId('ACCHLS-CHEC')
  @Form([
    Field(
      'checklistStandard',
      String,
      'Checklist Standard',
      hint: 'Based on WCAG, custom additions',
    ),
    Field(
      'checklistOwner',
      String,
      'Checklist Owner',
      hint: 'Who maintains the checklist',
    ),
    Field(
      'checkFrequency',
      String,
      'Check Frequency',
      hint: 'Per feature, per release, continuous',
    ),
    Field(
      'automatedChecks',
      String,
      'Automated Checks',
      hint: 'Automated accessibility testing coverage',
    ),
    Field(
      'manualChecks',
      String,
      'Manual Checks',
      hint: 'Manual testing procedures',
    ),
    Field(
      'userTesting',
      String,
      'User Testing',
      hint: 'Testing with users with disabilities',
    ),
    Field(
      'reportingFormat',
      String,
      'Reporting Format',
      hint: 'How accessibility status is reported',
    ),
    Field(
      'remediationProcess',
      String,
      'Remediation Process',
      hint: 'How issues are fixed',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? checklistOverviewContent;

  /// Accessibility checklist overview.
  @SerializationOrder(1)
  TextSection checklistOverview = TextSection();

  /// Contains 0+× AccessibilityCheck.
  @StandardReferences([
    'W3C WCAG 2.2 — the checklist enumerates testable success criteria for the interactive product',
    'EN 301 549 — accessibility requirements are enumerated as verifiable checklist items',
  ], 'The collection of accessibility checklist entries.')
  @SectionId('ACCH-ITEM-LST')
  @SectionIdPattern('ACCH-ITEM-xxx')
  @ContentHelp('Add one entry per accessibility check.')
  @SerializationOrder(2)
  List<AccessibilityCheckEntry> items = [];
}

/// An accessibility check entry (form).
@StandardReferences([
  'W3C WCAG 2.2 — each checklist item verifies a testable success criterion of the interactive product',
  'EN 301 549 — the product is checked against the applicable accessibility requirements',
], 'A single accessibility checklist entry describing what is verified and how.')
@SectionId('ACCH')
class AccessibilityCheckEntry extends DocSpecsSection {
  @Form([
    Field(
      'checkId',
      String,
      'Check ID',
      required: true,
      hint: 'Unique identifier for this check (e.g., ACCH-001)',
    ),
    Field(
      'checkItem',
      String,
      'Check Item',
      required: true,
      hint: 'What is being checked',
    ),
    Field(
      'checkDescription',
      String,
      'Check Description',
      hint: 'Detailed description',
    ),
    Field(
      'verificationMethod',
      String,
      'Verification Method',
      required: true,
      hint: 'Automated, manual, user testing',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// WCAG mapping and compliance classification.
  @SectionId('ACEC')
  @StandardReferences(
    [
      'W3C WCAG 2.2 — each check maps to a success criterion at conformance level A, AA, or AAA',
      'EN 301 549 — accessibility requirements are mapped to the applicable success criteria',
    ],
    'The mapping of an accessibility check to its WCAG success criterion and conformance level.',
  )
  @Form([
    Field(
      'wcagCriterion',
      String,
      'WCAG Criterion',
      hint: 'Related WCAG success criterion',
    ),
    Field('complianceLevel', String, 'Compliance Level', hint: 'A, AA, AAA'),
    Field(
      'checkCategory',
      String,
      'Check Category',
      hint: 'Perceivable, operable, understandable, robust',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? compliance;

  /// Testing execution ownership and status.
  @SectionId('ACEE')
  @StandardReferences([
    'W3C WCAG 2.2 — conformance is verified by testing each success criterion for the interactive product',
    'EN 301 549 — accessibility conformance is evaluated and the results are recorded',
  ], 'The ownership, tooling, and status of executing an accessibility check.')
  @Form([
    Field(
      'testingTool',
      String,
      'Testing Tool',
      hint: 'Specific tool or technique',
    ),
    Field(
      'responsibleParty',
      String,
      'Responsible Party',
      hint: 'Developer, QA, accessibility specialist',
    ),
    Field(
      'checkStatus',
      String,
      'Check Status',
      hint: 'Not tested, passed, failed, n/a',
    ),
    Field(
      'testDate',
      String,
      'Test Date',
      hint: 'Date the check was performed',
    ),
    Field('testedBy', String, 'Tested By', hint: 'Name or role of the tester'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? execution;

  /// Issue tracking and remediation details.
  @SectionId('ACER')
  @StandardReferences(
    [
      'W3C WCAG 2.2 — accessibility conformance failures are documented and remediated to meet the success criteria',
      'EN 301 549 — the interactive product records and resolves accessibility non-conformances',
    ],
    'The record of accessibility issues found during checking and the plan to remediate them.',
  )
  @Form([
    Field(
      'issuesFound',
      String,
      'Issues Found',
      hint: 'Description of any issues',
    ),
    Field(
      'remediationPlan',
      String,
      'Remediation Plan',
      hint: 'How issues will be fixed',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? remediation;
}

// ---------------------------------------------------------------------------
// 10.10 Responsive Design
// ---------------------------------------------------------------------------

/// 10.10. Responsive Design.
///
/// Comprehensive responsive design specification covering breakpoints,
/// adaptive layouts, and device-specific behavior for Flutter applications.
@StandardReferences(
  [
    'ISO 9241-125:2017 — presentation of information adapts the layout to the available display area',
    'W3C CSS — media queries let the interface respond to viewport size and capabilities',
    'WCAG 2.2 SC 1.4.10 Reflow — content reflows without loss of information or function at small viewports',
  ],
  'The responsive-design configuration describing how the interface adapts across viewports.',
)
@SectionId('REDE')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@CodeSpecKind(
  [CodeSpecPart.layout],
  note:
      'CE-LO — screen/region layout (unblocked by csm-2-2 layout-node + dsb6 tom_flutter_ui basis).',
)
class ResponsiveDesign extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Responsive Design Overview
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('REDE-RESP')
  @Form([
    // Philosophy
    Field(
      'responsivePhilosophy',
      String,
      'Responsive Philosophy',
      hint: 'Mobile-first, desktop-first, adaptive',
    ),
    Field(
      'primaryTargetDevice',
      String,
      'Primary Target Device',
      hint: 'Mobile phone, tablet, desktop',
    ),
    Field(
      'deviceAssumptions',
      String,
      'Device Assumptions',
      hint: 'Assumptions about target devices',
    ),
    // Framework approach
    Field(
      'responsiveFramework',
      String,
      'Responsive Framework',
      hint: 'LayoutBuilder, MediaQuery, responsive_framework',
    ),
    Field(
      'breakpointPackage',
      String,
      'Breakpoint Package',
      hint: 'Custom, responsive_framework, flutter_screenutil',
    ),
    Field(
      'orientationSupport',
      String,
      'Orientation Support',
      hint: 'Portrait only, landscape only, both',
    ),
    // Testing approach
    Field(
      'responsiveTestingApproach',
      String,
      'Responsive Testing Approach',
      hint: 'Device lab, emulator matrix, golden tests',
    ),
    Field(
      'targetDeviceMatrix',
      String,
      'Target Device Matrix',
      hint: 'List of target devices for testing',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? responsiveOverview;

  /// Responsive design narrative.
  @ContentHelp(
    'Overview of responsive design approach, '
    'key decisions, and implementation strategy.',
  )
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
@StandardReferences(
  [
    'W3C CSS Media Queries — breakpoints define the viewport widths at which the layout changes',
    'ISO 9241-125:2017 — the presentation adapts the layout to the available display area',
  ],
  'The configuration of viewport breakpoints, their units, and density handling for responsive layouts.',
)
@SectionId('BC')
@CodeSpecKind(
  [CodeSpecPart.layout],
  note:
      'CE-LO — screen/region layout (unblocked by csm-2-2 layout-node + dsb6 tom_flutter_ui basis).',
)
class BreakpointConfiguration extends DocSpecsSection {
  @SectionId('BC-BREA')
  @Form([
    // Standard breakpoints
    Field(
      'mobileMax',
      String,
      'Mobile Max Width',
      hint: 'Maximum width for mobile (e.g., 599)',
    ),
    Field(
      'tabletMin',
      String,
      'Tablet Min Width',
      hint: 'Minimum width for tablet (e.g., 600)',
    ),
    Field(
      'tabletMax',
      String,
      'Tablet Max Width',
      hint: 'Maximum width for tablet (e.g., 1023)',
    ),
    Field(
      'desktopMin',
      String,
      'Desktop Min Width',
      hint: 'Minimum width for desktop (e.g., 1024)',
    ),
    Field(
      'largeDesktopMin',
      String,
      'Large Desktop Min Width',
      hint: 'Minimum width for large screens (e.g., 1440)',
    ),
    // Additional breakpoints
    Field(
      'watchMax',
      String,
      'Watch Max Width',
      hint: 'Maximum width for wearables',
    ),
    Field(
      'foldableBreakpoint',
      String,
      'Foldable Breakpoint',
      hint: 'Breakpoint for foldable devices',
    ),
    Field(
      'customBreakpoints',
      String,
      'Custom Breakpoints',
      hint: 'Additional app-specific breakpoints',
    ),
    // Units and density
    Field(
      'breakpointUnit',
      String,
      'Breakpoint Unit',
      hint: 'Logical pixels, device pixels',
    ),
    Field(
      'densityHandling',
      String,
      'Density Handling',
      hint: 'How pixel density is handled',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? breakpointOverview;

  /// Breakpoint entries.
  @StandardReferences([
    'W3C CSS Media Queries — a breakpoint marks a viewport width at which the layout changes',
  ], 'The collection of layout breakpoint entries.')
  @SectionId('BRE-BREA-LST')
  @SectionIdPattern('BRE-BREA-xxx')
  @ContentHelp('Add one entry per layout breakpoint.')
  @SerializationOrder(1)
  List<BreakpointEntry> breakpoints = [];
}

/// A breakpoint entry.
@StandardReferences(
  [
    'W3C CSS Media Queries — a breakpoint marks a viewport width range at which the layout changes',
    'ISO 9241-125:2017 — the presentation adapts to the display area within the defined width range',
  ],
  'A single breakpoint entry defining a viewport width range and its associated layout and scaling rules.',
)
@SectionId('BE')
@CodeSpecKind(
  [CodeSpecPart.layout],
  note:
      'CE-LO — screen/region layout (unblocked by csm-2-2 layout-node + dsb6 tom_flutter_ui basis).',
)
class BreakpointEntry extends DocSpecsSection {
  @Form([
    Field(
      'breakpointId',
      String,
      'Breakpoint ID',
      required: true,
      hint: 'Unique identifier (e.g., TOM-MOBILE)',
    ),
    Field(
      'breakpointName',
      String,
      'Breakpoint Name',
      required: true,
      hint: 'Mobile, Tablet, Desktop, Large Desktop',
    ),
    Field(
      'minWidth',
      String,
      'Min Width',
      hint: 'Minimum width in logical pixels',
    ),
    Field(
      'maxWidth',
      String,
      'Max Width',
      hint: 'Maximum width in logical pixels',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Grid and layout rules for this breakpoint.
  @SectionId('BRENLA')
  @StandardReferences(
    [
      'W3C CSS — the grid layout adapts columns, gutters, and margins to the viewport at each breakpoint',
      'ISO 9241-125:2017 — the presentation arranges information within the available display area',
    ],
    'The grid columns, gutter, margin, and layout behavior applied at a given breakpoint.',
  )
  @Form([
    Field(
      'columns',
      int,
      'Grid Columns',
      hint: 'Number of grid columns at this breakpoint',
    ),
    Field('gutterWidth', String, 'Gutter Width', hint: 'Space between columns'),
    Field('marginWidth', String, 'Margin Width', hint: 'Edge margins'),
    Field(
      'layoutBehavior',
      String,
      'Layout Behavior',
      hint: 'How layout changes at this breakpoint',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? layout;

  /// Navigation and visual scaling rules.
  @SectionId('BRENSC')
  @StandardReferences(
    [
      'WCAG 2.2 SC 1.4.4 Resize text — typography scales without loss of content or function',
      'ISO/IEC 25010:2023 — adaptability tailors navigation and visual scaling to the display environment',
    ],
    'The navigation pattern and typography, spacing, and icon scaling applied at a given breakpoint.',
  )
  @Form([
    Field(
      'navigationPattern',
      String,
      'Navigation Pattern',
      hint: 'Bottom nav, drawer, rail, tabs',
    ),
    Field(
      'typographyScale',
      String,
      'Typography Scale',
      hint: 'Font size scaling factor',
    ),
    Field('spacingScale', String, 'Spacing Scale', hint: 'Spacing multiplier'),
    Field('iconScale', String, 'Icon Scale', hint: 'Icon size scaling factor'),
  ])
  @SerializationOrder(2)
  DocSpecsSection? scaling;
}

/// 10.10.2. Responsive Behavior.
///
/// How the UI adapts across breakpoints.
@StandardReferences(
  [
    'ISO 9241-125:2017 — the presentation of information adapts the layout to the available display area',
    'W3C Responsive Web Design — the interface responds to viewport changes across the full range of breakpoints',
    'WCAG 2.2 SC 1.4.10 Reflow — content adapts without loss at small viewports and high zoom',
  ],
  'The specification of how the interface adapts its layout, navigation, visibility, touch, and content across breakpoints.',
)
@SectionId('REBE')
@CodeSpecKind(
  [CodeSpecPart.layout],
  note:
      'CE-LO — screen/region layout (unblocked by csm-2-2 layout-node + dsb6 tom_flutter_ui basis).',
)
class ResponsiveBehavior extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Layout Adaptation
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('REBE-LAYO')
  @Form([
    Field(
      'mobileColumnLayout',
      String,
      'Mobile Column Layout',
      hint: 'Single column, stacked',
    ),
    Field(
      'tabletColumnLayout',
      String,
      'Tablet Column Layout',
      hint: '2-column, master-detail',
    ),
    Field(
      'desktopColumnLayout',
      String,
      'Desktop Column Layout',
      hint: '3-column, sidebar + main',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? layoutAdaptation;

  /// Navigation patterns per device class.
  @SectionId('REBENA')
  @StandardReferences(
    [
      'W3C Responsive Web Design — the navigation pattern adapts to the viewport size of each device class',
      'ISO/IEC 25010:2023 — adaptability selects a navigation form suited to the display environment',
    ],
    'The navigation patterns chosen for mobile, tablet, and desktop device classes.',
  )
  @Form([
    Field(
      'mobileNavigation',
      String,
      'Mobile Navigation',
      hint: 'Bottom nav bar, hamburger drawer',
    ),
    Field(
      'tabletNavigation',
      String,
      'Tablet Navigation',
      hint: 'Navigation rail, collapsible drawer',
    ),
    Field(
      'desktopNavigation',
      String,
      'Desktop Navigation',
      hint: 'Full sidebar, top navigation',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? navigation;

  /// Visibility rules.
  @SectionId('REBEVI')
  @StandardReferences(
    [
      'WCAG 2.2 SC 1.4.10 Reflow — showing or hiding elements per viewport keeps content usable without loss of function',
      'ISO/IEC 25010:2023 — adaptability tailors what is presented to the capabilities of the display environment',
    ],
    'The rules describing which elements are shown or hidden at each device class to keep the interface usable.',
  )
  @Form([
    Field(
      'mobileHiddenElements',
      String,
      'Mobile Hidden Elements',
      hint: 'Elements hidden on mobile',
    ),
    Field(
      'tabletHiddenElements',
      String,
      'Tablet Hidden Elements',
      hint: 'Elements hidden on tablet',
    ),
    Field(
      'desktopOnlyElements',
      String,
      'Desktop Only Elements',
      hint: 'Elements shown only on desktop',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? visibility;

  /// Touch and interaction optimizations.
  @SectionId('REBETO')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — operability requires interaction targets suited to the input device in use',
      'WCAG 2.2 SC 2.5.8 Target Size — touch targets are large enough to operate reliably on touch devices',
    ],
    'The rules optimizing touch targets, hover behavior, and gesture priority for the input capabilities of each device.',
  )
  @Form([
    Field(
      'touchTargetMinSize',
      String,
      'Touch Target Min Size',
      hint: 'Minimum touch target (48dp recommended)',
    ),
    Field(
      'hoverEffects',
      String,
      'Hover Effects',
      hint: 'When to show hover effects',
    ),
    Field(
      'gesturePriority',
      String,
      'Gesture Priority',
      hint: 'Swipe, long-press on touch devices',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? touch;

  /// Content reflow rules.
  @SectionId('REBECO')
  @StandardReferences(
    [
      'WCAG 2.2 SC 1.4.10 Reflow — content reflows into a single column without loss of information or function at small viewports',
      'W3C Responsive Web Design — content adapts fluidly as the viewport changes',
    ],
    'The rules describing how content, images, tables, and forms reflow as the viewport changes across breakpoints.',
  )
  @Form([
    Field(
      'contentReflowStrategy',
      String,
      'Content Reflow Strategy',
      hint: 'How content reflows across breakpoints',
    ),
    Field(
      'imageScaling',
      String,
      'Image Scaling',
      hint: 'How images scale responsively',
    ),
    Field(
      'tableResponsiveness',
      String,
      'Table Responsiveness',
      hint: 'Horizontal scroll, cards, hide columns',
    ),
    Field(
      'formLayout',
      String,
      'Form Layout',
      hint: 'How forms adapt: single column, multi-column',
    ),
  ])
  @SerializationOrder(4)
  String? contentReflow;

  /// Responsive behavior narrative.
  @ContentHelp(
    'Detailed description of responsive behavior '
    'across all breakpoints and device types.',
  )
  @SerializationOrder(5)
  TextSection behaviorNarrative = TextSection();

  /// Screen-specific responsive rules.
  @StandardReferences([
    'ISO 9241-125:2017 — presentation of information adapts per screen to the available display area',
  ], 'The collection of screen-specific responsive rule entries.')
  @SectionId('RESPSR-SCRE-LST')
  @SectionIdPattern('RESPSR-SCRE-xxx')
  @ContentHelp('Add one entry per screen with distinct responsive rules.')
  @SerializationOrder(6)
  List<ResponsiveScreenRuleEntry> screenRules = [];
}

/// A screen-specific responsive rule entry.
@StandardReferences(
  [
    'ISO 9241-125:2017 — the presentation of information adapts to the available display area for a given screen',
    'WCAG 2.2 SC 1.4.10 Reflow — the screen content reflows at small viewports without loss of information or function',
  ],
  'A single screen-specific responsive rule describing how one screen adapts across mobile, tablet, and desktop layouts.',
)
@SectionId('RESPSR')
@CodeSpecKind(
  [CodeSpecPart.layout],
  note:
      'CE-LO — screen/region layout (unblocked by csm-2-2 layout-node + dsb6 tom_flutter_ui basis).',
)
class ResponsiveScreenRuleEntry extends DocSpecsSection {
  @Form([
    Field(
      'screenId',
      String,
      'Screen ID',
      required: true,
      hint: 'Unique identifier of the screen this rule applies to',
      refersTo: ['SCREN.screenId'],
    ),
    Field(
      'screenName',
      String,
      'Screen Name',
      required: true,
      hint: 'Human-readable name of the screen',
    ),
    Field(
      'mobileLayout',
      String,
      'Mobile Layout',
      hint: 'How this screen is laid out on mobile',
    ),
    Field(
      'tabletLayout',
      String,
      'Tablet Layout',
      hint: 'How this screen is laid out on tablet',
    ),
    Field(
      'desktopLayout',
      String,
      'Desktop Layout',
      hint: 'How this screen is laid out on desktop',
    ),
    Field(
      'specialConsiderations',
      String,
      'Special Considerations',
      hint: 'Any screen-specific responsive notes or exceptions',
    ),
  ])
  @override
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
@StandardReferences(
  [
    'ISO 9241-161:2016 — visual user-interface elements are catalogued so they are used consistently',
    'ISO/IEC 25010:2023 — a shared component library supports maintainability through modularity and reuse',
    'ISO 9241-110:2020 — consistency principles govern the reuse of interface components',
  ],
  'The UI-components configuration describing the catalog of reusable interface components and the design system.',
)
@SectionId('UICO')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@CodeSpecKind(
  [CodeSpecPart.screenElement],
  note:
      'CE-EL — a screen element by semantic type then concrete implementation.',
)
class UiComponents extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Component Library Overview
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('UICO-COMP')
  @Form([
    Field(
      'designSystemName',
      String,
      'Design System Name',
      hint: 'Name of the design system (e.g., "Acme Design System")',
    ),
    Field(
      'designSystemVersion',
      String,
      'Design System Version',
      hint: 'Semantic version of the design system (e.g., "2.1.0")',
    ),
    Field(
      'basedOnFramework',
      String,
      'Based On Framework',
      hint: 'Material Design 3, Cupertino, Custom',
    ),
    Field(
      'sharedLibraryIntegration',
      bool,
      'Shared Library Integration',
      hint: 'Builds on the organisation-wide shared component library rather than bespoke components',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? componentLibraryOverview;

  /// Visual language and brand alignment.
  @SectionId('UCVL')
  @StandardReferences(
    [
      'ISO 9241-161:2016 — visual interface elements are catalogued so they are applied consistently',
      'ISO 9241-110:2020 — consistency underpins a coherent visual language',
      'ISO/IEC 25010:2023 — a shared visual language supports maintainability through reuse',
    ],
    'The visual-language configuration describing brand alignment and motion principles.',
  )
  @Form([
    Field(
      'visualLanguage',
      String,
      'Visual Language',
      hint: 'Clean, playful, professional, minimal',
    ),
    Field(
      'brandAlignment',
      String,
      'Brand Alignment',
      hint: 'How design aligns with brand guidelines',
    ),
    Field(
      'motionPrinciples',
      String,
      'Motion Principles',
      hint: 'Animation philosophy: subtle, expressive, functional',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? visualLanguage;

  /// Component naming and documentation approach.
  @SectionId('UCCA')
  @StandardReferences(
    [
      'ISO 9241-161:2016 — interface elements are named and documented so they are used consistently',
      'ISO 9241-110:2020 — consistency guides naming and documentation conventions',
      'ISO/IEC 25010:2023 — clear naming and documentation support maintainability',
    ],
    'The approach configuration describing component granularity, naming, and documentation practice.',
  )
  @Form([
    Field(
      'componentGranularity',
      String,
      'Component Granularity',
      hint: 'Atomic design levels: atoms, molecules, organisms',
    ),
    Field(
      'componentNaming',
      String,
      'Component Naming Convention',
      hint: 'PascalCase, kebab-case, prefix rules',
    ),
    Field(
      'componentDocumentation',
      String,
      'Component Documentation',
      hint: 'Storybook, living style guide, doc site',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? componentApproach;

  /// Extension and theming boundaries.
  @SectionId('UICOCU')
  @StandardReferences(
    [
      'ISO 9241-161:2016 — interface elements are catalogued so they are extended consistently',
      'ISO 9241-110:2020 — consistency governs how components can be themed and adapted',
      'ISO/IEC 25010:2023 — bounded extension points support maintainability and modularity',
    ],
    'The customization configuration describing how components can be extended and themed.',
  )
  @Form([
    Field(
      'extensionModel',
      String,
      'Extension Model',
      hint: 'How components can be extended or themed',
    ),
    Field(
      'themingApproach',
      String,
      'Theming Approach',
      hint: 'Token-based, widget-level, theme data',
    ),
    Field(
      'customizationBoundaries',
      String,
      'Customization Boundaries',
      hint: 'What can vs. cannot be customized',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? customization;

  /// 10.11.1. Component Library.
  @SerializationOrder(4)
  ComponentLibrary componentLibrary = ComponentLibrary();

  /// 10.11.2. Component Specifications — contains 0+×.
  @StandardReferences([
    'Atomic Design (Brad Frost) — each catalog component is specified as a composable building block',
    'ISO/IEC 25010:2023 — a catalog of reusable components supports maintainability through modularity',
  ], 'The collection of catalog component-specification entries.')
  @SectionId('UICOEN-COMP-LST')
  @SectionIdPattern('UICOEN-COMP-xxx')
  @ContentHelp('Add one entry per catalog component.')
  @SerializationOrder(5)
  List<UiComponentEntry> componentSpecs = [];

  /// 10.11.3. Component Families — contains 0+×.
  @StandardReferences(
    [
      'Atomic Design (Brad Frost) — related components are grouped into families of shared composition',
      'ISO/IEC 25010:2023 — component families support maintainability through modularity and reuse',
    ],
    'The collection of component-family entries grouping related catalog components.',
  )
  @SectionId('CMFA-COMP-LST')
  @SectionIdPattern('CMFA-COMP-xxx')
  @ContentHelp('Add one entry per component family.')
  @SerializationOrder(6)
  List<ComponentFamilyEntry> componentFamilies = [];
}

/// 10.11.1. Component Library.
///
/// Design system and component catalog specification.
@StandardReferences(
  [
    'Atomic Design (Brad Frost) — a component library composes atoms, molecules, and organisms',
    'Material Design — a design system unifies tokens, colour, type, and spacing',
    'ISO/IEC 25010:2023 — a shared component library supports maintainability through modularity and reuse',
  ],
  'The component-library configuration describing the design system and its shared foundations.',
)
@SectionId('COLI')
@CodeSpecKind(
  [CodeSpecPart.screenElement],
  note:
      'CE-EL — a screen element by semantic type then concrete implementation.',
)
class ComponentLibrary extends DocSpecsSection {
  @StandardReferences(
    [
      'Material Design — design tokens capture reusable values for the design system',
      'W3C CSS — foundational style values are expressed as reusable declarations',
      'ISO/IEC 25010:2023 — shared foundations support maintainability through reuse',
    ],
    'The collection of design-foundation entries defining the base design tokens.',
  )
  @SectionId('DESIG-DESI-LST')
  @SectionIdPattern('DESIG-DESI-xxx')
  @ContentHelp('Add one entry per design foundation.')
  @SerializationOrder(0)
  List<DesignFoundationEntry> designFoundations = [];

  /// Color system.
  @SectionId('COLICO')
  @StandardReferences(
    [
      'ISO 9241-112:2017 — colour is applied so information stays legible and distinguishable',
      'W3C WCAG 2.2 — SC 1.4.3 Contrast defines minimum contrast for text and colour',
      'Material Design — the colour system organises roles and tokens across the palette',
    ],
    'The library-level colour configuration covering the semantic palette and colour tokens.',
  )
  @Form([
    Field(
      'secondaryColor',
      String,
      'Secondary Color',
      hint: 'Secondary brand colour hex value (e.g., "#03DAC6")',
    ),
    Field(
      'tertiaryColor',
      String,
      'Tertiary Color',
      hint: 'Tertiary accent colour hex value (e.g., "#3700B3")',
    ),
    Field(
      'errorColor',
      String,
      'Error Color',
      hint: 'Colour for error states (e.g., "#B00020")',
    ),
    Field(
      'warningColor',
      String,
      'Warning Color',
      hint: 'Colour for warning states (e.g., "#FF9800")',
    ),
    Field(
      'successColor',
      String,
      'Success Color',
      hint: 'Colour for success states (e.g., "#4CAF50")',
    ),
    Field(
      'infoColor',
      String,
      'Info Color',
      hint: 'Colour for informational states (e.g., "#2196F3")',
    ),
    Field(
      'surfaceColors',
      String,
      'Surface Colors',
      hint: 'Background, card, dialog surfaces',
    ),
    Field(
      'colorTokenFormat',
      String,
      'Color Token Format',
      hint: 'CSS variables, Dart constants, theme data',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? colors;

  /// Typography system.
  @SectionId('COLITY')
  @StandardReferences(
    [
      'ISO 9241-112:2017 — typography presents information so text stays legible',
      'W3C CSS — font families and type scales are defined through style rules',
      'W3C WCAG 2.2 — SC 1.4.4 Resize text keeps text usable when scaled',
    ],
    'The library-level typography configuration covering font families, scales, and size units.',
  )
  @Form([
    Field(
      'fontFamilySecondary',
      String,
      'Secondary Font Family',
      hint: 'Secondary typeface for accents (e.g., "Roboto Slab")',
    ),
    Field(
      'fontFamilyMonospace',
      String,
      'Monospace Font Family',
      hint: 'Monospace typeface for code (e.g., "JetBrains Mono")',
    ),
    Field(
      'typographyScale',
      String,
      'Typography Scale',
      hint: 'Material type scale, custom scale',
    ),
    Field(
      'fontSizeUnit',
      String,
      'Font Size Unit',
      hint: 'Logical pixels, rem, sp',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? typography;

  /// Spacing and elevation.
  @SectionId('COLISP')
  @StandardReferences([
    'ISO 9241-125:2017 — spacing arranges information so the layout stays clear and consistent',
    'Material Design — spacing tokens define a coherent rhythm across the design system',
  ], 'The library-level configuration for spacing tokens and elevation levels.')
  @Form([
    Field(
      'spacingTokens',
      String,
      'Spacing Tokens',
      hint: 'xxs, xs, sm, md, lg, xl, xxl',
    ),
    Field(
      'elevationLevels',
      String,
      'Elevation Levels',
      hint: 'Number of elevation levels',
    ),
    Field(
      'elevationImplementation',
      String,
      'Elevation Implementation',
      hint: 'Shadows, borders, color shifts',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? spacing;

  /// Borders and corners.
  @SectionId('COLIBO')
  @StandardReferences(
    [
      'ISO 9241-112:2017 — borders present information so boundaries remain legible',
      'W3C WCAG 2.2 — SC 1.4.11 Non-text Contrast requires sufficient contrast for graphical boundaries',
    ],
    'The library-level configuration for border styles and corner radius scales.',
  )
  @Form([
    Field(
      'cornerRadiusScale',
      String,
      'Corner Radius Scale',
      hint: 'Rounded levels: none, sm, md, lg, full',
    ),
    Field(
      'borderStyleDefaults',
      String,
      'Border Style Defaults',
      hint:
          'Default border width, style, and colour (e.g., "1px solid outline")',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? borders;

  /// Icons and animation.
  @SectionId('COLIVI')
  @StandardReferences(
    [
      'ISO 9241-112:2017 — icons and motion are presented so information stays perceivable and legible',
      'ISO 9241-125:2017 — visual elements are arranged consistently across the layout',
      'Material Design — elevation and motion tokens give a coherent visual system',
    ],
    'The library-level visual configuration covering icons, elevation, and animation values.',
  )
  @Form([
    Field(
      'iconLibrary',
      String,
      'Icon Library',
      hint: 'Material Icons, Cupertino, custom',
    ),
    Field(
      'iconSizeScale',
      String,
      'Icon Size Scale',
      hint: 'Small, medium, large sizes',
    ),
    Field(
      'animationDurations',
      String,
      'Animation Durations',
      hint: 'Fast, normal, slow durations',
    ),
    Field(
      'animationCurves',
      String,
      'Animation Curves',
      hint: 'Easing curves: ease, easeInOut, custom',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? visuals;

  /// Design system narrative.
  @ContentHelp(
    'Comprehensive description of the design system foundations, '
    'visual language, and component philosophy.',
  )
  @SerializationOrder(6)
  TextSection designSystemNarrative = TextSection();

  /// Design token catalog.
  @ContentHelp(
    'Catalog of all design tokens: colors, typography, spacing, '
    'elevation, borders, and animation values.',
  )
  @SerializationOrder(7)
  TextSection designTokenCatalog = TextSection();

  /// Color palette specification.
  @StandardReferences([
    'ISO 9241-112:2017 — colour is applied so information stays legible and distinguishable',
    'W3C WCAG 2.2 — SC 1.4.3 Contrast defines minimum contrast for text and colour',
  ], 'The collection of colour palette entries in the design system.')
  @SectionId('COPA-COLO-LST')
  @SectionIdPattern('COPA-COLO-xxx')
  @ContentHelp('Add one entry per colour palette.')
  @SerializationOrder(8)
  List<ColorPaletteEntry> colorPalettes = [];

  /// Typography styles.
  @StandardReferences([
    'ISO 9241-112:2017 — typography presents information so text stays legible',
    'W3C CSS — text styles are declared through style rules',
    'W3C WCAG 2.2 — SC 1.4.4 Resize text keeps text usable when scaled',
  ], 'The collection of typography style entries in the library type scale.')
  @SectionId('TYST-TYPO-LST')
  @SectionIdPattern('TYST-TYPO-xxx')
  @ContentHelp('Add one entry per typography style.')
  @SerializationOrder(9)
  List<TypographyStyleEntry> typographyStyles = [];
}

/// A color palette entry.
@StandardReferences(
  [
    'ISO 9241-112:2017 — colour is applied so that information remains legible and distinguishable',
    'W3C WCAG 2.2 — SC 1.4.3 Contrast requires sufficient contrast between text and its background',
    'Material Design — a colour system defines primary, secondary, and surface roles across the interface',
  ],
  'A colour palette describing the colour set, variants, and contrast guidance used across the interface.',
)
@SectionId('COPA')
class ColorPaletteEntry extends DocSpecsSection {
  @Form([
    Field(
      'paletteName',
      String,
      'Palette Name',
      required: true,
      hint: 'Primary, Secondary, Neutral, Error',
    ),
    Field(
      'paletteRole',
      String,
      'Palette Role',
      hint: 'Brand, functional, semantic',
    ),
    Field(
      'colorCount',
      int,
      'Color Count',
      hint: 'Number of color stops in palette',
    ),
    Field('baseColor', String, 'Base Color', hint: 'Primary color value (hex)'),
    Field(
      'lightVariants',
      String,
      'Light Variants',
      hint: 'Lighter color stops',
    ),
    Field('darkVariants', String, 'Dark Variants', hint: 'Darker color stops'),
    Field(
      'onColorDefault',
      String,
      'On-Color Default',
      hint: 'Default text color on this palette',
    ),
    Field(
      'wcagCompliance',
      String,
      'WCAG Compliance',
      hint: 'Contrast compliance level',
    ),
    Field(
      'usageGuidelines',
      String,
      'Usage Guidelines',
      hint: 'When and where to apply this palette',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A typography style entry.
@StandardReferences(
  [
    'ISO 9241-112:2017 — text presentation such as size and weight is chosen so that information remains legible',
    'W3C WCAG 2.2 — SC 1.4.4 Resize text and SC 1.4.12 Text Spacing keep text readable when scaled and respaced',
    'Material Design — a type scale defines consistent typography roles across the interface',
  ],
  'A single typography style describing font, size, weight, and spacing for a text role.',
)
@SectionId('TYST')
class TypographyStyleEntry extends DocSpecsSection {
  @Form([
    Field(
      'styleName',
      String,
      'Style Name',
      required: true,
      hint: 'DisplayLarge, BodyMedium, LabelSmall',
    ),
    Field('fontFamily', String, 'Font Family', hint: 'Typeface family name'),
    Field('fontSize', String, 'Font Size', hint: 'Size in logical pixels'),
    Field(
      'fontWeight',
      String,
      'Font Weight',
      hint: 'Normal, medium, semibold, bold',
    ),
    Field('lineHeight', String, 'Line Height', hint: 'Line height multiplier'),
    Field(
      'letterSpacing',
      String,
      'Letter Spacing',
      hint: 'Spacing between characters',
    ),
    Field(
      'textDecoration',
      String,
      'Text Decoration',
      hint: 'None, underline, strikethrough',
    ),
    Field('useCase', String, 'Use Case', hint: 'Where this style is used'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A component family entry.
///
/// Groups related components by function (buttons, inputs, navigation, etc.).
@StandardReferences(
  [
    'Atomic Design (Brad Frost) — components are organised into families based on shared composition and function',
    'ISO/IEC 25010:2023 — grouping components into families supports modularity and reuse',
    'Material Design — a design system organises components into consistent families',
  ],
  'A grouping of related interface components that share function, patterns, and consistency rules.',
)
@SectionId('CMFA')
@CodeSpecKind(
  [CodeSpecPart.screenElement],
  note:
      'CE-EL — a screen element by semantic type then concrete implementation.',
)
class ComponentFamilyEntry extends DocSpecsSection {
  @Form([
    Field(
      'familyId',
      String,
      'Family ID',
      required: true,
      hint: 'Unique identifier (e.g., FAM-BTN)',
    ),
    Field(
      'familyName',
      String,
      'Family Name',
      required: true,
      hint: 'Buttons, Inputs, Navigation, Tables',
    ),
    Field(
      'familyDescription',
      String,
      'Family Description',
      hint: 'Purpose and scope of the family',
    ),
    Field(
      'componentCount',
      int,
      'Component Count',
      hint: 'Number of components in the family',
    ),
    Field(
      'sharedPatterns',
      String,
      'Shared Patterns',
      hint: 'Common patterns across family',
    ),
    Field(
      'consistencyRules',
      String,
      'Consistency Rules',
      hint: 'Rules for family consistency',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Family narrative.
  @SerializationOrder(1)
  TextSection familyNarrative = TextSection();

  /// Components in this family.
  @StandardReferences([
    'ISO/IEC 25010:2023 — a reusable component family supports maintainability through modularity',
    'Atomic Design (Brad Frost) — related components are collected into a shared family of interface parts',
  ], 'The collection of component references that make up this family.')
  @SectionId('FAMREF-COMP-LST')
  @SectionIdPattern('FAMREF-COMP-xxx')
  @ContentHelp('Add one entry per component in the family.')
  @SerializationOrder(2)
  List<FamilyComponentRef> components = [];
}

/// A component reference within a family.
@StandardReferences([
  'Atomic Design (Brad Frost) — components are composed and grouped into families of related interface parts',
  'ISO/IEC 25010:2023 — grouping related components as a family supports modularity and reuse',
], 'A reference identifying one component that belongs to a component family.')
@SectionId('FAMREF')
class FamilyComponentRef extends DocSpecsSection {
  @Form([
    Field(
      'componentId',
      String,
      'Component ID',
      required: true,
      hint: 'Identifier of the referenced component',
      refersTo: ['CMPNT.componentId'],
    ),
    Field(
      'componentName',
      String,
      'Component Name',
      required: true,
      hint: 'Name of the referenced component',
    ),
    Field(
      'familyRole',
      String,
      'Family Role',
      hint: 'Primary, secondary, specialized',
    ),
    Field(
      'relationToOthers',
      String,
      'Relation to Others',
      hint: 'How it relates to other family members',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A UI component entry.
///
/// Comprehensive specification for a single UI component covering identity,
/// visual design, behavior, states, responsiveness, accessibility,
/// authorization, and data binding.
@StandardReferences(
  [
    'ISO 9241-161:2016 — visual user-interface elements are described with their appearance, behaviour, and interaction guidance',
    'ISO/IEC 25010:2023 — a fully specified component supports maintainability and reusability across the interface',
    'W3C WAI-ARIA 1.2 — roles, states, and properties make the component perceivable to assistive technology',
  ],
  'The complete specification of a single user-interface component covering identity, visual design, behaviour, accessibility, authorization, and data binding.',
)
@SectionId('UICOMENT')
@CodeSpecKind(
  [CodeSpecPart.screenElement],
  note:
      'CE-EL — a screen element by semantic type then concrete implementation.',
)
class UiComponentEntry extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Component Identity
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('UICOMENT-IDEN')
  @Form([
    // Identity
    Field(
      'componentId',
      String,
      'Component ID',
      required: true,
      hint: 'Unique identifier (e.g., CMP-DTT-001)',
    ),
    Field(
      'componentName',
      String,
      'Component Name',
      required: true,
      hint: 'Human-readable name',
    ),
    Field(
      'componentFamily',
      String,
      'Component Family',
      hint: 'Button, Input, Table, Navigation, etc.',
    ),
    Field(
      'baseComponent',
      String,
      'Base Component',
      hint: 'Base component of the shared library this one specialises (Data Table, Text Input)',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? identity;

  /// Wrapper mapping and business purpose.
  @SectionId('UCEP')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — components conform with user expectations by mapping to a clear purpose and business context',
      'ISO/IEC 25010:2023 — a reusable component library supports maintainability through modularity and reusability',
    ],
    'The UI-component-entry purpose definition describing the wrapper mapping, purpose, business context, and user goals of one catalog component.',
  )
  @Form([
    Field(
      'tomWrapperClass',
      String,
      'Tom Wrapper Class',
      hint: 'TomDataTable, TomTextField, etc.',
    ),
    Field(
      'purpose',
      String,
      'Purpose',
      required: true,
      hint: 'What the component does',
    ),
    Field(
      'businessContext',
      String,
      'Business Context',
      hint: 'Business scenarios where used',
    ),
    Field(
      'userGoals',
      String,
      'User Goals',
      hint: 'What user accomplishes with this',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? purposeProfile;

  /// Classification details.
  @SectionId('UCEC')
  @StandardReferences(
    [
      'Atomic Design (Brad Frost) — classifying components as atoms, molecules, or organisms guides composition',
      'ISO/IEC 25010:2023 — a reusable component library supports maintainability through modularity and reusability',
    ],
    'The UI-component-entry classification definition describing atomic level, complexity, and reusability of one catalog component.',
  )
  @Form([
    Field(
      'atomicLevel',
      String,
      'Atomic Level',
      hint: 'Atom, molecule, organism',
    ),
    Field(
      'complexity',
      String,
      'Complexity',
      hint: 'Simple, moderate, complex',
    ),
    Field(
      'reusability',
      String,
      'Reusability',
      hint: 'Generic, semi-generic, specialized',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? classification;

  // ─────────────────────────────────────────────────────────────────────────
  // Visual Design
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('UICOMENT-VISU')
  @Form([
    Field(
      'defaultAppearance',
      String,
      'Default Appearance',
      hint: 'Visual description of default state',
    ),
    Field(
      'colorScheme',
      String,
      'Color Scheme',
      hint: 'Primary, secondary, surface colors used',
    ),
    Field('typography', String, 'Typography', hint: 'Text styles used'),
    Field(
      'iconography',
      String,
      'Iconography',
      hint: 'Icons used and their placement',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? visualDesign;

  /// Visual dimensions.
  @SectionId('UCED')
  @StandardReferences(
    [
      'ISO 9241-125:2017 — sizing of interface elements supports readable presentation of information',
      'WCAG 2.2 — SC 1.4.10 Reflow requires components to remain usable across a range of dimensions',
      'Material Design — layout and sizing guidance defines default and constraining dimensions for components',
    ],
    'The UI-component-entry dimension definition describing default, minimum, and maximum sizing for one catalog component.',
  )
  @Form([
    Field(
      'defaultWidth',
      String,
      'Default Width',
      hint: 'Default width or width behavior',
    ),
    Field(
      'defaultHeight',
      String,
      'Default Height',
      hint: 'Default height or height behavior',
    ),
    Field(
      'minDimensions',
      String,
      'Minimum Dimensions',
      hint: 'Smallest allowed size',
    ),
    Field(
      'maxDimensions',
      String,
      'Maximum Dimensions',
      hint: 'Largest allowed size',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? dimensions;

  /// Spacing rules.
  @SectionId('UCES')
  @StandardReferences(
    [
      'ISO 9241-125:2017 — spacing between elements supports clear presentation of information',
      'Material Design — spacing and layout guidance defines padding and margin rhythm for components',
      'ISO 9241-161:2016 — consistent spacing helps users perceive grouping of interface elements',
    ],
    'The UI-component-entry spacing definition describing internal padding, external margin, and content spacing for one catalog component.',
  )
  @Form([
    Field(
      'internalPadding',
      String,
      'Internal Padding',
      hint: 'Padding inside the component',
    ),
    Field(
      'externalMargin',
      String,
      'External Margin',
      hint: 'Margin around the component',
    ),
    Field(
      'contentSpacing',
      String,
      'Content Spacing',
      hint: 'Spacing between internal elements',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? spacing;

  /// Surface treatment.
  @SectionId('UICOENSU')
  @StandardReferences(
    [
      'Material Design — surface, elevation, and shadow properties define the visual layering of components',
      'ISO 9241-125:2017 — presentation of information relies on consistent surface treatment for legibility',
      'WCAG 2.2 — SC 1.4.11 Non-text Contrast requires component boundaries to remain distinguishable',
    ],
    'The UI-component-entry surface definition describing border, corner, elevation, and shadow treatment for one catalog component.',
  )
  @Form([
    Field('borderStyle', String, 'Border Style', hint: 'Solid, dashed, none'),
    Field(
      'cornerRadius',
      String,
      'Corner Radius',
      hint: 'Rounding of component corners',
    ),
    Field(
      'elevation',
      String,
      'Elevation',
      hint: 'Depth or z-level of the surface',
    ),
    Field(
      'shadowStyle',
      String,
      'Shadow Style',
      hint: 'Drop shadow appearance',
    ),
  ])
  @SerializationOrder(6)
  DocSpecsSection? surface;

  /// Visual design diagram.
  @ContentHelp('Visual diagram or mockup of the component.')
  @SerializationOrder(7)
  DiagramSection visualDiagram = DiagramSection();

  // ─────────────────────────────────────────────────────────────────────────
  // Interactive Behavior
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('UICOMENT-INTE')
  @Form([
    Field(
      'tapBehavior',
      String,
      'Tap Behavior',
      hint: 'What happens on tap/click',
    ),
    Field(
      'longPressBehavior',
      String,
      'Long Press Behavior',
      hint: 'What happens on long press',
    ),
    Field(
      'doubleTapBehavior',
      String,
      'Double Tap Behavior',
      hint: 'What happens on double tap',
    ),
    Field(
      'swipeBehavior',
      String,
      'Swipe Behavior',
      hint: 'What happens on swipe gestures',
    ),
    Field(
      'dragBehavior',
      String,
      'Drag Behavior',
      hint: 'What happens on drag gestures',
    ),
    Field('hoverBehavior', String, 'Hover Behavior'),
  ])
  @SerializationOrder(8)
  DocSpecsSection? interactiveBehavior;

  /// Focus and keyboard behavior.
  @SectionId('UCEIB')
  @StandardReferences(
    [
      'WCAG 2.2 — SC 2.1.1 Keyboard and SC 2.4.7 Focus Visible ensure the component is operable and its focus is apparent',
      'W3C WAI-ARIA 1.2 — keyboard interaction and focus management follow expected authoring patterns',
      'ISO 9241-171:2008 — keyboard access supports users who cannot operate a pointing device',
    ],
    'The UI-component-entry input-behaviour definition describing focus, keyboard navigation, and shortcut handling for one catalog component.',
  )
  @Form([
    Field(
      'focusBehavior',
      String,
      'Focus Behavior',
      hint: 'Focus ring, highlight, navigation',
    ),
    Field(
      'keyboardNavigation',
      String,
      'Keyboard Navigation',
      hint: 'Tab order, arrow key behavior',
    ),
    Field(
      'keyboardShortcuts',
      String,
      'Keyboard Shortcuts',
      hint: 'Key combinations the component handles',
    ),
  ])
  @SerializationOrder(9)
  DocSpecsSection? inputBehavior;

  /// Animation behavior.
  @SectionId('UCEA')
  @StandardReferences(
    [
      'Material Design — motion specifications define entry, exit, and state-change animations for components',
      'WCAG 2.2 — SC 2.3.3 Animation from Interactions allows motion effects to be reduced when requested',
      'ISO 9241-161:2016 — animated feedback communicates changes in component state to users',
    ],
    'The UI-component-entry animation definition describing entry, exit, transition, and feedback motion for one catalog component.',
  )
  @Form([
    Field(
      'entryAnimation',
      String,
      'Entry Animation',
      hint: 'How the component appears',
    ),
    Field(
      'exitAnimation',
      String,
      'Exit Animation',
      hint: 'How the component disappears',
    ),
    Field(
      'stateTransitions',
      String,
      'State Transitions',
      hint: 'Animation between states',
    ),
    Field(
      'feedbackAnimations',
      String,
      'Feedback Animations',
      hint: 'Ripple, scale, color change',
    ),
  ])
  @SerializationOrder(10)
  DocSpecsSection? animation;

  /// Scrolling behavior.
  @SectionId('UICOENSC')
  @StandardReferences(
    [
      'ISO 9241-161:2016 — scrollable regions and sticky elements are presented so users can perceive content boundaries',
      'ISO 9241-125:2017 — presentation of information remains legible as content scrolls within a component',
    ],
    'The UI-component-entry scroll definition describing scrolling and sticky behaviour of one catalog component.',
  )
  @Form([
    Field(
      'scrollBehavior',
      String,
      'Scroll Behavior',
      hint: 'If component is scrollable',
    ),
    Field(
      'stickyBehavior',
      String,
      'Sticky Behavior',
      hint: 'Headers, columns that stick',
    ),
  ])
  @SerializationOrder(11)
  DocSpecsSection? scroll;

  // ─────────────────────────────────────────────────────────────────────────
  // Responsiveness
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('UICOMENT-RESP')
  @Form([
    Field(
      'mobileLayout',
      String,
      'Mobile Layout',
      hint: 'Layout on mobile (< 600dp)',
    ),
    Field(
      'tabletLayout',
      String,
      'Tablet Layout',
      hint: 'Layout on tablet (600-1024dp)',
    ),
    Field(
      'desktopLayout',
      String,
      'Desktop Layout',
      hint: 'Layout on desktop (> 1024dp)',
    ),
    Field(
      'breakpointBehavior',
      String,
      'Breakpoint Behavior',
      hint: 'What changes at breakpoints',
    ),
    Field(
      'adaptiveContent',
      String,
      'Adaptive Content',
      hint: 'Content that appears/hides',
    ),
    Field(
      'touchTargets',
      String,
      'Touch Targets',
      hint: 'Minimum touch target sizes',
    ),
    Field(
      'orientationBehavior',
      String,
      'Orientation Behavior',
      hint: 'Portrait vs. landscape',
    ),
  ])
  @SerializationOrder(12)
  DocSpecsSection? responsiveness;

  // ─────────────────────────────────────────────────────────────────────────
  // Accessibility
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('UICOMENT-ACCE')
  @Form([
    Field(
      'semanticRole',
      String,
      'Semantic Role',
      hint: 'ARIA role or semantic meaning',
    ),
    Field(
      'screenReaderLabel',
      String,
      'Screen Reader Label',
      hint: 'How screen readers announce',
    ),
    Field(
      'screenReaderHint',
      String,
      'Screen Reader Hint',
      hint: 'Additional context for screen readers',
    ),
    Field('focusOrder', String, 'Focus Order', hint: 'Tab order in context'),
    Field(
      'ariaAttributes',
      String,
      'ARIA Attributes',
      hint: 'Required ARIA attributes',
    ),
    Field(
      'colorContrastNotes',
      String,
      'Color Contrast Notes',
      hint: 'Contrast ratios and compliance notes',
    ),
    Field(
      'motionSensitivity',
      String,
      'Motion Sensitivity',
      hint: 'Reduced motion behavior',
    ),
    Field(
      'textScalingBehavior',
      String,
      'Text Scaling Behavior',
      hint: 'How component responds to text scaling',
    ),
  ])
  @SerializationOrder(13)
  DocSpecsSection? accessibility;

  // ─────────────────────────────────────────────────────────────────────────
  // Authorization Integration
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('UICOMENT-AUTH')
  @Form([
    Field(
      'authBasePath',
      String,
      'Auth Base Path',
      hint: 'Base path for authorization lookup',
    ),
    Field(
      'authVisibilityBehavior',
      String,
      'Visibility Behavior',
      hint: 'Hidden, visible, conditionally visible',
    ),
    Field(
      'authEnabledBehavior',
      String,
      'Enabled Behavior',
      hint: 'Disabled, enabled, conditionally enabled',
    ),
    Field(
      'authReadonlyBehavior',
      String,
      'Readonly Behavior',
      hint: 'Readonly state behavior',
    ),
    Field(
      'authActionControl',
      String,
      'Action Control',
      hint: 'Which actions are auth-controlled',
    ),
    Field(
      'authFallbackBehavior',
      String,
      'Fallback Behavior',
      hint: 'Behavior when auth unavailable',
    ),
    Field(
      'fourStateMapping',
      String,
      'Four-State Mapping',
      hint: 'Mapping to TomAuthState four states',
    ),
  ])
  @SerializationOrder(14)
  DocSpecsSection? authorization;

  // ─────────────────────────────────────────────────────────────────────────
  // Resource Integration
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('UICOMENT-RESO')
  @Form([
    Field(
      'resourceBasePath',
      String,
      'Resource Base Path',
      hint: 'Base path for resource lookup',
    ),
    Field(
      'labelResource',
      String,
      'Label Resource',
      hint: 'Message key (MSGKR registry) for label text',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'hintResource',
      String,
      'Hint Resource',
      hint: 'Message key (MSGKR registry) for hint text',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'errorResource',
      String,
      'Error Resource',
      hint: 'Message key (MSGKR registry) for error messages',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'tooltipResource',
      String,
      'Tooltip Resource',
      hint: 'Message key (MSGKR registry) for tooltip text',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'placeholderResource',
      String,
      'Placeholder Resource',
      hint: 'Message key (MSGKR registry) for placeholder text',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'ariaLabelResource',
      String,
      'ARIA Label Resource',
      hint: 'Message key (MSGKR registry) for the ARIA label',
      refersTo: ['MSGKE.key'],
    ),
    Field(
      'iconResource',
      String,
      'Icon Resource',
      hint: 'Resource key for icon selection',
    ),
    Field(
      'resourceFallbacks',
      String,
      'Resource Fallbacks',
      hint: 'Fallback behavior when resource missing',
    ),
  ])
  @SerializationOrder(15)
  DocSpecsSection? resourceIntegration;

  // ─────────────────────────────────────────────────────────────────────────
  // Data Binding
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('UICOMENT-DATA')
  @Form([
    Field(
      'dataType',
      String,
      'Data Type',
      hint: 'Type of data component displays/edits',
    ),
    Field(
      'bindingPattern',
      String,
      'Binding Pattern',
      hint: 'Observable, form field, direct',
    ),
    Field(
      'valueAccessor',
      String,
      'Value Accessor',
      hint: 'How value is read/written',
    ),
    Field(
      'changeNotification',
      String,
      'Change Notification',
      hint: 'How changes are communicated',
    ),
    Field(
      'validationIntegration',
      String,
      'Validation Integration',
      hint: 'How validation errors are displayed',
    ),
    Field(
      'dirtyTracking',
      String,
      'Dirty Tracking',
      hint: 'How dirty state is tracked',
    ),
    Field(
      'undoRedoSupport',
      String,
      'Undo/Redo Support',
      hint: 'Whether edits can be undone and redone',
    ),
  ])
  @SerializationOrder(16)
  DocSpecsSection? dataBinding;

  /// Component behavior narrative.
  @ContentHelp(
    'Detailed description of component behavior, '
    'user interactions, and edge cases.',
  )
  @SerializationOrder(17)
  TextSection behaviorNarrative = TextSection();

  /// Contains 0+× ComponentState.
  @StandardReferences(
    [
      'W3C WAI-ARIA 1.2 — component states such as pressed, expanded, and disabled are exposed to assistive technology',
      'ISO 9241-161:2016 — each interactive state is presented so users can recognise it',
    ],
    'The collection of component-state entries defining the visual and functional states of the component.',
  )
  @SectionId('CMST-STAT-LST')
  @SectionIdPattern('CMST-STAT-xxx')
  @ContentHelp('Add one entry per component state.')
  @SerializationOrder(18)
  List<ComponentStateEntry> states = [];

  /// Contains 0+× ComponentVariant.
  @StandardReferences(
    [
      'Material Design — component variants define alternative appearances such as filled, outlined, and text styles',
      'ISO/IEC 25010:2023 — a set of component variants supports maintainability through modularity and reusability',
    ],
    'The collection of component-variant entries defining alternative configurations of the component.',
  )
  @SectionId('CMVN-VARI-LST')
  @SectionIdPattern('CMVN-VARI-xxx')
  @ContentHelp('Add one entry per component variant.')
  @SerializationOrder(19)
  List<ComponentVariantEntry> variants = [];

  /// Contains 0+× ComponentAction.
  @StandardReferences(
    [
      'ISO 9241-110:2020 — component actions conform with user expectations for interaction and controllability',
      'W3C WAI-ARIA 1.2 — actionable elements expose their role and available operations to assistive technology',
    ],
    'The collection of component-action entries defining operations the component can perform.',
  )
  @SectionId('CMAC-ACTI-LST')
  @SectionIdPattern('CMAC-ACTI-xxx')
  @ContentHelp('Add one entry per component action.')
  @SerializationOrder(20)
  List<ComponentActionEntry> actions = [];

  /// Contains 0+× ComponentSlot.
  @StandardReferences(
    [
      'Atomic Design (Brad Frost) — composition slots allow a component to host nested content in defined regions',
      'ISO/IEC 25010:2023 — configurable slots support maintainability through modularity and reusability',
    ],
    'The collection of component-slot entries defining named content regions of the component.',
  )
  @SectionId('CMSL-SLOT-LST')
  @SectionIdPattern('CMSL-SLOT-xxx')
  @ContentHelp('Add one entry per component slot.')
  @SerializationOrder(21)
  List<ComponentSlotEntry> slots = [];

  /// Contains 0+× ComponentProperty.
  @StandardReferences(
    [
      'W3C WAI-ARIA 1.2 — component properties such as label and description are exposed to assistive technology',
      'ISO/IEC 25010:2023 — a well-defined set of component properties supports maintainability through modularity',
    ],
    'The collection of component-property entries defining configurable properties of the component.',
  )
  @SectionId('CMPR-PROP-LST')
  @SectionIdPattern('CMPR-PROP-xxx')
  @ContentHelp('Add one entry per component property.')
  @SerializationOrder(22)
  List<ComponentPropertyEntry> properties = [];
}

/// A component state entry.
///
/// Defines a visual/functional state of the component.
@StandardReferences(
  [
    'W3C WAI-ARIA 1.2 — component states such as pressed, expanded, and disabled are exposed to assistive technology',
    'WCAG 2.2 — SC 2.4.7 Focus Visible ensures the active state of a component remains apparent',
    'ISO 9241-161:2016 — interactive elements present a recognisable appearance for each state',
  ],
  'The component state definition describing a distinct visual and functional state of a UI component.',
)
@SectionId('COMSTAENT')
@CodeSpecKind(
  [CodeSpecPart.viewState],
  note:
      'CE-ST — view-model / UI state (data-bound display, screen/component state).',
)
class ComponentStateEntry extends DocSpecsSection {
  @Form([
    Field(
      'stateId',
      String,
      'State ID',
      required: true,
      hint: 'Unique state identifier',
    ),
    Field(
      'stateName',
      String,
      'State Name',
      required: true,
      hint: 'Loading, Empty, Error, Disabled, etc.',
    ),
    Field(
      'stateDescription',
      String,
      'State Description',
      hint: 'What this state represents',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Visual appearance in this state.
  @SectionId('CSEV')
  @StandardReferences(
    [
      'ISO 9241-161:2016 — state changes alter the visual appearance of interactive elements',
      'WCAG 2.2 — SC 1.4.11 Non-text Contrast requires state indicators to stay perceivable',
      'Material Design — state layers define color and opacity overlays for each component state',
    ],
    'The state visual definition describing how a component appearance changes when it is in this state.',
  )
  @Form([
    Field(
      'visualChanges',
      String,
      'Visual Changes',
      hint: 'How appearance changes in this state',
    ),
    Field(
      'colorOverrides',
      String,
      'Color Overrides',
      hint: 'Colors replaced in this state',
    ),
    Field(
      'opacityChange',
      String,
      'Opacity Change',
      hint: 'Opacity applied in this state',
    ),
    Field(
      'iconChange',
      String,
      'Icon Change',
      hint: 'Icon swapped in this state',
    ),
    Field(
      'textChange',
      String,
      'Text Change',
      hint: 'Label or text shown in this state',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? visual;

  /// Behavior and accessibility changes in this state.
  @SectionId('CSEB')
  @StandardReferences(
    [
      'W3C WAI-ARIA 1.2 — states such as disabled, pressed, and expanded are exposed to assistive technology',
      'ISO 9241-110:2020 — interaction behavior in each state conforms to user expectations',
      'ISO 9241-161:2016 — interactive elements adjust their available operations per state',
    ],
    'The state behavior definition describing how interactions and accessibility change when a component is in this state.',
  )
  @Form([
    Field(
      'interactionChanges',
      String,
      'Interaction Changes',
      hint: 'How interactions change',
    ),
    Field(
      'accessibilityState',
      String,
      'Accessibility State',
      hint: 'Screen reader announcements',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? behavior;

  /// Entry and exit transition rules.
  @SectionId('CSET')
  @StandardReferences(
    [
      'ISO 9241-161:2016 — state transitions animate visual elements to keep users oriented',
      'ISO 9241-110:2020 — transitions between states remain consistent and predictable',
      'W3C WAI-ARIA 1.2 — state changes are communicated to assistive technology as they occur',
    ],
    'The state transition definition describing what triggers entry into and exit from a component state.',
  )
  @Form([
    Field(
      'entryTrigger',
      String,
      'Entry Trigger',
      hint: 'What causes entry to this state',
    ),
    Field(
      'exitTrigger',
      String,
      'Exit Trigger',
      hint: 'What causes exit from this state',
    ),
    Field(
      'transitionAnimation',
      String,
      'Transition Animation',
      hint: 'Animation played during the transition',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? transitions;

  /// State visual mockup.
  @SerializationOrder(4)
  DiagramSection stateMockup = DiagramSection();
}

/// A component variant entry.
///
/// Defines a variation of the component with different appearance or behavior.
@StandardReferences(
  [
    'Material Design — component variants provide named alternatives such as filled, outlined, and text',
    'ISO/IEC 25010:2023 — component variants support modularity and reusability within a design system',
    'W3C WAI-ARIA 1.2 — a variant preserves the accessible role while altering presentation',
  ],
  'The component variant definition describing an alternative appearance or behavior of a component.',
)
@SectionId('CVE')
@CodeSpecKind(
  [CodeSpecPart.screenElement],
  note:
      'CE-EL — a screen element by semantic type then concrete implementation.',
)
class ComponentVariantEntry extends DocSpecsSection {
  @Form([
    Field(
      'variantId',
      String,
      'Variant ID',
      required: true,
      hint: 'Unique variant identifier',
    ),
    Field(
      'variantName',
      String,
      'Variant Name',
      required: true,
      hint: 'Filled, Outlined, Tonal, Text',
    ),
    Field(
      'variantDescription',
      String,
      'Variant Description',
      hint: 'What distinguishes this variant',
    ),
    // Visual differentiation
    Field(
      'visualDifferences',
      String,
      'Visual Differences',
      hint: 'How variant looks different',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Visual styling details.
  @SectionId('CVEV')
  @StandardReferences(
    [
      'Material Design — variant visual styling covers color scheme, border, and elevation tokens',
      'W3C CSS — color, border, and shadow properties define variant appearance',
      'WCAG 2.2 — SC 1.4.11 Non-text Contrast requires variant boundaries to remain distinguishable',
    ],
    'The variant visual definition describing color scheme, border, and elevation styling of a component variant.',
  )
  @Form([
    Field(
      'colorSchemeVariant',
      String,
      'Color Scheme Variant',
      hint: 'Color palette applied to this variant',
    ),
    Field(
      'borderVariant',
      String,
      'Border Variant',
      hint: 'Border style for this variant',
    ),
    Field(
      'elevationVariant',
      String,
      'Elevation Variant',
      hint: 'Shadow or elevation level',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? visual;

  /// Behavioral and implementation notes.
  @SectionId('CVEB')
  @StandardReferences(
    [
      'Material Design — component variants may adjust behavior in addition to appearance',
      'ISO/IEC 25010:2023 — variant behavior differences are captured to preserve modularity and reusability',
      'ISO 9241-110:2020 — variant behavior remains consistent with user expectations',
    ],
    'The variant behavior definition describing how a component variant differs in behavior and implementation.',
  )
  @Form([
    Field(
      'behaviorDifferences',
      String,
      'Behavior Differences',
      hint: 'How behavior differs from the base component',
    ),
    Field(
      'useCaseDifferences',
      String,
      'Use Case Differences',
      hint: 'When to use this variant',
    ),
    Field(
      'implementationNote',
      String,
      'Implementation Note',
      hint: 'How variant is implemented',
    ),
    Field(
      'libraryVariant',
      String,
      'Library Variant',
      hint: 'Corresponding variant in the shared component library, if one exists',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? behavior;

  /// Variant visual mockup.
  @SerializationOrder(3)
  DiagramSection variantMockup = DiagramSection();
}

/// A component action entry.
///
/// Defines an action that can be triggered from the component.
@StandardReferences(
  [
    'ISO 9241-110:2020 — interactive controls trigger actions in a way that conforms to user expectations',
    'W3C WAI-ARIA 1.2 — actionable elements expose roles and states to assistive technology',
    'ISO 9241-161:2016 — command and button elements initiate user actions',
  ],
  'The component action definition describing an operation that a user can trigger from a component.',
)
@SectionId('CMAC')
@CodeSpecKind([CodeSpecPart.action], note: 'CE-AC — an action and its trigger.')
class ComponentActionEntry extends DocSpecsSection {
  @Form([
    Field('actionId', String, 'Action ID', required: true),
    Field(
      'actionName',
      String,
      'Action Name',
      required: true,
      hint: 'onTap, onSubmit, onDelete',
    ),
    Field(
      'actionTrigger',
      String,
      'Action Trigger',
      hint: 'User interaction that triggers',
    ),
    Field(
      'actionPayload',
      String,
      'Action Payload',
      hint: 'Data passed with action',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Authorization and confirmation behavior.
  @SectionId('CAEG')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — destructive or restricted actions request confirmation to prevent errors',
      'ISO 9241-161:2016 — dialogs and prompts guard interactive actions that need approval',
      'W3C WAI-ARIA 1.2 — confirmation dialogs use roles and properties accessible to assistive technology',
    ],
    'The action governance definition describing authorization requirements and confirmation prompts for an action.',
  )
  @Form([
    Field('actionResult', String, 'Action Result', hint: 'Expected outcome'),
    Field(
      'authRequired',
      bool,
      'Auth Required',
      hint: 'Requires authorization',
    ),
    Field(
      'authPermission',
      String,
      'Auth Permission',
      hint: 'Required permission',
    ),
    Field(
      'confirmationRequired',
      bool,
      'Confirmation Required',
      hint: 'Whether a confirmation prompt is shown',
    ),
    Field(
      'confirmationMessage',
      String,
      'Confirmation Message',
      hint: 'Text shown in the confirmation prompt',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? governance;

  /// Async execution and feedback behavior.
  @SectionId('CAEE')
  @StandardReferences(
    [
      'ISO 9241-110:2020 — interactive actions provide feedback conforming to user expectations',
      'ISO 9241-161:2016 — progress and status indicators communicate the outcome of an action',
      'W3C WAI-ARIA 1.2 — live regions announce asynchronous action results to assistive technology',
    ],
    'The action execution behavior describing asynchronous handling, error responses, and success feedback.',
  )
  @Form([
    Field(
      'asyncBehavior',
      String,
      'Async Behavior',
      hint: 'Loading state during async',
    ),
    Field(
      'errorHandling',
      String,
      'Error Handling',
      hint: 'What happens when the action fails',
    ),
    Field(
      'successFeedback',
      String,
      'Success Feedback',
      hint: 'Confirmation shown on success',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? execution;
}

/// A component slot entry.
///
/// Defines a slot where child widgets can be placed.
@StandardReferences(
  [
    'Atomic Design (Brad Frost) — slots compose atoms and molecules into larger organisms',
    'ISO/IEC 25010:2023 — slot-based composition supports modularity and reusability',
  ],
  'The component slot definition describing a placeholder where child content can be inserted.',
)
@SectionId('CMSL')
@CodeSpecKind(
  [CodeSpecPart.layout],
  note:
      'CE-LO — screen/region layout (unblocked by csm-2-2 layout-node + dsb6 tom_flutter_ui basis).',
)
class ComponentSlotEntry extends DocSpecsSection {
  @Form([
    Field(
      'slotId',
      String,
      'Slot ID',
      required: true,
      hint: 'Unique slot identifier',
    ),
    Field(
      'slotName',
      String,
      'Slot Name',
      required: true,
      hint: 'leading, trailing, title, content',
    ),
    Field(
      'slotDescription',
      String,
      'Slot Description',
      hint: 'Purpose of this slot',
    ),
    Field(
      'slotRequired',
      bool,
      'Slot Required',
      hint: 'Whether content is mandatory',
    ),
    Field(
      'acceptedWidgets',
      String,
      'Accepted Widgets',
      hint: 'Widget types allowed in slot',
    ),
    Field(
      'defaultContent',
      String,
      'Default Content',
      hint: 'What shows if slot is empty',
    ),
    Field(
      'sizingBehavior',
      String,
      'Sizing Behavior',
      hint: 'How slot affects component size',
    ),
    Field(
      'resourceKey',
      String,
      'Resource Key',
      hint: 'Resource for slot content',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// A component property entry.
///
/// Defines a configurable property of the component.
@StandardReferences(
  [
    'Material Design — component properties expose design-token values such as color, elevation, and shape',
    'ISO/IEC 25010:2023 — configurable properties support modularity and reusability of a component library',
    'W3C WAI-ARIA 1.2 — component properties describe characteristics exposed to assistive technology',
  ],
  'The configurable property definition describing a settable attribute of a UI component.',
)
@SectionId('CMPR')
@CodeSpecKind([
  CodeSpecPart.form,
], note: 'CE-FM — a configurable component property (field-like).')
class ComponentPropertyEntry extends DocSpecsSection {
  @Form([
    Field(
      'propertyId',
      String,
      'Property ID',
      required: true,
      hint: 'Unique property identifier',
    ),
    Field(
      'propertyName',
      String,
      'Property Name',
      required: true,
      hint: 'enabled, selected, elevation',
    ),
    Field(
      'propertyType',
      String,
      'Property Type',
      hint: 'bool, String, Color, int',
    ),
    Field(
      'defaultValue',
      String,
      'Default Value',
      hint: 'Value used when none is set',
    ),
    Field(
      'allowedValues',
      String,
      'Allowed Values',
      hint: 'Enum values or constraints',
    ),
    Field(
      'propertyDescription',
      String,
      'Property Description',
      hint: 'What this property controls',
    ),
    Field(
      'affectsAppearance',
      bool,
      'Affects Appearance',
      hint: 'Changes the visual look',
    ),
    Field(
      'affectsBehavior',
      bool,
      'Affects Behavior',
      hint: 'Changes how the component behaves',
    ),
    Field(
      'resourceResolvable',
      bool,
      'Resource Resolvable',
      hint: 'Can be resolved from resources',
    ),
    Field(
      'authControlled',
      bool,
      'Auth Controlled',
      hint: 'Controlled by authorization',
    ),
  ])
  @override
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
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — multi-language support contributes to portability through adaptability',
    'W3C Internationalization / BCP 47 — language tags identify supported and primary languages',
    'Unicode Standard / ISO/IEC 10646 — text handling and right-to-left support rely on Unicode',
  ],
  'The multi-language support architecture covering supported languages, primary language, and locale handling.',
)
@SectionId('MLAR')
@CodeSpecKind(
  [CodeSpecPart.text],
  note:
      'CE-TX — UI text / i18n copy (help, placeholder, message templates, locale handling).',
)
class MultiLanguageSupport extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Multi-language Overview
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('MLAR-MULT')
  @Form([
    // Scope
    Field(
      'supportedLanguages',
      String,
      'Supported Languages',
      hint: 'List of supported languages (e.g., en, de, fr, es)',
    ),
    Field(
      'primaryLanguage',
      String,
      'Primary Language',
      hint: 'Default/fallback language',
    ),
    Field(
      'futureLanguages',
      String,
      'Future Languages',
      hint: 'Languages planned for future support',
    ),
    Field(
      'rtlLanguages',
      String,
      'RTL Languages',
      hint: 'Right-to-left languages supported',
    ),
    // Locale handling
  ])
  @SerializationOrder(0)
  DocSpecsSection? multiLanguageOverview;

  /// Multi-language overview narrative.
  @ContentHelp(
    'Executive summary of internationalization and '
    'localization approach for the system.',
  )
  @SerializationOrder(1)
  TextSection overviewNarrative = TextSection();

  /// 10.12.4. Language and Country Selection.
  @SerializationOrder(2)
  LanguageCountrySelection languageCountrySelection =
      LanguageCountrySelection();

  /// Supported locale entries.
  @StandardReferences([
    'ISO 639 — language codes identify each supported locale',
    'ISO 3166 — country and region codes complete each locale identifier',
    'W3C Internationalization / BCP 47 — language tags name the supported locales',
  ], 'The collection of locales the system supports.')
  @SectionId('SULOEN-SUPP-LST')
  @SectionIdPattern('SULOEN-SUPP-xxx')
  @ContentHelp('Add one entry per supported locale.')
  @SerializationOrder(3)
  List<SupportedLocaleEntry> supportedLocales = [];
}

/// Locale modeling and fallback behavior.
@StandardReferences(
  [
    'W3C Internationalization / BCP 47 — language tags identify each locale and country variant',
    'ISO 639 — language codes; ISO 3166 — country codes compose the locale identifier',
    'ISO/IEC 25010:2023 — locale detection and fallback support portability adaptability',
  ],
  'The locale format, country variants, detection, and fallback-chain behavior.',
)
@SectionId('MLARLH')
@CodeSpecKind(
  [CodeSpecPart.text],
  note:
      'CE-TX — UI text / i18n copy (help, placeholder, message templates, locale handling).',
)
class LocaleHandlingRequirements extends DocSpecsSection {
  @Form([
    Field(
      'localeFormat',
      String,
      'Locale Format',
      hint: 'BCP 47, ISO 639-1, custom',
    ),
    Field(
      'countryVariants',
      String,
      'Country Variants',
      hint: 'en-US vs en-GB, de-DE vs de-AT',
    ),
    Field(
      'localeDetection',
      String,
      'Locale Detection',
      hint: 'Browser, OS, user setting, geo-IP',
    ),
    Field(
      'localeFallbackChain',
      String,
      'Locale Fallback Chain',
      hint: 'Fallback order when locale not available',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 10.12.1. Localization Process.
///
/// Workflow for identifying and preparing content for localization.
@StandardReferences(
  [
    'Unicode Standard / ISO/IEC 10646 — externalized strings are encoded and handled as Unicode text',
    'ISO/IEC 25010:2023 — string externalization and content tagging support portability adaptability',
    'ISO 17100:2015 — the identified localizable content feeds the translation process',
  ],
  'The workflow for identifying, externalizing, and tagging content for localization.',
)
@SectionId('LOPR')
@MapsTo(D12TransitionRolloutPlan)
@DetailedIn(D12TransitionRolloutPlan)
class LocalizationProcess extends DocSpecsSection {
  @SectionId('LOPR-LOCA')
  @Form([
    Field(
      'contentIdentification',
      String,
      'Content Identification',
      hint: 'How localizable content is identified',
    ),
    Field(
      'stringExternalization',
      String,
      'String Externalization',
      hint: 'Approach to externalizing strings',
    ),
    Field(
      'contentTagging',
      String,
      'Content Tagging',
      hint: 'How content is tagged for translation',
    ),
    Field(
      'localizationScope',
      String,
      'Localization Scope',
      hint: 'UI text, images, audio, video, documents',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? localizationProcessContent;

  /// Review process.
  @SectionId('LOPRR1')
  @StandardReferences(
    [
      'ISO 17100:2015 — the revision and review steps define quality checks on localized content',
      'ISO/IEC 25010:2023 — review supports usability of the adapted, localized product',
    ],
    'The review workflow, stakeholder approval, and quality assurance for localized content.',
  )
  @Form([
    Field(
      'reviewWorkflow',
      String,
      'Review Workflow',
      hint: 'Steps in the localization review',
    ),
    Field(
      'stakeholderApproval',
      String,
      'Stakeholder Approval',
      hint: 'Who approves localized content',
    ),
    Field(
      'qualityAssurance',
      String,
      'Quality Assurance',
      hint: 'QA process for localized content',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? review;

  /// Formatting rules.
  @SectionId('LOPRFO')
  @StandardReferences(
    [
      'CLDR (Unicode Common Locale Data Repository) — locale data drives date, number, and currency formatting',
      'ISO 8601 — the standard representation for dates and times per locale',
      'ISO 4217 — currency codes underpin locale-specific currency formatting',
    ],
    'The locale-specific formatting rules for dates, numbers, currency, addresses, and phone numbers.',
  )
  @Form([
    Field(
      'dateFormatRules',
      String,
      'Date Format Rules',
      hint: 'Locale-specific date formatting',
    ),
    Field(
      'numberFormatRules',
      String,
      'Number Format Rules',
      hint: 'Locale-specific number formatting',
    ),
    Field(
      'currencyFormatRules',
      String,
      'Currency Format Rules',
      hint: 'Locale-specific currency formatting',
    ),
    Field(
      'addressFormatRules',
      String,
      'Address Format Rules',
      hint: 'Locale-specific address formatting',
    ),
    Field(
      'phoneFormatRules',
      String,
      'Phone Format Rules',
      hint: 'Locale-specific phone number formatting',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? formatting;

  /// Deployment settings.
  @SectionId('LOPRDE')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — per-locale deployment and toggling contribute to portability adaptability',
      'CLDR (Unicode Common Locale Data Repository) — locale identifiers select which locale package is deployed',
    ],
    'The deployment, toggling, and per-locale customization settings for localized content.',
  )
  @Form([
    Field(
      'localeDeployment',
      String,
      'Locale Deployment',
      hint: 'How locales are deployed',
    ),
    Field(
      'localeToggling',
      String,
      'Locale Toggling',
      hint: 'Feature flags for locales',
    ),
    Field(
      'perLocaleCustomization',
      String,
      'Per-Locale Customization',
      hint: 'Locale-specific features or content',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? deployment;

  /// Localization process narrative.
  @SerializationOrder(4)
  TextSection localizationNarrative = TextSection();

  /// Localization workflow diagram.
  @SerializationOrder(5)
  FlowDiagramSection workflowDiagram = FlowDiagramSection();
}

/// 10.12.2. Translation Process.
///
/// Workflow for translating content.
@StandardReferences(
  [
    'ISO 17100:2015 — the translation process defines vendor qualification, translation, and revision steps',
    'ISO 18587:2017 — machine-translation post-editing is a defined stage within the process',
  ],
  'The overall translation process covering tooling, workflow, quality, terminology, and vendors.',
)
@SectionId('TRPR')
@MapsTo(D12TransitionRolloutPlan)
@DetailedIn(D12TransitionRolloutPlan)
class TranslationProcess extends DocSpecsSection {
  @SectionId('TRPR-TRAN')
  @Form([
    Field(
      'translationManagementSystem',
      String,
      'Translation Management System',
      hint: 'TMS tool (Phrase, Lokalise, Crowdin)',
    ),
    Field(
      'translationMemory',
      String,
      'Translation Memory',
      hint: 'TM usage and maintenance',
    ),
    Field(
      'machineTranslation',
      String,
      'Machine Translation',
      hint: 'MT usage (Google, DeepL, none)',
    ),
    Field(
      'catTools',
      String,
      'CAT Tools',
      hint: 'Computer-assisted translation tools',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? translationProcessContent;

  /// Translation workflow.
  @SectionId('TRPRWO')
  @StandardReferences(
    [
      'ISO 17100:2015 — the translation process sequences translation, revision, and in-country review steps',
      'ISO 18587:2017 — machine-translation post-editing can be inserted into the workflow',
    ],
    'The step-by-step translation workflow including review cycles and in-country review.',
  )
  @Form([
    Field(
      'translationWorkflow',
      String,
      'Translation Workflow',
      hint: 'Steps: extract → translate → review → integrate',
    ),
    Field(
      'reviewCycles',
      String,
      'Review Cycles',
      hint: 'Number of review rounds',
    ),
    Field(
      'inCountryReview',
      String,
      'In-Country Review',
      hint: 'Native speaker review process',
    ),
    Field(
      'contextualReview',
      String,
      'Contextual Review',
      hint: 'In-app review process',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? workflow;

  /// Quality assurance.
  @SectionId('TRPRQU')
  @StandardReferences(
    [
      'ISO 17100:2015 — the revision step defines linguistic quality checks on translated content',
      'ISO/IEC/IEEE 29119 — functional testing verifies that translated builds behave correctly',
    ],
    'The linguistic and functional quality-assurance checks applied to translations.',
  )
  @Form([
    Field(
      'qualityChecks',
      String,
      'Quality Checks',
      hint: 'Automated quality checks',
    ),
    Field(
      'linguisticQA',
      String,
      'Linguistic QA',
      hint: 'Linguistic quality assurance',
    ),
    Field(
      'functionalQA',
      String,
      'Functional QA',
      hint: 'Functional testing of translations',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? quality;

  /// Terminology and voice management.
  @SectionId('TRPRTE')
  @StandardReferences([
    'ISO 17100:2015 — terminology and style resources support consistent translation output',
  ], 'The glossary, style guide, and brand-voice management for translations.')
  @Form([
    Field(
      'glossaryManagement',
      String,
      'Glossary Management',
      hint: 'Term base management',
    ),
    Field(
      'styleGuide',
      String,
      'Style Guide',
      hint: 'Translation style guidelines',
    ),
    Field(
      'brandVoice',
      String,
      'Brand Voice',
      hint: 'How brand voice is maintained',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? terminology;

  /// Ongoing localization operations.
  @SectionId('TRPRON')
  @StandardReferences(
    [
      'ISO 17100:2015 — translation memory is a process asset maintained across ongoing localization work',
      'ISO 18587:2017 — continuous machine-translation post-editing supports ongoing operations',
    ],
    'The continuous localization and translation-memory maintenance operations.',
  )
  @Form([
    Field(
      'continuousLocalization',
      String,
      'Continuous Localization',
      hint: 'CI/CD integration for translations',
    ),
    Field(
      'translationMemoryMaintenance',
      String,
      'TM Maintenance',
      hint: 'How translation memory is maintained',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? ongoing;

  /// Translation process narrative.
  @SerializationOrder(5)
  TextSection translationNarrative = TextSection();

  /// Translation vendor entries.
  @StandardReferences([
    'ISO 17100:2015 — each listed translation vendor meets defined competence requirements',
    'ISO 18587:2017 — a listed vendor may provide machine-translation post-editing services',
  ], 'The collection of translation-vendor entries engaged for localization.')
  @SectionId('TRVEEN-VEND-LST')
  @SectionIdPattern('TRVEEN-VEND-xxx')
  @ContentHelp('Add one entry per translation vendor.')
  @SerializationOrder(6)
  List<TranslationVendorEntry> vendors = [];
}

/// A translation vendor entry.
@StandardReferences(
  [
    'ISO 17100:2015 — a translation vendor meets the defined competence and qualification requirements',
    'ISO 18587:2017 — a vendor may also provide post-editing of machine-translation output',
  ],
  'A single translation-vendor entry describing its type, languages, specializations, and quality.',
)
@SectionId('TVE')
class TranslationVendorEntry extends DocSpecsSection {
  @Form([
    Field(
      'vendorName',
      String,
      'Vendor Name',
      required: true,
      hint: 'Legal or trading name of the translation vendor',
    ),
    Field(
      'vendorType',
      String,
      'Vendor Type',
      hint: 'LSP, freelance, in-house',
    ),
    Field(
      'languages',
      String,
      'Languages',
      hint: 'Languages handled by vendor',
    ),
    Field(
      'specializations',
      String,
      'Specializations',
      hint: 'Technical, legal, marketing',
    ),
    Field(
      'turnaroundTime',
      String,
      'Turnaround Time',
      hint: 'Typical delivery time per job (e.g., 2 business days)',
    ),
    Field(
      'qualityRating',
      String,
      'Quality Rating',
      hint: 'Assessed quality score or rating for the vendor',
    ),
    Field(
      'contactInfo',
      String,
      'Contact Info',
      hint: 'Primary contact name, email, or phone',
    ),
  ])
  @override
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
@StandardReferences(
  [
    'ISO/IEC/IEEE 26514 — user documentation design and format follow a defined content structure',
    'ISO 17100:2015 — documentation can be localized through the translation process',
  ],
  'The end-user documentation format, platform, versioning, and localization deliverables.',
)
@SectionId('DOANTR')
@MapsTo(D12TransitionRolloutPlan)
@DetailedIn(D12TransitionRolloutPlan)
class UserDocumentationRequirements extends DocSpecsSection {
  @SectionId('DOANTR-DOCU')
  @Form([
    Field(
      'documentationFormat',
      String,
      'Documentation Format',
      hint: 'HTML, PDF, in-app, wiki',
    ),
    Field(
      'documentationPlatform',
      String,
      'Documentation Platform',
      hint: 'GitBook, Notion, custom, Confluence',
    ),
    Field(
      'documentationVersioning',
      String,
      'Documentation Versioning',
      hint: 'How docs are versioned with releases',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? documentationContent;

  /// Documentation deliverables provided to users.
  @SectionId('DATD')
  @StandardReferences([
    'ISO/IEC/IEEE 26514 — user documentation deliverables cover the required content set for software users',
    'ISO 17100:2015 — documentation deliverables can be produced and revised through the translation process',
  ], 'The set of end-user documentation deliverables included with the system.')
  @Form([
    Field(
      'userGuide',
      bool,
      'User Guide',
      hint: 'Include a full user guide (true or false)',
    ),
    Field(
      'quickStartGuide',
      bool,
      'Quick Start Guide',
      hint: 'Include a quick start guide (true or false)',
    ),
    Field(
      'onlineHelp',
      bool,
      'Online Help',
      hint: 'Include online help pages (true or false)',
    ),
    Field(
      'videoTutorials',
      bool,
      'Video Tutorials',
      hint: 'Include video tutorials (true or false)',
    ),
    Field(
      'contextualHelp',
      bool,
      'Contextual Help',
      hint: 'Include in-context help hints (true or false)',
    ),
    Field(
      'faq',
      bool,
      'FAQ',
      hint: 'Include a frequently-asked-questions page (true or false)',
    ),
    Field(
      'releaseNotes',
      bool,
      'Release Notes',
      hint: 'Include per-release notes (true or false)',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? deliverables;

  /// Documentation localization approach.
  @SectionId('DATL')
  @StandardReferences(
    [
      'ISO 17100:2015 — the translation process governs producing documentation in additional languages',
      'CLDR (Unicode Common Locale Data Repository) — locale data drives locale-appropriate documentation formatting',
      'ISO 3166 — country and region codes identify each documentation locale',
    ],
    'The approach for localizing and translating user documentation into supported languages.',
  )
  @Form([
    Field(
      'documentationLanguages',
      String,
      'Documentation Languages',
      hint: 'Languages for documentation',
    ),
    Field(
      'documentationTranslation',
      String,
      'Documentation Translation',
      hint: 'Translation approach for docs',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? localization;

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
@StandardReferences(
  [
    'ISO/IEC/IEEE 26514 — training material forms part of the software user documentation set',
    'ISO 17100:2015 — training deliverables can be translated for each supported language',
  ],
  'The training deliverables, formats, schedule, and knowledge-transfer plan provided to end users.',
)
@SectionId('TRMAT')
@MapsTo(D12TransitionRolloutPlan)
@DetailedIn(D12TransitionRolloutPlan)
class TrainingDeliverableRequirements extends DocSpecsSection {
  @SectionId('TRMAT-TRAI')
  @Form([
    // Training materials
    Field(
      'trainingMaterials',
      String,
      'Training Materials',
      hint: 'Slides, workbooks, exercises',
    ),
    Field(
      'trainingFormat',
      String,
      'Training Format',
      hint: 'In-person, virtual, self-paced',
    ),
    Field(
      'trainingDuration',
      String,
      'Training Duration',
      hint: 'Duration per role/module',
    ),
    // Training schedule
    Field(
      'trainingSchedule',
      String,
      'Training Schedule',
      hint: 'When training occurs',
    ),
    Field(
      'trainTheTrainer',
      bool,
      'Train-the-Trainer',
      hint: 'Train internal trainers',
    ),
    Field(
      'refresherTraining',
      String,
      'Refresher Training',
      hint: 'Ongoing training approach',
    ),
    // Knowledge transfer
    Field(
      'knowledgeTransferPlan',
      String,
      'Knowledge Transfer Plan',
      hint: 'How knowledge is transferred',
    ),
    Field(
      'supportHandoff',
      String,
      'Support Handoff',
      hint: 'Transition to support team',
    ),
    Field(
      'certificationProgram',
      String,
      'Certification Program',
      hint: 'User certification if applicable',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? trainingContent;

  /// Training narrative.
  @SerializationOrder(1)
  TextSection trainingNarrative = TextSection();

  /// Training module entries.
  @StandardReferences([
    'ISO/IEC/IEEE 26514 — training material is part of the documentation and enablement content set',
    'ISO 17100:2015 — each training module can be localized through the translation process',
  ], 'The collection of training-module entries offered to end users.')
  @SectionId('TRMOEN-TRAI-LST')
  @SectionIdPattern('TRMOEN-TRAI-xxx')
  @ContentHelp('Add one entry per training module.')
  @SerializationOrder(2)
  List<TrainingModuleEntry> trainingModules = [];
}

/// A training module entry.
@StandardReferences(
  [
    'ISO 17100:2015 — translation memory is a process asset maintained across localization work',
    'CLDR (Unicode Common Locale Data Repository) — locale data underpins delivering training content per language',
  ],
  'A single training module describing its audience, duration, delivery method, and assessment.',
)
@SectionId('TME')
class TrainingModuleEntry extends DocSpecsSection {
  @Form([
    Field(
      'moduleId',
      String,
      'Module ID',
      required: true,
      hint: 'Unique identifier for the module',
    ),
    Field(
      'moduleName',
      String,
      'Module Name',
      required: true,
      hint: 'Descriptive title of the module',
    ),
    Field(
      'targetAudience',
      String,
      'Target Audience',
      hint: 'End users, admins, power users',
    ),
    Field(
      'duration',
      String,
      'Duration',
      hint: 'Expected length (e.g., 2 hours, half day)',
    ),
    Field(
      'deliveryMethod',
      String,
      'Delivery Method',
      hint: 'In-person, virtual, self-paced',
    ),
    Field(
      'prerequisites',
      String,
      'Prerequisites',
      hint: 'Required prior knowledge or modules',
    ),
    Field(
      'learningObjectives',
      String,
      'Learning Objectives',
      hint: 'What learners will be able to do',
    ),
    Field(
      'assessmentMethod',
      String,
      'Assessment Method',
      hint: 'Quiz, exercise, certification',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 10.12.4. Language and Country Selection.
///
/// UI specification for language and country selection.
@StandardReferences(
  [
    'BCP 47 (W3C Internationalization) — language tags identify the languages offered in the picker',
    'ISO 639 — language codes name the selectable languages',
    'ISO 3166 — country and region codes name the selectable countries',
  ],
  'The user-interface specification for how users select their language and country.',
)
@SectionId('LACOSE')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
@CodeSpecKind(
  [CodeSpecPart.userSettings],
  note:
      'CE-UP — a user language/country preference, a server-persisted user '
      'setting restored on any device the user signs into (codespecs_mapping.md §11).',
)
class LanguageCountrySelection extends DocSpecsSection {
  @SectionId('LACOSE-LANG')
  @Form([
    Field(
      'pickerLocation',
      String,
      'Picker Location',
      hint: 'Header, footer, settings, onboarding',
    ),
    Field(
      'pickerStyle',
      String,
      'Picker Style',
      hint: 'Dropdown, modal, full page',
    ),
    Field(
      'languageDisplay',
      String,
      'Language Display',
      hint: 'Native names, English names, flags',
    ),
    Field(
      'countryDisplay',
      String,
      'Country Display',
      hint: 'How countries are displayed',
    ),
    Field(
      'searchable',
      bool,
      'Searchable',
      hint: 'Can user search languages/countries',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? languageSelectionContent;

  /// Default locale behavior.
  @SectionId('LCSD')
  @StandardReferences(
    [
      'BCP 47 (W3C Internationalization) — the accepted language tags drive default-locale detection',
      'ISO 3166 — country and region codes support geo-based default country detection',
    ],
    'How the default language and country are determined, including auto-detection sources.',
  )
  @Form([
    Field(
      'defaultLanguage',
      String,
      'Default Language',
      hint: 'How default language is determined',
    ),
    Field(
      'defaultCountry',
      String,
      'Default Country',
      hint: 'How default country is determined',
    ),
    Field(
      'autoDetection',
      String,
      'Auto-Detection',
      hint: 'Browser, OS, geo-IP detection',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? defaults;

  /// Retention rules — how a chosen preference survives, without naming a store.
  ///
  /// Where the preference lives is *not* authored here: it follows from the
  /// settings scope the preference is declared in (user setting vs device
  /// setting), never from a local/roaming-style flag on this section.
  @SectionId('LCSP')
  @StandardReferences(
    [
      'BCP 47 (W3C Internationalization) — the retained preference is expressed as a language tag',
      'ISO/IEC 25010:2023 — usability requires the chosen locale to survive across sessions',
    ],
    'How a chosen language and country preference is retained across sessions, before and after the user is identified.',
  )
  @Form([
    Field(
      'guestRetention',
      String,
      'Guest Retention',
      hint: 'Whether and for how long a preference chosen before sign-in is retained',
    ),
    Field(
      'signInCarryOver',
      String,
      'Sign-In Carry-Over',
      hint:
          'What happens to a guest-chosen locale when the user signs in and a stored preference applies',
    ),
    Field(
      'reselectionPrompt',
      String,
      'Re-Selection Prompt',
      hint: 'When the user is asked to confirm or re-pick the retained preference',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? persistence;

  /// Fallback behavior.
  @SectionId('LCSF')
  @StandardReferences(
    [
      'BCP 47 (W3C Internationalization) — the lookup and filtering rules define fallback between language tags',
      'CLDR (Unicode Common Locale Data Repository) — the locale inheritance chain guides fallback to a parent locale',
    ],
    'The fallback behavior when a requested locale is unavailable or only partially supported.',
  )
  @Form([
    Field(
      'localeFallbackBehavior',
      String,
      'Locale Fallback Behavior',
      hint: 'What happens when locale unavailable',
    ),
    Field(
      'partialLocalSupport',
      String,
      'Partial Locale Support',
      hint: 'UI in one locale, content in another',
    ),
    Field(
      'missingTranslationDisplay',
      String,
      'Missing Translation Display',
      hint: 'How missing translations are shown',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? fallback;

  /// Switching UX behavior.
  @SectionId('LCSU')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — usability covers how the interface responds when the user switches language',
      'WCAG 2.2 SC 3.1.2 — language of parts requires the interface to signal the active language after a switch',
    ],
    'The user-experience behavior when switching language, including confirmation and content retention.',
  )
  @Form([
    Field(
      'languageSwitchBehavior',
      String,
      'Language Switch Behavior',
      hint: 'Page reload, inline update',
    ),
    Field(
      'confirmationRequired',
      bool,
      'Confirmation Required',
      hint: 'Confirm before switching',
    ),
    Field(
      'contentRetention',
      String,
      'Content Retention',
      hint: 'What happens to in-progress content',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? ux;

  /// Language selection narrative.
  @SerializationOrder(5)
  TextSection languageSelectionNarrative = TextSection();

  /// Language selection mockup.
  @SerializationOrder(6)
  DiagramSection languagePickerMockup = DiagramSection();
}

/// 10.12.5. Translation Handling Requirements.
///
/// Technical requirements for internationalization framework.
@StandardReferences(
  [
    'BCP 47 (W3C Internationalization) — language tags drive locale loading and switching in the framework',
    'ICU MessageFormat — the message-format standard underpins string externalization and translation',
    'ISO/IEC 25010:2023 — adaptability requires externalizing strings so the product can be localized',
  ],
  'The technical internationalization framework, string externalization format, and locale handling.',
)
@SectionId('TRAREQ')
@MapsTo(D06ArchitectureTechnologySpecification)
@DetailedIn(D06ArchitectureTechnologySpecification)
@CodeSpecKind(
  [CodeSpecPart.text],
  note:
      'CE-TX — UI text / i18n copy (help, placeholder, message templates, locale handling).',
)
class TranslationRequirements extends DocSpecsSection {
  @SectionId('TRAREQ-TRAN')
  @Form([
    Field(
      'i18nFramework',
      String,
      'I18N Framework',
      hint: 'flutter_localizations, intl, easy_localization',
    ),
    Field(
      'stringExternalizationFormat',
      String,
      'String Externalization Format',
      hint: 'ARB, JSON, YAML, Gettext',
    ),
    Field(
      'localeHandling',
      String,
      'Locale Handling',
      hint: 'How locales are loaded and switched',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? translationRequirementsContent;

  /// RTL and bidirectional support.
  @SectionId('TRRERT')
  @StandardReferences(
    [
      'Unicode Standard / ISO/IEC 10646 — the Unicode bidirectional algorithm governs mixed left-to-right and right-to-left text',
      'ISO/IEC 25010:2023 — usability covers layout adaptation and mirroring for right-to-left languages',
    ],
    'The right-to-left and bidirectional text support, including mirroring rules for the interface.',
  )
  @Form([
    Field(
      'rtlSupport',
      bool,
      'RTL Support',
      hint: 'Whether right-to-left languages are supported',
    ),
    Field(
      'rtlImplementation',
      String,
      'RTL Implementation',
      hint: 'How RTL is implemented',
    ),
    Field(
      'bidirectionalText',
      String,
      'Bidirectional Text',
      hint: 'Handling mixed LTR/RTL content',
    ),
    Field(
      'rtlMirroring',
      String,
      'RTL Mirroring',
      hint: 'UI element mirroring rules',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? rtl;

  /// Locale-specific formatting rules.
  @SectionId('TRREFO')
  @StandardReferences(
    [
      'CLDR (Unicode Common Locale Data Repository) — supplies locale-specific date, number, and unit formatting data',
      'ISO 8601 — defines date and time representation',
      'ISO 4217 — defines currency codes for currency display',
    ],
    'The date, number, currency, and measurement-unit formatting rules applied per locale.',
  )
  @Form([
    Field(
      'dateTimeFormatting',
      String,
      'Date/Time Formatting',
      hint: 'intl DateFormat, custom',
    ),
    Field(
      'numberFormatting',
      String,
      'Number Formatting',
      hint: 'intl NumberFormat, custom',
    ),
    Field(
      'currencyFormatting',
      String,
      'Currency Formatting',
      hint: 'Currency display and conversion',
    ),
    Field(
      'measurementUnits',
      String,
      'Measurement Units',
      hint: 'Metric, imperial, locale-based',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? formatting;

  /// Pluralization and variants.
  @SectionId('TRREVA')
  @StandardReferences(
    [
      'ICU MessageFormat — expresses pluralization and gender selection for translated messages',
      'CLDR (Unicode Common Locale Data Repository) — provides the plural rules for each language',
    ],
    'The pluralization rules, gender handling, and contextual variants required for translated text.',
  )
  @Form([
    Field(
      'pluralizationRules',
      String,
      'Pluralization Rules',
      hint: 'ICU plural format, custom',
    ),
    Field(
      'genderSupport',
      String,
      'Gender Support',
      hint: 'Grammatical gender handling',
    ),
    Field(
      'contextualVariants',
      String,
      'Contextual Variants',
      hint: 'Formal/informal, regional variants',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? variants;

  /// Technical text and font support.
  @SectionId('TRRETE')
  @StandardReferences(
    [
      'Unicode Standard / ISO/IEC 10646 — defines character encoding, normalization, and text handling across scripts',
      'ISO/IEC 25010:2023 — usability covers font fallback and text direction handling for different scripts',
    ],
    'The Unicode handling, font fallback, text direction, and keyboard support required across scripts.',
  )
  @Form([
    Field(
      'unicodeSupport',
      String,
      'Unicode Support',
      hint: 'Unicode handling and normalization',
    ),
    Field(
      'fontFallback',
      String,
      'Font Fallback',
      hint: 'Font fallback for different scripts',
    ),
    Field(
      'textDirection',
      String,
      'Text Direction',
      hint: 'Directionality handling',
    ),
    Field(
      'keyboardLayouts',
      String,
      'Keyboard Layouts',
      hint: 'IME and keyboard support',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? technical;

  /// Translation requirements narrative.
  @SerializationOrder(5)
  TextSection requirementsNarrative = TextSection();
}

/// A supported locale entry.
@StandardReferences(
  [
    'BCP 47 (W3C Internationalization) — language tags identify each supported locale',
    'ISO 639 — language codes name the language of the locale',
    'ISO 3166 — country and region codes identify the territory of the locale',
  ],
  'A single locale the product supports, named by its language tag, language name, and region.',
)
@SectionId('SUPLOCENT')
@CodeSpecKind(
  [CodeSpecPart.text],
  note:
      'CE-TX — UI text / i18n copy (help, placeholder, message templates, locale handling).',
)
class SupportedLocaleEntry extends DocSpecsSection {
  @Form([
    Field(
      'localeCode',
      String,
      'Locale Code',
      required: true,
      hint: 'BCP 47 code (e.g., en-US)',
    ),
    Field(
      'languageName',
      String,
      'Language Name',
      required: true,
      hint: 'English name',
    ),
    Field(
      'nativeLanguageName',
      String,
      'Native Language Name',
      hint: 'Name in native language',
    ),
    Field('countryRegion', String, 'Country/Region', hint: 'Country or region'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Formatting and direction rules for the locale.
  @SectionId('SLEF')
  @StandardReferences(
    [
      'CLDR (Unicode Common Locale Data Repository) — supplies per-locale date, number, and currency formatting data',
      'ISO 4217 — currency codes identify the default currency for a locale',
      'ISO/IEC 25010:2023 — usability covers layout adaptation for right-to-left text direction',
    ],
    'The text direction, date, number, and currency formatting rules that apply to a supported locale.',
  )
  @Form([
    Field('textDirection', String, 'Text Direction', hint: 'LTR, RTL'),
    Field('dateFormat', String, 'Date Format', hint: 'Preferred date format'),
    Field(
      'numberFormat',
      String,
      'Number Format',
      hint: 'Decimal separator, thousand separator',
    ),
    Field('currency', String, 'Currency', hint: 'Default currency for locale'),
  ])
  @SerializationOrder(1)
  DocSpecsSection? formatting;

  /// Launch readiness and locale ownership.
  @SectionId('SULOENRO')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — adaptability lets the product be rolled out to additional locales without rework',
      'ISO 17100:2015 — the translation process assigns ownership and coverage for each target language',
    ],
    'The launch phasing, translation coverage, and ownership assigned to a supported locale.',
  )
  @Form([
    Field(
      'launchPhase',
      String,
      'Launch Phase',
      hint: 'When locale will be available',
    ),
    Field(
      'translationCoverage',
      String,
      'Translation Coverage',
      hint: 'Percentage translated',
    ),
    Field(
      'localeOwner',
      String,
      'Locale Owner',
      hint: 'Person responsible for locale',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? rollout;
}

// ---------------------------------------------------------------------------
// 10.13 Prototype
// ---------------------------------------------------------------------------

/// 10.13. Prototype.
///
/// Comprehensive prototype planning covering goals, feature selection,
/// prototype type, evaluation criteria, and stakeholder alignment.
@StandardReferences(
  [
    'ISO 9241-210:2019 — human-centred design produces prototypes so design solutions can be evaluated iteratively before commitment',
    'ISO 9241-11:2018 — usability is examined through prototyping in terms of effectiveness, efficiency, and satisfaction',
  ],
  'The prototype-planning configuration covering goals, feature selection, prototype type, and evaluation.',
)
@SectionId('PROTOT')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
class Prototype extends DocSpecsSection {
  // ─────────────────────────────────────────────────────────────────────────
  // Prototype Overview
  // ─────────────────────────────────────────────────────────────────────────
  @SectionId('PROTOT-PROT')
  @Form([
    Field(
      'prototypePurpose',
      String,
      'Prototype Purpose',
      hint: 'Primary goal: validation, alignment, feasibility',
    ),
    Field(
      'prototypeScope',
      String,
      'Prototype Scope',
      hint: 'What is included in prototype',
    ),
    Field(
      'targetAudience',
      String,
      'Target Audience',
      hint: 'Who will evaluate the prototype',
    ),
    Field(
      'successCriteria',
      String,
      'Success Criteria',
      hint: 'How success is measured',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? prototypeOverview;

  /// Prototype timing commitments.
  @SectionId('PRTI')
  @StandardReferences([
    'ISO 9241-210:2019 — iterative design activities are scheduled so prototyping and evaluation fit the project timeline',
  ], 'The timing commitments for the prototype phase and its evaluation window.')
  @Form([
    Field(
      'prototypeTimeline',
      String,
      'Prototype Timeline',
      hint: 'Duration for prototype phase',
    ),
    Field(
      'prototypeDeadline',
      String,
      'Prototype Deadline',
      hint: 'When prototype must be ready',
    ),
    Field(
      'evaluationPeriod',
      String,
      'Evaluation Period',
      hint: 'How long for evaluation',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? timeline;

  /// Prototype staffing and environment.
  @SectionId('PRORES')
  @StandardReferences(
    [
      'ISO 9241-210:2019 — human-centred design is resourced with appropriate people, budget, and environment',
    ],
    'The staffing, budget, and environment allocated to building the prototype.',
  )
  @Form([
    Field(
      'prototypeTeam',
      String,
      'Prototype Team',
      hint: 'Who builds the prototype',
    ),
    Field(
      'prototypeBudget',
      String,
      'Prototype Budget',
      hint: 'Budget allocation',
    ),
    Field(
      'prototypeEnvironment',
      String,
      'Prototype Environment',
      hint: 'Where prototype is deployed',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? resources;

  /// Approval and progression criteria.
  @SectionId('PRGO')
  @StandardReferences(
    [
      'ISO 9241-210:2019 — acceptance of a design solution is decided against agreed criteria with stakeholder involvement',
    ],
    'The approval and progression criteria that decide whether the prototype may proceed.',
  )
  @Form([
    Field(
      'acceptanceCriteria',
      String,
      'Acceptance Criteria',
      hint: 'Required criteria to proceed',
    ),
    Field(
      'stakeholderSignoff',
      String,
      'Stakeholder Signoff',
      hint: 'Who must approve prototype',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? governance;

  /// Prototype overview narrative.
  @ContentHelp(
    'Executive summary of prototype approach, '
    'objectives, and expected outcomes.',
  )
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

/// 10.13.1. Prototype Goals.
///
/// What the prototype should validate.
@StandardReferences([
  'ISO 9241-210:2019 — prototyping goals state what the design solution must validate before further investment',
  'ISO 9241-11:2018 — goals frame usability outcomes to be confirmed through evaluation',
], 'The goals the prototype is intended to validate.')
@SectionId('PG')
class PrototypeGoals extends DocSpecsSection {
  @SectionId('PG-GOAL')
  @Form([
    // Validation goals
    Field(
      'usabilityValidation',
      bool,
      'Usability Validation',
      hint: 'Validate usability of key workflows',
    ),
    Field(
      'stakeholderAlignment',
      bool,
      'Stakeholder Alignment',
      hint: 'Align stakeholders on UI/UX',
    ),
    Field(
      'technicalFeasibility',
      bool,
      'Technical Feasibility',
      hint: 'Prove technical approach works',
    ),
    Field(
      'performanceValidation',
      bool,
      'Performance Validation',
      hint: 'Validate performance targets',
    ),
    Field(
      'integrationValidation',
      bool,
      'Integration Validation',
      hint: 'Validate third-party integrations',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? goalsContent;

  /// Risk reduction and assumption testing.
  @SectionId('PRGORI')
  @StandardReferences([
    'ISO 9241-210:2019 — prototyping reduces risk by testing assumptions and resolving unknowns early',
  ], 'The risks, unknowns, and assumptions the prototype is meant to reduce.')
  @Form([
    Field(
      'riskMitigation',
      String,
      'Risk Mitigation',
      hint: 'Risks the prototype addresses',
    ),
    Field(
      'unknownsResolution',
      String,
      'Unknowns Resolution',
      hint: 'Unknowns to be resolved',
    ),
    Field(
      'assumptionsTesting',
      String,
      'Assumptions Testing',
      hint: 'Assumptions to be tested',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? riskProfile;

  /// User feedback objectives and intake.
  @SectionId('PRGOFE')
  @StandardReferences(
    [
      'ISO 9241-210:2019 — user feedback is gathered from prototype evaluation to inform the design',
    ],
    'The user-feedback objectives and how feedback from the prototype is collected.',
  )
  @Form([
    Field(
      'userFeedbackGoals',
      String,
      'User Feedback Goals',
      hint: 'What feedback to gather',
    ),
    Field(
      'usabilityTestingPlan',
      String,
      'Usability Testing Plan',
      hint: 'How usability testing is done',
    ),
    Field(
      'feedbackIntegration',
      String,
      'Feedback Integration',
      hint: 'How feedback flows back',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? feedbackProfile;

  /// Prototype goals narrative.
  @SerializationOrder(3)
  TextSection goalsNarrative = TextSection();

  /// Individual goal entries.
  @StandardReferences([
    'ISO 9241-210:2019 — individual validation goals are recorded so prototype evaluation can be traced against them',
  ], 'The collection of individual prototype-goal entries.')
  @SectionId('PRGOEN-GOAL-LST')
  @SectionIdPattern('PRGOEN-GOAL-xxx')
  @ContentHelp('Add one entry per prototype goal.')
  @SerializationOrder(4)
  List<PrototypeGoalEntry> goals = [];
}

/// A prototype goal entry.
@StandardReferences(
  [
    'ISO 9241-210:2019 — each prototyping goal is described with a validation method and success measure',
  ],
  'A single prototype-goal entry with its category, validation method, and success metric.',
)
@SectionId('PGE')
class PrototypeGoalEntry extends DocSpecsSection {
  @Form([
    Field(
      'goalId',
      String,
      'Goal ID',
      required: true,
      hint: 'Unique identifier for the goal',
    ),
    Field(
      'goalDescription',
      String,
      'Goal Description',
      required: true,
      hint: 'What the goal validates',
    ),
    Field(
      'goalCategory',
      String,
      'Goal Category',
      hint: 'Usability, technical, business',
    ),
    Field(
      'validationMethod',
      String,
      'Validation Method',
      hint: 'How goal is validated',
    ),
    Field(
      'successMetric',
      String,
      'Success Metric',
      hint: 'How success is measured',
    ),
    Field(
      'priority',
      String,
      'Priority',
      hint: 'Must-have, should-have, nice-to-have',
    ),
    Field(
      'relatedRisks',
      String,
      'Related Risks',
      hint: 'Risks this goal addresses',
    ),
    Field(
      'stakeholders',
      String,
      'Stakeholders',
      hint: 'Stakeholders interested in this goal',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 10.13.2. Selected Feature Subset.
///
/// Features included in the prototype.
@StandardReferences([
  'ISO 9241-210:2019 — a representative subset of features is prototyped so the riskiest and most valuable parts are evaluated first',
], 'The set of features selected for inclusion in the prototype.')
@SectionId('PRFESU')
class PrototypeFeatureSubset extends DocSpecsSection {
  @SectionId('PRFESU-FEAT')
  @Form([
    // Selection criteria
    Field(
      'selectionCriteria',
      String,
      'Selection Criteria',
      hint: 'How features were selected',
    ),
    Field(
      'riskBasedSelection',
      String,
      'Risk-Based Selection',
      hint: 'High-risk features included',
    ),
    Field(
      'valueBasedSelection',
      String,
      'Value-Based Selection',
      hint: 'High-value features included',
    ),
    Field(
      'uncertaintyBasedSelection',
      String,
      'Uncertainty-Based Selection',
      hint: 'Most uncertain features included',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? featureSubsetContent;

  /// Included and excluded feature scope.
  @SectionId('PFSS')
  @StandardReferences(
    [
      'ISO 9241-210:2019 — the scope of the prototype is bounded by stating which features are included, excluded, or partial',
    ],
    'The included, excluded, and partially implemented features of the prototype.',
  )
  @Form([
    Field(
      'includedFeatures',
      String,
      'Included Features',
      hint: 'Features in prototype',
    ),
    Field(
      'excludedFeatures',
      String,
      'Excluded Features',
      hint: 'Features not in prototype',
    ),
    Field(
      'partialFeatures',
      String,
      'Partial Features',
      hint: 'Features partially implemented',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? scope;

  /// Fidelity expectations for the prototype.
  @SectionId('PFSF')
  @StandardReferences(
    [
      'ISO 9241-210:2019 — prototype fidelity is chosen to suit the questions the evaluation must answer',
    ],
    'The fidelity expectations for interactivity, data, and visuals in the prototype.',
  )
  @Form([
    Field(
      'prototypeFidelity',
      String,
      'Prototype Fidelity',
      hint: 'Low, medium, high fidelity',
    ),
    Field(
      'interactiveFidelity',
      String,
      'Interactive Fidelity',
      hint: 'Level of interactivity',
    ),
    Field('dataFidelity', String, 'Data Fidelity', hint: 'Real vs. mock data'),
    Field(
      'visualFidelity',
      String,
      'Visual Fidelity',
      hint: 'Production visuals vs. wireframes',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? fidelity;

  /// Feature subset narrative.
  @SerializationOrder(3)
  TextSection featureNarrative = TextSection();

  /// Prototype feature entries.
  @StandardReferences([
    'ISO 9241-210:2019 — the prototyped features are enumerated so scope and fidelity can be tracked per feature',
  ], 'The collection of prototype-feature entries.')
  @SectionId('PRFEEN-FEAT-LST')
  @SectionIdPattern('PRFEEN-FEAT-xxx')
  @ContentHelp('Add one entry per prototype feature.')
  @SerializationOrder(4)
  List<PrototypeFeatureEntry> features = [];
}

/// A prototype feature entry.
@StandardReferences([
  'ISO 9241-210:2019 — each prototyped feature is described with its inclusion reason, fidelity, and completeness',
], 'A single prototype-feature entry with fidelity and completeness details.')
@SectionId('PFE')
class PrototypeFeatureEntry extends DocSpecsSection {
  @Form([
    Field(
      'featureId',
      String,
      'Feature ID',
      required: true,
      hint: 'Unique identifier for the feature',
    ),
    Field(
      'featureName',
      String,
      'Feature Name',
      required: true,
      hint: 'Name of the feature',
    ),
    Field(
      'inclusionReason',
      String,
      'Inclusion Reason',
      hint: 'Why this feature is included',
    ),
    Field('fidelityLevel', String, 'Fidelity Level', hint: 'Low, medium, high'),
    Field(
      'completenessLevel',
      String,
      'Completeness Level',
      hint: 'Full, partial, stub',
    ),
    Field(
      'relatedGoals',
      String,
      'Related Goals',
      hint: 'Prototype goals this addresses',
    ),
    Field(
      'implementationNotes',
      String,
      'Implementation Notes',
      hint: 'Notes on how the feature is built in the prototype',
    ),
    Field(
      'knownLimitations',
      String,
      'Known Limitations',
      hint: 'Known limitations of the prototyped feature',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}

/// 10.13.3. Prototype Type.
///
/// Classification and implications of the prototype type.
@StandardReferences([
  'ISO 9241-210:2019 — the prototype type is classified so its cost, quality, and reuse implications are made explicit',
], 'The classification of the prototype and the implications of that choice.')
@SectionId('PRTYSE')
class PrototypeType extends DocSpecsSection {
  @SectionId('PRTYSE-PROT')
  @Form([
    Field(
      'prototypeType',
      String,
      'Prototype Type',
      required: true,
      hint: 'Reusable, Training, Throwaway',
    ),
    Field(
      'typeRationale',
      String,
      'Type Rationale',
      hint: 'Why this type was chosen',
    ),
    Field(
      'typeImplications',
      String,
      'Type Implications',
      hint: 'Implications for development',
    ),
    Field(
      'codeQualityExpectation',
      String,
      'Code Quality Expectation',
      hint: 'Production, demo, quick-and-dirty',
    ),
    Field(
      'documentationRequirement',
      String,
      'Documentation Requirement',
      hint: 'Documentation needed',
    ),
    Field(
      'transitionPlan',
      String,
      'Transition Plan',
      hint: 'How prototype transitions',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? prototypeTypeOverview;

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
@StandardReferences([
  'ISO 9241-210:2019 — an evolutionary prototype that becomes part of the product is held to production design and quality standards',
  'ISO/IEC 25010:2023 — reusable prototype code is expected to support maintainability through quality and testability',
], 'A reusable prototype that becomes part of the final product.')
@SectionId('REUPRO')
class ReusablePrototype extends DocSpecsSection {
  @SectionId('REUPRO-REUS')
  @Form([
    Field(
      'codeQualityRequirements',
      String,
      'Code Quality Requirements',
      hint: 'Standards prototype code must meet',
    ),
    Field(
      'testCoverageRequirement',
      String,
      'Test Coverage Requirement',
      hint: 'Required test coverage',
    ),
    Field(
      'codeReviewRequired',
      bool,
      'Code Review Required',
      hint: 'Whether code review is required',
    ),
    Field(
      'documentationRequired',
      bool,
      'Documentation Required',
      hint: 'Whether documentation is required',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? reusableContent;

  /// Architecture alignment and refactoring expectations.
  @SectionId('REPRAR')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — the prototype aligns with the target architecture to support maintainability and limit technical debt',
    ],
    'The architecture alignment and refactoring expectations for a reusable prototype.',
  )
  @Form([
    Field(
      'architectureAlignment',
      String,
      'Architecture Alignment',
      hint: 'How prototype aligns with target architecture',
    ),
    Field(
      'refactoringPlan',
      String,
      'Refactoring Plan',
      hint: 'Planned refactoring after prototype',
    ),
    Field(
      'technicalDebt',
      String,
      'Technical Debt',
      hint: 'Acceptable technical debt',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? architecture;

  /// Integration and merge strategy.
  @SectionId('REPRIN')
  @StandardReferences(
    [
      'ISO/IEC 25010:2023 — the prototype is integrated into the product under defined merge criteria to protect maintainability',
    ],
    'The integration and merge strategy for bringing reusable prototype code into the product.',
  )
  @Form([
    Field(
      'integrationPlan',
      String,
      'Integration Plan',
      hint: 'How prototype integrates into product',
    ),
    Field(
      'featureBranchStrategy',
      String,
      'Feature Branch Strategy',
      hint: 'Git branching approach',
    ),
    Field(
      'mergeCriteria',
      String,
      'Merge Criteria',
      hint: 'Criteria to merge prototype code',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? integration;

  /// Transition and handoff planning.
  @SectionId('REPRTR')
  @StandardReferences([
    'ISO 9241-210:2019 — handoff of the design solution to the development team is planned as part of iterative design',
  ], 'The transition and handoff planning for a reusable prototype.')
  @Form([
    Field(
      'transitionTimeline',
      String,
      'Transition Timeline',
      hint: 'When the transition to the product occurs',
    ),
    Field(
      'teamHandoff',
      String,
      'Team Handoff',
      hint: 'Handoff to development team',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? transition;

  /// Reusable prototype narrative.
  @SerializationOrder(4)
  TextSection reusableNarrative = TextSection();
}

/// 10.13.3.2. Training Prototype.
///
/// Prototype where concepts are reused but not code.
@StandardReferences([
  'ISO 9241-210:2019 — a learning-oriented prototype preserves design decisions and lessons even when its code is not reused',
], 'A training prototype whose concepts, not code, are carried forward.')
@SectionId('TP')
class TrainingPrototype extends DocSpecsSection {
  @SectionId('TP-TRAI')
  @Form([
    // Knowledge transfer
    Field(
      'designDecisionsCarriedForward',
      String,
      'Design Decisions Carried Forward',
      hint: 'What design decisions are preserved',
    ),
    Field(
      'patternsDocumented',
      String,
      'Patterns Documented',
      hint: 'Patterns documented from prototype',
    ),
    Field(
      'lessonsLearned',
      String,
      'Lessons Learned',
      hint: 'What was learned',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? trainingContent;

  /// Code disposition and reimplementation planning.
  @SectionId('TRPRDI')
  @StandardReferences(
    [
      'ISO 9241-210:2019 — the disposition of prototype code and any reimplementation are planned after learning is captured',
    ],
    'The code disposition and reimplementation planning for a training prototype.',
  )
  @Form([
    Field(
      'codeDisposition',
      String,
      'Code Disposition',
      hint: 'What happens to prototype code',
    ),
    Field(
      'reimplementationPlan',
      String,
      'Reimplementation Plan',
      hint: 'Plan for reimplementing features',
    ),
    Field(
      'reimplementationEstimate',
      String,
      'Reimplementation Estimate',
      hint: 'Effort to reimplement',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? disposition;

  /// Documentation outputs and team learning.
  @SectionId('TRPROU')
  @StandardReferences(
    [
      'ISO 9241-210:2019 — documentation and design outputs from the prototype are captured so team learning is retained',
    ],
    'The documentation outputs and team learning produced by a training prototype.',
  )
  @Form([
    Field(
      'documentationProduced',
      String,
      'Documentation Produced',
      hint: 'Documentation from prototype',
    ),
    Field(
      'designSystemOutput',
      String,
      'Design System Output',
      hint: 'Design system artifacts',
    ),
    Field(
      'componentSpecifications',
      String,
      'Component Specifications',
      hint: 'Component specs from prototype',
    ),
    Field(
      'teamSkillsGained',
      String,
      'Team Skills Gained',
      hint: 'Skills team gained',
    ),
    Field(
      'technologyInsights',
      String,
      'Technology Insights',
      hint: 'Technology insights gained',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? outputs;

  /// Training prototype narrative.
  @SerializationOrder(3)
  TextSection trainingNarrative = TextSection();
}

/// 10.13.3.3. Throwaway Prototype.
///
/// Prototype evaluated and then discarded.
@StandardReferences([
  'ISO 9241-210:2019 — a throwaway prototype supports formative evaluation and is discarded once its questions are answered',
], 'A throwaway prototype that is evaluated and then discarded.')
@SectionId('THPR')
class ThrowawayPrototype extends DocSpecsSection {
  @SectionId('THPR-THRO')
  @Form([
    Field(
      'evaluationCriteria',
      String,
      'Evaluation Criteria',
      hint: 'Criteria for evaluation',
    ),
    Field(
      'evaluationMethod',
      String,
      'Evaluation Method',
      hint: 'How prototype is evaluated',
    ),
    Field(
      'evaluationParticipants',
      String,
      'Evaluation Participants',
      hint: 'Who participates in evaluation',
    ),
    Field(
      'evaluationTimeline',
      String,
      'Evaluation Timeline',
      hint: 'When evaluation takes place',
    ),
  ])
  @SerializationOrder(0)
  DocSpecsSection? throwawayContent;

  /// Findings and decisions captured from evaluation.
  @SectionId('THPRFI')
  @StandardReferences(
    [
      'ISO 9241-210:2019 — findings and decisions from evaluation are documented to inform the design',
    ],
    'The findings and decisions captured from evaluating a throwaway prototype.',
  )
  @Form([
    Field(
      'findingsDocumentation',
      String,
      'Findings Documentation',
      hint: 'How findings are documented',
    ),
    Field(
      'recommendationsOutput',
      String,
      'Recommendations Output',
      hint: 'Recommendations produced',
    ),
    Field(
      'decisionsMade',
      String,
      'Decisions Made',
      hint: 'Decisions made based on prototype',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? findings;

  /// Disposal and follow-up handling.
  @SectionId('THPRDI')
  @StandardReferences([
    'ISO 9241-210:2019 — disposal and follow-up of the discarded prototype are handled deliberately',
  ], 'The disposal and follow-up handling for a throwaway prototype.')
  @Form([
    Field(
      'disposalPlan',
      String,
      'Disposal Plan',
      hint: 'How prototype is disposed',
    ),
    Field(
      'archivingApproach',
      String,
      'Archiving Approach',
      hint: 'Whether/how prototype is archived',
    ),
    Field(
      'nextSteps',
      String,
      'Next Steps',
      hint: 'What happens after evaluation',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? disposition;

  /// Long-term value retained from the prototype.
  @SectionId('THPRVA')
  @StandardReferences([
    'ISO 9241-210:2019 — insights worth retaining are preserved even when the prototype itself is discarded',
  ], 'The long-term value and insights retained from a throwaway prototype.')
  @Form([
    Field(
      'insightsCaptured',
      String,
      'Insights Captured',
      hint: 'Key insights from prototype',
    ),
    Field(
      'futureReference',
      String,
      'Future Reference',
      hint: 'What to preserve for future',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? value;

  /// Throwaway prototype narrative.
  @SerializationOrder(4)
  TextSection throwawayNarrative = TextSection();
}

// ---------------------------------------------------------------------------
// 10.14 Wireframes and Mockups
// ---------------------------------------------------------------------------

/// 10.14. Wireframes and Mockups.
///
/// Wireframe and mockup inventory beyond individual screen descriptions.
///.
@StandardReferences(
  [
    'ISO 9241-210:2019 — candidate design solutions are produced as wireframes and mockups so they can be evaluated before build',
    'ISO 9241-125:2017 — the visual presentation of information is planned so layouts communicate content clearly',
  ],
  'The catalog of wireframes and mockups that visualise the interface beyond individual screen descriptions.',
)
@SectionId('WIANMO')
@MapsTo(D09ExperienceDesignSpecification)
@DetailedIn(D09ExperienceDesignSpecification)
class WireframesAndMockups extends DocSpecsSection {
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
  @override
  @SerializationOrder(0)
  String? content;
}

/// A single design foundation entry.
@StandardReferences(
  [
    'ISO 9241-125:2017 — visual attributes such as colour, typography, and spacing are defined so information is presented consistently',
    'ISO/IEC 25010:2023 — shared visual foundations support maintainability through consistency and reuse',
  ],
  'A single design-foundation entry recording a colour, font, and spacing choice for the interface.',
)
@SectionId('DESIG')
class DesignFoundationEntry extends DocSpecsSection {
  @Form([
    Field(
      'primaryColor',
      String,
      'Primary Color',
      hint: 'Primary brand color (hex or semantic name)',
    ),
    Field(
      'fontFamilyPrimary',
      String,
      'Primary Font Family',
      hint: 'Primary font family (typeface name)',
    ),
    Field(
      'spacingScale',
      String,
      'Spacing Scale',
      hint: '4px base, 8px base, custom scale',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}
