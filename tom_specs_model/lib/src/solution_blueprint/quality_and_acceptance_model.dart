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
}
