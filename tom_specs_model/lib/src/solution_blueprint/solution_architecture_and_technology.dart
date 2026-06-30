/// SBP.11 — Solution Architecture & Technology.
///
/// Consolidates the technical solution framing: the technology framework
/// concept (from [TechnicalFrameworkConcept]) and the catalogue of components
/// to use (from [ComponentsAndDependencies]). Seeds the Architecture & Technology
/// Specification (ATS) document.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import 'components.dart';
import 'technical_framework.dart';

/// SBP.11 Solution Architecture & Technology.
///
/// Public anchor: ISO/IEC/IEEE 42010 architecture description.
@SectionId('SOAT')
class SolutionArchitectureAndTechnology {
  @Unused()
  String? content;

  /// Technical framework and platform concept.
  TechnicalFrameworkConcept technicalFramework = TechnicalFrameworkConcept();

  /// Components, libraries, and services to reuse.
  ComponentsAndDependencies componentsToUse = ComponentsAndDependencies();
}
