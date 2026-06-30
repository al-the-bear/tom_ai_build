/// SBP.14 — Quality & Acceptance Model.
///
/// Consolidates quality goals (from [SystemQualityGoals]) with delivery scope
/// and acceptance criteria (from [DeliveryScopeAndAcceptance]). An ISO/IEC
/// 25010:2023 product-quality cross-map is added in IP-6. Seeds the Quality &
/// Acceptance Plan (QAP) document.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/enums.dart';
import 'delivery_scope_and_acceptance.dart';
import 'quality_model.dart';

/// SBP.14 Quality & Acceptance Model.
@StandardReferences(
  ['ISO/IEC 25010:2023 — product quality model'],
  'The product-quality goals the solution is measured against, together with '
  'the scope and criteria for accepting delivery.',
)
@SectionId('QACM')
class QualityAndAcceptanceModel {
  @Unused()
  @SerializationOrder(0)
  String? content;

  /// Quality goals and attributes.
  @SerializationOrder(1)
  SystemQualityGoals systemQualityGoals = SystemQualityGoals();

  /// Delivery scope and acceptance criteria.
  @SerializationOrder(2)
  DeliveryScopeAndAcceptance deliveryAcceptance = DeliveryScopeAndAcceptance();

  /// ISO/IEC 25010:2023 product-quality cross-map (§5 completeness addition).
  @SerializationOrder(3)
  Iso25010Coverage iso25010Coverage = Iso25010Coverage();
}

/// ISO/IEC 25010:2023 product-quality cross-map (derived).
///
/// A *derived* view over the canonical quality spine: the eight
/// `*Characteristic` classes under [SystemQualityGoals] are the single source
/// of truth for the taxonomy (L34C-8); this cross-map does not re-declare it.
/// Each entry references one of those characteristics (via the closed
/// [Iso25010Characteristic] enum) and records which quality goals / NFRs
/// address it and the target metric — so coverage of any 25010:2023
/// characteristic (e.g. compatibility, flexibility) cannot be silently missed.
@SectionId('I25CV')
class Iso25010Coverage {
  @ContentType('description', 'Summarize how the quality goals cover the '
      'eight ISO/IEC 25010:2023 characteristics. The taxonomy itself is owned '
      'by the SystemQualityGoals characteristic spine; this is a derived '
      'coverage view, not a second copy of the taxonomy.')
  @SerializationOrder(0)
  String? content;

  /// One entry per ISO/IEC 25010:2023 characteristic addressed.
  @SectionId('I25CV-CHAR-LST')
  @SectionIdPattern('I25CV-CHAR-xxx')
  @ContentHelp('Add one entry per ISO/IEC 25010:2023 characteristic '
      '(functional suitability, performance efficiency, compatibility, '
      'interaction capability, reliability, security, maintainability, '
      'flexibility).')
  @SerializationOrder(1)
  List<Iso25010CoverageEntry> characteristics = [];
}

/// A single ISO/IEC 25010:2023 coverage entry (form).
@SectionId('I25CE')
class Iso25010CoverageEntry {
  @Form([
    Field('characteristic', Iso25010Characteristic,
        'ISO/IEC 25010:2023 Characteristic',
        required: true),
    Field('addressedBy', String, 'Addressed By (which quality goals / NFRs)'),
    Field('targetMetric', String, 'Target Metric'),
  ])
  @SerializationOrder(0)
  String? content;
}
