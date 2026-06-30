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
@StandardReferences(
  ['ISO/IEC/IEEE 42010:2011 — architecture description'],
  'The technical solution framing: the architecture description plus the '
  'technology and components the solution is built from.',
)
@SectionId('SOAT')
class SolutionArchitectureAndTechnology {
  @Unused()
  @SerializationOrder(0)
  String? content;

  /// Technical framework and platform concept.
  @SerializationOrder(1)
  TechnicalFrameworkConcept technicalFramework = TechnicalFrameworkConcept();

  /// Components, libraries, and services to reuse.
  @SerializationOrder(2)
  ComponentsAndDependencies componentsToUse = ComponentsAndDependencies();
}
