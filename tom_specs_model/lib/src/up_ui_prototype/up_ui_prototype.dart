/// UP — UI Prototype.
///
/// Phase 3 DocSpec root class. Aggregates 12 top-level sections from
/// 11 PD00-USE-* seeds plus PD00-USE-MUL-LCS (multi-source) per §5.8
/// of second_wave_documents.md.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../pd_project_definition/pd_project_definition.dart';

/// UP00 UI Prototype.
///
/// Full UI design and prototype specification — vision, screens,
/// screen flow, print, error handling, help, accessibility, responsive,
/// components, language/country selection, prototype, wireframes and
/// mockups.
@Document(
  name: 'UI Prototype',
  description: 'Full UI design and prototype specification — vision, '
      'screens, flow, print, errors, help, accessibility, responsive '
      'design, components, language selection, prototype, and '
      'wireframes/mockups.',
  basedOn: [ProjectDefinition],
)
@SectionId('UP')
class UiPrototype {
  @ContentHelp('Executive overview of the UI prototype and design system.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  /// Design vision — PD00-USE-VIS.
  DesignVision designVision = DesignVision();

  /// Screen descriptions — PD00-USE-SCR.
  ScreenDescriptions screens = ScreenDescriptions();

  /// Screen flow structure — PD00-USE-SCF.
  ScreenFlowStructure screenFlow = ScreenFlowStructure();

  /// Print layout — PD00-USE-PRI.
  PrintLayout printLayout = PrintLayout();

  /// Error handling concept — PD00-USE-ERR.
  ErrorHandlingConcept errorHandling = ErrorHandlingConcept();

  /// Help concept — PD00-USE-HLP.
  HelpConcept helpConcept = HelpConcept();

  /// Accessibility — PD00-USE-ACC.
  Accessibility accessibility = Accessibility();

  /// Responsive design — PD00-USE-RES.
  ResponsiveDesign responsiveDesign = ResponsiveDesign();

  /// UI components — PD00-USE-COM.
  UiComponents uiComponents = UiComponents();

  /// Language and country selection — PD00-USE-MUL-LCS.
  LanguageCountrySelection languageCountrySelection =
      LanguageCountrySelection();

  /// Prototype — PD00-USE-PRO.
  Prototype prototype = Prototype();

  /// Wireframes and mockups — PD00-USE-WIR (new in Phase A, HBSG AS10-WIR).
  @SectionId('WIANMO-WIRE-LST')
  @SectionIdPattern('WIANMO-WIRE-xxx')
  List<WireframesAndMockups> wireframesAndMockups = [];
}
