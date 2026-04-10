/// Section 10: User Interface Design and Prototype [PD00-USE].
///
/// Seeds → UP, SR, TR depending on subsection.
library;

import 'package:tom_specs_core/tom_specs_core.dart';



/// 10. User Interface Design and Prototype [PD00-USE].
class UserInterfaceDesign {
  String? content;

  /// 10.1. Design Vision [PD00-USE-VIS]. Seeds → UP.
  DesignVision designVision = DesignVision();

  /// 10.2. Screen Descriptions [PD00-USE-SCR]. Seeds → UP.
  ScreenDescriptions screens = ScreenDescriptions();

  /// 10.3. Screen Flow Structure [PD00-USE-SCF]. Seeds → UP.
  ScreenFlowStructure screenFlow = ScreenFlowStructure();

  /// 10.4. Print Layout [PD00-USE-PRI]. Seeds → UP.
  PrintLayout printLayout = PrintLayout();

  /// 10.5. Data Structure Alignment [PD00-USE-DAT]. Seeds → UP.
  String? dataStructureAlignment;

  /// 10.6. Authorization Concept Compliance [PD00-USE-AUT]. Seeds → UP.
  String? authorizationCompliance;

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
class DesignVision {
  String? content;

  /// 10.1.1. Design Goals [PD00-USE-VIS-GOA] — contains 0+× DesignGoal.
  List<DesignGoalEntry> designGoals = [];

  /// 10.1.2. Design Principles [PD00-USE-VIS-PRI] — contains 0+× UiDesignPrinciple.
  List<UiDesignPrincipleEntry> designPrinciples = [];

  /// 10.1.3. User Personas [PD00-USE-VIS-PER] — contains 1+× Persona.
  List<PersonaEntry> personas = [];
}

/// A design goal entry (form) [PD00-USE-VIS-GOA-nn].
class DesignGoalEntry {
  String? content;
  String? goal;
  String? description;
}

/// A design principle entry (form) [PD00-USE-VIS-PRI-nn].
class UiDesignPrincipleEntry {
  String? content;
  String? principle;
  String? rationale;
}

/// A user persona entry [PD00-USE-VIS-PER-nn] (form).
class PersonaEntry {
  String? content;
  String? personaName;
  String? age;
  String? role;
  /// Contains 0+× PersonaGoal.
  List<PersonaGoalEntry> goals = [];
  /// Contains 0+× PersonaPainPoint.
  List<PersonaPainPointEntry> painPoints = [];
  String? technicalProficiency;
  String? typicalUsage;
  String? device;
}

/// A persona goal entry (form) [PD00-USE-VIS-PER-nn-GOA-nn].
class PersonaGoalEntry {
  String? content;
  String? goal;
  String? priority;
}

/// A pain point entry (form) [PD00-USE-VIS-PER-nn-PAI-nn].
class PersonaPainPointEntry {
  String? content;
  String? painPoint;
  String? impact;
}

// ---------------------------------------------------------------------------
// 10.2 Screen Descriptions
// ---------------------------------------------------------------------------

/// 10.2. Screen Descriptions [PD00-USE-SCR].
class ScreenDescriptions {
  String? content;

  /// 10.2.1. Screen Inventory [PD00-USE-SCR-INV] — contains 1+× Screen.
  List<ScreenEntry> screenInventory = [];

  /// 10.2.2. Information Architecture [PD00-USE-SCR-INF].
  String? informationArchitecture;
}

/// A screen entry [PD00-USE-SCR-INV-nn] (form).
class ScreenEntry {
  String? content;
  String? screenId;
  String? screenName;
  String? purpose;
  /// Contains 0+× ScreenElement.
  List<ScreenElementEntry> keyElements = [];
  /// Contains 0+× ScreenUserCategory.
  List<ScreenUserCategoryEntry> userCategories = [];
  String? accessLevel;
  /// Contains 0+× Point.
  List<EntryPointEntry> entryPoints = [];
  String? layout;
}

/// A screen element entry (form) [PD00-USE-SCR-INV-nn-ELE-nn].
class ScreenElementEntry {
  String? content;
  String? elementName;
  String? elementType;
}

/// A user category entry (form) [PD00-USE-SCR-INV-nn-UCT-nn].
class ScreenUserCategoryEntry {
  String? content;
  String? categoryName;
  String? description;
}

/// An entry point entry (form) [PD00-USE-SCR-INV-nn-EPT-nn].
class EntryPointEntry {
  String? content;
  String? entryPoint;
  String? source;
}

// ---------------------------------------------------------------------------
// 10.3 Screen Flow Structure
// ---------------------------------------------------------------------------

/// 10.3. Screen Flow Structure [PD00-USE-SCF].
class ScreenFlowStructure {
  String? content;

  /// 10.3.1. Navigation Model [PD00-USE-SCF-NAV].
  String? navigationModel;

  /// 10.3.2. Screen Flow Diagram [PD00-USE-SCF-DIA] (mermaid).
  FlowDiagramSection screenFlowDiagram = FlowDiagramSection();
}

// ---------------------------------------------------------------------------
// 10.4 Print Layout
// ---------------------------------------------------------------------------

/// 10.4. Print Layout [PD00-USE-PRI].
class PrintLayout {
  String? content;

  /// 10.4.1. Reports [PD00-USE-PRI-REP] — contains 0+× Report.
  List<ReportEntry> reports = [];

  /// 10.4.2. Export Formats [PD00-USE-PRI-EXP] — contains 0+× ExportFormat.
  List<ExportFormatEntry> exportFormats = [];
}

/// An export format entry (form) [PD00-USE-PRI-EXP-nn].
class ExportFormatEntry {
  String? content;
  String? formatName;
  String? description;
}

/// A report entry [PD00-USE-PRI-REP-nn] (form).
class ReportEntry {
  String? content;
  String? reportName;
  String? purpose;
  String? reportContent;
  String? format;
  String? generationTrigger;
  /// Contains 0+× Recipient.
  List<RecipientEntry> recipients = [];
  String? customization;
}

/// A recipient entry (form) [PD00-USE-PRI-REP-nn-REC-nn].
class RecipientEntry {
  String? content;
  String? recipientName;
  String? role;
}

// ---------------------------------------------------------------------------
// 10.7 Error Handling
// ---------------------------------------------------------------------------

/// 10.7. Error Handling Concept [PD00-USE-ERR].
class ErrorHandlingConcept {
  String? content;

  /// 10.7.1. Validation Feedback [PD00-USE-ERR-VAL].
  String? validationFeedback;

  /// 10.7.2. System Error Display [PD00-USE-ERR-SYS].
  String? systemErrorDisplay;

  /// 10.7.3. Error Recovery [PD00-USE-ERR-REC].
  String? errorRecovery;
}

// ---------------------------------------------------------------------------
// 10.8 Help Concept
// ---------------------------------------------------------------------------

/// 10.8. Help Concept [PD00-USE-HLP].
class HelpConcept {
  String? content;

  /// 10.8.1. Contextual Help [PD00-USE-HLP-CON].
  String? contextualHelp;

  /// 10.8.2. Onboarding [PD00-USE-HLP-ONB].
  String? onboarding;

  /// 10.8.3. Support Access [PD00-USE-HLP-SUP].
  String? supportAccess;
}

// ---------------------------------------------------------------------------
// 10.9 Accessibility
// ---------------------------------------------------------------------------

/// 10.9. Accessibility [PD00-USE-ACC].
class Accessibility {
  String? content;

  /// 10.9.1. WCAG Compliance Level [PD00-USE-ACC-WCA].
  String? wcagComplianceLevel;

  /// 10.9.2. Accessibility Checklist [PD00-USE-ACC-CHK].
  AccessibilityChecklist accessibilityChecklist = AccessibilityChecklist();
}

/// 10.9.2. Accessibility Checklist [PD00-USE-ACC-CHK].
class AccessibilityChecklist {
  String? content;
  /// Contains 0+× AccessibilityCheck.
  List<AccessibilityCheckEntry> items = [];
}

/// An accessibility check entry (form) [PD00-USE-ACC-CHK-nn].
class AccessibilityCheckEntry {
  String? content;
  String? checkItem;
  String? wcagCriterion;
  String? complianceLevel;
  String? verificationMethod;
}

// ---------------------------------------------------------------------------
// 10.10 Responsive Design
// ---------------------------------------------------------------------------

/// 10.10. Responsive Design [PD00-USE-RES].
class ResponsiveDesign {
  String? content;

  /// 10.10.1. Breakpoints [PD00-USE-RES-BRE] — contains 0+× Breakpoint.
  List<BreakpointEntry> breakpoints = [];

  /// 10.10.2. Responsive Behavior [PD00-USE-RES-BEH].
  String? responsiveBehavior;
}

/// A breakpoint entry (form) [PD00-USE-RES-BRE-nn].
class BreakpointEntry {
  String? content;
  String? breakpointName;
  String? minWidth;
  String? layoutBehavior;
}

// ---------------------------------------------------------------------------
// 10.11 UI Components
// ---------------------------------------------------------------------------

/// 10.11. UI Components [PD00-USE-COM].
class UiComponents {
  String? content;

  /// 10.11.1. Component Library [PD00-USE-COM-LIB].
  String? componentLibrary;

  /// 10.11.2. Component Specifications [PD00-USE-COM-SPE] — contains 0+×.
  List<UiComponentEntry> componentSpecs = [];
}

/// A UI component entry [PD00-USE-COM-SPE-nn] (form).
class UiComponentEntry {
  String? content;
  String? componentName;
  String? purpose;
  String? behavior;
  /// Contains 0+× ComponentState.
  List<ComponentStateEntry> states = [];
  /// Contains 0+× ComponentVariant.
  List<ComponentVariantEntry> variants = [];
  String? responsive;
}

/// A component state entry (form) [PD00-USE-COM-SPE-nn-STA-nn].
class ComponentStateEntry {
  String? content;
  String? stateName;
  String? description;
}

/// A component variant entry (form) [PD00-USE-COM-SPE-nn-VAR-nn].
class ComponentVariantEntry {
  String? content;
  String? variantName;
  String? description;
}

// ---------------------------------------------------------------------------
// 10.12 Multi-language and Rollout
// ---------------------------------------------------------------------------

/// 10.12. Multi-language and Rollout Support [PD00-USE-MUL].
class MultiLanguageAndRollout {
  String? content;

  /// 10.12.1. Multi-language Support [PD00-USE-MUL-LAN].
  MultiLanguageSupport multiLanguageSupport = MultiLanguageSupport();

  /// 10.12.2. Rollout Support [PD00-USE-MUL-ROL].
  RolloutSupport rolloutSupport = RolloutSupport();
}

/// 10.12.1. Multi-language Support [PD00-USE-MUL-LAN].
class MultiLanguageSupport {
  String? content;

  /// 10.12.1.1. Localization Process [PD00-USE-MUL-LAN-LOC]. Seeds → SR.
  String? localizationProcess;

  /// 10.12.1.2. Translation Process [PD00-USE-MUL-LAN-TRA]. Seeds → SR.
  String? translationProcess;

  /// 10.12.1.3. Language and Country Selection [PD00-USE-MUL-LAN-LCS]. Seeds → UP.
  String? languageAndCountrySelection;

  /// 10.12.1.4. Translation Handling Requirements [PD00-USE-MUL-LAN-REQ]. Seeds → TR.
  String? translationHandlingRequirements;
}

/// 10.12.2. Rollout Support [PD00-USE-MUL-ROL].
class RolloutSupport {
  String? content;

  /// 10.12.2.1. User Documentation [PD00-USE-MUL-ROL-DOC]. Seeds → SR.
  String? userDocumentation;

  /// 10.12.2.2. Training Plan [PD00-USE-MUL-ROL-TRA]. Seeds → SR.
  String? trainingPlan;

  /// 10.12.2.3. Phased Deployment Strategy [PD00-USE-MUL-ROL-DEP].
  String? phasedDeploymentStrategy;

  /// 10.12.2.4. Communication Plan [PD00-USE-MUL-ROL-COM].
  String? communicationPlan;
}

// ---------------------------------------------------------------------------
// 10.13 Prototype
// ---------------------------------------------------------------------------

/// 10.13. Prototype [PD00-USE-PRO].
class Prototype {
  String? content;

  /// 10.13.1. Prototype Goals [PD00-USE-PRO-GOA] — contains 0+× PrototypeGoal.
  List<PrototypeGoalEntry> prototypeGoals = [];

  /// 10.13.2. Selected Feature Subset [PD00-USE-PRO-FEA].
  String? selectedFeatureSubset;

  /// 10.13.3. Prototype Type [PD00-USE-PRO-TYP].
  PrototypeTypeSection prototypeType = PrototypeTypeSection();
}

/// 10.13.3. Prototype Type [PD00-USE-PRO-TYP].
class PrototypeTypeSection {
  String? content;

  /// 10.13.3.1. Reusable Prototype [PD00-USE-PRO-TYP-REU].
  String? reusablePrototype;

  /// 10.13.3.2. Training Prototype [PD00-USE-PRO-TYP-TRA].
  String? trainingPrototype;

  /// 10.13.3.3. Throwaway Prototype [PD00-USE-PRO-TYP-THR].
  String? throwawayPrototype;
}

/// A prototype goal entry (form) [PD00-USE-PRO-GOA-nn].
class PrototypeGoalEntry {
  String? content;
  String? goal;
  String? description;
}
