/// SBP.14 — Quality & Acceptance Model.
///
/// Consolidates quality goals (from [SystemQualityGoals]) with delivery scope
/// and acceptance criteria (from [DeliveryScopeAndAcceptance]). An ISO/IEC
/// 25010 product-quality cross-map is added in IP-6. Seeds the Quality &
/// Acceptance Plan (QAP) document.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import 'delivery_acceptance.dart';
import 'system_quality_goals.dart';

/// SBP.14 Quality & Acceptance Model.
///
/// Public anchor: ISO/IEC 25010 product quality.
@SectionId('QACM')
class QualityAndAcceptanceModel {
  @Unused()
  String? content;

  /// Quality goals and attributes.
  SystemQualityGoals systemQualityGoals = SystemQualityGoals();

  /// Delivery scope and acceptance criteria.
  DeliveryScopeAndAcceptance deliveryAcceptance = DeliveryScopeAndAcceptance();

  /// ISO/IEC 25010 product-quality cross-map (§5 completeness addition).
  Iso25010Coverage iso25010Coverage = Iso25010Coverage();
}

/// ISO/IEC 25010 product-quality cross-map.
///
/// Maps the system's quality goals onto the eight ISO/IEC 25010 product
/// quality characteristics so that compatibility and portability cannot be
/// silently missed.
@SectionId('I25CV')
class Iso25010Coverage {
  @ContentType('description', 'Summarize how the quality goals cover the '
      'eight ISO/IEC 25010 characteristics.')
  String? content;

  /// One entry per ISO/IEC 25010 characteristic addressed.
  @SectionId('I25CV-CHAR-LST')
  @SectionIdPattern('I25CV-CHAR-xxx')
  @ContentHelp('Add one entry per ISO/IEC 25010 characteristic (functional '
      'suitability, performance efficiency, compatibility, usability, '
      'reliability, security, maintainability, portability).')
  List<Iso25010CoverageEntry> characteristics = [];
}

/// A single ISO/IEC 25010 coverage entry (form).
@SectionId('I25CE')
class Iso25010CoverageEntry {
  @Form([
    Field('characteristic', String, 'ISO/IEC 25010 Characteristic',
        required: true),
    Field('addressedBy', String, 'Addressed By (which quality goals / NFRs)'),
    Field('targetMetric', String, 'Target Metric'),
  ])
  String? content;
}
