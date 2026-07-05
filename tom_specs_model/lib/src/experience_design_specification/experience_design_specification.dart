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
@StandardReferences(
  [
    'ISO 9241-210:2019 — human-centred design for interactive systems',
    'WCAG 2.2 — web content accessibility guidelines',
  ],
  'The full UI design and prototype specification covering vision, screens, flow, accessibility, responsive design, components, localization, and wireframes.',
)
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
  @SerializationOrder(0)
  String? content;

  /// Standard TomSpecs document header.
  @SerializationOrder(1)
  DocumentHeader header = DocumentHeader();

  /// Design vision.
  @SerializationOrder(2)
  DesignVision designVision = DesignVision();

  /// Screen descriptions.
  @SerializationOrder(3)
  ScreenDescriptions screens = ScreenDescriptions();

  /// Screen flow structure.
  @SerializationOrder(4)
  ScreenFlowStructure screenFlow = ScreenFlowStructure();

  /// Print layout.
  @SerializationOrder(5)
  PrintAndExportLayout printLayout = PrintAndExportLayout();

  /// Error handling concept.
  @SerializationOrder(6)
  ErrorHandling errorHandling = ErrorHandling();

  /// Help concept.
  @SerializationOrder(7)
  UserAssistance userAssistance = UserAssistance();

  /// Accessibility.
  @SerializationOrder(8)
  Accessibility accessibility = Accessibility();

  /// Responsive design.
  @SerializationOrder(9)
  ResponsiveDesign responsiveDesign = ResponsiveDesign();

  /// UI components.
  @SerializationOrder(10)
  UiComponents uiComponents = UiComponents();

  /// Language and country selection.
  @SerializationOrder(11)
  LanguageCountrySelection languageCountrySelection =
      LanguageCountrySelection();

  /// Prototype.
  @SerializationOrder(12)
  Prototype prototype = Prototype();

  /// Wireframes and mockups (new in Phase A).
  ///
  /// One whole-catalog content section; collapsed from
  /// `List<WireframesAndMockups>` (L34C-12 SR-52).
  @SerializationOrder(13)
  WireframesAndMockups wireframesAndMockups = WireframesAndMockups();
}
