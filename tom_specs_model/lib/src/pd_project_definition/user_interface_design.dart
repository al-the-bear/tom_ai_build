import '../common/enums.dart';

/// Section 10: User Interface Design and Prototype [PD00-USE].
///
/// Seeds → UP, SR, TR depending on subsection.
class UserInterfaceDesign {
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
class DesignVision {
  /// 10.1.1. Design Goals [PD00-USE-VIS-GOA].
  final String? designGoals;

  /// 10.1.2. Design Principles [PD00-USE-VIS-PRI].
  final String? designPrinciples;

  /// 10.1.3. User Personas [PD00-USE-VIS-PER] — contains 1+× Persona.
  final List<Persona> personas;

  const DesignVision({
    this.designGoals,
    this.designPrinciples,
    this.personas = const [],
  });
}

/// A user persona [PD00-USE-VIS-PER-nn].
class Persona {
  final String personaName;
  final int? age;
  final String role;
  final String goals;
  final String? painPoints;
  final TechnicalProficiency? technicalProficiency;
  final String? typicalUsage;
  final String? device;

  const Persona({
    required this.personaName,
    this.age,
    required this.role,
    required this.goals,
    this.painPoints,
    this.technicalProficiency,
    this.typicalUsage,
    this.device,
  });
}

// ---------------------------------------------------------------------------
// 10.2 Screen Descriptions
// ---------------------------------------------------------------------------

/// 10.2. Screen Descriptions [PD00-USE-SCR].
class ScreenDescriptions {
  /// 10.2.1. Screen Inventory [PD00-USE-SCR-INV] — contains 1+× Screen.
  final List<Screen> screenInventory;

  /// 10.2.2. Information Architecture [PD00-USE-SCR-INF].
  final String? informationArchitecture;

  const ScreenDescriptions({
    this.screenInventory = const [],
    this.informationArchitecture,
  });
}

/// An application screen [PD00-USE-SCR-INV-nn].
class Screen {
  final String screenId;
  final String screenName;
  final String purpose;
  final String? keyElements;
  final String? userCategories;
  final String? accessLevel;
  final String? entryPoints;
  final String? layout;

  const Screen({
    required this.screenId,
    required this.screenName,
    required this.purpose,
    this.keyElements,
    this.userCategories,
    this.accessLevel,
    this.entryPoints,
    this.layout,
  });
}

// ---------------------------------------------------------------------------
// 10.3 Screen Flow Structure
// ---------------------------------------------------------------------------

/// 10.3. Screen Flow Structure [PD00-USE-SCF].
class ScreenFlowStructure {
  /// 10.3.1. Navigation Model [PD00-USE-SCF-NAV].
  final String? navigationModel;

  /// 10.3.2. Screen Flow Diagram [PD00-USE-SCF-DIA] (mermaid).
  final String? screenFlowDiagram;

  const ScreenFlowStructure({
    this.navigationModel,
    this.screenFlowDiagram,
  });
}

// ---------------------------------------------------------------------------
// 10.4 Print Layout
// ---------------------------------------------------------------------------

/// 10.4. Print Layout [PD00-USE-PRI].
class PrintLayout {
  /// 10.4.1. Reports [PD00-USE-PRI-REP] — contains 0+× Report.
  final List<Report> reports;

  /// 10.4.2. Export Formats [PD00-USE-PRI-EXP].
  final String? exportFormats;

  const PrintLayout({
    this.reports = const [],
    this.exportFormats,
  });
}

/// A report definition [PD00-USE-PRI-REP-nn].
class Report {
  final String reportName;
  final String purpose;
  final String? content;
  final String? format;
  final String? generationTrigger;
  final String? recipients;
  final String? customization;

  const Report({
    required this.reportName,
    required this.purpose,
    this.content,
    this.format,
    this.generationTrigger,
    this.recipients,
    this.customization,
  });
}

// ---------------------------------------------------------------------------
// 10.7 Error Handling
// ---------------------------------------------------------------------------

/// 10.7. Error Handling Concept [PD00-USE-ERR].
class ErrorHandlingConcept {
  final String? validationFeedback;
  final String? systemErrorDisplay;
  final String? errorRecovery;

  const ErrorHandlingConcept({
    this.validationFeedback,
    this.systemErrorDisplay,
    this.errorRecovery,
  });
}

// ---------------------------------------------------------------------------
// 10.8 Help Concept
// ---------------------------------------------------------------------------

/// 10.8. Help Concept [PD00-USE-HLP].
class HelpConcept {
  final String? contextualHelp;
  final String? onboarding;
  final String? supportAccess;

  const HelpConcept({
    this.contextualHelp,
    this.onboarding,
    this.supportAccess,
  });
}

// ---------------------------------------------------------------------------
// 10.9 Accessibility
// ---------------------------------------------------------------------------

/// 10.9. Accessibility [PD00-USE-ACC].
class Accessibility {
  final String? wcagComplianceLevel;
  final String? accessibilityChecklist;

  const Accessibility({
    this.wcagComplianceLevel,
    this.accessibilityChecklist,
  });
}

// ---------------------------------------------------------------------------
// 10.10 Responsive Design
// ---------------------------------------------------------------------------

/// 10.10. Responsive Design [PD00-USE-RES].
class ResponsiveDesign {
  final String? breakpoints;
  final String? responsiveBehavior;

  const ResponsiveDesign({
    this.breakpoints,
    this.responsiveBehavior,
  });
}

// ---------------------------------------------------------------------------
// 10.11 UI Components
// ---------------------------------------------------------------------------

/// 10.11. UI Components [PD00-USE-COM].
class UiComponents {
  /// 10.11.1. Component Library [PD00-USE-COM-LIB].
  final String? componentLibrary;

  /// 10.11.2. Component Specifications — contains 0+× UiComponentSpec.
  final List<UiComponentSpec> componentSpecs;

  const UiComponents({
    this.componentLibrary,
    this.componentSpecs = const [],
  });
}

/// A UI component specification [PD00-USE-COM-SPE-nn].
class UiComponentSpec {
  final String componentName;
  final String purpose;
  final String? behavior;
  final String? states;
  final String? variants;
  final String? responsive;

  const UiComponentSpec({
    required this.componentName,
    required this.purpose,
    this.behavior,
    this.states,
    this.variants,
    this.responsive,
  });
}

// ---------------------------------------------------------------------------
// 10.12 Multi-language and Rollout
// ---------------------------------------------------------------------------

/// 10.12. Multi-language and Rollout Support [PD00-USE-MUL].
class MultiLanguageAndRollout {
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
class Prototype {
  /// 10.13.1. Prototype Goals [PD00-USE-PRO-GOA].
  final String? prototypeGoals;

  /// 10.13.2. Selected Feature Subset [PD00-USE-PRO-FEA].
  final String? selectedFeatureSubset;

  /// 10.13.3. Prototype Type [PD00-USE-PRO-TYP].
  final PrototypeType? prototypeType;

  /// Description for the chosen prototype type.
  final String? prototypeTypeDescription;

  const Prototype({
    this.prototypeGoals,
    this.selectedFeatureSubset,
    this.prototypeType,
    this.prototypeTypeDescription,
  });
}
