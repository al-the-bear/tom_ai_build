/// Section 10: User Interface Design and Prototype [PD00-USE].
///
/// Seeds → UP, SR, TR depending on subsection.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 10. User Interface Design and Prototype [PD00-USE]. Seeds → UP.
@SectionId('PD00-USE')
@Comment('Seeds → UP')
class UserInterfaceDesign {
  @Unused()
  String? content;

  /// 10.1. Design Vision [PD00-USE-VIS]. Seeds → UP.
  DesignVision designVision = DesignVision();

  /// 10.2. Screen Descriptions [PD00-USE-SCR]. Seeds → UP.
  ScreenDescriptions screens = ScreenDescriptions();

  /// 10.3. Screen Flow Structure [PD00-USE-SCF]. Seeds → UP.
  ScreenFlowStructure screenFlow = ScreenFlowStructure();

  /// 10.4. Print Layout [PD00-USE-PRI]. Seeds → UP.
  PrintLayout printLayout = PrintLayout();

  /// Data Structure Alignment.
  TextSection dataStructureAlignment = TextSection();

  /// Authorization Compliance.
  TextSection authorizationCompliance = TextSection();

  /// 10.7. Error Handling Concept [PD00-USE-ERR]. Seeds → UP.
  ErrorHandlingConcept errorHandling = ErrorHandlingConcept();

  /// 10.8. Help Concept [PD00-USE-HLP]. Seeds → UP.
  HelpConcept helpConcept = HelpConcept();

  /// 10.9. Accessibility [PD00-USE-ACC]. Seeds → UP.
  Accessibility accessibility = Accessibility();

  /// 10.10. Responsive Design [PD00-USE-RES]. Seeds → UP.
  ResponsiveDesign responsiveDesign = ResponsiveDesign();

  /// 10.11. UI Components [PD00-USE-COM]. Seeds → UP.
  UiComponents uiComponents = UiComponents();

  /// 10.12. Multi-language and Rollout Support [PD00-USE-MUL].
  MultiLanguageAndRollout multiLanguage = MultiLanguageAndRollout();

  /// 10.13. Prototype [PD00-USE-PRO]. Seeds → UP.
  Prototype prototype = Prototype();
}

// ---------------------------------------------------------------------------
// 10.1 Design Vision
// ---------------------------------------------------------------------------

/// 10.1. Design Vision [PD00-USE-VIS].
///
/// Overall design vision for the user interface, encompassing goals,
/// principles, and user personas that guide all UI decisions.
@SectionId('PD00-USE-VIS')
class DesignVision {
  @Unused()
  String? content;

  /// 10.1.1. Design Goals [PD00-USE-VIS-GOA].
  DesignGoals designGoals = DesignGoals();

  /// 10.1.2. Design Principles [PD00-USE-VIS-PRI].
  DesignPrinciples designPrinciples = DesignPrinciples();

  /// 10.1.3. User Personas [PD00-USE-VIS-PER].
  UserPersonas personas = UserPersonas();
}

// ---------------------------------------------------------------------------
// 10.1.1 Design Goals
// ---------------------------------------------------------------------------

/// 10.1.1. Design Goals [PD00-USE-VIS-GOA].
///
/// Primary design objectives that the UI must achieve: simplicity, efficiency,
/// accessibility, consistency, delight. Goals are prioritized for the project.
@SectionId('PD00-USE-VIS-GOA')
class DesignGoals {
  @Unused()
  String? content;

  /// Overview of the design goal framework and prioritization approach.
  TextSection overview = TextSection();

  /// Contains 0+× DesignGoal.
  @SectionIdPattern('PD00-USE-VIS-GOA-xx')
  List<DesignGoalEntry> items = [];
}

/// A design goal entry (form) [PD00-USE-VIS-GOA-nn].
///
/// Each goal represents a measurable UI objective with success criteria.
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

/// 10.1.2. Design Principles [PD00-USE-VIS-PRI].
///
/// Guiding principles for all UI decisions: progressive disclosure, direct
/// manipulation, feedback, consistency, error prevention.
@SectionId('PD00-USE-VIS-PRI')
class DesignPrinciples {
  @Unused()
  String? content;

  /// Overview of the design principle framework.
  TextSection overview = TextSection();

  /// Contains 0+× UiDesignPrinciple.
  @SectionIdPattern('PD00-USE-VIS-PRI-xx')
  List<UiDesignPrincipleEntry> items = [];
}

/// A design principle entry (form) [PD00-USE-VIS-PRI-nn].
///
/// Each principle guides UI decisions with rationale and examples.
class UiDesignPrincipleEntry {
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

/// 10.1.3. User Personas [PD00-USE-VIS-PER].
///
/// Container for user persona definitions. Each persona represents a distinct
/// user archetype with goals, pain points, and context.
@SectionId('PD00-USE-VIS-PER')
class UserPersonas {
  @Unused()
  String? content;

  /// Overview of persona research methodology and usage.
  TextSection overview = TextSection();

  /// Contains 1+× Persona.
  @SectionIdPattern('PD00-USE-VIS-PER-xx')
  @Min(1)
  List<PersonaEntry> items = [];
}

/// A user persona entry [PD00-USE-VIS-PER-nn] (form).
///
/// Represents a distinct user archetype with detailed context for UI design.
class PersonaEntry {
  @Form([
    Field('personaName', String, 'Persona Name', required: true,
        hint: 'Name and title, e.g., "Marco, Finance Manager"'),
    Field('age', String, 'Age',
        hint: 'Age or age range'),
    Field('role', String, 'Role',
        hint: 'Job title and responsibilities'),
    Field('bio', String, 'Background',
        hint: 'Brief biographical context'),
    Field('technicalProficiency', String, 'Technical Proficiency',
        hint: 'Beginner/Intermediate/Advanced — with context'),
    Field('typicalUsage', String, 'Typical Usage',
        hint: 'Frequency, duration, and primary activities'),
    Field('primaryDevice', String, 'Primary Device',
        hint: 'Desktop/Laptop/Tablet/Mobile'),
    Field('additionalDevices', String, 'Additional Devices',
        hint: 'Secondary devices used'),
    Field('workEnvironment', String, 'Work Environment',
        hint: 'Office/Remote/Field/Hybrid'),
    Field('accessibilityNeeds', String, 'Accessibility Needs',
        hint: 'Visual/Motor/Cognitive/None'),
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

  /// 10.1.3.n.1. Persona Goals [PD00-USE-VIS-PER-nn-GOA].
  PersonaGoals goals = PersonaGoals();

  /// 10.1.3.n.2. Persona Pain Points [PD00-USE-VIS-PER-nn-PAI].
  PersonaPainPoints painPoints = PersonaPainPoints();

  /// 10.1.3.n.3. Persona Scenarios [PD00-USE-VIS-PER-nn-SCE].
  PersonaScenarios scenarios = PersonaScenarios();
}

/// 10.1.3.n.1. Persona Goals [PD00-USE-VIS-PER-nn-GOA].
@SectionId('PD00-USE-VIS-PER-xx-GOA')
class PersonaGoals {
  @Unused()
  String? content;

  /// Contains 0+× PersonaGoal.
  @SectionIdPattern('PD00-USE-VIS-PER-xx-GOA-xx')
  List<PersonaGoalEntry> items = [];
}

/// A persona goal entry (form) [PD00-USE-VIS-PER-nn-GOA-mm].
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

/// 10.1.3.n.2. Persona Pain Points [PD00-USE-VIS-PER-nn-PAI].
@SectionId('PD00-USE-VIS-PER-xx-PAI')
class PersonaPainPoints {
  @Unused()
  String? content;

  /// Contains 0+× PersonaPainPoint.
  @SectionIdPattern('PD00-USE-VIS-PER-xx-PAI-xx')
  List<PersonaPainPointEntry> items = [];
}

/// A pain point entry (form) [PD00-USE-VIS-PER-nn-PAI-mm].
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

/// 10.1.3.n.3. Persona Scenarios [PD00-USE-VIS-PER-nn-SCE].
///
/// Key usage scenarios for this persona — helps map personas to screens/flows.
@SectionId('PD00-USE-VIS-PER-xx-SCE')
class PersonaScenarios {
  @Unused()
  String? content;

  /// Contains 0+× PersonaScenario.
  @SectionIdPattern('PD00-USE-VIS-PER-xx-SCE-xx')
  List<PersonaScenarioEntry> items = [];
}

/// A persona scenario entry (form) [PD00-USE-VIS-PER-nn-SCE-mm].
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

/// 10.2. Screen Descriptions [PD00-USE-SCR].
@SectionId('PD00-USE-SCR')
class ScreenDescriptions {
  @Unused()
  String? content;

  /// 10.2.1. Screen Inventory [PD00-USE-SCR-INV].
  ScreenInventory screenInventory = ScreenInventory();

  /// 10.2.2. Information Architecture [PD00-USE-SCR-INF].
  InformationArchitecture informationArchitecture = InformationArchitecture();
}

// ---------------------------------------------------------------------------
// 10.2.1 Screen Inventory
// ---------------------------------------------------------------------------

/// 10.2.1. Screen Inventory [PD00-USE-SCR-INV].
///
/// Container for screen definitions. Each entry fully describes one application
/// screen including its purpose, layout zones, elements, actions, and states.
@SectionId('PD00-USE-SCR-INV')
class ScreenInventory {
  @Unused()
  String? content;

  /// Overview of the screen inventory structure and conventions.
  TextSection overview = TextSection();

  /// Contains 1+× Screen.
  @SectionIdPattern('PD00-USE-SCR-INV-xx')
  @Min(1)
  List<ScreenEntry> items = [];
}

/// A screen entry [PD00-USE-SCR-INV-nn] (form).
///
/// Comprehensive specification of a single application screen, covering
/// identity, purpose, authorization, layout, elements, and behavior.
class ScreenEntry {
  @Form([
    Field('screenId', String, 'Screen ID', required: true,
        hint: 'Unique identifier, e.g., SCR-001'),
    Field('screenName', String, 'Screen Name', required: true,
        hint: 'Human-readable screen title'),
    Field('purpose', String, 'Purpose',
        hint: 'Business purpose — what the user accomplishes here'),
    Field('screenCategory', String, 'Screen Category',
        hint:
            'List/Detail/Form/Dashboard/Settings/Wizard/Dialog/Report/Landing'),
    Field('parentScreenId', String, 'Parent Screen ID',
        hint: 'Parent screen if this is a sub-screen or drill-down'),
    Field('routePattern', String, 'Route Pattern',
        hint: 'Navigation route path, e.g., /orders/:id/edit'),
    Field('accessLevel', String, 'Access Level',
        hint: 'Public/Authenticated/Role-specific'),
    Field('requiredRoles', String, 'Required Roles',
        hint: 'Authorization roles that may access this screen'),
    Field('requiredPermissions', String, 'Required Permissions',
        hint: 'Specific permissions needed'),
    Field('permissionEffect', String, 'Permission Effect',
        hint: 'Hide-Screen/Show-Readonly/Show-With-Restrictions'),
    Field('relatedUseCases', String, 'Related Use Cases',
        hint: 'UC references this screen serves'),
    Field('relatedRequirements', String, 'Related Requirements',
        hint: 'RC references this screen satisfies'),
    Field('relatedBusinessProcesses', String, 'Related Business Processes',
        hint: 'BP references where this screen appears'),
    Field('dataEntities', String, 'Data Entities',
        hint: 'BDM entity references displayed/edited'),
    Field('primaryAction', String, 'Primary Action',
        hint: 'Main user action on this screen'),
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

  /// Screen design rationale and notes.
  TextSection designNotes = TextSection();

  /// 10.2.1.n.1. Screen Sections [PD00-USE-SCR-INV-nn-SEC].
  ScreenSections sections = ScreenSections();

  /// 10.2.1.n.2. Screen Actions [PD00-USE-SCR-INV-nn-ACT].
  ScreenActions actions = ScreenActions();

  /// 10.2.1.n.3. Screen States [PD00-USE-SCR-INV-nn-STA].
  ScreenStates states = ScreenStates();

  /// Contains 0+× ScreenUserCategory.
  @SectionIdPattern('PD00-USE-SCR-INV-xx-UCT-xx')
  List<ScreenUserCategoryEntry> userCategories = [];

  /// Contains 0+× EntryPoint.
  @SectionIdPattern('PD00-USE-SCR-INV-xx-EPT-xx')
  List<EntryPointEntry> entryPoints = [];

  /// Contains 0+× ScreenResponsiveRule.
  @SectionIdPattern('PD00-USE-SCR-INV-xx-RSP-xx')
  List<ScreenResponsiveRuleEntry> responsiveRules = [];
}

// ---------------------------------------------------------------------------
// 10.2.1.n.1 Screen Sections (Zones)
// ---------------------------------------------------------------------------

/// 10.2.1.n.1. Screen Sections [PD00-USE-SCR-INV-nn-SEC].
///
/// Logical zones within a screen that group related elements.
@SectionId('PD00-USE-SCR-INV-xx-SEC')
class ScreenSections {
  @Unused()
  String? content;

  /// Contains 0+× ScreenSection.
  @SectionIdPattern('PD00-USE-SCR-INV-xx-SEC-xx')
  List<ScreenSectionEntry> items = [];
}

/// A screen section entry (form) [PD00-USE-SCR-INV-nn-SEC-mm].
///
/// A logical zone within a screen: header, toolbar, content area, sidebar, etc.
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
    Field('layoutDirection', String, 'Layout Direction',
        hint: 'Horizontal/Vertical/Wrap/Grid'),
    Field('displayOrder', int, 'Display Order',
        hint: 'Position in reading order'),
    Field('collapsible', String, 'Collapsible',
        hint: 'Yes/No — can the user collapse this section?'),
    Field('initiallyCollapsed', String, 'Initially Collapsed',
        hint: 'Yes/No — default collapsed state'),
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'When this section is shown, e.g., role==Admin'),
    Field('titleResource', String, 'Title Resource',
        hint: 'Resource key for section header text'),
    Field('borderStyle', String, 'Border Style',
        hint: 'Named style or resource key'),
  ])
  String? content;

  /// Contains 0+× ScreenElement within this section.
  @SectionIdPattern('PD00-USE-SCR-INV-xx-SEC-xx-ELE-xx')
  List<ScreenElementEntry> elements = [];
}

/// A screen element entry (form) [PD00-USE-SCR-INV-nn-SEC-mm-ELE-kk].
///
/// Any interactive or display element within a screen section: buttons, fields,
/// data displays, icons, labels, status indicators.
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
    Field('placementOrder', int, 'Placement Order',
        hint: 'Order within parent section'),
    Field('width', String, 'Width',
        hint: 'Fill/Auto/Fixed(200)/Proportion(1/3)'),
    Field('alignment', String, 'Alignment',
        hint: 'Start/Center/End/Stretch'),
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

  /// 10.2.1.n.m.k.1. Element Action [PD00-USE-SCR-INV-nn-SEC-mm-ELE-kk-ACN].
  ScreenElementAction? elementAction;

  /// 10.2.1.n.m.k.2. Element Field Spec [PD00-USE-SCR-INV-nn-SEC-mm-ELE-kk-FLD].
  ScreenElementFieldSpec? fieldSpec;

  /// 10.2.1.n.m.k.3. Element Data Display [PD00-USE-SCR-INV-nn-SEC-mm-ELE-kk-DAT].
  ScreenElementDataDisplay? dataDisplay;

  /// Contains 0+× ElementValidationRule.
  @SectionIdPattern('PD00-USE-SCR-INV-xx-SEC-xx-ELE-xx-VAL-xx')
  List<ElementValidationRuleEntry> validationRules = [];
}

/// Action specification for an action-type element (form).
///
/// Defines button/link behavior: action reference, confirmation, navigation.
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
    Field('keyboardShortcut', String, 'Keyboard Shortcut',
        hint: 'Shortcut binding, e.g., Ctrl+S'),
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
    Field('prefixResource', String, 'Prefix Resource',
        hint: 'Prefix text/icon resource, e.g., currency symbol'),
    Field('suffixResource', String, 'Suffix Resource',
        hint: 'Suffix text/icon resource, e.g., unit label'),
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
    Field('inputMask', String, 'Input Mask',
        hint: 'Pattern, e.g., ##/##/####'),
    Field('displayFormat', String, 'Display Format',
        hint: 'Format pattern, e.g., #,##0.00'),
    Field('validationTrigger', String, 'Validation Trigger',
        hint: 'On-Change/On-Blur/On-Submit/Debounced'),
    Field('errorDisplayMode', String, 'Error Display Mode',
        hint: 'Below-Field/Tooltip/Inline/Banner'),
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
    Field('required', String, 'Required',
        hint: 'Yes/No/Conditional'),
    Field('requiredCondition', String, 'Required Condition',
        hint: 'Condition when field becomes required'),
    Field('clearButton', String, 'Clear Button',
        hint: 'Yes/No — show clear/reset affordance'),
  ])
  String? content;
}

/// Data display specification for display-type elements (form).
///
/// Defines how data is presented: format, empty state, refresh, drill-down.
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
    Field('refreshMode', String, 'Refresh Mode',
        hint: 'Auto/Manual/Interval(seconds)'),
    Field('drillDownTarget', String, 'Drill-Down Target',
        hint: 'Screen ID navigated to on click/tap'),
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

/// A validation rule entry (form) [PD00-USE-SCR-INV-nn-SEC-mm-ELE-kk-VAL-pp].
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

/// 10.2.1.n.2. Screen Actions [PD00-USE-SCR-INV-nn-ACT].
///
/// Top-level actions available on the screen (toolbar, app bar, FAB).
@SectionId('PD00-USE-SCR-INV-xx-ACT')
class ScreenActions {
  @Unused()
  String? content;

  /// Contains 0+× ScreenAction.
  @SectionIdPattern('PD00-USE-SCR-INV-xx-ACT-xx')
  List<ScreenActionEntry> items = [];
}

/// A screen action entry (form) [PD00-USE-SCR-INV-nn-ACT-mm].
///
/// A top-level action available on the screen via toolbar, app bar, or FAB.
class ScreenActionEntry {
  @Form([
    Field('actionId', String, 'Action ID', required: true,
        hint: 'Unique action identifier'),
    Field('actionName', String, 'Action Name', required: true,
        hint: 'Human-readable action name'),
    Field('actionType', String, 'Action Type',
        hint:
            'Submit/Save/Cancel/Delete/Navigate/Export/Import/Print/Refresh'),
    Field('labelResource', String, 'Label Resource',
        hint: 'Resource key for button label'),
    Field('iconResource', String, 'Icon Resource',
        hint: 'Resource key for action icon'),
    Field('placement', String, 'Placement',
        hint: 'App-Bar/Toolbar/FAB/Context-Menu/Overflow-Menu'),
    Field('buttonStyle', String, 'Button Style',
        hint: 'Primary/Secondary/Tertiary/Danger/Icon-Only/Text-Only'),
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'When this action is shown'),
    Field('enabledCondition', String, 'Enabled Condition',
        hint: 'When this action is active'),
    Field('requiredPermission', String, 'Required Permission',
        hint: 'Permission needed to use this action'),
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

/// 10.2.1.n.3. Screen States [PD00-USE-SCR-INV-nn-STA].
///
/// Different visual/behavioral states the screen can be in.
@SectionId('PD00-USE-SCR-INV-xx-STA')
class ScreenStates {
  @Unused()
  String? content;

  /// Contains 0+× ScreenState.
  @SectionIdPattern('PD00-USE-SCR-INV-xx-STA-xx')
  List<ScreenStateEntry> items = [];
}

/// A screen state entry (form) [PD00-USE-SCR-INV-nn-STA-mm].
///
/// A specific state the screen can be in: loading, empty, error, permission-denied.
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

/// A user category entry (form) [PD00-USE-SCR-INV-nn-UCT-mm].
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

/// An entry point entry (form) [PD00-USE-SCR-INV-nn-EPT-mm].
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

/// A responsive rule entry (form) [PD00-USE-SCR-INV-nn-RSP-mm].
///
/// How the screen adapts at different breakpoints.
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

/// 10.2.2. Information Architecture [PD00-USE-SCR-INF].
///
/// Overall information architecture: site map, content hierarchy, navigation
/// structure, and entry points. Describes how screens relate to each other
/// and how content is organized across the application.
@SectionId('PD00-USE-SCR-INF')
class InformationArchitecture {
  @Unused()
  String? content;

  /// Site map overview.
  TextSection siteMap = TextSection();

  /// Content hierarchy description.
  TextSection contentHierarchy = TextSection();

  /// Navigation structure.
  TextSection navigationStructure = TextSection();

  /// Global entry points.
  TextSection globalEntryPoints = TextSection();

  /// 10.2.2.5. Information Architecture Diagram [PD00-USE-SCR-INF-DIA].
  FlowDiagramSection architectureDiagram = FlowDiagramSection();
}

// ---------------------------------------------------------------------------
// 10.3 Screen Flow Structure
// ---------------------------------------------------------------------------

/// 10.3. Screen Flow Structure [PD00-USE-SCF].
@SectionId('PD00-USE-SCF')
class ScreenFlowStructure {
  @Unused()
  String? content;

  /// 10.3.1. Navigation Model [PD00-USE-SCF-NAV].
  NavigationModel navigationModel = NavigationModel();

  /// 10.3.2. Screen Flow Diagram [PD00-USE-SCF-DIA] (mermaid-flow).
  FlowDiagramSection screenFlowDiagram = FlowDiagramSection();
}

// ---------------------------------------------------------------------------
// 10.3.1 Navigation Model
// ---------------------------------------------------------------------------

/// 10.3.1. Navigation Model [PD00-USE-SCF-NAV].
///
/// Comprehensive navigation structure: primary, secondary, utility, contextual
/// navigation, deep linking, navigation guards, and platform adaptation.
@SectionId('PD00-USE-SCF-NAV')
class NavigationModel {
  @Unused()
  String? content;

  /// 10.3.1.1. Navigation Overview [PD00-USE-SCF-NAV-OVR].
  NavigationOverview overview = NavigationOverview();

  /// 10.3.1.2. Navigation Hierarchy [PD00-USE-SCF-NAV-HIE].
  NavigationHierarchy hierarchy = NavigationHierarchy();

  /// 10.3.1.3. Primary Navigation [PD00-USE-SCF-NAV-PRI].
  PrimaryNavigation primaryNavigation = PrimaryNavigation();

  /// 10.3.1.4. Secondary Navigation [PD00-USE-SCF-NAV-SEC].
  SecondaryNavigation secondaryNavigation = SecondaryNavigation();

  /// 10.3.1.5. Utility Navigation [PD00-USE-SCF-NAV-UTL].
  UtilityNavigation utilityNavigation = UtilityNavigation();

  /// 10.3.1.6. Contextual Navigation [PD00-USE-SCF-NAV-CTX].
  ContextualNavigation contextualNavigation = ContextualNavigation();

  /// 10.3.1.7. Deep Linking [PD00-USE-SCF-NAV-DPL].
  DeepLinking deepLinking = DeepLinking();

  /// 10.3.1.8. Navigation Guards [PD00-USE-SCF-NAV-GRD].
  NavigationGuards navigationGuards = NavigationGuards();
}

// ---------------------------------------------------------------------------
// 10.3.1.1 Navigation Overview
// ---------------------------------------------------------------------------

/// 10.3.1.1. Navigation Overview [PD00-USE-SCF-NAV-OVR].
///
/// Overall navigation strategy, routing approach, and design decisions.
@SectionId('PD00-USE-SCF-NAV-OVR')
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

/// 10.3.1.2. Navigation Hierarchy [PD00-USE-SCF-NAV-HIE].
///
/// Full navigation tree: groups and items forming the app's navigation structure.
@SectionId('PD00-USE-SCF-NAV-HIE')
class NavigationHierarchy {
  @Unused()
  String? content;

  /// Overview of the navigation hierarchy structure.
  TextSection overview = TextSection();

  /// Contains 0+× NavigationGroup.
  @SectionIdPattern('PD00-USE-SCF-NAV-HIE-xx')
  List<NavigationGroupEntry> groups = [];
}

/// A navigation group entry (form) [PD00-USE-SCF-NAV-HIE-nn].
///
/// Logical grouping of navigation items (e.g., "Sales", "Administration").
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
    Field('displayOrder', int, 'Display Order',
        hint: 'Sort position among siblings'),
    Field('collapsible', String, 'Collapsible',
        hint: 'Yes/No — can the group be collapsed?'),
    Field('initiallyExpanded', String, 'Initially Expanded',
        hint: 'Yes/No — default expanded state'),
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'Business rule for visibility'),
    Field('requiredRoles', String, 'Required Roles',
        hint: 'Comma-separated role IDs'),
    Field('requiredPermissions', String, 'Required Permissions',
        hint: 'Specific permissions required'),
    Field('permissionBehavior', String, 'Permission Behavior',
        hint: 'Hide/Disable/Collapse when unauthorized'),
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

  /// Contains 0+× NavigationItem.
  @SectionIdPattern('PD00-USE-SCF-NAV-HIE-xx-ITM-xx')
  List<NavigationItemEntry> items = [];
}

/// A navigation item entry (form) [PD00-USE-SCF-NAV-HIE-nn-ITM-mm].
///
/// A single navigable destination within a group.
class NavigationItemEntry {
  @Form([
    Field('itemId', String, 'Item ID', required: true,
        hint: 'Unique identifier, e.g., nav-customers'),
    Field('label', String, 'Label Resource', required: true,
        hint: 'Resource key for display label'),
    Field('shortLabel', String, 'Short Label Resource',
        hint: 'Abbreviated label for bottom nav/compact mode'),
    Field('icon', String, 'Icon Resource',
        hint: 'Primary icon resource key'),
    Field('activeIcon', String, 'Active Icon Resource',
        hint: 'Icon variant when selected (filled vs outlined)'),
    Field('description', String, 'Description Resource',
        hint: 'Tooltip or subtitle text'),
    Field('targetScreenId', String, 'Target Screen ID',
        hint: 'Reference to Screen Inventory SCR-xxx'),
    Field('targetRoute', String, 'Target Route',
        hint: 'Route path, e.g., /customers'),
    Field('targetRouteParams', String, 'Route Parameters',
        hint: 'Default params, e.g., {status: active}'),
    Field('displayOrder', int, 'Display Order',
        hint: 'Position within parent group'),
    Field('isDefault', String, 'Is Default',
        hint: 'Yes/No — default selected item in group'),
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
    Field('badgeType', String, 'Badge Type',
        hint: 'None/Count/Dot/Text/Icon'),
    Field('badgeSource', String, 'Badge Source',
        hint: 'Data binding for badge, e.g., inbox.unreadCount'),
    Field('badgeColor', String, 'Badge Color',
        hint: 'Error/Warning/Info/Success/Neutral'),
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

/// 10.3.1.3. Primary Navigation [PD00-USE-SCF-NAV-PRI].
///
/// How the main navigation appears across platforms: drawer, sidebar, bottom nav.
@SectionId('PD00-USE-SCF-NAV-PRI')
class PrimaryNavigation {
  @Form([
    Field('mobilePattern', String, 'Mobile Pattern',
        hint: 'Drawer/Bottom-Nav/Bottom-Nav+Drawer'),
    Field('tabletPattern', String, 'Tablet Pattern',
        hint: 'Rail/Collapsible-Sidebar/Drawer'),
    Field('desktopPattern', String, 'Desktop Pattern',
        hint: 'Sidebar/Sidebar-Collapsible/Top-Nav+Sidebar'),
    Field('drawerBehavior', String, 'Drawer Behavior',
        hint: 'Modal-Overlay/Push-Content/Persistent'),
    Field('drawerWidth', String, 'Drawer Width',
        hint: 'Width specification, e.g., 280dp/25%'),
    Field('drawerHeaderContent', String, 'Drawer Header',
        hint: 'User-Avatar/App-Logo/User-Card/Custom'),
    Field('drawerFooterContent', String, 'Drawer Footer',
        hint: 'Version-Info/Settings-Link/Logout/None'),
    Field('bottomNavMaxItems', int, 'Bottom Nav Max Items',
        hint: 'Maximum items (Material guideline: 3-5)'),
    Field('bottomNavStyle', String, 'Bottom Nav Style',
        hint: 'Fixed/Shifting/Labeled/Icon-Only'),
    Field('bottomNavShowLabels', String, 'Show Labels',
        hint: 'Always/Selected-Only/Never'),
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

  /// Design notes and tradeoffs.
  TextSection designNotes = TextSection();
}

// ---------------------------------------------------------------------------
// 10.3.1.4 Secondary Navigation
// ---------------------------------------------------------------------------

/// 10.3.1.4. Secondary Navigation [PD00-USE-SCF-NAV-SEC].
///
/// In-page navigation: tab bars, segmented controls.
@SectionId('PD00-USE-SCF-NAV-SEC')
class SecondaryNavigation {
  @Unused()
  String? content;

  /// Overview of secondary navigation patterns.
  TextSection overview = TextSection();

  /// Contains 0+× TabBarDefinition.
  @SectionIdPattern('PD00-USE-SCF-NAV-SEC-xx')
  List<TabBarDefinitionEntry> tabBars = [];
}

/// A tab bar definition entry (form) [PD00-USE-SCF-NAV-SEC-nn].
///
/// Defines a tab bar or segmented control on a specific screen.
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
    Field('tabBarPosition', String, 'Position',
        hint: 'Top/Bottom/Left'),
    Field('isScrollable', String, 'Scrollable',
        hint: 'Yes/No — scrollable when tabs exceed width'),
    Field('defaultTabIndex', int, 'Default Tab',
        hint: 'Zero-based index of initially selected tab'),
    Field('persistSelection', String, 'Persist Selection',
        hint: 'Yes/No — remember last selected tab'),
    Field('swipeEnabled', String, 'Swipe Navigation',
        hint: 'Yes/No — swipe between tabs on mobile'),
    Field('lazyLoading', String, 'Lazy Loading',
        hint: 'Yes/No — load tab content when first selected'),
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'When entire tab bar is shown'),
  ])
  String? content;

  /// Contains 1+× TabItem.
  @SectionIdPattern('PD00-USE-SCF-NAV-SEC-xx-TAB-xx')
  @Min(1)
  List<TabItemEntry> tabs = [];
}

/// A tab item entry (form) [PD00-USE-SCF-NAV-SEC-nn-TAB-mm].
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

/// 10.3.1.5. Utility Navigation [PD00-USE-SCF-NAV-UTL].
///
/// Always-visible utility items: user menu, notifications, help, settings.
@SectionId('PD00-USE-SCF-NAV-UTL')
class UtilityNavigation {
  @Unused()
  String? content;

  /// Contains 0+× UtilityNavigationItem.
  @SectionIdPattern('PD00-USE-SCF-NAV-UTL-xx')
  List<UtilityNavigationItemEntry> items = [];
}

/// A utility navigation item entry (form) [PD00-USE-SCF-NAV-UTL-nn].
///
/// A persistent utility element in the app bar: user avatar, notifications bell,
/// help icon, settings.
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
    Field('displayOrder', int, 'Display Order',
        hint: 'Sort position'),
    Field('widgetType', String, 'Widget Type',
        hint: 'Icon-Button/Avatar/Dropdown/Popup-Menu/Badge-Icon'),
    Field('visibilityCondition', String, 'Visibility Condition',
        hint: 'When shown'),
    Field('requiredRoles', String, 'Required Roles',
        hint: 'Access control'),
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

  /// Contains 0+× UtilityMenuItem.
  @SectionIdPattern('PD00-USE-SCF-NAV-UTL-xx-MEN-xx')
  List<UtilityMenuItemEntry> menuItems = [];
}

/// A utility menu item entry (form) [PD00-USE-SCF-NAV-UTL-nn-MEN-mm].
///
/// Entry in a utility popup/dropdown menu (e.g., user menu items).
class UtilityMenuItemEntry {
  @Form([
    Field('menuItemId', String, 'Menu Item ID', required: true),
    Field('label', String, 'Label Resource', required: true,
        hint: 'Display text'),
    Field('icon', String, 'Icon Resource',
        hint: 'Leading icon'),
    Field('displayOrder', int, 'Display Order',
        hint: 'Position in menu'),
    Field('actionType', String, 'Action Type',
        hint: 'Navigate/Action/External-Link/Divider'),
    Field('targetRoute', String, 'Target Route',
        hint: 'Navigation target'),
    Field('actionId', String, 'Action ID',
        hint: 'Action system reference, e.g., logout'),
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

/// 10.3.1.6. Contextual Navigation [PD00-USE-SCF-NAV-CTX].
///
/// Breadcrumbs, back navigation, related links.
@SectionId('PD00-USE-SCF-NAV-CTX')
class ContextualNavigation {
  @Unused()
  String? content;

  /// 10.3.1.6.1. Breadcrumb Configuration [PD00-USE-SCF-NAV-CTX-BRD].
  BreadcrumbConfiguration breadcrumbs = BreadcrumbConfiguration();

  /// Back navigation behavior.
  TextSection backNavigation = TextSection();

  /// Related links behavior.
  TextSection relatedLinks = TextSection();
}

/// 10.3.1.6.1. Breadcrumb Configuration [PD00-USE-SCF-NAV-CTX-BRD].
@SectionId('PD00-USE-SCF-NAV-CTX-BRD')
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

/// 10.3.1.7. Deep Linking [PD00-USE-SCF-NAV-DPL].
///
/// External entry points, URL patterns, share links.
@SectionId('PD00-USE-SCF-NAV-DPL')
class DeepLinking {
  @Unused()
  String? content;

  /// Deep linking strategy overview.
  TextSection strategy = TextSection();

  /// Contains 0+× DeepLinkPattern.
  @SectionIdPattern('PD00-USE-SCF-NAV-DPL-xx')
  List<DeepLinkPatternEntry> patterns = [];
}

/// A deep link pattern entry (form) [PD00-USE-SCF-NAV-DPL-nn].
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

/// 10.3.1.8. Navigation Guards [PD00-USE-SCF-NAV-GRD].
///
/// Route guards: unsaved changes, authentication redirects, permission checks.
@SectionId('PD00-USE-SCF-NAV-GRD')
class NavigationGuards {
  @Unused()
  String? content;

  /// Overview of navigation guard strategy.
  TextSection overview = TextSection();

  /// Contains 0+× NavigationGuard.
  @SectionIdPattern('PD00-USE-SCF-NAV-GRD-xx')
  List<NavigationGuardEntry> guards = [];
}

/// A navigation guard entry (form) [PD00-USE-SCF-NAV-GRD-nn].
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

/// 10.4. Print Layout [PD00-USE-PRI].
@SectionId('PD00-USE-PRI')
class PrintLayout {
  @Unused()
  String? content;

  /// 10.4.1. Reports [PD00-USE-PRI-REP] — contains 0+× Report.
  @SectionIdPattern('PD00-USE-PRI-REP-xx')
  List<ReportEntry> reports = [];

  /// 10.4.2. Export Formats [PD00-USE-PRI-EXP] — contains 0+× ExportFormat.
  @SectionIdPattern('PD00-USE-PRI-EXP-xx')
  List<ExportFormatEntry> exportFormats = [];
}

/// An export format entry (form) [PD00-USE-PRI-EXP-nn].
class ExportFormatEntry {
  @Form([
    Field('formatName', String, 'Format Name'),
    Field('description', String, 'Short description'),
  ])
  String? content;
}

/// A report entry [PD00-USE-PRI-REP-nn] (form).
class ReportEntry {
  @Form([
    Field('reportName', String, 'Report Name', required: true),
    Field('purpose', String, 'Purpose'),
    Field('reportContent', String, 'Report Content'),
    Field('format', String, 'Format'),
    Field('generationTrigger', String, 'Generation Trigger'),
    Field('customization', String, 'Customization'),
  ])
  String? content;

  /// Contains 0+× Recipient.
  @SectionIdPattern('PD00-USE-PRI-REP-xx-REC-xx')
  List<RecipientEntry> recipients = [];
}

/// A recipient entry (form) [PD00-USE-PRI-REP-nn-REC-nn].
class RecipientEntry {
  @Form([
    Field('recipientName', String, 'Recipient Name'),
    Field('role', String, 'Role'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 10.7 Error Handling
// ---------------------------------------------------------------------------

/// 10.7. Error Handling Concept [PD00-USE-ERR].
@SectionId('PD00-USE-ERR')
class ErrorHandlingConcept {
  @Unused()
  String? content;

  /// Validation Feedback.
  TextSection validationFeedback = TextSection();

  /// System Error Display.
  TextSection systemErrorDisplay = TextSection();

  /// Error Recovery.
  TextSection errorRecovery = TextSection();
}

// ---------------------------------------------------------------------------
// 10.8 Help Concept
// ---------------------------------------------------------------------------

/// 10.8. Help Concept [PD00-USE-HLP].
@SectionId('PD00-USE-HLP')
class HelpConcept {
  @Unused()
  String? content;

  /// Contextual Help.
  TextSection contextualHelp = TextSection();

  /// Onboarding.
  TextSection onboarding = TextSection();

  /// Support Access.
  TextSection supportAccess = TextSection();
}

// ---------------------------------------------------------------------------
// 10.9 Accessibility
// ---------------------------------------------------------------------------

/// 10.9. Accessibility [PD00-USE-ACC].
@SectionId('PD00-USE-ACC')
class Accessibility {
  @Unused()
  String? content;

  /// Wcag Compliance Level.
  TextSection wcagComplianceLevel = TextSection();

  /// 10.9.2. Accessibility Checklist [PD00-USE-ACC-CHK].
  AccessibilityChecklist accessibilityChecklist = AccessibilityChecklist();
}

/// 10.9.2. Accessibility Checklist [PD00-USE-ACC-CHK].
@SectionId('PD00-USE-ACC-CHK')
class AccessibilityChecklist {
  @Unused()
  String? content;

  /// Contains 0+× AccessibilityCheck.
  @SectionIdPattern('PD00-USE-ACC-CHK-xx')
  List<AccessibilityCheckEntry> items = [];
}

/// An accessibility check entry (form) [PD00-USE-ACC-CHK-nn].
class AccessibilityCheckEntry {
  @Form([
    Field('checkItem', String, 'Check Item'),
    Field('wcagCriterion', String, 'Wcag Criterion'),
    Field('complianceLevel', String, 'Compliance Level'),
    Field('verificationMethod', String, 'Verification Method'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 10.10 Responsive Design
// ---------------------------------------------------------------------------

/// 10.10. Responsive Design [PD00-USE-RES].
@SectionId('PD00-USE-RES')
class ResponsiveDesign {
  @Unused()
  String? content;

  /// 10.10.1. Breakpoints [PD00-USE-RES-BRE] — contains 0+× Breakpoint.
  @SectionIdPattern('PD00-USE-RES-BRE-xx')
  List<BreakpointEntry> breakpoints = [];

  /// Responsive Behavior.
  TextSection responsiveBehavior = TextSection();
}

/// A breakpoint entry (form) [PD00-USE-RES-BRE-nn].
class BreakpointEntry {
  @Form([
    Field('breakpointName', String, 'Breakpoint Name', required: true),
    Field('minWidth', String, 'Min Width'),
    Field('layoutBehavior', String, 'Layout Behavior'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 10.11 UI Components
// ---------------------------------------------------------------------------

/// 10.11. UI Components [PD00-USE-COM].
@SectionId('PD00-USE-COM')
class UiComponents {
  @Unused()
  String? content;

  /// Component Library.
  TextSection componentLibrary = TextSection();

  /// 10.11.2. Component Specifications [PD00-USE-COM-SPE] — contains 0+×.
  @SectionIdPattern('PD00-USE-COM-SPE-xx')
  List<UiComponentEntry> componentSpecs = [];
}

/// A UI component entry [PD00-USE-COM-SPE-nn] (form).
class UiComponentEntry {
  @Form([
    Field('componentName', String, 'Component Name', required: true),
    Field('purpose', String, 'Purpose'),
    Field('behavior', String, 'Behavior'),
    Field('responsive', String, 'Responsive'),
  ])
  String? content;

  /// Contains 0+× ComponentState.
  @SectionIdPattern('PD00-USE-COM-SPE-xx-STA-xx')
  List<ComponentStateEntry> states = [];

  /// Contains 0+× ComponentVariant.
  @SectionIdPattern('PD00-USE-COM-SPE-xx-VAR-xx')
  List<ComponentVariantEntry> variants = [];
}

/// A component state entry (form) [PD00-USE-COM-SPE-nn-STA-nn].
class ComponentStateEntry {
  @Form([
    Field('stateName', String, 'State Name'),
    Field('description', String, 'Short description'),
  ])
  String? content;
}

/// A component variant entry (form) [PD00-USE-COM-SPE-nn-VAR-nn].
class ComponentVariantEntry {
  @Form([
    Field('variantName', String, 'Variant Name'),
    Field('description', String, 'Short description'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 10.12 Multi-language and Rollout
// ---------------------------------------------------------------------------

/// 10.12. Multi-language and Rollout Support [PD00-USE-MUL].
@SectionId('PD00-USE-MUL')
class MultiLanguageAndRollout {
  @Unused()
  String? content;

  /// 10.12.1. Multi-language Support [PD00-USE-MUL-LAN].
  MultiLanguageSupport multiLanguageSupport = MultiLanguageSupport();

  /// 10.12.2. Rollout Support [PD00-USE-MUL-ROL].
  RolloutSupport rolloutSupport = RolloutSupport();
}

/// 10.12.1. Multi-language Support [PD00-USE-MUL-LAN].
@SectionId('PD00-USE-MUL-LAN')
class MultiLanguageSupport {
  @Unused()
  String? content;

  /// Localization Process.
  TextSection localizationProcess = TextSection();

  /// Translation Process.
  TextSection translationProcess = TextSection();

  /// Language And Country Selection.
  TextSection languageAndCountrySelection = TextSection();

  /// Translation Handling Requirements.
  TextSection translationHandlingRequirements = TextSection();
}

/// 10.12.2. Rollout Support [PD00-USE-MUL-ROL].
@SectionId('PD00-USE-MUL-ROL')
class RolloutSupport {
  @Unused()
  String? content;

  /// User Documentation.
  TextSection userDocumentation = TextSection();

  /// Training Plan.
  TextSection trainingPlan = TextSection();

  /// Phased Deployment Strategy.
  TextSection phasedDeploymentStrategy = TextSection();

  /// Communication Plan.
  TextSection communicationPlan = TextSection();
}

// ---------------------------------------------------------------------------
// 10.13 Prototype
// ---------------------------------------------------------------------------

/// 10.13. Prototype [PD00-USE-PRO].
@SectionId('PD00-USE-PRO')
class Prototype {
  @Unused()
  String? content;

  /// 10.13.1. Prototype Goals [PD00-USE-PRO-GOA] — contains 0+× PrototypeGoal.
  @SectionIdPattern('PD00-USE-PRO-GOA-xx')
  List<PrototypeGoalEntry> prototypeGoals = [];

  /// Selected Feature Subset.
  TextSection selectedFeatureSubset = TextSection();

  /// 10.13.3. Prototype Type [PD00-USE-PRO-TYP].
  PrototypeTypeSection prototypeType = PrototypeTypeSection();
}

/// 10.13.3. Prototype Type [PD00-USE-PRO-TYP].
@SectionId('PD00-USE-PRO-TYP')
class PrototypeTypeSection {
  @Unused()
  String? content;

  /// Reusable Prototype.
  TextSection reusablePrototype = TextSection();

  /// Training Prototype.
  TextSection trainingPrototype = TextSection();

  /// Throwaway Prototype.
  TextSection throwawayPrototype = TextSection();
}

/// A prototype goal entry (form) [PD00-USE-PRO-GOA-nn].
class PrototypeGoalEntry {
  @Form([
    Field('goal', String, 'Goal', required: true),
    Field('description', String, 'Short description'),
  ])
  String? content;
}
