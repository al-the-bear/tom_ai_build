/// Section 10: User Interface Design and Prototype [PD00-USE].
///
/// Seeds → UP, SR, TR depending on subsection.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 10. User Interface Design and Prototype [PD00-USE].
@tomReflector
class UserInterfaceDesign {
  final String? content;

  /// 10.1. Design Vision [PD00-USE-VIS]. Seeds → UP.
  final DesignVision designVision;

  /// 10.2. Screen Descriptions [PD00-USE-SCR]. Seeds → UP.
  final ScreenDescriptions screens;

  /// 10.3. Screen Flow Structure [PD00-USE-SCF]. Seeds → UP.
  final ScreenFlowStructure screenFlow;

  /// 10.4. Print Layout [PD00-USE-PRI]. Seeds → UP.
  final PrintLayout printLayout;

  /// 10.5. Data Structure Alignment [PD00-USE-DAT]. Seeds → UP.
  final String? dataStructureAlignment;

  /// 10.6. Authorization Concept Compliance [PD00-USE-AUT]. Seeds → UP.
  final String? authorizationCompliance;

  /// 10.7. Error Handling Concept [PD00-USE-ERR]. Seeds → UP.
  final ErrorHandlingConcept errorHandling;

  /// 10.8. Help Concept [PD00-USE-HLP]. Seeds → UP.
  final HelpConcept helpConcept;

  /// 10.9. Accessibility [PD00-USE-ACC]. Seeds → UP.
  final Accessibility accessibility;

  /// 10.10. Responsive Design [PD00-USE-RES]. Seeds → UP.
  final ResponsiveDesign responsiveDesign;

  /// 10.11. UI Components [PD00-USE-COM]. Seeds → UP.
  final UiComponents uiComponents;

  /// 10.12. Multi-language and Rollout Support [PD00-USE-MUL].
  final MultiLanguageAndRollout multiLanguage;

  /// 10.13. Prototype [PD00-USE-PRO]. Seeds → UP.
  final Prototype prototype;

  const UserInterfaceDesign({
    this.content,
    this.designVision = const DesignVision(),
    this.screens = const ScreenDescriptions(),
    this.screenFlow = const ScreenFlowStructure(),
    this.printLayout = const PrintLayout(),
    this.dataStructureAlignment,
    this.authorizationCompliance,
    this.errorHandling = const ErrorHandlingConcept(),
    this.helpConcept = const HelpConcept(),
    this.accessibility = const Accessibility(),
    this.responsiveDesign = const ResponsiveDesign(),
    this.uiComponents = const UiComponents(),
    this.multiLanguage = const MultiLanguageAndRollout(),
    this.prototype = const Prototype(),
  });
}

// ---------------------------------------------------------------------------
// 10.1 Design Vision
// ---------------------------------------------------------------------------

/// 10.1. Design Vision [PD00-USE-VIS].
@tomReflector
class DesignVision {
  final String? content;

  /// 10.1.1. Design Goals [PD00-USE-VIS-GOA].
  final List<String> designGoals;

  /// 10.1.2. Design Principles [PD00-USE-VIS-PRI].
  final List<String> designPrinciples;

  /// 10.1.3. User Personas [PD00-USE-VIS-PER] — contains 1+× Persona.
  final List<PersonaEntry> personas;

  const DesignVision({
    this.content,
    this.designGoals = const [],
    this.designPrinciples = const [],
    this.personas = const [],
  });
}

/// A user persona entry [PD00-USE-VIS-PER-nn] (form).
@tomReflector
class PersonaEntry {
  final String? content;
  final String? personaName;
  final String? age;
  final String? role;
  final List<String> goals;
  final List<String> painPoints;
  final String? technicalProficiency;
  final String? typicalUsage;
  final String? device;

  const PersonaEntry({
    this.content,
    this.personaName,
    this.age,
    this.role,
    this.goals = const [],
    this.painPoints = const [],
    this.technicalProficiency,
    this.typicalUsage,
    this.device,
  });
}

// ---------------------------------------------------------------------------
// 10.2 Screen Descriptions
// ---------------------------------------------------------------------------

/// 10.2. Screen Descriptions [PD00-USE-SCR].
@tomReflector
class ScreenDescriptions {
  final String? content;

  /// 10.2.1. Screen Inventory [PD00-USE-SCR-INV] — contains 1+× Screen.
  final List<ScreenEntry> screenInventory;

  /// 10.2.2. Information Architecture [PD00-USE-SCR-INF].
  final String? informationArchitecture;

  const ScreenDescriptions({
    this.content,
    this.screenInventory = const [],
    this.informationArchitecture,
  });
}

/// A screen entry [PD00-USE-SCR-INV-nn] (form).
@tomReflector
class ScreenEntry {
  final String? content;
  final String? screenId;
  final String? screenName;
  final String? purpose;
  final List<String> keyElements;
  final List<String> userCategories;
  final String? accessLevel;
  final List<String> entryPoints;
  final String? layout;

  const ScreenEntry({
    this.content,
    this.screenId,
    this.screenName,
    this.purpose,
    this.keyElements = const [],
    this.userCategories = const [],
    this.accessLevel,
    this.entryPoints = const [],
    this.layout,
  });
}

// ---------------------------------------------------------------------------
// 10.3 Screen Flow Structure
// ---------------------------------------------------------------------------

/// 10.3. Screen Flow Structure [PD00-USE-SCF].
@tomReflector
class ScreenFlowStructure {
  final String? content;

  /// 10.3.1. Navigation Model [PD00-USE-SCF-NAV].
  final String? navigationModel;

  /// 10.3.2. Screen Flow Diagram [PD00-USE-SCF-DIA] (mermaid).
  final String? screenFlowDiagram;

  const ScreenFlowStructure({
    this.content,
    this.navigationModel,
    this.screenFlowDiagram,
  });
}

// ---------------------------------------------------------------------------
// 10.4 Print Layout
// ---------------------------------------------------------------------------

/// 10.4. Print Layout [PD00-USE-PRI].
@tomReflector
class PrintLayout {
  final String? content;

  /// 10.4.1. Reports [PD00-USE-PRI-REP] — contains 0+× Report.
  final List<ReportEntry> reports;

  /// 10.4.2. Export Formats [PD00-USE-PRI-EXP].
  final List<String> exportFormats;

  const PrintLayout({
    this.content,
    this.reports = const [],
    this.exportFormats = const [],
  });
}

/// A report entry [PD00-USE-PRI-REP-nn] (form).
@tomReflector
class ReportEntry {
  final String? content;
  final String? reportName;
  final String? purpose;
  final String? reportContent;
  final String? format;
  final String? generationTrigger;
  final List<String> recipients;
  final String? customization;

  const ReportEntry({
    this.content,
    this.reportName,
    this.purpose,
    this.reportContent,
    this.format,
    this.generationTrigger,
    this.recipients = const [],
    this.customization,
  });
}

// ---------------------------------------------------------------------------
// 10.7 Error Handling
// ---------------------------------------------------------------------------

/// 10.7. Error Handling Concept [PD00-USE-ERR].
@tomReflector
class ErrorHandlingConcept {
  final String? content;

  /// 10.7.1. Validation Feedback [PD00-USE-ERR-VAL].
  final String? validationFeedback;

  /// 10.7.2. System Error Display [PD00-USE-ERR-SYS].
  final String? systemErrorDisplay;

  /// 10.7.3. Error Recovery [PD00-USE-ERR-REC].
  final String? errorRecovery;

  const ErrorHandlingConcept({
    this.content,
    this.validationFeedback,
    this.systemErrorDisplay,
    this.errorRecovery,
  });
}

// ---------------------------------------------------------------------------
// 10.8 Help Concept
// ---------------------------------------------------------------------------

/// 10.8. Help Concept [PD00-USE-HLP].
@tomReflector
class HelpConcept {
  final String? content;

  /// 10.8.1. Contextual Help [PD00-USE-HLP-CON].
  final String? contextualHelp;

  /// 10.8.2. Onboarding [PD00-USE-HLP-ONB].
  final String? onboarding;

  /// 10.8.3. Support Access [PD00-USE-HLP-SUP].
  final String? supportAccess;

  const HelpConcept({
    this.content,
    this.contextualHelp,
    this.onboarding,
    this.supportAccess,
  });
}

// ---------------------------------------------------------------------------
// 10.9 Accessibility
// ---------------------------------------------------------------------------

/// 10.9. Accessibility [PD00-USE-ACC].
@tomReflector
class Accessibility {
  final String? content;

  /// 10.9.1. WCAG Compliance Level [PD00-USE-ACC-WCA].
  final String? wcagComplianceLevel;

  /// 10.9.2. Accessibility Checklist [PD00-USE-ACC-CHK].
  final AccessibilityChecklist accessibilityChecklist;

  const Accessibility({
    this.content,
    this.wcagComplianceLevel,
    this.accessibilityChecklist = const AccessibilityChecklist(),
  });
}

/// 10.9.2. Accessibility Checklist [PD00-USE-ACC-CHK].
@tomReflector
class AccessibilityChecklist {
  final String? content;
  final List<AccessibilityCheckEntry> items;

  const AccessibilityChecklist({this.content, this.items = const []});
}

/// An accessibility check entry (form).
@tomReflector
class AccessibilityCheckEntry {
  final String? content;
  final String? checkItem;
  final String? wcagCriterion;
  final String? complianceLevel;
  final String? verificationMethod;

  const AccessibilityCheckEntry({
    this.content,
    this.checkItem,
    this.wcagCriterion,
    this.complianceLevel,
    this.verificationMethod,
  });
}

// ---------------------------------------------------------------------------
// 10.10 Responsive Design
// ---------------------------------------------------------------------------

/// 10.10. Responsive Design [PD00-USE-RES].
@tomReflector
class ResponsiveDesign {
  final String? content;

  /// 10.10.1. Breakpoints [PD00-USE-RES-BRE].
  final List<String> breakpoints;

  /// 10.10.2. Responsive Behavior [PD00-USE-RES-BEH].
  final String? responsiveBehavior;

  const ResponsiveDesign({
    this.content,
    this.breakpoints = const [],
    this.responsiveBehavior,
  });
}

// ---------------------------------------------------------------------------
// 10.11 UI Components
// ---------------------------------------------------------------------------

/// 10.11. UI Components [PD00-USE-COM].
@tomReflector
class UiComponents {
  final String? content;

  /// 10.11.1. Component Library [PD00-USE-COM-LIB].
  final String? componentLibrary;

  /// 10.11.2. Component Specifications [PD00-USE-COM-SPE] — contains 0+×.
  final List<UiComponentEntry> componentSpecs;

  const UiComponents({
    this.content,
    this.componentLibrary,
    this.componentSpecs = const [],
  });
}

/// A UI component entry [PD00-USE-COM-SPE-nn] (form).
@tomReflector
class UiComponentEntry {
  final String? content;
  final String? componentName;
  final String? purpose;
  final String? behavior;
  final List<String> states;
  final List<String> variants;
  final String? responsive;

  const UiComponentEntry({
    this.content,
    this.componentName,
    this.purpose,
    this.behavior,
    this.states = const [],
    this.variants = const [],
    this.responsive,
  });
}

// ---------------------------------------------------------------------------
// 10.12 Multi-language and Rollout
// ---------------------------------------------------------------------------

/// 10.12. Multi-language and Rollout Support [PD00-USE-MUL].
@tomReflector
class MultiLanguageAndRollout {
  final String? content;

  /// 10.12.1. Localization Process [PD00-USE-MUL-LOC]. Seeds → SR.
  final String? localizationProcess;

  /// 10.12.2. Translation Process [PD00-USE-MUL-TRA]. Seeds → SR.
  final String? translationProcess;

  /// 10.12.3. System User Documentation and Training [PD00-USE-MUL-DOC]. Seeds → SR.
  final String? userDocumentationAndTraining;

  /// 10.12.4. Language and Country Selection [PD00-USE-MUL-LCS]. Seeds → UP.
  final String? languageAndCountrySelection;

  /// 10.12.5. Translation Handling Requirements [PD00-USE-MUL-REQ]. Seeds → TR.
  final String? translationHandlingRequirements;

  const MultiLanguageAndRollout({
    this.content,
    this.localizationProcess,
    this.translationProcess,
    this.userDocumentationAndTraining,
    this.languageAndCountrySelection,
    this.translationHandlingRequirements,
  });
}

// ---------------------------------------------------------------------------
// 10.13 Prototype
// ---------------------------------------------------------------------------

/// 10.13. Prototype [PD00-USE-PRO].
@tomReflector
class Prototype {
  final String? content;

  /// 10.13.1. Prototype Goals [PD00-USE-PRO-GOA].
  final List<String> prototypeGoals;

  /// 10.13.2. Selected Feature Subset [PD00-USE-PRO-FEA].
  final String? selectedFeatureSubset;

  /// 10.13.3. Prototype Type [PD00-USE-PRO-TYP].
  final PrototypeTypeSection prototypeType;

  const Prototype({
    this.content,
    this.prototypeGoals = const [],
    this.selectedFeatureSubset,
    this.prototypeType = const PrototypeTypeSection(),
  });
}

/// 10.13.3. Prototype Type [PD00-USE-PRO-TYP].
@tomReflector
class PrototypeTypeSection {
  final String? content;

  /// 10.13.3.1. Reusable Prototype [PD00-USE-PRO-TYP-REU].
  final String? reusablePrototype;

  /// 10.13.3.2. Training Prototype [PD00-USE-PRO-TYP-TRA].
  final String? trainingPrototype;

  /// 10.13.3.3. Throwaway Prototype [PD00-USE-PRO-TYP-THR].
  final String? throwawayPrototype;

  const PrototypeTypeSection({
    this.content,
    this.reusablePrototype,
    this.trainingPrototype,
    this.throwawayPrototype,
  });
}
