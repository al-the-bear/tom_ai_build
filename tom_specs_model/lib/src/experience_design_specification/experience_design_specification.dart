/// D09 — Experience Design Specification.
///
/// Phase 3 DocSpec root class. Aggregates 12 top-level sections projected
/// from the corresponding Solution Blueprint experience-design sections.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../common/review_team.dart';
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
  description:
      'Full UI design and prototype specification — vision, '
      'screens, flow, print, errors, help, accessibility, responsive '
      'design, components, language selection, prototype, and '
      'wireframes/mockups.',
  basedOn: [D00SolutionBlueprint],
)
@SectionId('XDS')
class D09ExperienceDesignSpecification extends DocSpecsSection {
  @ContentHelp('Executive overview of the UI prototype and design system.')
  @override
  @SerializationOrder(0)
  String? content;

  /// Standard TomSpecs document header.
  @SerializationOrder(1)
  DocumentHeader header = DocumentHeader();

  /// This document's own review team; when it has members it replaces the
  /// Solution Blueprint's team for this document type and its default team.
  @SerializationOrder(2)
  ReviewTeam reviewTeam = ReviewTeam();

  /// Chronological revision history of this document, with the reviewers of
  /// each revision.
  @StandardReferences([
    'ISO/IEC/IEEE 29148:2018 §6 — front matter (revision history)',
  ], 'The ordered set of published revisions of this document.')
  @SectionId('RVENT-REVS-LST')
  @SectionIdPattern('RVENT-REVS-xxx')
  @ContentHelp(
    'Add one entry per revision, newest last: version, date, author, a short '
    'summary, the review team the round started with and the reviewers who '
    'returned a copy.',
  )
  @SerializationOrder(3)
  List<RevisionEntry> revisionHistory = [];

  /// Design vision.
  @SerializationOrder(4)
  DesignVision designVision = DesignVision();

  /// Screen descriptions.
  @SerializationOrder(5)
  ScreenDescriptions screens = ScreenDescriptions();

  /// Screen flow structure.
  @SerializationOrder(6)
  ScreenFlowStructure screenFlow = ScreenFlowStructure();

  /// Print layout.
  @SerializationOrder(7)
  PrintAndExportLayout printLayout = PrintAndExportLayout();

  /// Report definitions — the CE-RP report projections over the domain model.
  @SerializationOrder(8)
  ReportDefinitions reportDefinitions = ReportDefinitions();

  /// Error handling concept.
  @SerializationOrder(9)
  ErrorHandling errorHandling = ErrorHandling();

  /// Help concept.
  @SerializationOrder(10)
  UserAssistance userAssistance = UserAssistance();

  /// Accessibility.
  @SerializationOrder(11)
  Accessibility accessibility = Accessibility();

  /// Responsive design.
  @SerializationOrder(12)
  ResponsiveDesign responsiveDesign = ResponsiveDesign();

  /// UI components.
  @SerializationOrder(13)
  UiComponents uiComponents = UiComponents();

  /// Language and country selection.
  @SerializationOrder(14)
  LanguageCountrySelection languageCountrySelection =
      LanguageCountrySelection();

  /// Prototype.
  @SerializationOrder(15)
  Prototype prototype = Prototype();

  /// Wireframes and mockups (new in Phase A).
  ///
  /// One whole-catalog content section; collapsed from
  /// `List<WireframesAndMockups>` (L34C-12 SR-52).
  @SerializationOrder(16)
  WireframesAndMockups wireframesAndMockups = WireframesAndMockups();
}
