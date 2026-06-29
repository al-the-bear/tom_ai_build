/// D09 — Experience Design Specification.
///
/// Phase 3 DocSpec root class. Aggregates 12 top-level sections projected
/// from the corresponding Solution Blueprint experience-design sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// XDS00 Experience Design Specification.
///
/// Full UI design and prototype specification — vision, screens,
/// screen flow, print, error handling, help, accessibility, responsive,
/// components, language/country selection, prototype, wireframes and
/// mockups.
@Document(
  name: 'Experience Design Specification',
  description: 'Full UI design and prototype specification — vision, '
      'screens, flow, print, errors, help, accessibility, responsive '
      'design, components, language selection, prototype, and '
      'wireframes/mockups.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('XDS')
class D09ExperienceDesignSpecification {
  @ContentHelp('Executive overview of the UI prototype and design system.')
  String? content;

  /// Standard TomSpecs document header.
  DocumentHeader header = DocumentHeader();

  /// Design vision.
  DesignVision designVision = DesignVision();

  /// Screen descriptions.
  ScreenDescriptions screens = ScreenDescriptions();

  /// Screen flow structure.
  ScreenFlowStructure screenFlow = ScreenFlowStructure();

  /// Print layout.
  PrintLayout printLayout = PrintLayout();

  /// Error handling concept.
  ErrorHandlingConcept errorHandling = ErrorHandlingConcept();

  /// Help concept.
  HelpConcept helpConcept = HelpConcept();

  /// Accessibility.
  Accessibility accessibility = Accessibility();

  /// Responsive design.
  ResponsiveDesign responsiveDesign = ResponsiveDesign();

  /// UI components.
  UiComponents uiComponents = UiComponents();

  /// Language and country selection.
  LanguageCountrySelection languageCountrySelection =
      LanguageCountrySelection();

  /// Prototype.
  Prototype prototype = Prototype();

  /// Wireframes and mockups (new in Phase A).
  @SectionId('WIANMO-WIRE-LST')
  @SectionIdPattern('WIANMO-WIRE-xxx')
  List<WireframesAndMockups> wireframesAndMockups = [];
}
