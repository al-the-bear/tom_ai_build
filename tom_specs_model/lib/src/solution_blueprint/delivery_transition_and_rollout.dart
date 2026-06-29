/// SBP.15 — Delivery, Transition & Rollout.
///
/// Consolidates the staged delivery plan (from [SystemStagePlan]) with the
/// rollout and transition concept (from [SystemRolloutConcept]). Seeds the
/// Delivery Roadmap (DRM) and Transition & Rollout Plan (TRP) documents.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import 'system_rollout_concept.dart';
import 'system_stage_plan.dart';

/// SBP.15 Delivery, Transition & Rollout.
///
/// Public anchor: PMBOK phasing + ISO 29148 transition requirements.
@SectionId('DTRO')
class DeliveryTransitionAndRollout {
  @Unused()
  String? content;

  /// Staged delivery / phase plan.
  SystemStagePlan systemStagePlan = SystemStagePlan();

  /// Rollout and transition concept.
  SystemRolloutConcept systemRolloutConcept = SystemRolloutConcept();
}
