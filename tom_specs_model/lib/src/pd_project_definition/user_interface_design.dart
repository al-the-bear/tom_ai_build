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
@SectionId('PD00-USE-VIS')
class DesignVision {
  @Unused()
  String? content;

  /// 10.1.1. Design Goals [PD00-USE-VIS-GOA] — contains 0+× DesignGoal.
  @SectionIdPattern('PD00-USE-VIS-GOA-xx')
  List<DesignGoalEntry> designGoals = [];

  /// 10.1.2. Design Principles [PD00-USE-VIS-PRI] — contains 0+× UiDesignPrinciple.
  @SectionIdPattern('PD00-USE-VIS-PRI-xx')
  List<UiDesignPrincipleEntry> designPrinciples = [];

  /// 10.1.3. User Personas [PD00-USE-VIS-PER] — contains 1+× Persona.
  @SectionIdPattern('PD00-USE-VIS-PER-xx')
  @Min(1)
  List<PersonaEntry> personas = [];
}

/// A design goal entry (form) [PD00-USE-VIS-GOA-nn].
class DesignGoalEntry {
  @Form([
    Field('goal', String, 'Goal', required: true),
    Field('description', String, 'Short description'),
  ])
  String? content;
}

/// A design principle entry (form) [PD00-USE-VIS-PRI-nn].
class UiDesignPrincipleEntry {
  @Form([
    Field('principle', String, 'Principle', required: true),
    Field('rationale', String, 'Rationale'),
  ])
  String? content;
}

/// A user persona entry [PD00-USE-VIS-PER-nn] (form).
class PersonaEntry {
  @Form([
    Field('personaName', String, 'Persona Name', required: true),
    Field('age', String, 'Age'),
    Field('role', String, 'Role'),
    Field('technicalProficiency', String, 'Technical Proficiency'),
    Field('typicalUsage', String, 'Typical Usage'),
    Field('device', String, 'Device'),
  ])
  String? content;

  /// Contains 0+× PersonaGoal.
  @SectionIdPattern('PD00-USE-VIS-PER-xx-GOA-xx')
  List<PersonaGoalEntry> goals = [];

  /// Contains 0+× PersonaPainPoint.
  @SectionIdPattern('PD00-USE-VIS-PER-xx-PAI-xx')
  List<PersonaPainPointEntry> painPoints = [];
}

/// A persona goal entry (form) [PD00-USE-VIS-PER-nn-GOA-nn].
class PersonaGoalEntry {
  @Form([
    Field('goal', String, 'Goal', required: true),
    Field('priority', String, 'Priority level'),
  ])
  String? content;
}

/// A pain point entry (form) [PD00-USE-VIS-PER-nn-PAI-nn].
class PersonaPainPointEntry {
  @Form([
    Field('painPoint', String, 'Pain Point', required: true),
    Field('impact', String, 'Impact assessment'),
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

  /// 10.2.1. Screen Inventory [PD00-USE-SCR-INV] — contains 1+× Screen.
  @SectionIdPattern('PD00-USE-SCR-INV-xx')
  @Min(1)
  List<ScreenEntry> screenInventory = [];

  /// Information Architecture.
  TextSection informationArchitecture = TextSection();
}

/// A screen entry [PD00-USE-SCR-INV-nn] (form).
class ScreenEntry {
  @Form([
    Field('screenId', String, 'Screen Id', required: true),
    Field('screenName', String, 'Screen Name', required: true),
    Field('purpose', String, 'Purpose'),
    Field('accessLevel', String, 'Access Level'),
    Field('layout', String, 'Layout'),
  ])
  String? content;

  /// Contains 0+× ScreenElement.
  @SectionIdPattern('PD00-USE-SCR-INV-xx-ELE-xx')
  List<ScreenElementEntry> keyElements = [];

  /// Contains 0+× ScreenUserCategory.
  @SectionIdPattern('PD00-USE-SCR-INV-xx-UCT-xx')
  List<ScreenUserCategoryEntry> userCategories = [];

  /// Contains 0+× Point.
  @SectionIdPattern('PD00-USE-SCR-INV-xx-EPT-xx')
  List<EntryPointEntry> entryPoints = [];
}

/// A screen element entry (form) [PD00-USE-SCR-INV-nn-ELE-nn].
class ScreenElementEntry {
  @Form([
    Field('elementName', String, 'Element Name'),
    Field('elementType', String, 'Element Type'),
  ])
  String? content;
}

/// A user category entry (form) [PD00-USE-SCR-INV-nn-UCT-nn].
class ScreenUserCategoryEntry {
  @Form([
    Field('categoryName', String, 'Category Name', required: true),
    Field('description', String, 'Short description'),
  ])
  String? content;
}

/// An entry point entry (form) [PD00-USE-SCR-INV-nn-EPT-nn].
class EntryPointEntry {
  @Form([
    Field('entryPoint', String, 'Entry Point'),
    Field('source', String, 'Source'),
  ])
  String? content;
}

// ---------------------------------------------------------------------------
// 10.3 Screen Flow Structure
// ---------------------------------------------------------------------------

/// 10.3. Screen Flow Structure [PD00-USE-SCF].
@SectionId('PD00-USE-SCF')
class ScreenFlowStructure {
  @Unused()
  String? content;

  /// Navigation Model.
  TextSection navigationModel = TextSection();

  /// 10.3.2. Screen Flow Diagram [PD00-USE-SCF-DIA] (mermaid).
  FlowDiagramSection screenFlowDiagram = FlowDiagramSection();
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
